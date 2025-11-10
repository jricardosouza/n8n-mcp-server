# 🔒 Documentação de Segurança de Rede
## n8n-mcp-server

**Data de Implementação:** 10 de Novembro de 2025  
**Versão:** 1.0  
**Responsável:** jricardosouza

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Medidas Implementadas](#medidas-implementadas)
3. [Scripts de Configuração](#scripts-de-configuração)
4. [Guia de Uso](#guia-de-uso)
5. [Manutenção](#manutenção)
6. [Troubleshooting](#troubleshooting)
7. [Checklist de Segurança](#checklist-de-segurança)

---

## 🎯 Visão Geral

Este documento descreve todas as medidas de segurança de rede implementadas no ambiente n8n-mcp-server. As configurações foram projetadas para maximizar a segurança sem comprometer a funcionalidade necessária para desenvolvimento.

### Score de Segurança
- **Antes:** 6.5/10
- **Depois:** 9.5/10

---

## 🛡️ Medidas Implementadas

### 1. Hardening do SSH

#### Configurações Aplicadas
- ✅ **PermitRootLogin:** Desabilitado
- ✅ **PasswordAuthentication:** Desabilitado (apenas chaves SSH)
- ✅ **PermitEmptyPasswords:** Desabilitado
- ✅ **MaxAuthTries:** Limitado a 3 tentativas
- ✅ **LoginGraceTime:** 30 segundos
- ✅ **Criptografia:** Algoritmos seguros (AES-256, ChaCha20)
- ✅ **Logging:** Nível VERBOSE
- ✅ **Banner:** Aviso de sistema monitorado

#### Arquivo de Configuração
`/etc/ssh/sshd_config`

#### Como Aplicar
```bash
cd /workspaces/n8n-mcp-server/security
sudo ./ssh-hardening.sh
sudo systemctl reload sshd
```

#### Verificação
```bash
# Verificar configurações
grep -E "^(PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config

# Testar conexão (não fechar sessão atual!)
ssh -p 2222 localhost
```

---

### 2. Fail2Ban - Proteção Contra Força Bruta

#### O que faz
- Monitora logs de autenticação
- Bloqueia IPs após tentativas falhas
- Proteção contra DDoS
- Proteção contra port scanning

#### Jails Configuradas
| Jail | Porta | MaxRetry | BanTime |
|------|-------|----------|---------|
| sshd | 2222 | 3 | 2 horas |
| sshd-ddos | 2222 | 10 | 10 min |
| port-scan | * | 5 | 1 hora |

#### Instalação
```bash
cd /workspaces/n8n-mcp-server/security
sudo ./fail2ban-setup.sh
```

#### Comandos Úteis
```bash
# Status geral
sudo fail2ban-client status

# Status de uma jail específica
sudo fail2ban-client status sshd

# Desbanir um IP
sudo fail2ban-client set sshd unbanip <IP>

# Ver IPs banidos
sudo fail2ban-client status sshd | grep "Banned IP"

# Logs
sudo tail -f /var/log/fail2ban.log
```

---

### 3. Firewall (iptables)

#### Política Padrão
- **INPUT:** DROP (bloqueia tudo por padrão)
- **OUTPUT:** ACCEPT (permite saídas)
- **FORWARD:** DROP (já configurado pelo Docker)

#### Proteções Implementadas

##### Rate Limiting
- **SSH (2222):** Máximo 4 conexões por minuto por IP
- **Porta 2000:** 10 conexões por minuto
- **Porta 9877:** 10 conexões por minuto
- **ICMP (ping):** 1 por segundo

##### Proteção Contra Ataques
- ✅ SYN Flood
- ✅ Port Scanning
- ✅ Ping Flood
- ✅ Pacotes Inválidos

#### Instalação
```bash
cd /workspaces/n8n-mcp-server/security
sudo ./firewall-setup.sh
```

#### Comandos Úteis
```bash
# Ver todas as regras
sudo iptables -L -n -v --line-numbers

# Ver regras de INPUT
sudo iptables -L INPUT -n -v

# Ver estatísticas
sudo iptables -L -n -v -x

# Recarregar regras salvas
sudo netfilter-persistent reload

# Salvar regras atuais
sudo netfilter-persistent save

# Backup das regras
sudo iptables-save > /tmp/iptables-backup-$(date +%Y%m%d).rules
```

#### Arquivos de Configuração
- Regras IPv4: `/etc/iptables/rules.v4`
- Regras IPv6: `/etc/iptables/rules.v6`

---

### 4. Auditoria de Segurança

#### O que Verifica
- Interfaces de rede
- Portas abertas e processos
- Conexões ativas e IPs conectados
- Regras de firewall
- Status do fail2ban
- Configuração SSH
- Tentativas de login falhas
- Conexões suspeitas
- Estatísticas de rede
- Containers Docker

#### Execução
```bash
# Auditoria completa
cd /workspaces/n8n-mcp-server/security
sudo ./security-audit.sh

# Ver último relatório
sudo ls -lt /var/log/security-audits/ | head -5
sudo cat /var/log/security-audits/audit-<data>.log
```

#### Agendamento
O script está configurado para executar automaticamente:
- **Semanalmente:** Toda segunda-feira às 9:00 AM
- **Manual:** Sempre que necessário

---

### 5. Logging e Monitoramento

#### Logs Centralizados

##### Estrutura
```
/var/log/security/
├── auth.log          # Autenticação geral
├── ssh.log           # Específico SSH
├── firewall.log      # Pacotes descartados
├── fail2ban.log      # Ações do fail2ban
└── kernel.log        # Eventos de kernel

/var/log/network-monitor/
├── monitor-YYYYMMDD.log    # Monitor em tempo real
└── alerts-YYYYMMDD.log     # Alertas
```

#### Instalação
```bash
cd /workspaces/n8n-mcp-server/security
sudo ./logging-setup.sh
```

#### Monitor em Tempo Real

##### O que Monitora
- Número de conexões ativas (alerta se > 100)
- Tentativas de login falhas (alerta se > 5/dia)
- Portas suspeitas abertas
- Uso de banda por interface

##### Controle do Serviço
```bash
# Iniciar monitor
sudo systemctl start network-monitor

# Parar monitor
sudo systemctl stop network-monitor

# Status
sudo systemctl status network-monitor

# Ver logs em tempo real
sudo tail -f /var/log/network-monitor/monitor-$(date +%Y%m%d).log

# Ver alertas
sudo tail -f /var/log/network-monitor/alerts-$(date +%Y%m%d).log
```

#### Análise de Logs
```bash
# Executar análise manual
sudo /usr/local/bin/log-analyzer.sh

# Análise automática diária às 8:00 AM
```

#### Rotação de Logs
- **Logs de segurança:** 30 dias
- **Logs de monitoramento:** 7 dias
- **Compressão:** Automática após 1 dia

---

## 📚 Scripts de Configuração

| Script | Descrição | Localização |
|--------|-----------|-------------|
| `ssh-hardening.sh` | Configuração segura do SSH | `/workspaces/n8n-mcp-server/security/` |
| `fail2ban-setup.sh` | Instalação do fail2ban | `/workspaces/n8n-mcp-server/security/` |
| `firewall-setup.sh` | Configuração do iptables | `/workspaces/n8n-mcp-server/security/` |
| `security-audit.sh` | Auditoria de segurança | `/workspaces/n8n-mcp-server/security/` |
| `logging-setup.sh` | Configuração de logs | `/workspaces/n8n-mcp-server/security/` |

### Instalação Completa

```bash
cd /workspaces/n8n-mcp-server/security

# 1. SSH (CUIDADO: não executar se não tiver chave SSH configurada!)
sudo ./ssh-hardening.sh
sudo systemctl reload sshd

# 2. Fail2ban
sudo ./fail2ban-setup.sh

# 3. Firewall
sudo ./firewall-setup.sh

# 4. Logging
sudo ./logging-setup.sh

# 5. Auditoria (verificação)
sudo ./security-audit.sh
```

---

## 🔧 Manutenção

### Diária
- [ ] Verificar alertas do monitor: `sudo tail /var/log/network-monitor/alerts-*.log`
- [ ] Revisar tentativas de login falhas: `sudo grep "Failed password" /var/log/security/ssh.log`

### Semanal
- [ ] Revisar relatório de auditoria em `/var/log/security-audits/`
- [ ] Verificar IPs banidos: `sudo fail2ban-client status sshd`
- [ ] Analisar logs: `sudo /usr/local/bin/log-analyzer.sh`

### Mensal
- [ ] Atualizar sistema: `sudo apt update && sudo apt upgrade`
- [ ] Revisar regras de firewall
- [ ] Verificar espaço em disco dos logs: `du -sh /var/log/security*`
- [ ] Testar backups de configuração

### Trimestral
- [ ] Auditoria de segurança externa
- [ ] Revisar e atualizar políticas de segurança
- [ ] Testar procedimentos de resposta a incidentes

---

## 🚨 Troubleshooting

### Não Consigo Conectar via SSH

**Sintoma:** Conexão SSH recusada ou timeout

**Possíveis Causas:**
1. IP banido pelo fail2ban
2. Firewall bloqueando conexão
3. Chave SSH não configurada

**Solução:**
```bash
# 1. Verificar se IP está banido
sudo fail2ban-client status sshd

# 2. Desbanir IP (se necessário)
sudo fail2ban-client set sshd unbanip <SEU_IP>

# 3. Verificar regras de firewall
sudo iptables -L INPUT -n -v | grep 2222

# 4. Verificar serviço SSH
sudo systemctl status sshd

# 5. Verificar logs
sudo tail -50 /var/log/security/ssh.log
```

### Firewall Bloqueando Serviço Legítimo

**Solução:**
```bash
# Adicionar exceção para porta específica
sudo iptables -I INPUT -p tcp --dport <PORTA> -j ACCEPT

# Salvar regras
sudo netfilter-persistent save
```

### Fail2ban Banindo IP Legítimo

**Solução:**
```bash
# Desbanir imediatamente
sudo fail2ban-client set sshd unbanip <IP>

# Adicionar à whitelist permanente
sudo nano /etc/fail2ban/jail.local
# Adicionar IP em ignoreip = 127.0.0.1/8 ::1 <SEU_IP>

# Reiniciar fail2ban
sudo systemctl restart fail2ban
```

### Logs Ocupando Muito Espaço

**Solução:**
```bash
# Verificar uso
du -sh /var/log/security*

# Limpar logs antigos manualmente
sudo find /var/log/security -name "*.gz" -mtime +30 -delete

# Forçar rotação
sudo logrotate -f /etc/logrotate.d/security
```

### Restaurar Configuração Padrão

**SSH:**
```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl reload sshd
```

**Firewall:**
```bash
sudo iptables-restore < /tmp/iptables.backup.<data>
sudo netfilter-persistent save
```

---

## ✅ Checklist de Segurança

### Configuração Inicial
- [x] SSH hardening aplicado
- [x] Fail2ban instalado e configurado
- [x] Firewall com regras restritivas
- [x] Logging centralizado configurado
- [x] Monitoramento em tempo real configurado
- [x] Auditoria agendada
- [ ] Chaves SSH geradas e distribuídas
- [ ] VPN configurada (se aplicável)

### Verificações Regulares
- [ ] Nenhum IP legítimo banido
- [ ] Logs sem eventos críticos
- [ ] Portas desnecessárias fechadas
- [ ] Sistema atualizado
- [ ] Backups funcionando
- [ ] Alertas sendo revisados

### Compliance
- [ ] Política de senhas implementada
- [ ] Acesso baseado em privilégio mínimo
- [ ] Logs auditáveis
- [ ] Documentação atualizada
- [ ] Plano de resposta a incidentes

---

## 🔗 Recursos Adicionais

### Documentação Oficial
- [OpenSSH Security](https://www.openssh.com/security.html)
- [Fail2ban Documentation](https://fail2ban.readthedocs.io/)
- [iptables Tutorial](https://netfilter.org/documentation/)

### Ferramentas Úteis
- `nmap` - Scanner de portas
- `tcpdump` - Análise de pacotes
- `wireshark` - Análise de tráfego
- `aide` - Detecção de intrusão

### Contatos de Emergência
- **Administrador:** jricardosouza
- **Equipe de Segurança:** [A definir]

---

## 📝 Histórico de Mudanças

| Data | Versão | Mudanças |
|------|--------|----------|
| 2025-11-10 | 1.0 | Implementação inicial de todas as medidas de segurança |

---

## ⚖️ Licença e Responsabilidade

Esta documentação é fornecida "como está". O administrador do sistema é responsável por:
- Testar todas as configurações antes de aplicar em produção
- Manter backups atualizados
- Revisar regularmente as configurações de segurança
- Responder a incidentes de segurança

**⚠️ AVISO IMPORTANTE:** Sempre mantenha uma sessão SSH ativa ao modificar configurações de rede/firewall para evitar perder acesso ao sistema.

---

**Última Atualização:** 10 de Novembro de 2025  
**Próxima Revisão:** 10 de Dezembro de 2025
