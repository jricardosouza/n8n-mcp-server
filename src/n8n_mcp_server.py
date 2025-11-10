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

# Inicializar servidor MCP
mcp = FastMCP("n8n-automation-server")


class N8NClient:
    """Cliente para interação com API do N8N com retry logic e cache"""

    def __init__(self):
        self.base_url = N8N_API_URL.rstrip('/')
        self.headers = {
            "X-N8N-API-KEY": N8N_API_KEY,
            "Content-Type": "application/json"
        }
        self.client = httpx.AsyncClient(timeout=30.0)
        self._cache: Dict[str, tuple[Any, datetime]] = {}
        self._cache_ttl = timedelta(minutes=5)

    async def close(self):
        """Fechar conexões HTTP"""
        await self.client.aclose()

    def _get_cache(self, key: str) -> Optional[Any]:
        """Obter valor do cache se ainda válido"""
        if key in self._cache:
            value, timestamp = self._cache[key]
            if datetime.now() - timestamp < self._cache_ttl:
                logger.debug(f"Cache hit: {key}")
                return value
            else:
                del self._cache[key]
        return None

    def _set_cache(self, key: str, value: Any):
        """Armazenar valor no cache"""
        self._cache[key] = (value, datetime.now())
        logger.debug(f"Cache set: {key}")

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
        # Verificar cache para requisições GET
        cache_key = f"{method}:{endpoint}"
        if use_cache and method == "GET":
            cached_result = self._get_cache(cache_key)
            if cached_result is not None:
                return cached_result

        url = f"{self.base_url}{endpoint}"

        try:
            logger.debug(f"Requisição {method} para {endpoint}")
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
            error_detail = e.response.text if hasattr(e.response, 'text') else 'Sem detalhes'
            logger.error(f"Erro HTTP {e.response.status_code} em {endpoint}: {error_detail}")
            raise Exception(
                f"Falha na API N8N ({e.response.status_code}): "
                f"{error_detail[:100]}"
            )
        except httpx.NetworkError as e:
            logger.error(f"Erro de rede em {endpoint}: {str(e)}")
            raise Exception(f"Erro de rede ao acessar N8N: Verifique sua conexão")
        except httpx.TimeoutException:
            logger.error(f"Timeout em {endpoint}")
            raise Exception("Timeout ao acessar API N8N: Tente novamente")
        except Exception as e:
            logger.error(f"Erro inesperado em {endpoint}: {str(e)}")
            raise


# Instância global do cliente
n8n_client = N8NClient()


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
        logger.error(f"Erro ao obter workflow {workflow_id}: {str(e)}")
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

        logger.info(f"Workflow {workflow_id} executado: {result['execution_id']}")
        return result

    except Exception as e:
        logger.error(f"Erro ao executar workflow {workflow_id}: {str(e)}")
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
        logger.error(f"Erro ao consultar execução {execution_id}: {str(e)}")
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
        # N8N usa PATCH para atualizar workflows
        payload = {"active": active}

        response = await n8n_client._make_request(
            "PATCH",
            f"/workflows/{workflow_id}",
            json=payload
        )

        status = "ativado" if active else "desativado"
        logger.info(f"Workflow {workflow_id} {status} com sucesso")
        
        return {
            "success": True,
            "workflow_id": workflow_id,
            "active": active,
            "message": f"Workflow {status} com sucesso"
        }

    except Exception as e:
        logger.error(f"Erro ao modificar workflow {workflow_id}: {str(e)}")
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
        logger.error(f"Erro ao listar execuções: {str(e)}")
        raise


if __name__ == "__main__":
    try:
        # Executar servidor MCP via stdio
        mcp.run(transport="stdio")
    finally:
        # Garantir fechamento de conexões
        asyncio.run(n8n_client.close())
