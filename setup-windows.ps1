# N8N MCP Server - Script de Instalação Automatizada para Windows 11 Pro
# Autor: Ricardo Souza (@jricardosouza)
# Data: 2025-11-06

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "N8N MCP Server - Setup para Windows" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se está executando como Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "[AVISO] Este script não está sendo executado como Administrador." -ForegroundColor Yellow
    Write-Host "Algumas operações podem falhar. Recomenda-se executar como Administrador." -ForegroundColor Yellow
    Write-Host ""
}

# Função para verificar se um comando existe
function Test-CommandExists {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# Etapa 1: Verificar Python
Write-Host "[1/7] Verificando instalação do Python..." -ForegroundColor Green

if (-not (Test-CommandExists python)) {
    Write-Host "[ERRO] Python não encontrado!" -ForegroundColor Red
    Write-Host "Por favor, instale o Python 3.10+ de: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "IMPORTANTE: Marque a opção 'Add Python to PATH' durante a instalação!" -ForegroundColor Yellow
    exit 1
}

$pythonVersion = python --version
Write-Host "✓ Python encontrado: $pythonVersion" -ForegroundColor Green
Write-Host ""

# Etapa 2: Verificar pip
Write-Host "[2/7] Verificando pip..." -ForegroundColor Green

if (-not (Test-CommandExists pip)) {
    Write-Host "[ERRO] pip não encontrado!" -ForegroundColor Red
    Write-Host "Tentando instalar pip..." -ForegroundColor Yellow
    python -m ensurepip --upgrade
}

Write-Host "✓ pip está disponível" -ForegroundColor Green
Write-Host ""

# Etapa 3: Obter diretório do projeto
Write-Host "[3/7] Configurando diretório do projeto..." -ForegroundColor Green

$projectPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($projectPath)) {
    $projectPath = Get-Location
}

Write-Host "Diretório do projeto: $projectPath" -ForegroundColor Cyan
Write-Host ""

# Etapa 4: Criar Virtual Environment
Write-Host "[4/7] Criando ambiente virtual (venv)..." -ForegroundColor Green

$venvPath = Join-Path $projectPath "venv"

if (Test-Path $venvPath) {
    Write-Host "[AVISO] Virtual environment já existe. Removendo..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $venvPath
}

python -m venv $venvPath

if (-not $?) {
    Write-Host "[ERRO] Falha ao criar virtual environment!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Virtual environment criado em: $venvPath" -ForegroundColor Green
Write-Host ""

# Etapa 5: Ativar venv e instalar dependências
Write-Host "[5/7] Instalando dependências Python..." -ForegroundColor Green

$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
$pythonVenv = Join-Path $venvPath "Scripts\python.exe"
$pipVenv = Join-Path $venvPath "Scripts\pip.exe"

# Instalar dependências usando o pip do venv
$requirementsPath = Join-Path $projectPath "requirements.txt"

Write-Host "Instalando pacotes de requirements.txt..." -ForegroundColor Cyan
& $pipVenv install --upgrade pip
& $pipVenv install -r $requirementsPath

if (-not $?) {
    Write-Host "[ERRO] Falha ao instalar dependências!" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Dependências instaladas com sucesso!" -ForegroundColor Green
Write-Host ""

# Etapa 6: Configurar arquivo .env
Write-Host "[6/7] Configurando arquivo .env..." -ForegroundColor Green

$envPath = Join-Path $projectPath ".env"
$envExamplePath = Join-Path $projectPath ".env.example"

if (-not (Test-Path $envPath)) {
    if (Test-Path $envExamplePath) {
        Copy-Item $envExamplePath $envPath
        Write-Host "✓ Arquivo .env criado a partir de .env.example" -ForegroundColor Green
        Write-Host ""
        Write-Host "[ATENÇÃO] Configure suas credenciais N8N no arquivo .env:" -ForegroundColor Yellow
        Write-Host "  Arquivo: $envPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Edite as seguintes variáveis:" -ForegroundColor Yellow
        Write-Host "  - N8N_API_URL=https://sua-instancia.n8n.io/api/v1" -ForegroundColor Cyan
        Write-Host "  - N8N_API_KEY=sua_chave_api_aqui" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "[AVISO] .env.example não encontrado. Criando .env vazio..." -ForegroundColor Yellow

        $envContent = @"
# N8N API Configuration
N8N_API_URL=https://sua-instancia.n8n.io/api/v1
N8N_API_KEY=sua_chave_api_aqui
"@
        Set-Content -Path $envPath -Value $envContent
        Write-Host "✓ Arquivo .env criado" -ForegroundColor Green
    }
} else {
    Write-Host "✓ Arquivo .env já existe" -ForegroundColor Green
}
Write-Host ""

# Etapa 7: Configurar Claude Desktop
Write-Host "[7/7] Gerando configuração do Claude Desktop..." -ForegroundColor Green

$claudeConfigDir = Join-Path $env:APPDATA "Claude"
$claudeConfigPath = Join-Path $claudeConfigDir "claude_desktop_config.json"

# Criar diretório se não existir
if (-not (Test-Path $claudeConfigDir)) {
    New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
}

# Ler credenciais do .env
$n8nApiUrl = ""
$n8nApiKey = ""

if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match "^N8N_API_URL=(.+)$") {
            $n8nApiUrl = $matches[1]
        }
        if ($_ -match "^N8N_API_KEY=(.+)$") {
            $n8nApiKey = $matches[1]
        }
    }
}

# Caminho do Python e script no venv
$pythonExePath = Join-Path $venvPath "Scripts\python.exe"
$serverScriptPath = Join-Path $projectPath "src\n8n_mcp_server.py"

# Gerar configuração JSON
$configContent = @{
    mcpServers = @{
        "n8n-automation" = @{
            command = $pythonExePath
            args = @($serverScriptPath)
            env = @{
                N8N_API_URL = $n8nApiUrl
                N8N_API_KEY = $n8nApiKey
            }
        }
    }
} | ConvertTo-Json -Depth 10

# Criar arquivo de configuração de exemplo
$exampleConfigPath = Join-Path $projectPath "claude_desktop_config.windows.json"
Set-Content -Path $exampleConfigPath -Value $configContent

Write-Host "✓ Configuração de exemplo criada em:" -ForegroundColor Green
Write-Host "  $exampleConfigPath" -ForegroundColor Cyan
Write-Host ""

Write-Host "Para configurar o Claude Desktop:" -ForegroundColor Yellow
Write-Host "1. Copie o conteúdo de $exampleConfigPath" -ForegroundColor Cyan
Write-Host "2. Cole em $claudeConfigPath" -ForegroundColor Cyan
Write-Host "3. Ajuste as credenciais N8N se necessário" -ForegroundColor Cyan
Write-Host "4. Reinicie o Claude Desktop completamente" -ForegroundColor Cyan
Write-Host ""

# Resumo Final
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Instalação Concluída com Sucesso!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Próximos Passos:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configure suas credenciais N8N no arquivo .env:" -ForegroundColor Yellow
Write-Host "   notepad $envPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Teste o servidor MCP:" -ForegroundColor Yellow
Write-Host "   & '$pythonExePath' '$serverScriptPath'" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Configure o Claude Desktop com o arquivo:" -ForegroundColor Yellow
Write-Host "   $exampleConfigPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Reinicie o Claude Desktop e teste com:" -ForegroundColor Yellow
Write-Host "   'Liste meus workflows N8N'" -ForegroundColor Cyan
Write-Host ""

Write-Host "Documentação adicional:" -ForegroundColor Cyan
Write-Host "- WINDOWS_SETUP.md - Guia completo para Windows" -ForegroundColor White
Write-Host "- TROUBLESHOOTING.md - Resolução de problemas" -ForegroundColor White
Write-Host ""

Write-Host "Instalação finalizada! ✓" -ForegroundColor Green
