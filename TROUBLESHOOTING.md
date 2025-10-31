# 🔧 Guia de Resolução de Problemas - N8N MCP Server

## ❌ Problema Identificado: ModuleNotFoundError

O servidor MCP N8N não está funcionando no macOS porque as dependências Python não foram instaladas.

### Erro no Log
```
ModuleNotFoundError: No module named 'httpx'
```

**Causa**: O Claude Desktop está tentando executar `python3 src/n8n_mcp_server.py` mas as bibliotecas Python necessárias (httpx, mcp, fastmcp, etc.) não estão instaladas no ambiente Python do sistema.

---

## ✅ Solução 1: Instalar Dependências Globalmente (Mais Simples)

### Passo 1: Instalar as dependências
```bash
cd /Users/ricardo/Desktop/n8n-mcp-server
pip3 install -r requirements.txt
```

### Passo 2: Verificar instalação
```bash
python3 -c "import httpx, mcp, fastmcp; print('✓ Todas as dependências instaladas!')"
```

### Passo 3: Testar o servidor MCP
```bash
python3 src/n8n_mcp_server.py
```

Se aparecer uma tela em branco esperando entrada, está funcionando! Pressione `Ctrl+C` para sair.

### Passo 4: Reiniciar Claude Desktop
1. Feche **completamente** o Claude Desktop
2. Abra novamente
3. Teste com: "Liste meus workflows N8N"

---

## ✅ Solução 2: Usar Virtual Environment (Recomendado)

Esta solução isola as dependências e é mais profissional:

### Passo 1: Criar e ativar venv
```bash
cd /Users/ricardo/Desktop/n8n-mcp-server
python3 -m venv venv
source venv/bin/activate
```

### Passo 2: Instalar dependências no venv
```bash
pip install -r requirements.txt
```

### Passo 3: Atualizar configuração do Claude Desktop

Edite `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "n8n-automation": {
      "command": "/Users/ricardo/Desktop/n8n-mcp-server/venv/bin/python3",
      "args": [
        "/Users/ricardo/Desktop/n8n-mcp-server/src/n8n_mcp_server.py"
      ],
      "env": {
        "N8N_API_URL": "https://jricardosouza.app.n8n.cloud/api/v1",
        "N8N_API_KEY": "SEU_API_KEY_AQUI"
      }
    }
  }
}
```

**Mudança importante**: O `command` agora aponta para o Python do venv: `/Users/ricardo/Desktop/n8n-mcp-server/venv/bin/python3`

### Passo 4: Testar o servidor
```bash
source venv/bin/activate
python src/n8n_mcp_server.py
```

### Passo 5: Reiniciar Claude Desktop
1. Feche completamente o Claude Desktop
2. Abra novamente
3. Teste com: "Liste meus workflows N8N"

---

## 🔍 Verificação de Funcionamento

### Teste 1: Dependências instaladas
```bash
python3 -c "import httpx; print('httpx:', httpx.__version__)"
python3 -c "import mcp; print('mcp: OK')"
python3 -c "import fastmcp; print('fastmcp: OK')"
python3 -c "from dotenv import load_dotenv; print('python-dotenv: OK')"
```

### Teste 2: Servidor executa sem erros
```bash
cd /Users/ricardo/Desktop/n8n-mcp-server
python3 src/n8n_mcp_server.py
```

Resultado esperado:
- Tela em branco (aguardando entrada via stdio)
- **SEM** mensagens de erro como "ModuleNotFoundError"
- Pressione `Ctrl+C` para sair

### Teste 3: Claude Desktop reconhece o servidor

Após reiniciar o Claude Desktop, verifique o log:
```bash
tail -f ~/Desktop/mcp.log | grep n8n
```

Deve aparecer:
```
[info] [n8n-automation] Initializing server...
[info] [n8n-automation] Server started and connected successfully
[info] [n8n-automation] Message from server: (resposta do servidor)
```

---

## 📊 Comparação das Soluções

| Aspecto | Solução 1 (Global) | Solução 2 (Venv) |
|---------|-------------------|------------------|
| Simplicidade | ⭐⭐⭐ Muito simples | ⭐⭐ Requer mais passos |
| Isolamento | ❌ Pode causar conflitos | ✅ Totalmente isolado |
| Profissionalismo | ⭐⭐ Básico | ⭐⭐⭐ Padrão de mercado |
| Manutenção | ⭐⭐ Pode quebrar com updates | ⭐⭐⭐ Estável |

**Recomendação**: Use Solução 2 (venv) para projetos sérios, Solução 1 para testes rápidos.

---

## 🚨 Problemas Comuns

### Erro: "pip3: command not found"
```bash
# Instalar pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
rm get-pip.py
```

### Erro: "Permission denied"
Use `--user` flag:
```bash
pip3 install --user -r requirements.txt
```

### Erro: "externally-managed-environment"
No macOS com Python via Homebrew:
```bash
# Opção 1: Usar venv (recomendado)
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Opção 2: Instalar globalmente com --break-system-packages (não recomendado)
pip3 install --break-system-packages -r requirements.txt
```

### Claude Desktop não detecta mudanças
1. **Fechar completamente** o Claude Desktop (não apenas minimizar)
2. Esperar 5 segundos
3. Abrir novamente
4. Verificar o log: `tail -50 ~/Desktop/mcp.log`

---

## 📝 Checklist de Validação

- [ ] Dependências instaladas sem erros
- [ ] `python3 -c "import httpx"` funciona
- [ ] `python3 src/n8n_mcp_server.py` executa sem erros
- [ ] Claude Desktop reiniciado completamente
- [ ] Log do MCP não mostra "ModuleNotFoundError"
- [ ] Teste com: "Liste meus workflows N8N" funciona

---

## 🆘 Suporte Adicional

Se ainda houver problemas:

1. **Verifique o log completo**:
   ```bash
   tail -200 ~/Desktop/mcp.log | grep -A 10 n8n
   ```

2. **Execute com debug ativado**:
   ```bash
   cd /Users/ricardo/Desktop/n8n-mcp-server
   python3 -u src/n8n_mcp_server.py 2>&1 | tee debug.log
   ```

3. **Verifique versões**:
   ```bash
   python3 --version  # Deve ser 3.10+
   pip3 --version
   which python3
   ```

4. **Variáveis de ambiente**:
   ```bash
   cat .env
   # Confirme que N8N_API_URL e N8N_API_KEY estão corretos
   ```

---

## 🎯 Próximos Passos

Após resolver:

1. ✅ Testar todos os 6 MCP tools:
   - `list_workflows`
   - `get_workflow_details`
   - `execute_workflow`
   - `get_execution_status`
   - `activate_workflow`
   - `list_executions`

2. ✅ Configurar ambiente de desenvolvimento (opcional):
   - Instalar VS Code Python extension
   - Configurar debugger
   - Adicionar testes unitários

3. ✅ Documentar workflows N8N automatizados

---

**Data de criação**: 31 de outubro de 2025  
**Última atualização**: 31 de outubro de 2025  
**Autor**: Ricardo Souza (@jricardosouza)
