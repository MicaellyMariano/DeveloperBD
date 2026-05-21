@echo off
cd /d "%~dp0"
title RelatoriosCEM - Recompilando

echo Recompilando RelatoriosCEM.exe com a correcao...
echo.

python -m PyInstaller --onefile --windowed --name=RelatoriosCEM --clean --noconfirm relatorios_cem.py

echo.
if exist dist\RelatoriosCEM.exe (
    echo Sucesso! EXE atualizado em: %cd%\dist\RelatoriosCEM.exe
    explorer dist
) else (
    echo ERRO ao compilar. Veja as mensagens acima.
)

pause
