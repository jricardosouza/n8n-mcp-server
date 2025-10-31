# Sincronização de Configurações do VS Code na Nuvem

Este guia explica como sincronizar as configurações do workspace N8N MCP Server com o VS Code na nuvem (Settings Sync).

## 🌐 Ativar Settings Sync no VS Code

### 1. Ativar Sincronização

No VS Code:
1. Pressione `Cmd+Shift+P` (macOS) ou `Ctrl+Shift+P` (Windows/Linux)
2. Digite: `Settings Sync: Turn On...`
3. Selecione `Turn On`
4. Escolha sua conta GitHub ou Microsoft

### 2. Selecionar o que Sincronizar

Marque as seguintes opções:
- ✅ Settings (Configurações)
- ✅ Extensions (Extensões)
- ✅ Keyboard Shortcuts
- ✅ User Snippets
- ✅ UI State

### 3. Configuração Automática do Workspace

As configurações específicas do workspace já estão salvas em:
- `.vscode/settings.json`
- `.vscode/extensions.json`
- `.vscode/launch.json`
- `.vscode/tasks.json`
- `.vscode/workspace-config.json`

Estes arquivos estão commitados no repositório Git e serão automaticamente carregados quando você clonar/abrir o projeto em qualquer máquina.

## 📦 Usando o Workspace em Outra Máquina

### Opção 1: Via GitHub Codespaces

1. Acesse: https://github.com/jricardosouza/n8n-mcp-server
2. Clique em `Code` → `Codespaces` → `Create codespace on main`
3. Todas as configurações serão carregadas automaticamente
4. Configure os secrets do Codespace:
   - `N8N_API_URL`
   - `N8N_API_KEY`

### Opção 2: Via Clone Local

1. Clone o repositório:
```bash
git clone https://github.com/jricardosouza/n8n-mcp-server.git
cd n8n-mcp-server
```

2. Abra no VS Code:
```bash
code .
```

3. O VS Code detectará automaticamente:
   - Configurações do workspace (`.vscode/`)
   - Extensões recomendadas
   - Tasks e launch configs

4. Instale as extensões recomendadas quando solicitado

5. Configure o `.env`:
```bash
cp .env.example .env
# Edite o .env com suas credenciais
```

6. Crie o ambiente virtual:
```bash
python3 -m venv venv
source venv/bin/activate  # macOS/Linux
# ou
.\venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

## 🔄 Sincronização Contínua

### Quando você fizer mudanças nas configurações:

1. **Configurações do Workspace** (`.vscode/*`):
   - Commit e push para o GitHub
   - Estarão disponíveis para todos que usarem o repositório

2. **Configurações Pessoais do VS Code**:
   - Sincronizadas automaticamente via Settings Sync
   - Aplicadas em todas as suas máquinas

## 🎯 Estrutura de Configuração

```
n8n-mcp-server/
├── .vscode/
│   ├── settings.json          # Configurações do workspace
│   ├── extensions.json        # Extensões recomendadas
│   ├── launch.json            # Configurações de debug
│   ├── tasks.json             # Tasks automatizadas
│   └── workspace-config.json  # Configuração consolidada
├── .devcontainer/
│   ├── devcontainer.json      # Config do Codespace
│   └── Dockerfile             # Imagem customizada
├── .github/
│   └── copilot-instructions.md # Instruções para Claude Code
├── .env                       # Credenciais (NÃO commitado)
├── .env.example               # Template de credenciais
└── .gitignore                 # Arquivos ignorados
```

## 📋 Checklist de Sincronização

Para garantir que tudo está sincronizado:

- [ ] Settings Sync ativado no VS Code
- [ ] Conta GitHub/Microsoft vinculada
- [ ] Arquivos `.vscode/*` commitados no Git
- [ ] Extensões recomendadas instaladas
- [ ] `.env` configurado localmente (não sincronizado por segurança)
- [ ] Secrets do Codespace configurados no GitHub

## 🔐 Segurança

### O que É Sincronizado:
✅ Configurações do workspace  
✅ Extensões recomendadas  
✅ Tasks e launch configs  
✅ Instruções do Copilot  

### O que NÃO É Sincronizado (por segurança):
❌ Arquivo `.env` (ignorado pelo Git)  
❌ Credenciais N8N  
❌ Tokens GitHub  
❌ Dados sensíveis  

## 🚀 Acesso Rápido

### VS Code Settings Sync Status:
- Comando: `Settings Sync: Show Synced Data`
- Atalho: Ver status na barra de status (ícone de nuvem)

### Forçar Sincronização Manual:
1. `Cmd+Shift+P` / `Ctrl+Shift+P`
2. `Settings Sync: Sync Now`

### Ver Conflitos:
1. `Cmd+Shift+P` / `Ctrl+Shift+P`
2. `Settings Sync: Show Conflicts`

## 📱 Acesso Mobile (iOS)

Para trabalhar no projeto via iOS:

1. **Usar GitHub Codespaces** (melhor opção):
   - Acesse github.com via Safari no iOS
   - Abra o repositório
   - Crie/abra um Codespace
   - Use o VS Code na web

2. **Usar App do GitHub**:
   - Visualize e edite arquivos
   - Faça commits
   - Gerencie issues e PRs

3. **Usar Working Copy + VS Code Server**:
   - Clone o repo no Working Copy
   - Configure um servidor remoto
   - Acesse via VS Code Server

## ✅ Validação

Para verificar se tudo está sincronizado:

```bash
# Clone em uma nova pasta de teste
git clone https://github.com/jricardosouza/n8n-mcp-server.git test-sync
cd test-sync
code .
```

Verifique se:
1. VS Code abre com todas as configurações
2. Extensões recomendadas são sugeridas
3. Tasks aparecem no menu Terminal > Run Task
4. Launch configs aparecem no Debug panel

---

**Última Atualização**: 30 de Outubro de 2025  
**Versão**: 1.0.0
