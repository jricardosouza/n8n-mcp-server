# 🤖 N8N MCP Server

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/jricardosouza/n8n-mcp-server)
[![Python](https://img.shields.io/badge/python-3.10+-green.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/jricardosouza/n8n-mcp-server)

Um servidor MCP (Model Context Protocol) profissional e completo que integra o N8N com Claude Desktop, permitindo controlar workflows de automação através de linguagem natural.

---

## ✨ Características

- 🚀 **7 Ferramentas MCP** para controle completo do N8N
- 🔄 **Retry Logic** automático com backoff exponencial
- 💾 **Cache Inteligente** para otimização de performance
- 🏥 **Health Check** para monitoramento de conectividade
- 🪟 **Suporte Windows 11 Pro** com scripts automatizados
- 🍎 **Suporte macOS** testado e documentado
- 🐧 **Compatível com Linux** via Codespaces
- 📚 **Documentação Completa** e detalhada
- 🔒 **Seguro** com credenciais isoladas
- ⚡ **Pronto para Produção**

---

## 🎯 O que Este Servidor Faz?

Transforme comandos em linguagem natural em ações no N8N:

```
Você: "Liste meus workflows N8N"
Claude: Retorna lista de todos os workflows

Você: "Execute o workflow de backup"
Claude: Executa o workflow especificado

Você: "Verifique a saúde da conexão com N8N"
Claude: Retorna status, tempo de resposta e quantidade de workflows
```

---

## 🛠️ Ferramentas MCP Disponíveis

### 1. **health_check** ⭐ NOVO!
Verifica conectividade e saúde da conexão com N8N
- Retorna status da API
- Tempo de resposta em segundos
- Quantidade total de workflows
- Timestamp da verificação

### 2. **list_workflows**
Lista todos os workflows disponíveis
- Filtragem por workflows ativos
- Informações de nome, ID, status, tags
- Datas de criação e atualização

### 3. **get_workflow_details**
Obtém detalhes completos de um workflow
- Estrutura de nós (nodes)
- Conexões entre nós
- Configurações do workflow
- Tags e metadados

### 4. **execute_workflow**
Executa um workflow específico
- Suporte a dados de entrada customizados
- Retorna ID de execução
- Status da execução

### 5. **get_execution_status**
Verifica status de uma execução
- Status (running/completed)
- Timestamps de início e término
- Dados de retorno

### 6. **activate_workflow**
Ativa ou desativa workflows
- Controle de estado (ativo/inativo)
- Confirmação de operação

### 7. **list_executions**
Lista execuções recentes
- Filtragem por workflow
- Limite configurável de resultados
- Histórico completo de execuções

---

## 🚀 Instalação Rápida

### Windows 11 Pro

**Opção 1: Script Automatizado (Recomendado)**
```powershell
# Clone o repositório
git clone https://github.com/jricardosouza/n8n-mcp-server.git
cd n8n-mcp-server

# Execute o script de setup
.\setup-windows.bat
```

**Opção 2: Setup Completo com PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File setup-windows.ps1
```

📖 **Documentação Completa**: [WINDOWS_SETUP.md](WINDOWS_SETUP.md)

### macOS

```bash
# Clone o repositório
git clone https://github.com/jricardosouza/n8n-mcp-server.git
cd n8n-mcp-server

# Crie virtual environment
python3 -m venv venv
source venv/bin/activate

# Instale dependências
pip install -r requirements.txt

# Configure credenciais
cp .env.example .env
nano .env  # Configure N8N_API_URL e N8N_API_KEY
```

📖 **Documentação Completa**: [CLAUDE_DESKTOP_SETUP.md](CLAUDE_DESKTOP_SETUP.md)

### GitHub Codespaces

1. Acesse: https://github.com/jricardosouza/n8n-mcp-server
2. Clique em `Code` → `Codespaces` → `Create codespace on main`
3. Configure secrets:
   - `N8N_API_URL`
   - `N8N_API_KEY`

📖 **Documentação Completa**: [CODESPACE_SETUP.md](CODESPACE_SETUP.md)

---

## ⚙️ Configuração

### 1. Credenciais N8N

Edite o arquivo `.env`:

```env
N8N_API_URL=https://sua-instancia.n8n.io/api/v1
N8N_API_KEY=sua_chave_api_n8n_aqui
```

**Como obter API Key do N8N:**
1. Acesse sua instância N8N
2. Settings → API
3. Generate API Key
4. Copie a chave gerada

### 2. Claude Desktop

**Windows:**
```powershell
# Localização do arquivo de configuração
%APPDATA%\Claude\claude_desktop_config.json
```

**macOS:**
```bash
# Localização do arquivo de configuração
~/Library/Application Support/Claude/claude_desktop_config.json
```

**Exemplo de configuração:**
```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "/caminho/completo/para/venv/bin/python",
      "args": [
        "/caminho/completo/para/src/n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://sua-instancia.n8n.io/api/v1",
        "N8N_API_KEY": "sua_chave_api_n8n_aqui"
      }
    }
  }
}
```

---

## 🧪 Teste

### Teste Manual do Servidor

**Windows:**
```powershell
.\venv\Scripts\python.exe src\n8n_mcp_server.py
```

**macOS/Linux:**
```bash
./venv/bin/python src/n8n_mcp_server.py
```

Se aparecer uma tela em branco esperando entrada, está funcionando! Pressione `Ctrl+C` para sair.

### Teste no Claude Desktop

Após configurar e reiniciar o Claude Desktop:

```
Verifique a saúde da conexão com N8N
```

Resposta esperada:
```json
{
  "status": "healthy",
  "api_url": "https://sua-instancia.n8n.io/api/v1",
  "response_time_seconds": 0.234,
  "total_workflows": 5,
  "timestamp": "2025-11-06T12:34:56"
}
```

---

## 📚 Documentação

### Guias de Instalação
- 🪟 [**WINDOWS_SETUP.md**](WINDOWS_SETUP.md) - Setup completo para Windows 11 Pro
- 🍎 [**CLAUDE_DESKTOP_SETUP.md**](CLAUDE_DESKTOP_SETUP.md) - Setup para macOS
- ☁️ [**CODESPACE_SETUP.md**](CODESPACE_SETUP.md) - Setup via GitHub Codespaces
- ☁️ [**CLOUD_SYNC_GUIDE.md**](CLOUD_SYNC_GUIDE.md) - Sincronização multi-dispositivo

### Guias de Uso
- 🚀 [**VSCODE_PUSH_GUIDE.md**](VSCODE_PUSH_GUIDE.md) - Como fazer push via VS Code
- 🔧 [**TROUBLESHOOTING.md**](TROUBLESHOOTING.md) - Resolução de problemas
- ✅ [**RESOLVED.md**](RESOLVED.md) - Problemas já resolvidos

---

## 🆕 Novidades da Versão 2.0

### Melhorias de Performance
- ⚡ **Retry Logic Automático**: Até 3 tentativas com backoff exponencial
- 💾 **Cache Inteligente**: Cache de 5 minutos para requisições GET
- 🏥 **Health Check Tool**: Nova ferramenta de diagnóstico

### Melhorias de Erro
- 🎯 **Erros Específicos**: Distinção entre erros de rede, timeout e HTTP
- 📝 **Mensagens Detalhadas**: Erros mais informativos para diagnóstico
- 🔍 **Logging Aprimorado**: Logs mais detalhados com níveis debug

### Suporte a Plataformas
- 🪟 **Windows 11 Pro**: Scripts automatizados e documentação completa
- 🍎 **macOS**: Testado e validado
- 🐧 **Linux/Codespaces**: Suporte via container

### Ferramentas de Desenvolvimento
- 📦 **Scripts de Setup**: PowerShell e Batch para Windows
- 📖 **Documentação Expandida**: 6 guias detalhados
- 🔧 **Guia de Push**: Instruções para VS Code com Claude Code

---

## 🔒 Segurança

### Melhores Práticas Implementadas

✅ **Credenciais Isoladas**
- Arquivo `.env` não é commitado (`.gitignore`)
- Variáveis de ambiente separadas
- Suporte a secrets do GitHub Codespaces

✅ **Validação de Entrada**
- Validação de credenciais no startup
- Timeout de 30 segundos para requisições
- Tratamento robusto de erros

✅ **Segurança de Rede**
- Retry limitado a 3 tentativas
- Backoff exponencial para evitar sobrecarga
- Verificação de status HTTP

---

## 🛠️ Desenvolvimento

### Estrutura do Projeto

```
n8n-mcp-server/
├── src/
│   └── n8n_mcp_server.py       # Servidor MCP principal
├── .devcontainer/
│   └── devcontainer.json        # Configuração Codespace
├── .vscode/
│   ├── settings.json            # Configurações VS Code
│   ├── extensions.json          # Extensões recomendadas
│   └── tasks.json               # Tasks automatizadas
├── setup-windows.ps1            # Setup PowerShell para Windows
├── setup-windows.bat            # Setup Batch para Windows
├── requirements.txt             # Dependências Python
├── .env.example                 # Template de credenciais
├── .gitignore                   # Arquivos ignorados
├── WINDOWS_SETUP.md             # Guia Windows
├── CLAUDE_DESKTOP_SETUP.md      # Guia macOS
├── CODESPACE_SETUP.md           # Guia Codespaces
├── VSCODE_PUSH_GUIDE.md         # Guia de push
├── TROUBLESHOOTING.md           # Resolução de problemas
├── CLOUD_SYNC_GUIDE.md          # Sincronização
├── RESOLVED.md                  # Problemas resolvidos
└── README.md                    # Este arquivo
```

### Dependências

```
mcp >= 0.9.0         # Model Context Protocol
fastmcp >= 0.2.0     # FastMCP framework
httpx >= 0.24.0      # Cliente HTTP async
python-dotenv >= 1.0.0  # Gerenciamento de .env
tenacity >= 8.2.0    # Retry logic
```

### Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit suas mudanças: `git commit -m 'feat: Nova funcionalidade'`
4. Push para a branch: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

📖 Veja também: [VSCODE_PUSH_GUIDE.md](VSCODE_PUSH_GUIDE.md)

---

## 🐛 Troubleshooting

### Windows

**Erro: "python não é reconhecido como comando"**
- Reinstale Python marcando "Add Python to PATH"

**Erro: "ModuleNotFoundError"**
```powershell
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Claude Desktop não reconhece o servidor**
- Verifique caminhos no `claude_desktop_config.json`
- Reinicie Claude Desktop completamente (Fechar via bandeja)

### macOS

**Erro: "ModuleNotFoundError: No module named 'httpx'"**
```bash
source venv/bin/activate
pip install -r requirements.txt
```

**Servidor conecta mas não retorna dados**
- Verifique credenciais N8N no `.env`
- Teste: `curl -H "X-N8N-API-KEY: $N8N_API_KEY" $N8N_API_URL/workflows`

📖 **Documentação Completa**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 📊 Status do Projeto

- ✅ **Código**: 100% funcional e testado
- ✅ **Documentação**: Completa e detalhada
- ✅ **Windows**: Totalmente suportado (v2.0)
- ✅ **macOS**: Totalmente suportado
- ✅ **Linux/Codespaces**: Totalmente suportado
- ✅ **Testes**: Validado em produção
- ✅ **Segurança**: Credenciais isoladas
- ✅ **Performance**: Otimizado com cache e retry

---

## 📝 Licença

MIT License - Veja [LICENSE](LICENSE) para detalhes.

---

## 👤 Autor

**Ricardo Souza** ([@jricardosouza](https://github.com/jricardosouza))

- **Criado**: 30 de Outubro de 2025
- **Última Atualização**: 06 de Novembro de 2025
- **Versão**: 2.0.0

---

## 🙏 Agradecimentos

- [Anthropic](https://www.anthropic.com/) - Claude AI e Claude Code
- [N8N](https://n8n.io/) - Plataforma de automação
- [Model Context Protocol](https://github.com/anthropics/mcp) - Framework MCP

---

## 🔗 Links Úteis

- **Repositório**: https://github.com/jricardosouza/n8n-mcp-server
- **Issues**: https://github.com/jricardosouza/n8n-mcp-server/issues
- **N8N Cloud**: https://n8n.io/cloud
- **Claude Desktop**: https://claude.ai/download
- **Documentação MCP**: https://modelcontextprotocol.io/

---

**⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!**
