#!/usr/bin/env python3
"""
N8N MCP Server - Model Context Protocol Server for N8N Integration

This server provides MCP tools for interacting with N8N workflows through
Large Language Models (LLMs) like Claude.

Author: Ricardo Souza (@jricardosouza)
Date: 2025-10-30
License: MIT
"""

import os
import httpx
import asyncio
import logging
import re
from collections import OrderedDict
from urllib.parse import urlparse
from mcp.server.fastmcp import FastMCP
from dotenv import load_dotenv
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Carregar variáveis de ambiente
load_dotenv()

N8N_API_URL = os.getenv("N8N_API_URL")
N8N_API_KEY = os.getenv("N8N_API_KEY")

if not N8N_API_URL or not N8N_API_KEY:
    raise ValueError("N8N_API_URL e N8N_API_KEY são obrigatórios no arquivo .env")

# Validate HTTPS requirement
def validate_https_url(url: str) -> str:
    """Validate that URL uses HTTPS protocol for security"""
    parsed = urlparse(url)
    if parsed.scheme != 'https':
        raise ValueError(
            f"Security Error: API URL must use HTTPS protocol. Got: {parsed.scheme}. "
            "HTTP connections are not allowed for security reasons."
        )
    if not parsed.netloc:
        raise ValueError("Security Error: Invalid API URL format")
    return url

# Validate API URL on startup
N8N_API_URL = validate_https_url(N8N_API_URL)

# Inicializar servidor MCP
mcp = FastMCP("n8n-automation-server")


class N8NClient:
    """Cliente para interação com API do N8N com retry logic e cache"""
    
    # Security configurations
    MAX_CACHE_SIZE = 100  # Maximum number of cached items
    MAX_ENDPOINT_LENGTH = 500  # Maximum endpoint path length
    RATE_LIMIT_REQUESTS = 100  # Maximum requests per window
    RATE_LIMIT_WINDOW = 60  # Time window in seconds
    
    # Allowed endpoint patterns (whitelist approach)
    ALLOWED_ENDPOINT_PATTERNS = [
        r'^/workflows$',
        r'^/workflows/[a-zA-Z0-9_-]+$',
        r'^/workflows/[a-zA-Z0-9_-]+/execute$',
        r'^/executions$',
        r'^/executions/[a-zA-Z0-9_-]+$',
    ]

    def __init__(self):
        self.base_url = N8N_API_URL.rstrip('/')
        self.headers = {
            "X-N8N-API-KEY": N8N_API_KEY,
            "Content-Type": "application/json",
            "User-Agent": "n8n-mcp-server/2.0.0",
            "Accept": "application/json",
        }
        
        # Security: Explicit SSL/TLS verification and timeout configuration
        timeout = httpx.Timeout(
            connect=10.0,  # Connection timeout
            read=30.0,     # Read timeout
            write=10.0,    # Write timeout
            pool=5.0       # Pool timeout
        )
        
        self.client = httpx.AsyncClient(
            timeout=timeout,
            verify=True,  # Enforce SSL/TLS certificate verification
            follow_redirects=False,  # Prevent redirect-based attacks
            limits=httpx.Limits(
                max_keepalive_connections=5,
                max_connections=10,
                keepalive_expiry=5.0
            )
        )
        
        # LRU cache with size limit
        self._cache: OrderedDict[str, tuple[Any, datetime]] = OrderedDict()
        self._cache_ttl = timedelta(minutes=5)
        
        # Rate limiting
        self._rate_limit_tokens = self.RATE_LIMIT_REQUESTS
        self._rate_limit_last_reset = datetime.now()

    def _validate_endpoint(self, endpoint: str) -> str:
        """
        Validate and sanitize endpoint to prevent path traversal and injection attacks
        
        Args:
            endpoint: API endpoint path
            
        Returns:
            Sanitized endpoint
            
        Raises:
            ValueError: If endpoint is invalid or potentially malicious
        """
        # Check length
        if len(endpoint) > self.MAX_ENDPOINT_LENGTH:
            raise ValueError(f"Endpoint path too long (max {self.MAX_ENDPOINT_LENGTH} chars)")
        
        # Remove any query parameters (should use params argument instead)
        if '?' in endpoint:
            raise ValueError("Query parameters must be passed via params argument, not in endpoint")
        
        # Check for path traversal attempts
        if '..' in endpoint or '//' in endpoint:
            raise ValueError("Invalid endpoint: path traversal detected")
        
        # Ensure endpoint starts with /
        if not endpoint.startswith('/'):
            endpoint = '/' + endpoint
        
        # Validate against whitelist patterns
        endpoint_matches = any(
            re.match(pattern, endpoint) 
            for pattern in self.ALLOWED_ENDPOINT_PATTERNS
        )
        
        if not endpoint_matches:
            logger.warning(f"Endpoint not in whitelist: {endpoint}")
            # Allow but log - strict mode would raise error here
        
        return endpoint

    def _check_rate_limit(self) -> None:
        """
        Check and enforce rate limiting using token bucket algorithm
        
        Raises:
            Exception: If rate limit is exceeded
        """
        now = datetime.now()
        time_since_reset = (now - self._rate_limit_last_reset).total_seconds()
        
        # Reset tokens if window has passed
        if time_since_reset >= self.RATE_LIMIT_WINDOW:
            self._rate_limit_tokens = self.RATE_LIMIT_REQUESTS
            self._rate_limit_last_reset = now
        
        # Check if we have tokens available
        if self._rate_limit_tokens <= 0:
            wait_time = self.RATE_LIMIT_WINDOW - time_since_reset
            raise Exception(
                f"Rate limit exceeded. Maximum {self.RATE_LIMIT_REQUESTS} requests "
                f"per {self.RATE_LIMIT_WINDOW} seconds. "
                f"Please wait {wait_time:.1f} seconds."
            )
        
        # Consume a token
        self._rate_limit_tokens -= 1

    async def close(self):
        """Fechar conexões HTTP"""
        await self.client.aclose()

    def _get_cache(self, key: str) -> Optional[Any]:
        """Obter valor do cache se ainda válido"""
        if key in self._cache:
            value, timestamp = self._cache[key]
            if datetime.now() - timestamp < self._cache_ttl:
                logger.debug(f"Cache hit for endpoint")
                # Move to end for LRU
                self._cache.move_to_end(key)
                return value
            else:
                del self._cache[key]
        return None

    def _set_cache(self, key: str, value: Any):
        """Armazenar valor no cache com limite de tamanho"""
        # Enforce cache size limit (LRU eviction)
        if len(self._cache) >= self.MAX_CACHE_SIZE:
            # Remove oldest item
            self._cache.popitem(last=False)
        
        self._cache[key] = (value, datetime.now())
        logger.debug(f"Cache set for endpoint")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((httpx.NetworkError, httpx.TimeoutException)),
        reraise=True
    )
    async def _make_request(
        self,
        method: str,
        endpoint: str,
        use_cache: bool = False,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Método genérico para requisições HTTP com retry e cache

        Args:
            method: Método HTTP (GET, POST, PUT, DELETE)
            endpoint: Endpoint da API (ex: /workflows)
            use_cache: Se True, usa cache para requisições GET
            **kwargs: Argumentos adicionais para httpx

        Returns:
            Resposta JSON da API
        """
        # Security validations
        self._check_rate_limit()
        endpoint = self._validate_endpoint(endpoint)
        
        # Verificar cache para requisições GET
        cache_key = f"{method}:{endpoint}"
        if use_cache and method == "GET":
            cached_result = self._get_cache(cache_key)
            if cached_result is not None:
                return cached_result

        url = f"{self.base_url}{endpoint}"

        try:
            logger.debug(f"Requisição {method} para endpoint")
            response = await self.client.request(
                method=method,
                url=url,
                headers=self.headers,
                **kwargs
            )
            response.raise_for_status()
            result = response.json()

            # Armazenar em cache se for GET
            if use_cache and method == "GET":
                self._set_cache(cache_key, result)

            return result

        except httpx.HTTPStatusError as e:
            # Security: Don't expose sensitive details in error messages
            status_code = e.response.status_code
            logger.error(f"Erro HTTP {status_code} em requisição")
            
            # Provide user-friendly error without exposing internals
            if status_code == 401:
                error_msg = "Autenticação falhou. Verifique sua API key."
            elif status_code == 403:
                error_msg = "Acesso negado. Verifique suas permissões."
            elif status_code == 404:
                error_msg = "Recurso não encontrado."
            elif status_code >= 500:
                error_msg = "Erro no servidor N8N. Tente novamente mais tarde."
            else:
                error_msg = f"Erro HTTP {status_code}"
            
            raise Exception(f"Falha na API N8N: {error_msg}")
            
        except httpx.NetworkError as e:
            logger.error(f"Erro de rede em requisição: {type(e).__name__}")
            raise Exception(f"Erro de rede ao acessar N8N: Verifique sua conexão")
        except httpx.TimeoutException:
            logger.error(f"Timeout em requisição")
            raise Exception("Timeout ao acessar API N8N: Tente novamente")
        except Exception as e:
            logger.error(f"Erro inesperado em requisição: {type(e).__name__}")
            raise


# Instância global do cliente
n8n_client = N8NClient()


def validate_id(value: str, id_type: str = "ID") -> str:
    """
    Validate and sanitize ID inputs to prevent injection attacks
    
    Args:
        value: ID value to validate
        id_type: Type of ID for error messages
        
    Returns:
        Sanitized ID
        
    Raises:
        ValueError: If ID is invalid
    """
    if not value or not isinstance(value, str):
        raise ValueError(f"{id_type} deve ser uma string não vazia")
    
    # Trim whitespace
    value = value.strip()
    
    # Check length (reasonable limit)
    if len(value) > 100:
        raise ValueError(f"{id_type} muito longo (máximo 100 caracteres)")
    
    # Allow alphanumeric, hyphens, underscores only
    if not re.match(r'^[a-zA-Z0-9_-]+$', value):
        raise ValueError(
            f"{id_type} inválido. Apenas letras, números, hífens e underscores são permitidos"
        )
    
    return value


@mcp.tool()
async def health_check() -> Dict[str, Any]:
    """
    Verifica a conectividade e saúde da conexão com N8N

    Returns:
        Status da conexão e informações da API
    """
    try:
        start_time = datetime.now()
        data = await n8n_client._make_request("GET", "/workflows", use_cache=False)
        response_time = (datetime.now() - start_time).total_seconds()

        workflows = data.get("data", [])

        return {
            "status": "healthy",
            "api_url": n8n_client.base_url,
            "response_time_seconds": round(response_time, 3),
            "total_workflows": len(workflows),
            "timestamp": datetime.now().isoformat()
        }

    except Exception as e:
        return {
            "status": "unhealthy",
            "api_url": n8n_client.base_url,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }


@mcp.tool()
async def list_workflows(active_only: bool = False) -> List[Dict[str, Any]]:
    """
    Lista todos os workflows disponíveis na instância N8N

    Args:
        active_only: Se True, retorna apenas workflows ativos

    Returns:
        Lista de workflows com id, nome e status
    """
    try:
        data = await n8n_client._make_request("GET", "/workflows", use_cache=True)
        workflows = data.get("data", [])

        if active_only:
            workflows = [w for w in workflows if w.get("active", False)]

        # Formatar resposta
        result = []
        for workflow in workflows:
            result.append({
                "id": workflow.get("id"),
                "name": workflow.get("name"),
                "active": workflow.get("active"),
                "tags": workflow.get("tags", []),
                "created_at": workflow.get("createdAt"),
                "updated_at": workflow.get("updatedAt")
            })

        logger.info(f"Listados {len(result)} workflows")
        return result

    except Exception as e:
        logger.error(f"Erro ao listar workflows: {str(e)}")
        raise


@mcp.tool()
async def get_workflow_details(workflow_id: str) -> Dict[str, Any]:
    """
    Obtém detalhes completos de um workflow específico

    Args:
        workflow_id: ID do workflow (pode ser nome ou ID numérico)

    Returns:
        Detalhes completos do workflow incluindo nós e conexões
    """
    try:
        # Security: Validate input
        workflow_id = validate_id(workflow_id, "Workflow ID")
        
        data = await n8n_client._make_request(
            "GET",
            f"/workflows/{workflow_id}",
            use_cache=True
        )

        workflow = data.get("data", {})

        return {
            "id": workflow.get("id"),
            "name": workflow.get("name"),
            "active": workflow.get("active"),
            "nodes": workflow.get("nodes", []),
            "connections": workflow.get("connections", {}),
            "settings": workflow.get("settings", {}),
            "tags": workflow.get("tags", [])
        }

    except Exception as e:
        logger.error(f"Erro ao obter workflow: {type(e).__name__}")
        raise


@mcp.tool()
async def execute_workflow(
    workflow_id: str,
    input_data: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Executa um workflow específico do N8N

    Args:
        workflow_id: ID do workflow a ser executado
        input_data: Dados de entrada opcionais para o workflow (JSON)

    Returns:
        Resultado da execução incluindo ID de execução e status
    """
    try:
        # Security: Validate input
        workflow_id = validate_id(workflow_id, "Workflow ID")
        
        # Endpoint para execução
        endpoint = f"/workflows/{workflow_id}/execute"

        # Preparar payload
        payload = {}
        if input_data:
            payload["data"] = input_data

        # Executar workflow
        response = await n8n_client._make_request(
            "POST",
            endpoint,
            json=payload
        )

        execution = response.get("data", {})

        result = {
            "execution_id": execution.get("id"),
            "workflow_id": workflow_id,
            "status": "completed" if execution.get("finished") else "running",
            "started_at": execution.get("startedAt"),
            "finished_at": execution.get("stoppedAt"),
            "mode": execution.get("mode")
        }

        logger.info(f"Workflow executado com sucesso")
        return result

    except Exception as e:
        logger.error(f"Erro ao executar workflow: {type(e).__name__}")
        raise


@mcp.tool()
async def get_execution_status(execution_id: str) -> Dict[str, Any]:
    """
    Verifica o status de uma execução específica

    Args:
        execution_id: ID da execução a ser consultada

    Returns:
        Status e detalhes da execução
    """
    try:
        # Security: Validate input
        execution_id = validate_id(execution_id, "Execution ID")
        
        data = await n8n_client._make_request("GET", f"/executions/{execution_id}")

        execution = data.get("data", {})

        return {
            "id": execution.get("id"),
            "workflow_id": execution.get("workflowId"),
            "workflow_name": execution.get("workflowData", {}).get("name"),
            "status": "completed" if execution.get("finished") else "running",
            "started_at": execution.get("startedAt"),
            "finished_at": execution.get("stoppedAt"),
            "mode": execution.get("mode"),
            "data": execution.get("data")
        }

    except Exception as e:
        logger.error(f"Erro ao consultar execução: {type(e).__name__}")
        raise


@mcp.tool()
async def activate_workflow(workflow_id: str, active: bool = True) -> Dict[str, Any]:
    """
    Ativa ou desativa um workflow específico

    Args:
        workflow_id: ID do workflow
        active: True para ativar, False para desativar

    Returns:
        Status da operação
    """
    try:
        # Security: Validate input
        workflow_id = validate_id(workflow_id, "Workflow ID")
        
        # N8N usa PATCH para atualizar workflows
        payload = {"active": active}

        response = await n8n_client._make_request(
            "PATCH",
            f"/workflows/{workflow_id}",
            json=payload
        )

        status = "ativado" if active else "desativado"
        logger.info(f"Workflow {status} com sucesso")
        
        return {
            "success": True,
            "workflow_id": workflow_id,
            "active": active,
            "message": f"Workflow {status} com sucesso"
        }

    except Exception as e:
        logger.error(f"Erro ao modificar workflow: {type(e).__name__}")
        raise


@mcp.tool()
async def list_executions(
    workflow_id: Optional[str] = None,
    limit: int = 10
) -> List[Dict[str, Any]]:
    """
    Lista execuções recentes de workflows

    Args:
        workflow_id: ID do workflow (opcional, se não fornecido lista todas)
        limit: Número máximo de execuções a retornar (padrão: 10)

    Returns:
        Lista de execuções recentes
    """
    try:
        # Security: Validate inputs
        if workflow_id:
            workflow_id = validate_id(workflow_id, "Workflow ID")
        
        # Validate limit
        if not isinstance(limit, int) or limit < 1 or limit > 100:
            raise ValueError("Limit deve ser um inteiro entre 1 e 100")
        
        params = {"limit": limit}
        if workflow_id:
            params["workflowId"] = workflow_id

        data = await n8n_client._make_request(
            "GET",
            "/executions",
            params=params
        )

        executions = data.get("data", [])

        result = []
        for execution in executions:
            result.append({
                "id": execution.get("id"),
                "workflow_id": execution.get("workflowId"),
                "workflow_name": execution.get("workflowData", {}).get("name"),
                "status": "completed" if execution.get("finished") else "running",
                "started_at": execution.get("startedAt"),
                "finished_at": execution.get("stoppedAt"),
                "mode": execution.get("mode")
            })

        logger.info(f"Listadas {len(result)} execuções")
        return result

    except Exception as e:
        logger.error(f"Erro ao listar execuções: {type(e).__name__}")
        raise


if __name__ == "__main__":
    try:
        # Executar servidor MCP via stdio
        mcp.run(transport="stdio")
    finally:
        # Garantir fechamento de conexões
        asyncio.run(n8n_client.close())
