# n8n-mcp-server

Um projeto **completo, profissional e pronto para uso** que:
- ✅ Transforma comandos em linguagem natural em ações N8N
- ✅ Documenta exaustivamente todas as funcionalidades
- ✅ Oferece múltiplas opções de deployment
- ✅ Segue melhores práticas da indústria
- ✅ Está otimizado para Claude Code
- ✅ É extensível e manutenível
- ✅ **Implementa segurança de rede robusta**

## 🔒 Recursos de Segurança

Este servidor implementa medidas abrangentes de segurança de rede:

- **HTTPS Enforcement** - Valida que URLs usam HTTPS (exceto localhost)
- **SSL/TLS Validation** - Validação de certificados com TLS 1.2 mínimo
- **Request/Response Limits** - Proteção contra ataques DoS
- **Sensitive Data Sanitization** - Redação automática de credenciais em logs
- **Security Headers** - Headers de segurança em todas as requisições
- **Configuration Validation** - Validação rigorosa de todas as configurações

📖 **Documentação completa:** [NETWORK-SECURITY.md](./NETWORK-SECURITY.md)

## 🚀 Quick Start

1. Clone o repositório
2. Configure suas variáveis de ambiente:
```bash
cp .env.example .env
# Edite .env com suas credenciais n8n
```

3. Instale dependências:
```bash
npm install
```

4. Execute o servidor:
```bash
npm start
```

## 📚 Documentação

- [Network Security Guide](./NETWORK-SECURITY.md) - Guia completo de segurança de rede
- [Security Documentation](./security/SECURITY-DOCUMENTATION.md) - Segurança de infraestrutura

## ⚖️ Licença

MIT
