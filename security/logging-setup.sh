#!/bin/bash
# Security Logging and Monitoring Setup
# Data: 2025-11-10
# Configura logging centralizado e monitoramento de eventos

set -e

echo "📊 Configurando logging e monitoramento de segurança..."

# Criar diretórios de logs
sudo mkdir -p /var/log/security
sudo mkdir -p /var/log/network-monitor

# ===== CONFIGURAR RSYSLOG PARA LOGS DE SEGURANÇA =====
echo "Configurando rsyslog..."

sudo tee /etc/rsyslog.d/10-security.conf > /dev/null << 'EOF'
# Logs de autenticação
auth,authpriv.*                 /var/log/security/auth.log

# Logs de firewall
:msg, contains, "IPTables-Dropped"     /var/log/security/firewall.log

# Logs de fail2ban
:programname, isequal, "fail2ban"      /var/log/security/fail2ban.log

# Logs de SSH
:programname, isequal, "sshd"          /var/log/security/ssh.log

# Logs de kernel relacionados a rede
kern.*                                  /var/log/security/kernel.log
EOF

# Reiniciar rsyslog
sudo systemctl restart rsyslog

# ===== CONFIGURAR LOGROTATE =====
echo "Configurando rotação de logs..."

sudo tee /etc/logrotate.d/security > /dev/null << 'EOF'
/var/log/security/*.log {
    daily
    rotate 30
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}

/var/log/network-monitor/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
}
EOF

# ===== SCRIPT DE MONITORAMENTO EM TEMPO REAL =====
cat > /tmp/network-monitor.sh << 'EOF'
#!/bin/bash
# Monitor de rede em tempo real

LOG_FILE="/var/log/network-monitor/monitor-$(date +%Y%m%d).log"
ALERT_FILE="/var/log/network-monitor/alerts-$(date +%Y%m%d).log"

# Limiar de alertas
MAX_CONNECTIONS=100
MAX_FAILED_LOGIN=5
MAX_BANDWIDTH_MBPS=100

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_alert() {
    echo "[ALERTA $(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ALERT_FILE"
    echo "[ALERTA] $1" >&2
}

# Monitorar conexões
check_connections() {
    CONN_COUNT=$(ss -tunap 2>/dev/null | grep ESTAB | wc -l)
    log_message "Conexões ativas: $CONN_COUNT"
    
    if [ "$CONN_COUNT" -gt "$MAX_CONNECTIONS" ]; then
        send_alert "Número elevado de conexões: $CONN_COUNT (limite: $MAX_CONNECTIONS)"
    fi
}

# Monitorar tentativas de login falhas
check_failed_logins() {
    FAILED=$(grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$(date '+%b %d')" | wc -l)
    log_message "Tentativas de login falhas hoje: $FAILED"
    
    if [ "$FAILED" -gt "$MAX_FAILED_LOGIN" ]; then
        send_alert "Múltiplas tentativas de login falhas: $FAILED"
    fi
}

# Monitorar portas suspeitas
check_suspicious_ports() {
    SUSPICIOUS=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -v -E ":(22|80|443|53|2222|2000|9877)" | wc -l)
    
    if [ "$SUSPICIOUS" -gt 0 ]; then
        PORTS=$(netstat -tuln 2>/dev/null | grep LISTEN | grep -v -E ":(22|80|443|53|2222|2000|9877)")
        send_alert "Portas suspeitas abertas:\n$PORTS"
    fi
}

# Loop principal
while true; do
    check_connections
    check_failed_logins
    check_suspicious_ports
    sleep 60
done
EOF

sudo mv /tmp/network-monitor.sh /usr/local/bin/network-monitor.sh
sudo chmod +x /usr/local/bin/network-monitor.sh

# ===== CRIAR SERVIÇO SYSTEMD PARA MONITORAMENTO =====
sudo tee /etc/systemd/system/network-monitor.service > /dev/null << 'EOF'
[Unit]
Description=Network Security Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/network-monitor.sh
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# Habilitar serviço (mas não iniciar ainda, pois pode não ser necessário em dev)
sudo systemctl daemon-reload
sudo systemctl enable network-monitor.service

# ===== SCRIPT DE ANÁLISE DE LOGS =====
cat > /tmp/log-analyzer.sh << 'EOF'
#!/bin/bash
# Analisador de logs de segurança

echo "=== ANÁLISE DE LOGS DE SEGURANÇA ==="
echo "Data: $(date)"
echo ""

# IPs com mais tentativas de login falhas
echo "=== TOP 10 IPs COM TENTATIVAS DE LOGIN FALHAS ==="
if [ -f /var/log/security/ssh.log ]; then
    grep "Failed password" /var/log/security/ssh.log 2>/dev/null | \
        grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head -10
else
    grep "Failed password" /var/log/auth.log 2>/dev/null | \
        grep -oP 'from \K[0-9.]+' | sort | uniq -c | sort -rn | head -10
fi
echo ""

# Bloqueios do fail2ban
echo "=== BLOQUEIOS FAIL2BAN (ÚLTIMAS 24H) ==="
if [ -f /var/log/security/fail2ban.log ]; then
    grep "Ban " /var/log/security/fail2ban.log 2>/dev/null | grep "$(date '+%Y-%m-%d')" | tail -20
else
    echo "Log do fail2ban não encontrado"
fi
echo ""

# Pacotes descartados pelo firewall
echo "=== PACOTES DESCARTADOS PELO FIREWALL (ÚLTIMOS 50) ==="
if [ -f /var/log/security/firewall.log ]; then
    tail -50 /var/log/security/firewall.log
else
    dmesg | grep "IPTables-Dropped" | tail -50 || echo "Nenhum pacote descartado recentemente"
fi
echo ""

# Eventos de kernel suspeitos
echo "=== EVENTOS DE KERNEL RELACIONADOS À REDE ==="
if [ -f /var/log/security/kernel.log ]; then
    grep -i "suspicious\|attack\|flood" /var/log/security/kernel.log 2>/dev/null | tail -20 || echo "Nenhum evento suspeito"
else
    echo "Log de kernel não encontrado"
fi
echo ""

echo "=== FIM DA ANÁLISE ==="
EOF

sudo mv /tmp/log-analyzer.sh /usr/local/bin/log-analyzer.sh
sudo chmod +x /usr/local/bin/log-analyzer.sh

# ===== CONFIGURAR CRON PARA ANÁLISES PERIÓDICAS =====
echo "Configurando tarefas agendadas..."

# Permite configurar o caminho do script de auditoria via variável de ambiente
SECURITY_AUDIT_SCRIPT_PATH="${SECURITY_AUDIT_SCRIPT_PATH:-/usr/local/bin/security-audit.sh}"

# Análise diária de logs
(sudo crontab -l 2>/dev/null || true; echo "0 8 * * * /usr/local/bin/log-analyzer.sh > /var/log/security/daily-analysis-\$(date +\%Y\%m\%d).log 2>&1") | sudo crontab -

# Auditoria semanal
(sudo crontab -l 2>/dev/null || true; echo "0 9 * * 1 ${SECURITY_AUDIT_SCRIPT_PATH}") | sudo crontab -

echo "✅ Logging e monitoramento configurados!"
echo ""
echo "📋 Arquivos de log:"
echo "  - /var/log/security/auth.log - Autenticação"
echo "  - /var/log/security/ssh.log - SSH"
echo "  - /var/log/security/firewall.log - Firewall"
echo "  - /var/log/security/fail2ban.log - Fail2ban"
echo "  - /var/log/network-monitor/*.log - Monitor em tempo real"
echo ""
echo "🛠️  Comandos úteis:"
echo "  - sudo systemctl start network-monitor - Iniciar monitoramento"
echo "  - sudo systemctl status network-monitor - Status do monitor"
echo "  - /usr/local/bin/log-analyzer.sh - Analisar logs"
echo "  - tail -f /var/log/security/ssh.log - Acompanhar SSH em tempo real"
