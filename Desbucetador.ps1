param (
    [string]$LogPath = "$PSScriptRoot\TrocadorIP_Log_Default.txt"
)

$StartTime = Get-Date
$timestamp = $StartTime.ToString("yyyy-MM-dd_HHmm")
$LogPath = "$env:USERPROFILE\Desktop\TrocadorIP_Log_$timestamp.txt"

function Log {
    param ($msg)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

function CheckAdmin {
    # Verificar se o script está sendo executado como administrador
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "ERRO: Este script precisa ser executado como Administrador!" -ForegroundColor Red
        Log "ERRO: Script não executado como administrador."
        exit
    }
}

function OptimizeInternet {
    Write-Host "`nOtimizando configurações de rede..." -ForegroundColor Yellow
    Log "Iniciando otimização da internet."

    # Limpar cache de DNS
    Write-Host "Limpando cache de DNS..." -ForegroundColor Yellow
    Log "Limpando cache de DNS."
    ipconfig /flushdns

    # Ajustar configurações TCP
    Write-Host "Ajustando configurações TCP..." -ForegroundColor Yellow
    Log "Ajustando configurações TCP."
    netsh int tcp set global autotuninglevel=normal

    # Remover configurações de proxy
    Write-Host "Removendo configurações de proxy (se aplicável)..." -ForegroundColor Yellow
    Log "Removendo configurações de proxy."
    netsh winhttp reset proxy

    # Redefinir configurações de rede
    Write-Host "Redefinindo configurações de rede..." -ForegroundColor Yellow
    Log "Redefinindo configurações de rede."
    netsh int ip reset
    netsh winsock reset

    Write-Host "Otimização concluída com sucesso!" -ForegroundColor Green
    Log "Otimização concluída."
}

function RestartAdapter {
    param ($adapterName)
    try {
        Write-Host "`nReiniciando adaptador de rede..." -ForegroundColor Yellow
        Log "Desativando e reativando adaptador..."
        Disable-NetAdapter -Name $adapterName -Confirm:$false
        Start-Sleep -Seconds 3
        Enable-NetAdapter -Name $adapterName -Confirm:$false
        Start-Sleep -Seconds 5
    } catch {
        Write-Host "Falha ao reiniciar o adaptador. Verifique se o script está sendo executado como Administrador." -ForegroundColor Red
        Log "ERRO: Falha ao reiniciar adaptador. $_"
        exit
    }
}

function RenewIP {
    Write-Host "`nLiberando e renovando IP..." -ForegroundColor Yellow
    Log "Liberando e renovando IP."
    ipconfig /release
    Start-Sleep -Seconds 3
    ipconfig /renew
    Start-Sleep -Seconds 5
}

function GetPublicIP {
    try {
        $publicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
        Write-Host "`nIP PÚBLICO (externo): $publicIP" -ForegroundColor Magenta
        Log "IP público: $publicIP"
    } catch {
        Write-Host "`nFalha ao obter IP público!" -ForegroundColor Red
        Log "ERRO: Falha ao obter IP público."
    }
}

# Início do script
CheckAdmin

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "         TROCADOR DE IP AVANÇADO               " -ForegroundColor Green
Write-Host "            By Strong e ChatGPT                " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Cyan
Log "Script iniciado."

# Listar adaptadores ativos
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface } 
if ($adapters.Count -eq 0) {
    Write-Host "Nenhum adaptador ativo encontrado." -ForegroundColor Red
    Log "ERRO: Nenhum adaptador ativo."
    exit
}

# Permitir escolha do adaptador se houver mais de um
if ($adapters.Count -gt 1) {
    Write-Host "`nAdaptadores ativos encontrados:"
    $i = 1
    foreach ($ad in $adapters) {
        Write-Host "$i. $($ad.Name) - $($ad.InterfaceDescription)"
        $i++
    }
    $choice = Read-Host "Escolha o número do adaptador"
    if ($choice -notmatch '^\d+$' -or $choice -lt 1 -or $choice -gt $adapters.Count) {
        Write-Host "Escolha inválida! O script será encerrado." -ForegroundColor Red
        Log "ERRO: Escolha inválida de adaptador."
        exit
    }
    $adapter = $adapters[$choice - 1]
} else {
    $adapter = $adapters[0]
}
Log "Adaptador selecionado: $($adapter.Name)"
Write-Host "`nUsando adaptador: $($adapter.Name)" -ForegroundColor Yellow

# Backup da configuração atual
$ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name
$backup = @{
    IPAddress = $ipConfig.IPv4Address.IPAddress
    Gateway = $ipConfig.IPv4DefaultGateway.NextHop
    DNS = $ipConfig.DnsServer.ServerAddresses
}
Log "Backup da configuração atual: IP=$($backup.IPAddress), Gateway=$($backup.Gateway), DNS=$($backup.DNS -join ', ')"

# Verificar se usa DHCP
$ipInterface = Get-NetIPInterface -InterfaceAlias $adapter.Name -AddressFamily IPv4
if ($ipInterface.Dhcp -eq "Enabled") {
    Write-Host "`n-> IP configurado como DINÂMICO (DHCP)" -ForegroundColor Green
    Log "IP é dinâmico (DHCP)"
} else {
    Write-Host "`n-> IP configurado como FIXO (estático/manual)" -ForegroundColor Red
    Log "IP é fixo (estático)"
}

# IP atual
$oldIP = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "169.*"}).IPAddress
Write-Host "`nIP LOCAL ATUAL: $oldIP" -ForegroundColor Cyan
Log "IP atual: $oldIP"

# Otimizar Internet
Write-Host "`nDeseja otimizar a internet? (S/N)" -ForegroundColor Yellow
$optimizeChoice = Read-Host
if ($optimizeChoice -eq 'S') {
    OptimizeInternet
}

# Reiniciar adaptador
RestartAdapter -adapterName $adapter.Name

# Renovar IP
RenewIP

# Novo IP
$newIP = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "169.*"}).IPAddress
Write-Host "`nNOVO IP LOCAL: $newIP" -ForegroundColor Cyan
Log "Novo IP: $newIP"

# Obter IP público
GetPublicIP

# Verificar conectividade
Write-Host "`nTestando conexão com a internet..." -ForegroundColor Gray
if (Test-Connection -ComputerName 8.8.8.8 -Quiet -Count 2) {
    Write-Host "Conexão com a internet: OK" -ForegroundColor Green
    Log "Teste de conexão: SUCESSO"
} else {
    Write-Host "Conexão com a internet: FALHOU" -ForegroundColor Red
    Log "Teste de conexão: FALHOU"
}

# Tempo total
$EndTime = Get-Date
$duration = New-TimeSpan -Start $StartTime -End $EndTime
Write-Host "`nDuração total: $($duration.Minutes) minuto(s) e $($duration.Seconds) segundo(s)"
Log "Duração total: $($duration.Minutes)m $($duration.Seconds)s"

Write-Host "`n===============================================" -ForegroundColor Cyan
Write-Host "        OPERAÇÃO CONCLUÍDA COM SUCESSO         " -ForegroundColor Green
Write-Host "         Log salvo em: $LogPath" -ForegroundColor DarkGray
Write-Host "===============================================" -ForegroundColor Cyan
Pause