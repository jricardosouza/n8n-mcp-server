#!/bin/bash
# Firewall Configuration with iptables
# Data: 2025-11-10
# Implementa regras restritivas com rate limiting

set -e

echo "🔥 Configurando firewall com iptables..."

# Salvar regras atuais
sudo iptables-save > /tmp/iptables.backup.$(date +%Y%m%d-%H%M%S)

# Flush de regras existentes (exceto Docker)
echo "Limpando regras antigas (mantendo Docker)..."

# ===== POLÍTICAS PADRÃO =====
# INPUT: DROP (bloquear tudo por padrão)
# OUTPUT: ACCEPT (permitir saída)
# FORWARD: já está DROP (mantido pelo Docker)
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT ACCEPT

# ===== REGRAS BÁSICAS =====
# Permitir loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Permitir conexões estabelecidas e relacionadas
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ===== PROTEÇÃO CONTRA ATAQUES =====
# Proteção contra port scanning
sudo iptables -N PORT_SCANNING 2>/dev/null || sudo iptables -F PORT_SCANNING
sudo iptables -A PORT_SCANNING -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
sudo iptables -A PORT_SCANNING -j DROP

# Proteção contra SYN flood
sudo iptables -N SYN_FLOOD 2>/dev/null || sudo iptables -F SYN_FLOOD
sudo iptables -A SYN_FLOOD -m limit --limit 10/s --limit-burst 50 -j RETURN
sudo iptables -A SYN_FLOOD -j DROP
sudo iptables -A INPUT -p tcp --syn -j SYN_FLOOD

# Dropar pacotes inválidos
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Proteção contra ping flood
sudo iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 2 -j ACCEPT
sudo iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# ===== RATE LIMITING PARA SERVIÇOS =====
# SSH (porta 2222) - rate limiting agressivo
sudo iptables -N SSH_RATE_LIMIT 2>/dev/null || sudo iptables -F SSH_RATE_LIMIT
sudo iptables -A SSH_RATE_LIMIT -m recent --name SSH --set
sudo iptables -A SSH_RATE_LIMIT -m recent --name SSH --update --seconds 60 --hitcount 4 -j DROP
sudo iptables -A SSH_RATE_LIMIT -j ACCEPT

# Aplicar rate limiting ao SSH
sudo iptables -A INPUT -p tcp --dport 2222 -m conntrack --ctstate NEW -j SSH_RATE_LIMIT

# Porta 2000 - rate limiting moderado
sudo iptables -A INPUT -p tcp --dport 2000 -m limit --limit 10/min --limit-burst 5 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 2000 -j DROP

# Porta 9877 - rate limiting moderado
sudo iptables -A INPUT -p tcp --dport 9877 -m limit --limit 10/min --limit-burst 5 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9877 -j DROP

# ===== REGRAS ESPECÍFICAS =====
# Permitir DNS local
sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT

# Permitir DHCP
sudo iptables -A INPUT -p udp --sport 67:68 --dport 67:68 -j ACCEPT

# ===== LOG DE PACOTES DESCARTADOS (limitado para não encher logs) =====
sudo iptables -N LOGGING 2>/dev/null || sudo iptables -F LOGGING
sudo iptables -A LOGGING -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
sudo iptables -A LOGGING -j DROP
sudo iptables -A INPUT -j LOGGING

# ===== PERSISTÊNCIA =====
# Instalar iptables-persistent
echo "Instalando iptables-persistent..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Salvar regras
sudo netfilter-persistent save

echo "✅ Firewall configurado com sucesso!"
echo ""
echo "📋 Regras ativas:"
sudo iptables -L -n -v --line-numbers | head -50
echo ""
echo "💾 Regras salvas em /etc/iptables/rules.v4"
echo "🔄 Para recarregar: sudo netfilter-persistent reload"
echo "📊 Para ver regras: sudo iptables -L -n -v"
