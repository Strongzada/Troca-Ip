@echo off
title Executar Trocador de IP Avancado
color 0A

:: Verifica se o script está sendo executado como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script precisa ser executado como Administrador.
    echo Por favor, clique com o botao direito e selecione "Executar como Administrador".
    pause
    exit /b
)

:: Caminho do script PowerShell e log na mesma pasta do .bat
set SCRIPT_PATH=%~dp0Desbucetador.ps1
set LOG_PATH=%~dp0TrocadorIP_Log_%date:~10,4%-%date:~7,2%-%date:~4,2%_%time:~0,2%-%time:~3,2%.txt

:: Informar sobre o local do log
echo ===============================================
echo         EXECUTANDO TROCADOR DE IP AVANCADO
echo ===============================================
echo.
echo O arquivo de log sera salvo na mesma pasta que este arquivo:
echo %~dp0
echo.
pause

:: Executa o PowerShell como administrador e passa o caminho do log como argumento
echo Executando o script PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_PATH%\" -LogPath \"%LOG_PATH%\"' -Verb RunAs"

pause