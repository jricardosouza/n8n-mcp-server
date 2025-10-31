# Instruções para Claude Code

Este arquivo contém instruções específicas para o Claude Code ao trabalhar neste projeto.

## 🎯 Contexto do Projeto

Este é um servidor MCP (Model Context Protocol) que integra com o N8N para permitir controle programático de workflows através de interfaces de linguagem natural.

### Tecnologias Principais

- Python 3.10+
- FastMCP (Framework MCP)
- HTTPX (Cliente HTTP Assíncrono)
- N8N API

## 📋 Padrões de Código

### Estilo

- Use Python type hints em todas as funções
- Mantenha linhas com no máximo 88 caracteres (black)
- Use docstrings no formato Google Style Python

### Logging

- Use o módulo `logging` para todos os logs
- Níveis apropriados: DEBUG, INFO, WARNING, ERROR
- Inclua contexto relevante nas mensagens

### Tratamento de Erros

- Use try/except específicos
- Log apropriado de exceções
- Mensagens de erro informativas

### Async/Await

- Use async/await consistentemente
- Evite bloqueio do loop de eventos
- Gerencie recursos corretamente

## 🔍 Áreas de Foco

Ao analisar ou modificar o código, foque em:

1. Compatibilidade com o protocolo MCP
2. Tratamento robusto de erros HTTP
3. Gestão eficiente de recursos
4. Performance em operações assíncronas
5. Segurança no manuseio de credenciais

## ⚡ Workflows Comuns

### Adicionar Nova Ferramenta MCP

```python
@mcp.tool()
async def nova_ferramenta(param1: str, param2: int = 10) -> Dict[str, Any]:
    """
    Descrição detalhada da ferramenta.
    
    Args:
        param1: Descrição do parâmetro 1
        param2: Descrição do parâmetro 2 (padrão: 10)
    
    Returns:
        Dicionário com os resultados
    """
    try:
        # Implementação
        ...
    except Exception as e:
        logger.error(f"Erro em nova_ferramenta: {str(e)}")
        raise
```

### Testes

```python
@pytest.mark.asyncio
async def test_nova_ferramenta():
    """Teste da nova ferramenta"""
    result = await nova_ferramenta("teste", 42)
    assert result["success"] is True
```

## 🚫 Anti-patterns a Evitar

1. Operações síncronas em código assíncrono
2. Credenciais hardcoded
3. Logs insuficientes
4. Try/except genéricos
5. Conexões HTTP não gerenciadas

## 📚 Recursos

- [MCP Protocol Docs](https://modelcontextprotocol.io/)
- [N8N API Reference](https://docs.n8n.io/api/)
- [FastMCP GitHub](https://github.com/jlowin/fastmcp)

## 🔐 Segurança

- NÃO commitar arquivos `.env`
- NÃO expor credenciais em logs
- SEMPRE validar input do usuário
- USAR HTTPS para todas as conexões