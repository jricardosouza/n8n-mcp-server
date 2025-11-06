# 🪟 Guia Completo de Instalação - Windows 11 Pro

Este guia fornece instruções detalhadas para configurar o N8N MCP Server no Windows 11 Pro para uso com Claude Desktop.

---

## 📋 Pré-requisitos

### 1. Python 3.10 ou Superior

**Verificar se Python está instalado:**
```powershell
python --version
```

Se não estiver instalado:

1. Acesse: https://www.python.org/downloads/
2. Baixe o instalador do Python 3.10+ para Windows
3. **IMPORTANTE**: Durante a instalação, marque a opção:
   - ✅ **"Add Python to PATH"**
4. Execute a instalação
5. Reinicie o terminal

### 2. Claude Desktop

Baixe e instale o Claude Desktop:
- https://claude.ai/download

### 3. Git (Opcional - para desenvolvimento)

Se você planeja contribuir ou fazer push de mudanças:
- https://git-scm.com/download/win

---

## 🚀 Instalação Rápida (Recomendado)

### Opção 1: Script Batch (Mais Rápido)

1. **Clone ou baixe este repositório**

2. **Abra o Command Prompt** no diretório do projeto:
   ```cmd
   cd caminho\para\n8n-mcp-server
   ```

3. **Execute o script de setup:**
   ```cmd
   setup-windows.bat
   ```

4. **Siga as instruções na tela**

### Opção 2: Script PowerShell (Completo)

1. **Abra o PowerShell** no diretório do projeto:
   ```powershell
   cd caminho\para\n8n-mcp-server
   ```

2. **Execute o script de setup:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup-windows.ps1
   ```

3. **Siga as instruções detalhadas**

---

## 🔧 Instalação Manual (Passo a Passo)

Se preferir fazer manualmente ou se os scripts falharem:

### Passo 1: Clone o Repositório

```powershell
git clone https://github.com/jricardosouza/n8n-mcp-server.git
cd n8n-mcp-server
```

Ou baixe o ZIP e extraia em uma pasta de sua escolha.

### Passo 2: Criar Virtual Environment

```powershell
python -m venv venv
```

### Passo 3: Ativar o Virtual Environment

```powershell
.\venv\Scripts\Activate.ps1
```

Se receber erro de política de execução:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\venv\Scripts\Activate.ps1
```

Você deve ver `(venv)` no início da linha do prompt.

### Passo 4: Instalar Dependências

```powershell
pip install --upgrade pip
pip install -r requirements.txt
```

### Passo 5: Configurar Credenciais N8N

1. **Copie o arquivo de exemplo:**
   ```powershell
   copy .env.example .env
   ```

2. **Edite o arquivo `.env`:**
   ```powershell
   notepad .env
   ```

3. **Configure suas credenciais:**
   ```
   N8N_API_URL=https://sua-instancia.n8n.io/api/v1
   N8N_API_KEY=sua_chave_api_n8n_aqui
   ```

   **Onde encontrar suas credenciais N8N:**
   - **URL**: Sua instância N8N (ex: `https://jricardosouza.n8n.io`)
   - **API Key**: N8N → Settings → API → Generate API Key

4. **Salve e feche o arquivo**

### Passo 6: Testar o Servidor

```powershell
python src\n8n_mcp_server.py
```

Se aparecer uma tela em branco esperando entrada, está funcionando! Pressione `Ctrl+C` para sair.

### Passo 7: Configurar Claude Desktop

1. **Localize o arquivo de configuração do Claude Desktop:**
   ```powershell
   notepad "$env:APPDATA\Claude\claude_desktop_config.json"
   ```

2. **Se o arquivo não existir, crie-o com o seguinte conteúdo:**

   **IMPORTANTE**: Substitua os caminhos pelos caminhos reais do seu sistema!

   ```json
   {
     "mcpServers": {
       "n8n-automation": {
         "command": "C:\\Users\\SeuUsuario\\caminho\\para\\n8n-mcp-server\\venv\\Scripts\\python.exe",
         "args": [
           "C:\\Users\\SeuUsuario\\caminho\\para\\n8n-mcp-server\\src\\n8n_mcp_server.py"
         ],
         "env": {
           "N8N_API_URL": "https://sua-instancia.n8n.io/api/v1",
           "N8N_API_KEY": "sua_chave_api_n8n_aqui"
         }
       }
     }
   }
   ```

3. **Obter os caminhos corretos:**

   Para o Python do venv:
   ```powershell
   cd n8n-mcp-server
   (Get-Item .\venv\Scripts\python.exe).FullName
   ```

   Para o script do servidor:
   ```powershell
   (Get-Item .\src\n8n_mcp_server.py).FullName
   ```

4. **Cole os caminhos na configuração** e substitua os valores de `N8N_API_URL` e `N8N_API_KEY`

5. **Salve o arquivo**

### Passo 8: Reiniciar Claude Desktop

1. **Feche completamente o Claude Desktop** (Clique com botão direito no ícone da bandeja → Exit)
2. **Aguarde 5 segundos**
3. **Abra o Claude Desktop novamente**

### Passo 9: Testar a Integração

No Claude Desktop, digite:

```
Verifique a saúde da conexão com N8N
```

ou

```
Liste meus workflows N8N
```

Se retornar dados dos seus workflows, está funcionando! 🎉

---

## 🛠️ Ferramentas MCP Disponíveis

Com o N8N MCP Server configurado, você pode usar estas 7 ferramentas no Claude Desktop:

### 1. `health_check` (NOVA!)
Verifica conectividade e saúde da conexão com N8N

**Exemplo:**
```
Verifique a saúde da conexão com N8N
```

### 2. `list_workflows`
Lista todos os workflows disponíveis

**Exemplo:**
```
Liste meus workflows N8N
Liste apenas os workflows ativos
```

### 3. `get_workflow_details`
Obtém detalhes completos de um workflow

**Exemplo:**
```
Mostre os detalhes do workflow "n8n-mcp-server"
```

### 4. `execute_workflow`
Executa um workflow específico

**Exemplo:**
```
Execute o workflow com ID BigjtDbJ5NfG3xNb
```

### 5. `get_execution_status`
Verifica o status de uma execução

**Exemplo:**
```
Qual o status da execução 12345?
```

### 6. `activate_workflow`
Ativa ou desativa um workflow

**Exemplo:**
```
Ative o workflow "n8n-mcp-server"
Desative o workflow BigjtDbJ5NfG3xNb
```

### 7. `list_executions`
Lista execuções recentes de workflows

**Exemplo:**
```
Liste as últimas 10 execuções
Mostre as execuções do workflow BigjtDbJ5NfG3xNb
```

---

## 🔍 Verificação e Diagnóstico

### Verificar se Python está no PATH

```powershell
python --version
pip --version
```

### Verificar se as dependências foram instaladas

```powershell
.\venv\Scripts\python.exe -c "import httpx, mcp, fastmcp; print('OK')"
```

### Verificar conectividade com N8N

```powershell
# Ler credenciais do .env
Get-Content .env

# Testar manualmente (substitua $N8N_API_KEY e $N8N_API_URL)
curl -H "X-N8N-API-KEY: $N8N_API_KEY" $N8N_API_URL/workflows
```

### Ver logs do Claude Desktop

Os logs ficam em:
```
%APPDATA%\Claude\logs\
```

Para visualizar:
```powershell
notepad "$env:APPDATA\Claude\logs\mcp.log"
```

---

## ⚠️ Problemas Comuns

### Erro: "python não é reconhecido como comando"

**Solução:**
1. Reinstale o Python marcando "Add Python to PATH"
2. Ou adicione manualmente ao PATH:
   - Pesquise "Variáveis de Ambiente" no Windows
   - Edite a variável PATH do usuário
   - Adicione: `C:\Users\SeuUsuario\AppData\Local\Programs\Python\Python310`

### Erro: "Não é possível carregar arquivo .ps1"

**Solução:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Erro: "ModuleNotFoundError: No module named 'httpx'"

**Causa:** As dependências não foram instaladas no venv correto

**Solução:**
```powershell
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Claude Desktop não reconhece o servidor

**Verificações:**

1. **Caminho do Python está correto?**
   ```powershell
   (Get-Item .\venv\Scripts\python.exe).FullName
   ```

2. **Caminho do script está correto?**
   ```powershell
   (Get-Item .\src\n8n_mcp_server.py).FullName
   ```

3. **Credenciais N8N estão corretas?**
   - Verifique o arquivo `.env`
   - Teste manualmente com curl

4. **Claude Desktop foi reiniciado completamente?**
   - Feche via bandeja do sistema
   - Aguarde 5-10 segundos
   - Abra novamente

### Servidor conecta mas não retorna dados

**Verificações:**

1. **Credenciais N8N estão corretas?**
   ```powershell
   Get-Content .env
   ```

2. **Teste direto da API N8N:**
   ```powershell
   curl -H "X-N8N-API-KEY: sua_chave" https://sua-instancia.n8n.io/api/v1/workflows
   ```

3. **Verifique logs:**
   ```powershell
   notepad "$env:APPDATA\Claude\logs\mcp.log"
   ```

---

## 🔄 Atualização do Servidor

Para atualizar o servidor com novas funcionalidades:

```powershell
cd n8n-mcp-server
git pull origin main
.\venv\Scripts\Activate.ps1
pip install --upgrade -r requirements.txt
```

Reinicie o Claude Desktop após a atualização.

---

## 🚀 Melhorias Implementadas (v2.0)

### Novas Funcionalidades

1. **Retry Logic com Tenacity**
   - Até 3 tentativas automáticas em caso de falhas de rede
   - Backoff exponencial entre tentativas

2. **Cache Inteligente**
   - Cache de 5 minutos para requisições GET
   - Reduz latência e carga na API N8N

3. **Health Check Tool**
   - Nova ferramenta para verificar conectividade
   - Retorna tempo de resposta e status da API

4. **Melhor Tratamento de Erros**
   - Mensagens de erro mais informativas
   - Diferentes tipos de erro (rede, timeout, HTTP)

5. **Logging Aprimorado**
   - Logs mais detalhados para diagnóstico
   - Debug mode disponível

---

## 📚 Documentação Adicional

- **TROUBLESHOOTING.md** - Resolução de problemas detalhada
- **CLAUDE_DESKTOP_SETUP.md** - Setup original para macOS
- **CLOUD_SYNC_GUIDE.md** - Sincronização multi-dispositivo
- **VSCODE_PUSH_GUIDE.md** - Guia de push via VS Code com Claude Code

---

## 🔒 Segurança

### Melhores Práticas

1. **Nunca commite o arquivo `.env`**
   - Já está no `.gitignore`
   - Contém suas credenciais secretas

2. **Use credenciais exclusivas para o MCP Server**
   - Gere uma API Key específica no N8N
   - Revogue se necessário

3. **Mantenha o software atualizado**
   - Atualize Python regularmente
   - Atualize as dependências do projeto

4. **Proteja o arquivo de configuração do Claude**
   - `claude_desktop_config.json` contém credenciais
   - Não compartilhe este arquivo

---

## ✅ Checklist de Instalação

- [ ] Python 3.10+ instalado
- [ ] Python adicionado ao PATH
- [ ] Repositório clonado/baixado
- [ ] Virtual environment criado
- [ ] Dependências instaladas
- [ ] Arquivo `.env` configurado com credenciais N8N
- [ ] Servidor testado manualmente
- [ ] Claude Desktop instalado
- [ ] `claude_desktop_config.json` configurado
- [ ] Claude Desktop reiniciado
- [ ] Teste com "Liste meus workflows N8N" funcionando

---

## 🆘 Suporte

Se ainda houver problemas após seguir este guia:

1. **Verifique a documentação:**
   - `TROUBLESHOOTING.md`
   - README.md

2. **Colete informações de diagnóstico:**
   ```powershell
   python --version
   pip list
   Get-Content .env
   notepad "$env:APPDATA\Claude\logs\mcp.log"
   ```

3. **Abra uma issue no GitHub:**
   - https://github.com/jricardosouza/n8n-mcp-server/issues
   - Inclua informações de diagnóstico
   - Descreva o problema detalhadamente

---

## 🎉 Conclusão

Parabéns! Seu N8N MCP Server está configurado e pronto para uso no Windows 11 Pro.

**Teste agora:**
```
Liste meus workflows N8N
```

**Aproveite a automação poderosa do N8N diretamente no Claude Desktop!** 🚀

---

**Autor**: Ricardo Souza (@jricardosouza)
**Última Atualização**: 06 de Novembro de 2025
**Versão**: 2.0.0
**Plataforma**: Windows 11 Pro
