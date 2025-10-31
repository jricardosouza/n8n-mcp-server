# Configuração do N8N MCP Server para Claude Desktop

## 📋 Pré-requisitos

1. Python 3.10 ou superior instalado
2. Credenciais do N8N (API URL e API Key)
3. Claude Desktop instalado

## 🚀 Instalação Rápida

### 1. Instalar Dependências

```bash
# Navegue até o diretório do projeto
cd /caminho/para/n8n-mcp-server

# Crie e ative o ambiente virtual (opcional mas recomendado)
python3 -m venv venv

# Ativar ambiente virtual:
# No macOS/Linux:
source venv/bin/activate
# No Windows:
.\venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt
```

### 2. Configurar Variáveis de Ambiente

Edite o arquivo `.env` na raiz do projeto:

```env
N8N_API_URL=https://sua-instancia.app.n8n.cloud/api/v1
N8N_API_KEY=sua_chave_api_aqui
```

### 3. Testar o Servidor Localmente

```bash
python src/n8n_mcp_server.py
```

Se não houver erros, o servidor está pronto para uso!

## 🔧 Configuração no Claude Desktop

### Para macOS

1. Localize o arquivo de configuração:
```bash
~/Library/Application Support/Claude/claude_desktop_config.json
```

2. Adicione a seguinte configuração:

```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "python3",
      "args": [
        "/CAMINHO/ABSOLUTO/PARA/n8n-mcp-server/src/n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://sua-instancia.app.n8n.cloud/api/v1",
        "N8N_API_KEY": "sua_chave_api_aqui"
      }
    }
  }
}
```

**IMPORTANTE**: 
- Substitua `/CAMINHO/ABSOLUTO/PARA/` pelo caminho completo real
- Substitua as credenciais do N8N pelas suas

### Para Windows

1. Localize o arquivo de configuração:
```
%APPDATA%\Claude\claude_desktop_config.json
```

2. Adicione a seguinte configuração:

```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "python",
      "args": [
        "C:\\CAMINHO\\COMPLETO\\PARA\\n8n-mcp-server\\src\\n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://sua-instancia.app.n8n.cloud/api/v1",
        "N8N_API_KEY": "sua_chave_api_aqui"
      }
    }
  }
}
```

**IMPORTANTE para Windows**: 
- Use barras duplas `\\` nos caminhos
- Substitua pelo caminho completo real
- Substitua as credenciais do N8N pelas suas

### Para iOS (Claude Mobile)

O Claude Mobile não suporta servidores MCP locais diretamente. Para usar no iOS:

1. **Opção 1**: Deploy em servidor remoto (veja seção de deployment)
2. **Opção 2**: Use Claude Desktop em um Mac

## 🧪 Testar a Integração

1. **Reinicie o Claude Desktop** completamente (feche e reabra)

2. **Teste com comandos** como:
```
Liste meus workflows N8N
```

```
Execute o workflow "AI Agent workflow"
```

```
Mostre os detalhes do workflow n8n-mcp-server
```

```
Quais foram as últimas execuções?
```

## 🛠️ Ferramentas Disponíveis

O servidor MCP oferece as seguintes ferramentas:

1. **list_workflows** - Lista todos os workflows
   - Parâmetro opcional: `active_only` (bool)

2. **get_workflow_details** - Obtém detalhes de um workflow
   - Parâmetro: `workflow_id` (string)

3. **execute_workflow** - Executa um workflow
   - Parâmetros: `workflow_id` (string), `input_data` (dict, opcional)

4. **get_execution_status** - Verifica status de uma execução
   - Parâmetro: `execution_id` (string)

5. **activate_workflow** - Ativa/desativa um workflow
   - Parâmetros: `workflow_id` (string), `active` (bool)

6. **list_executions** - Lista execuções recentes
   - Parâmetros opcionais: `workflow_id` (string), `limit` (int)

## 🔍 Troubleshooting

### Erro: "N8N_API_KEY não encontrada"
- Verifique se o arquivo `.env` existe
- Confirme que as variáveis estão no formato correto
- Para Claude Desktop, verifique a seção `env` no JSON

### Erro: "Connection timeout"
- Verifique se a URL do N8N está correta
- Teste a conectividade: `curl -H "X-N8N-API-KEY: sua_chave" sua_url/workflows`
- Aumente o timeout se necessário

### Erro: "Tool not found in Claude Desktop"
- Verifique se o caminho está correto e absoluto
- Reinicie o Claude Desktop completamente
- Verifique se Python está no PATH

### Erro: "Unable to import 'mcp'"
- Execute: `pip install -r requirements.txt`
- Verifique se está usando o Python correto

## 📝 Exemplo de Configuração Completa

### macOS Example:

```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "python3",
      "args": [
        "/Users/ricardo/Desktop/n8n-mcp-server/src/n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://jricardosouza.app.n8n.cloud/api/v1",
        "N8N_API_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    }
  }
}
```

### Windows Example:

```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "python",
      "args": [
        "C:\\Users\\Ricardo\\Desktop\\n8n-mcp-server\\src\\n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://jricardosouza.app.n8n.cloud/api/v1",
        "N8N_API_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    }
  }
}
```

## 🔐 Segurança

- **NUNCA** commite o arquivo `.env` com credenciais reais
- **NUNCA** compartilhe suas API Keys publicamente
- Use o `.env.example` como template
- Revogue e gere novas credenciais se forem expostas

## 📚 Recursos Adicionais

- [Documentação MCP](https://modelcontextprotocol.io/)
- [API N8N](https://docs.n8n.io/api/)
- [Claude Desktop](https://claude.ai/download)

## ✅ Checklist Final

Antes de usar em produção:

- [ ] Dependências instaladas (`pip install -r requirements.txt`)
- [ ] Arquivo `.env` configurado com credenciais válidas
- [ ] Teste local funcionando (`python src/n8n_mcp_server.py`)
- [ ] Claude Desktop configurado com caminho absoluto correto
- [ ] Claude Desktop reiniciado
- [ ] Teste de conectividade com N8N bem-sucedido
- [ ] Comandos de teste no Claude Desktop funcionando

---

**Versão**: 1.0.0  
**Data**: 30 de Outubro de 2025  
**Autor**: Ricardo Souza (@jricardosouza)
