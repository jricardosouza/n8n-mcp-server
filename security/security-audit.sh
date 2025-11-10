#!/bin/bash
# Network Security Audit Script
# Data: 2025-11-10
# Realiza auditoria completa de segurança de rede

set -e

REPORT_DIR="/var/log/security-audits"
REPORT_FILE="$REPORT_DIR/audit-$(date +%Y%m%d-%H%M%S).log"

# Criar diretório de relatórios se não existir
sudo mkdir -p "$REPORT_DIR"

echo "🔍 Iniciando auditoria de segurança de rede..."
echo "📄 Relatório será salvo em: $REPORT_FILE"

{
    echo "======================================================"
    echo "RELATÓRIO DE AUDITORIA DE SEGURANÇA DE REDE"
    echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "======================================================"
    echo ""

    # 1. INTERFACES DE REDE
    echo "=== 1. INTERFACES DE REDE ==="
    ip addr show
    echo ""

    # 2. PORTAS ABERTAS
    echo "=== 2. PORTAS ABERTAS (LISTENING) ==="
    sudo netstat -tuln | grep LISTEN
    echo ""

    # 3. CONEXÕES ATIVAS
    echo "=== 3. CONEXÕES ATIVAS ==="
    sudo ss -tunap | grep ESTAB | wc -l
    echo "Total de conexões estabelecidas: $(sudo ss -tunap | grep ESTAB | wc -l)"
    echo ""
    echo "Top 10 IPs conectados:"
    sudo ss -tunap | grep ESTAB | awk '{print $6}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
    echo ""

    # 4. REGRAS DE FIREWALL
    echo "=== 4. REGRAS DE FIREWALL (iptables) ==="
    sudo iptables -L -n -v | head -100
    echo ""

    # 5. STATUS FAIL2BAN
    echo "=== 5. STATUS FAIL2BAN ==="
    if command -v fail2ban-client &> /dev/null; then
        sudo fail2ban-client status
        echo ""
        for jail in $(sudo fail2ban-client status | grep "Jail list" | sed 's/.*://; s/,//g'); do
            echo "--- Jail: $jail ---"
            sudo fail2ban-client status "$jail"
            echo ""
        done
    else
        echo "Fail2ban não instalado"
    fi
    echo ""

    # 6. CONFIGURAÇÃO SSH
    echo "=== 6. CONFIGURAÇÃO SSH ==="
    sudo grep -E "^(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|MaxAuthTries)" /etc/ssh/sshd_config
    echo ""

    # 7. PROCESSOS EM ESCUTA
    echo "=== 7. PROCESSOS EM ESCUTA (TOP 20) ==="
    sudo lsof -i -P -n | grep LISTEN | head -20
    echo ""

    # 8. TENTATIVAS DE LOGIN FALHAS
    echo "=== 8. ÚLTIMAS TENTATIVAS DE LOGIN FALHAS (SSH) ==="
    sudo grep "Failed password" /var/log/auth.log 2>/dev/null | tail -20 || echo "Nenhuma tentativa falha recente"
    echo ""

    # 9. CONEXÕES SUSPEITAS
    echo "=== 9. ANÁLISE DE CONEXÕES SUSPEITAS ==="
    echo "Conexões em portas não padrão:"
    sudo ss -tunap | grep -v -E ":(22|80|443|53|2222|2000|9877)" | grep ESTAB || echo "Nenhuma conexão suspeita"
    echo ""

    # 10. USO DE BANDA POR INTERFACE
    echo "=== 10. ESTATÍSTICAS DE REDE ==="
    for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
        echo "Interface: $iface"
        ip -s link show "$iface" | grep -A2 "RX:\|TX:"
        echo ""
    done

    # 11. VERIFICAÇÃO DE PACOTES SUSPEITOS
    echo "=== 11. LOGS DE FIREWALL (ÚLTIMOS 50) ==="
    sudo dmesg | grep -i "iptables\|firewall" | tail -50 || echo "Nenhum log de firewall encontrado"
    echo ""

    # 12. SERVIÇOS DOCKER
    echo "=== 12. CONTAINERS DOCKER ==="
    if command -v docker &> /dev/null; then
        sudo docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"
        echo ""
        echo "Redes Docker:"
        sudo docker network ls
    else
        echo "Docker não disponível"
    fi
    echo ""

    # 13. VERIFICAÇÃO DE PORTAS EXPOSTAS DESNECESSARIAMENTE
    echo "=== 13. ANÁLISE DE RISCO - PORTAS EXPOSTAS ==="
    echo "Portas expostas em todas as interfaces (0.0.0.0 ou ::):"
    sudo netstat -tuln | grep "0.0.0.0:\|:::" | grep LISTEN
    echo ""

    # 14. RESUMO DE SEGURANÇA
    echo "=== 14. RESUMO DE SEGURANÇA ==="
    
    # Contar problemas
    ISSUES=0
    
    # PermitRootLogin
    if sudo grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
        echo "❌ CRÍTICO: Login root está habilitado no SSH"
        ((ISSUES++))
    else
        echo "✅ Login root desabilitado"
    fi
    
    # PasswordAuthentication
    if sudo grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
        echo "⚠️  AVISO: Autenticação por senha habilitada"
        ((ISSUES++))
    else
        echo "✅ Autenticação por senha desabilitada"
    fi
    
    # Firewall
    if sudo iptables -L | grep -q "policy DROP"; then
        echo "✅ Firewall com política restritiva"
    else
        echo "⚠️  AVISO: Firewall pode estar muito permissivo"
        ((ISSUES++))
    fi
    
    # Fail2ban
    if command -v fail2ban-client &> /dev/null && sudo systemctl is-active --quiet fail2ban; then
        echo "✅ Fail2ban ativo"
    else
        echo "⚠️  AVISO: Fail2ban não está ativo"
        ((ISSUES++))
    fi
    
    echo ""
    echo "Total de problemas encontrados: $ISSUES"
    
    if [ $ISSUES -eq 0 ]; then
        echo "🎉 SCORE DE SEGURANÇA: EXCELENTE (10/10)"
    elif [ $ISSUES -le 2 ]; then
        echo "✅ SCORE DE SEGURANÇA: BOM (8/10)"
    elif [ $ISSUES -le 4 ]; then
        echo "⚠️  SCORE DE SEGURANÇA: MÉDIO (6/10)"
    else
        echo "❌ SCORE DE SEGURANÇA: BAIXO (4/10)"
    fi
    
    echo ""
    echo "======================================================"
    echo "FIM DO RELATÓRIO"
    echo "======================================================"

} | sudo tee "$REPORT_FILE" > /dev/null

echo ""
echo "✅ Auditoria concluída!"
echo "📄 Relatório completo: $REPORT_FILE"
echo ""
echo "📊 Resumo rápido:"
cat "$REPORT_FILE" | grep -A 20 "=== 14. RESUMO DE SEGURANÇA ==="
