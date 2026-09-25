#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Supprime les cartes réseau VMware fantômes (pnputil) après migration et réapplique
    la configuration IP/DNS capturée par Pre-Migration-Check.ps1 sur la nouvelle carte VirtIO.
    Elimina las NICs fantasma de VMware y reaplica la configuración IP/DNS capturada antes de migrar.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$PreMigrationJson,

    [string]$InterfaceAlias = 'Ethernet'
)

$ErrorActionPreference = 'Stop'

function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "[ATTENTION] $Msg" -ForegroundColor Yellow }

if (-not (Test-Path $PreMigrationJson)) {
    throw "Fichier introuvable : $PreMigrationJson / Archivo no encontrado: $PreMigrationJson"
}
$report = Get-Content -Path $PreMigrationJson -Raw | ConvertFrom-Json

Write-Info "Recherche des cartes réseau fantômes (pnputil)... / Buscando NICs fantasma (pnputil)..."
$ghosts = Get-PnpDevice -Class Net -PresentOnly:$false | Where-Object { $_.Status -ne 'OK' -and $_.ConfigManagerErrorCode -eq 22 -or $_.Status -eq 'Unknown' }
$disconnected = Get-CimInstance -ClassName Win32_PNPEntity | Where-Object {
    $_.PNPClass -eq 'Net' -and $_.ConfigManagerErrorCode -in @(22, 45)
}

if ($disconnected) {
    foreach ($dev in $disconnected) {
        Write-Warn2 "Carte fantôme détectée : $($dev.Name) ($($dev.DeviceID))"
        Write-Warn2 "NIC fantasma detectada: $($dev.Name) ($($dev.DeviceID))"
        if ($PSCmdlet.ShouldProcess($dev.Name, 'Supprimer via pnputil / Eliminar vía pnputil')) {
            $instanceId = $dev.DeviceID
            & pnputil.exe /remove-device "$instanceId" 2>&1 | ForEach-Object { Write-Info $_ }
        }
    }
} else {
    Write-Ok "Aucune carte fantôme trouvée. / No se encontraron NICs fantasma."
}

Write-Info "Réapplication de la configuration IP sur '$InterfaceAlias'... / Reaplicando la configuración IP en '$InterfaceAlias'..."
$ipInfo = $report.IPConfiguration | Where-Object { $_.IPv4Address } | Select-Object -First 1
if (-not $ipInfo) {
    Write-Warn2 "Aucune configuration IPv4 trouvée dans le rapport — configuration DHCP conservée."
    Write-Warn2 "No se encontró configuración IPv4 en el informe — se mantiene configuración DHCP."
    return
}

$ip      = $ipInfo.IPv4Address.IPAddress
$prefix  = $ipInfo.IPv4Address.PrefixLength
$gateway = $ipInfo.IPv4DefaultGateway.NextHop
$dns     = @($report.DnsServers | Where-Object { $_.ServerAddresses } | Select-Object -First 1 -ExpandProperty ServerAddresses)

$adapter = Get-NetAdapter -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
if (-not $adapter) {
    Write-Warn2 "Carte '$InterfaceAlias' introuvable ou inactive, sélection automatique de la première carte active."
    Write-Warn2 "NIC '$InterfaceAlias' no encontrada o inactiva, seleccionando automáticamente la primera activa."
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
}
if (-not $adapter) { throw "Aucune carte réseau active trouvée. / No se encontró ninguna NIC activa." }

if ($PSCmdlet.ShouldProcess($adapter.Name, "Appliquer IP $ip/$prefix, passerelle $gateway")) {
    Remove-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $ip -PrefixLength $prefix -DefaultGateway $gateway | Out-Null
    if ($dns) { Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses $dns }
}

Write-Ok "Configuration réseau réappliquée sur $($adapter.Name) : $ip/$prefix, passerelle $gateway."
Write-Ok "Configuración de red reaplicada en $($adapter.Name): $ip/$prefix, gateway $gateway."
