#!/bin/bash
# SSH Security Hardening Script
# Data: 2025-11-10

set -e

echo "🔒 Aplicando configurações de segurança SSH..."

# Backup
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Configurações de segurança
sudo tee -a /etc/ssh/sshd_config > /dev/null << 'EOF'

# ===== Configurações de Segurança Adicionais =====
# Desabilitar autenticação por senha vazia
PermitEmptyPasswords no

# Timeout de login
LoginGraceTime 30

# Máximo de tentativas de autenticação
MaxAuthTries 3

# Máximo de sessões
MaxSessions 5

# Desabilitar encaminhamento TCP
AllowTcpForwarding no

# Desabilitar encaminhamento de agente
AllowAgentForwarding no

# Apenas protocolo SSH versão 2
Protocol 2

# Configurações de criptografia forte
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256

# Log mais detalhado
LogLevel VERBOSE

# Banner de aviso
Banner /etc/ssh/banner
EOF

# Criar banner
sudo tee /etc/ssh/banner > /dev/null << 'EOF'
***************************************************************************
                        SISTEMA MONITORADO
                        
Este sistema é privado e monitorado. Acesso não autorizado é proibido.
Todas as atividades são registradas e podem ser utilizadas em processos
legais. Desconecte imediatamente se você não está autorizado.
***************************************************************************
EOF

echo "✅ Configurações SSH aplicadas com sucesso!"
echo "⚠️  Execute 'sudo systemctl reload sshd' ou 'sudo service ssh reload' para aplicar"
