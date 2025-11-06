@echo off
REM N8N MCP Server - Setup Rápido para Windows 11 Pro
REM Autor: Ricardo Souza (@jricardosouza)
REM Data: 2025-11-06

echo =====================================
echo N8N MCP Server - Setup Windows
echo =====================================
echo.

REM Verificar se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    echo.
    echo Por favor, instale o Python 3.10+ de:
    echo https://www.python.org/downloads/
    echo.
    echo IMPORTANTE: Marque 'Add Python to PATH' durante a instalacao!
    pause
    exit /b 1
)

echo [1/5] Python encontrado!
python --version
echo.

REM Obter diretório do script
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

echo [2/5] Criando ambiente virtual...
if exist venv (
    echo Virtual environment ja existe. Removendo...
    rmdir /s /q venv
)

python -m venv venv
if errorlevel 1 (
    echo [ERRO] Falha ao criar virtual environment!
    pause
    exit /b 1
)
echo Virtual environment criado!
echo.

echo [3/5] Instalando dependencias...
venv\Scripts\pip.exe install --upgrade pip
venv\Scripts\pip.exe install -r requirements.txt
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias!
    pause
    exit /b 1
)
echo Dependencias instaladas com sucesso!
echo.

echo [4/5] Configurando arquivo .env...
if not exist .env (
    if exist .env.example (
        copy .env.example .env
        echo Arquivo .env criado a partir de .env.example
    ) else (
        echo # N8N API Configuration > .env
        echo N8N_API_URL=https://sua-instancia.n8n.io/api/v1 >> .env
        echo N8N_API_KEY=sua_chave_api_aqui >> .env
        echo Arquivo .env criado
    )
    echo.
    echo [ATENCAO] Configure suas credenciais N8N no arquivo .env
    echo.
) else (
    echo Arquivo .env ja existe
    echo.
)

echo [5/5] Testando instalacao...
venv\Scripts\python.exe -c "import httpx, mcp, fastmcp; print('Todas as dependencias OK!')"
if errorlevel 1 (
    echo [ERRO] Falha ao importar dependencias!
    pause
    exit /b 1
)
echo.

echo =====================================
echo Instalacao Concluida com Sucesso!
echo =====================================
echo.
echo Proximos Passos:
echo.
echo 1. Configure suas credenciais N8N no arquivo .env:
echo    notepad .env
echo.
echo 2. Execute o setup completo do PowerShell para configurar Claude Desktop:
echo    powershell -ExecutionPolicy Bypass -File setup-windows.ps1
echo.
echo 3. Ou configure manualmente o Claude Desktop em:
echo    %%APPDATA%%\Claude\claude_desktop_config.json
echo.
echo 4. Teste o servidor:
echo    venv\Scripts\python.exe src\n8n_mcp_server.py
echo.
echo Documentacao: WINDOWS_SETUP.md
echo.

pause
