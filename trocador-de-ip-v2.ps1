# Trocador de IP - By Strong e ChatGPT
$LogPath = "$env:USERPROFILE\Desktop\TrocadorIP_Log.txt"

function Log {
    param ($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $msg"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "      TROCADOR DE IP AUTOMÁTICO        " -ForegroundColor Green
Write-Host "        By Strong e ChatGPT            " -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Log "Iniciando troca de IP..."

# Detectar adaptador ativo com IPv4
$adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.HardwareInterface -eq $true } | Select-Object -First 1

if (-not $adapter) {
    Write-Host "Nenhum adaptador ativo encontrado!" -ForegroundColor Red
    Log "ERRO: Nenhum adaptador ativo encontrado."
    exit
}

Log "Adaptador detectado: $($adapter.Name)"
Write-Host "`nAdaptador detectado: $($adapter.Name)" -ForegroundColor Yellow

# Verificar tipo de IP
$ipConfig = Get-NetIPInterface -InterfaceAlias $adapter.Name -AddressFamily IPv4
if ($ipConfig.Dhcp -eq "Enabled") {
    Write-Host "`n-> IP configurado como DINÂMICO (DHCP)" -ForegroundColor Green
    Log "IP é dinâmico (DHCP)"
} else {
    Write-Host "`n-> IP configurado como FIXO (estático/manual)" -ForegroundColor Red
    Log "IP é fixo (estático)"
}

# IP local antes
$oldIP = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "169.*"}).IPAddress
Write-Host "`nIP LOCAL ATUAL: $oldIP" -ForegroundColor Cyan
Log "IP atual: $oldIP"

# Reiniciar adaptador
Write-Host "`nReiniciando adaptador de rede..." -ForegroundColor Yellow
Log "Desativando adaptador..."
Disable-NetAdapter -Name $adapter.Name -Confirm:$false
Start-Sleep -Seconds 3
Log "Reativando adaptador..."
Enable-NetAdapter -Name $adapter.Name -Confirm:$false
Start-Sleep -Seconds 5

# Liberação e renovação de IP
Write-Host "`nLiberando e renovando IP..." -ForegroundColor Yellow
ipconfig /release
Start-Sleep -Seconds 3
ipconfig /renew
Start-Sleep -Seconds 5

# IP local após
$newIP = (Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "169.*"}).IPAddress
Write-Host "`nNOVO IP LOCAL: $newIP" -ForegroundColor Cyan
Log "Novo IP: $newIP"

# IP público
try {
    $publicIP = Invoke-RestMethod -Uri "https://api.ipify.org"
    Write-Host "`nIP PÚBLICO (externo): $publicIP" -ForegroundColor Magenta
    Log "IP público: $publicIP"
} catch {
    Write-Host "`nFalha ao obter IP público!" -ForegroundColor Red
    Log "ERRO: Falha ao obter IP público."
}

Write-Host "`n=======================================" -ForegroundColor Cyan
Write-Host "        OPERAÇÃO CONCLUÍDA              " -ForegroundColor Green
Write-Host "      Log salvo em: $LogPath            " -ForegroundColor DarkGray
Write-Host "=======================================" -ForegroundColor Cyan
Pause
