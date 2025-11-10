#!/bin/bash
# Fail2ban Setup and Configuration
# Data: 2025-11-10

set -e

echo "🛡️  Instalando e configurando fail2ban..."

# Instalar fail2ban
sudo apt-get update -qq
sudo apt-get install -y fail2ban

# Criar configuração customizada
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
# Ban por 1 hora (3600 segundos)
bantime = 3600
# Janela de tempo para contar tentativas falhas (10 minutos)
findtime = 600
# Máximo de tentativas antes do ban
maxretry = 3
# Backend para monitorar logs
backend = systemd

# Ignorar IPs locais
ignoreip = 127.0.0.1/8 ::1

# Ação padrão: ban via iptables
banaction = iptables-multiport
action = %(action_mwl)s

[sshd]
enabled = true
port = 2222
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
findtime = 600

[sshd-ddos]
enabled = true
port = 2222
logpath = /var/log/auth.log
maxretry = 10
findtime = 60
bantime = 600

# Proteção contra port scanning
[port-scan]
enabled = true
logpath = /var/log/syslog
maxretry = 5
findtime = 300
bantime = 3600

# Proteção Node.js (se houver logs)
[nodejs]
enabled = false
port = 2000,9877
logpath = /var/log/nodejs/*.log
maxretry = 5
bantime = 3600
EOF

# Criar filtro customizado para port scan
sudo tee /etc/fail2ban/filter.d/port-scan.conf > /dev/null << 'EOF'
[Definition]
failregex = ^.*kernel:.*IN=.* SRC=<HOST> .*
            ^.*kernel:.*iptables.*SRC=<HOST> .*
ignoreregex =
EOF

# Iniciar e habilitar fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

echo "✅ Fail2ban instalado e configurado!"
echo "📊 Use 'sudo fail2ban-client status' para ver o status"
echo "📊 Use 'sudo fail2ban-client status sshd' para ver bans do SSH"
