#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Bilan pré-migration d'une VM Windows sous VMware avant le passage à Proxmox :
    réseau, disques/volumes, BitLocker, VMware Tools, services, firmware BIOS/UEFI.
    Exporte un rapport JSON utilisé ensuite par Restore-NetworkConfig.ps1 et Post-Migration-Validate.ps1.
    Diagnóstico pre-migración de una VM Windows en VMware: red, discos, BitLocker, VMware Tools, servicios y firmware.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = ".\pre-migration-$($env:COMPUTERNAME)-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

$ErrorActionPreference = 'Stop'

function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "[ATTENTION] $Msg" -ForegroundColor Yellow }

Write-Info "Collecte de la configuration réseau... / Recopilando configuración de red..."
$ipConfig  = Get-NetIPConfiguration | Select-Object InterfaceAlias, InterfaceDescription, IPv4Address, IPv4DefaultGateway, DNSServer
$dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, ServerAddresses
$routes    = Get-NetRoute -AddressFamily IPv4 | Where-Object { $_.NextHop -ne '0.0.0.0' -or $_.DestinationPrefix -ne '0.0.0.0/0' } |
    Select-Object DestinationPrefix, NextHop, InterfaceAlias, RouteMetric

Write-Info "Collecte des disques et volumes... / Recopilando discos y volúmenes..."
$disks      = Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, Size, BusType
$partitions = Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size, Type
$volumes    = Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, SizeRemaining

Write-Info "Vérification BitLocker... / Comprobando BitLocker..."
$bitlocker = @()
$bitlockerAlert = $false
try {
    $bitlocker = Get-BitLockerVolume | Select-Object MountPoint, VolumeStatus, ProtectionStatus, EncryptionPercentage
    foreach ($vol in $bitlocker) {
        if ($vol.ProtectionStatus -eq 'On' -or $vol.VolumeStatus -eq 'FullyEncrypted') {
            $bitlockerAlert = $true
            Write-Warn2 "BitLocker actif sur $($vol.MountPoint) — suspendre ou déchiffrer avant migration (le vTPM ne migre pas)."
            Write-Warn2 "BitLocker activo en $($vol.MountPoint) — suspender o descifrar antes de migrar (el vTPM no migra)."
        }
    }
} catch {
    Write-Info "BitLocker non disponible sur ce système. / BitLocker no disponible en este sistema."
}

Write-Info "Détection de VMware Tools... / Detectando VMware Tools..."
$vmwareToolsKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$vmwareTools = Get-ItemProperty -Path $vmwareToolsKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*VMware Tools*' } |
    Select-Object DisplayName, DisplayVersion, UninstallString, PSChildName
$vmwareToolsPresent = [bool]$vmwareTools
if ($vmwareToolsPresent) {
    Write-Warn2 "VMware Tools détecté — le désinstaller AVANT la migration avec Remove-VMwareTools.ps1."
    Write-Warn2 "VMware Tools detectado — desinstalarlo ANTES de la migración con Remove-VMwareTools.ps1."
} else {
    Write-Ok "VMware Tools absent. / VMware Tools no presente."
}

Write-Info "Inventaire des services automatiques... / Inventario de servicios automáticos..."
$autoServices = Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" |
    Select-Object Name, DisplayName, State, StartMode
$vmwareServices = $autoServices | Where-Object { $_.Name -like '*vmware*' -or $_.Name -like '*vmtools*' }

Write-Info "Détection du firmware (BIOS/UEFI)... / Detectando firmware (BIOS/UEFI)..."
$firmwareType = try {
    if ((Get-CimInstance -ClassName Win32_ComputerSystem).BootupState -and (Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) -ne $null) { 'UEFI' } else { 'BIOS' }
} catch { 'BIOS' }
$peFirmwareType = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Name 'PEFirmwareType' -ErrorAction SilentlyContinue).PEFirmwareType
if ($peFirmwareType -eq 2) { $firmwareType = 'UEFI' } elseif ($peFirmwareType -eq 1) { $firmwareType = 'BIOS' }
Write-Info "Firmware : $firmwareType / Firmware: $firmwareType"

$report = [ordered]@{
    Hostname         = $env:COMPUTERNAME
    Timestamp        = (Get-Date).ToString('o')
    FirmwareType     = $firmwareType
    IPConfiguration  = $ipConfig
    DnsServers       = $dnsServers
    Routes           = $routes
    Disks            = $disks
    Partitions       = $partitions
    Volumes          = $volumes
    BitLocker        = $bitlocker
    BitLockerAlert   = $bitlockerAlert
    VMwareToolsFound = $vmwareToolsPresent
    VMwareTools      = $vmwareTools
    AutoServices     = $autoServices
    VMwareServices   = $vmwareServices
}

$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutputPath -Encoding utf8
Write-Ok "Rapport enregistré : $OutputPath"
Write-Ok "Informe guardado: $OutputPath"

if ($bitlockerAlert -or $vmwareToolsPresent) {
    Write-Warn2 "Des actions sont requises avant la migration (voir ci-dessus)."
    Write-Warn2 "Se requieren acciones antes de migrar (ver arriba)."
} else {
    Write-Ok "Aucun blocage détecté. VM prête pour l'export. / Sin bloqueos detectados. VM lista para exportar."
}
