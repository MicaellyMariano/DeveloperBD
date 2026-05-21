@echo off
:: Muda para a pasta onde este .bat esta localizado
cd /d "%~dp0"

title RelatoriosCEM - Instalador
color 1F
cls

echo ============================================================
echo   RelatoriosCEM - Instalador e Compilador
echo   Sistema RAM
echo ============================================================
echo.

:: [1/4] Verificar Python
echo [1/4] Verificando Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  ERRO: Python nao encontrado no PATH!
    echo.
    echo  Para instalar o Python gratuitamente:
    echo    1. Acesse: https://python.org/downloads
    echo    2. Clique em "Download Python 3.x.x"
    echo    3. Na instalacao, marque "Add Python to PATH"
    echo    4. Apos instalar, feche e abra este arquivo novamente.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo  %%v encontrado!
echo.

:: [2/4] Instalar fdb
echo [2/4] Instalando biblioteca fdb (conexao com Firebird)...
pip install fdb --quiet --disable-pip-version-check
if %errorlevel% neq 0 (
    echo  Aviso: fdb falhou. Tentando versao alternativa...
    pip install fdb --quiet
)
echo  Biblioteca fdb OK!
echo.

:: [3/4] Instalar PyInstaller
echo [3/4] Instalando PyInstaller...
pip install pyinstaller --quiet --disable-pip-version-check
if %errorlevel% neq 0 (
    echo  ERRO ao instalar PyInstaller.
    pause
    exit /b 1
)
echo  PyInstaller OK!
echo.

:: [4/4] Compilar para EXE
echo [4/4] Compilando para EXE (aguarde 1-2 minutos)...
echo.

if not exist relatorios_cem.py (
    echo  ERRO: arquivo relatorios_cem.py nao encontrado em:
    echo  %cd%
    pause
    exit /b 1
)

python -m PyInstaller --onefile --windowed --name=RelatoriosCEM --clean --noconfirm relatorios_cem.py

echo.
if exist dist\RelatoriosCEM.exe (
    echo ============================================================
    echo   SUCESSO!
    echo   EXE criado em: %cd%\dist\RelatoriosCEM.exe
    echo.
    echo   Copie o RelatoriosCEM.exe para qualquer pasta e use.
    echo ============================================================
    echo.
    explorer dist
) else (
    echo  ERRO ao criar o EXE. Veja as mensagens acima.
)

echo.
pause
