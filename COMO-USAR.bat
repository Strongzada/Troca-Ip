@echo off
title Guia de Uso - Trocador de IP Avançado
color 0A

:: Exibir o guia de uso
echo ===============================================
echo         GUIA DE USO - TROCADOR DE IP AVANCADO
echo ===============================================
echo.
echo Bem-vindo ao Trocador de IP Avancado!
echo Este script ajuda a trocar o IP, otimizar a internet e ajustar configuracoes de rede.
echo.
echo ====== COMO USAR ======
echo 1. Certifique-se de que este arquivo .bat e o arquivo ^"Desbucetador.ps1^" estejam na mesma pasta.
echo 2. Clique com o botao direito neste arquivo .bat e selecione ^"Executar como Administrador^".
echo 3. Siga as instrucoes exibidas durante a execucao do script.
echo.
echo ====== FUNCIONALIDADES ======
echo - Troca de IP.
echo - Otimizacao da internet (limpeza de DNS, ajuste de TCP, etc.).
echo - Backup automatico das configuracoes de rede.
echo - Teste de conectividade.
echo - Obtencao do IP publico e local.
echo.
echo ====== OBSERVACOES ======
echo - Para o script funcionar corretamente, e necessario ter permissao de Administrador.
echo - Um arquivo de log sera salvo na sua Area de Trabalho com detalhes de todas as operacoes.
echo.
pause

:: Perguntar se o usuário deseja executar o script
echo Deseja executar o script agora? (S/N)
set /p escolha=

if /i "%escolha%"=="S" (
    :: Verificar permissões de administrador
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        echo Este script precisa ser executado como Administrador.
        echo Por favor, clique com o botao direito e selecione ^"Executar como Administrador^".
        pause
        exit /b
    )

    :: Caminho do script PowerShell
    set SCRIPT_PATH=%~dp0Desbucetador.ps1

    :: Executa o PowerShell como administrador
    echo Executando o script PowerShell como Administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_PATH%\"' -Verb RunAs"

    pause
) else (
    echo Saindo sem executar o script. Ate logo!
    pause
    exit /b
)