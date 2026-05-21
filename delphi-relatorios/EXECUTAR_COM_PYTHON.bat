@echo off
cd /d "%~dp0"
title RelatoriosCEM

python relatorios_cem.py
if %errorlevel% neq 0 (
    echo.
    echo  Erro ao iniciar. Verifique se Python e fdb estao instalados.
    echo  Se necessario, execute INSTALAR_E_CRIAR_EXE.bat primeiro.
    echo.
    pause
)
