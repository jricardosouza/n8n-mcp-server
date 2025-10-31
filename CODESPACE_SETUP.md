# Configuração de Secrets do GitHub Codespace

## Passo a Passo para Configurar Secrets

### 1. Acesse a página de configurações do repositório:
https://github.com/jricardosouza/n8n-mcp-server/settings/secrets/codespaces

### 2. Adicione os seguintes secrets:

#### Secret 1: N8N_API_URL
- Nome: `N8N_API_URL`
- Valor: `https://jricardosouza.n8n.io/api/v1`

#### Secret 2: N8N_API_KEY
- Nome: `N8N_API_KEY`
- Valor: [Sua nova chave API do N8N - REVOGUE A ANTIGA PRIMEIRO]

### 3. Como usar no Codespace:

Os secrets estarão automaticamente disponíveis como variáveis de ambiente no seu Codespace.

Você pode verificar se estão configurados com:
```bash
echo $N8N_API_URL
echo $N8N_API_KEY
```

### 4. Teste de Conectividade N8N:

Execute no terminal do Codespace:
```bash
curl -H "X-N8N-API-KEY: $N8N_API_KEY" $N8N_API_URL/workflows
```

Se retornar JSON com workflows, a conexão está funcionando! ✅

## Próximos Passos no Codespace

1. Abra o Codespace que você criou
2. O ambiente já estará configurado com:
   - Python 3.10
   - Todas as extensões (Claude Code, Pylance, GitLens)
   - Dependências instaladas automaticamente
3. Os secrets estarão disponíveis como variáveis de ambiente
4. Execute o servidor MCP:
   ```bash
   python src/n8n_mcp_server.py
   ```

## Verificação de Segurança ⚠️

LEMBRE-SE DE:
- [ ] Revogar as credenciais antigas que foram expostas
- [ ] Gerar novas credenciais N8N
- [ ] Configurar os secrets acima com as NOVAS credenciais
- [ ] Nunca commitar o arquivo .env (já está no .gitignore)
