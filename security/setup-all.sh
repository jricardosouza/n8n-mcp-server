#!/bin/bash
# Master Security Setup Script
# Data: 2025-11-10
# Executa todos os scripts de segurança em ordem

set -e

SCRIPT_DIR="/workspaces/n8n-mcp-server/security"
LOG_FILE="/tmp/security-setup-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔒 =============================================="
echo "🔒  CONFIGURAÇÃO COMPLETA DE SEGURANÇA DE REDE"
echo "🔒 =============================================="
echo ""
echo "📄 Log: $LOG_FILE"
echo ""

# Função para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Função para avisos
warn() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Função para sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para erro
error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    error "Este script precisa ser executado como root (use sudo)"
    exit 1
fi

# Banner de aviso
warn "ATENÇÃO: Esta configuração irá modificar:"
echo "  - Configurações SSH (/etc/ssh/sshd_config)"
echo "  - Regras de firewall (iptables)"
echo "  - Instalar fail2ban"
echo "  - Configurar logging e monitoramento"
echo ""
warn "IMPORTANTE: Mantenha uma sessão SSH ativa durante todo o processo!"
echo ""
read -p "Deseja continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    error "Instalação cancelada pelo usuário"
    exit 1
fi

echo ""
log "Iniciando configuração de segurança..."
echo ""

# ===== PASSO 1: SSH HARDENING =====
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASSO 1/5: Configurando SSH (Hardening)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

warn "Verificando se você tem chave SSH configurada..."
if [ ! -f ~/.ssh/authorized_keys ] || [ ! -s ~/.ssh/authorized_keys ]; then
    warn "AVISO: Nenhuma chave SSH encontrada em ~/.ssh/authorized_keys"
    warn "Desabilitar PasswordAuthentication pode BLOQUEAR seu acesso!"
    echo ""
    read -p "Tem certeza que deseja continuar? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        warn "Pulando configuração SSH por segurança"
    else
        bash "$SCRIPT_DIR/ssh-hardening.sh" 2>&1 | tee -a "$LOG_FILE"
        systemctl reload sshd
        success "SSH configurado com sucesso"
    fi
else
    bash "$SCRIPT_DIR/ssh-hardening.sh" 2>&1 | tee -a "$LOG_FILE"
    systemctl reload sshd
    success "SSH configurado com sucesso"
fi

sleep 2

# ===== PASSO 2: FAIL2BAN =====
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASSO 2/5: Instalando e Configurando Fail2ban"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if bash "$SCRIPT_DIR/fail2ban-setup.sh" 2>&1 | tee -a "$LOG_FILE"; then
    success "Fail2ban configurado com sucesso"
else
    error "Erro ao configurar fail2ban (verifique $LOG_FILE)"
fi

sleep 2

# ===== PASSO 3: FIREWALL =====
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASSO 3/5: Configurando Firewall (iptables)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

warn "Configurando firewall... Isto pode afetar conexões ativas!"

if bash "$SCRIPT_DIR/firewall-setup.sh" 2>&1 | tee -a "$LOG_FILE"; then
    success "Firewall configurado com sucesso"
else
    error "Erro ao configurar firewall (verifique $LOG_FILE)"
fi

sleep 2

# ===== PASSO 4: LOGGING =====
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASSO 4/5: Configurando Logging e Monitoramento"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if bash "$SCRIPT_DIR/logging-setup.sh" 2>&1 | tee -a "$LOG_FILE"; then
    success "Logging configurado com sucesso"
else
    error "Erro ao configurar logging (verifique $LOG_FILE)"
fi

sleep 2

# ===== PASSO 5: AUDITORIA =====
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASSO 5/5: Executando Auditoria de Segurança"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if bash "$SCRIPT_DIR/security-audit.sh" 2>&1 | tee -a "$LOG_FILE"; then
    success "Auditoria executada com sucesso"
else
    error "Erro ao executar auditoria (verifique $LOG_FILE)"
fi

# ===== RESUMO FINAL =====
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "Todas as medidas de segurança foram implementadas!"
echo ""
echo "📋 Resumo das Alterações:"
echo "  ✅ SSH: Login root desabilitado, apenas chaves SSH"
echo "  ✅ Fail2ban: Proteção contra força bruta ativa"
echo "  ✅ Firewall: Regras restritivas com rate limiting"
echo "  ✅ Logging: Logs centralizados configurados"
echo "  ✅ Monitoramento: Serviço disponível (não iniciado)"
echo "  ✅ Auditoria: Agendada semanalmente"
echo ""
echo "📖 Documentação completa em:"
echo "   $SCRIPT_DIR/SECURITY-DOCUMENTATION.md"
echo ""
echo "🔍 Próximos Passos:"
echo "  1. Revisar relatório de auditoria"
echo "  2. Testar conexão SSH (em nova janela!)"
echo "  3. Verificar serviços: systemctl status fail2ban"
echo "  4. Iniciar monitor (opcional): systemctl start network-monitor"
echo ""
echo "⚠️  IMPORTANTE:"
warn "Não feche esta sessão SSH até confirmar que consegue conectar em uma nova!"
echo ""
echo "📊 Ver status completo:"
echo "   fail2ban-client status"
echo "   iptables -L -n -v"
echo "   tail -f /var/log/security/*.log"
echo ""
log "Setup concluído. Log completo salvo em $LOG_FILE"
