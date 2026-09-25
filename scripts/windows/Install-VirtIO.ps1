#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installe silencieusement les pilotes VirtIO (virtio-win 0.1.271) et qemu-ga après le
    premier démarrage sur Proxmox, ISO virtio-win montée. Vérifie le service QEMU-GA.
    Instala en silencio los drivers VirtIO y qemu-ga tras el primer arranque en Proxmox.
#>
[CmdletBinding()]
param(
    # Lettre de lecteur (ex. 'D:') ou chemin complet vers virtio-win-guest-tools.exe ; si omis, auto-détection.
    # Letra de unidad (ej. 'D:') o ruta completa; si se omite, autodetección.
    [string]$IsoPath
)

$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Fail       { param([string]$Msg) Write-Host "[ECHEC] $Msg" -ForegroundColor Red; exit 1 }

function Find-GuestToolsExe {
    Write-Info "Recherche du volume étiqueté 'virtio-win'... / Buscando el volumen etiquetado 'virtio-win'..."
    $virtioVolumes = Get-Volume -ErrorAction SilentlyContinue |
        Where-Object { $_.FileSystemLabel -like 'virtio-win*' -and $_.DriveLetter }
    foreach ($vol in $virtioVolumes) {
        $candidate = "$($vol.DriveLetter):\virtio-win-guest-tools.exe"
        if (Test-Path $candidate) { return $candidate }
    }

    Write-Info "Volume 'virtio-win' non trouvé, recherche sur tous les lecteurs CD-ROM... / Volumen 'virtio-win' no encontrado, buscando en todas las unidades CD-ROM..."
    $cdroms = Get-CimInstance -ClassName Win32_CDROMDrive | Where-Object { $_.Drive } | Select-Object -ExpandProperty Drive
    foreach ($drive in $cdroms) {
        $candidate = Join-Path $drive 'virtio-win-guest-tools.exe'
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$exePath = if ($IsoPath) {
    if ((Get-Item $IsoPath).PSIsContainer) {
        Join-Path $IsoPath 'virtio-win-guest-tools.exe'
    } else {
        Join-Path (Split-Path -Parent $IsoPath) 'virtio-win-guest-tools.exe'
    }
} else {
    Find-GuestToolsExe
}

if (-not $exePath -or -not (Test-Path $exePath)) {
    Fail "virtio-win-guest-tools.exe introuvable. Monter l'ISO virtio-win (0.1.271) et relancer avec -IsoPath. / virtio-win-guest-tools.exe no encontrado. Montar el ISO virtio-win (0.1.271) y reintentar con -IsoPath."
}

Write-Info "Installation silencieuse depuis $exePath... / Instalación silenciosa desde $exePath..."
$proc = Start-Process -FilePath $exePath -ArgumentList '/install', '/quiet', '/norestart' -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Fail "L'installateur virtio-win-guest-tools a retourné le code $($proc.ExitCode). / El instalador virtio-win-guest-tools devolvió el código $($proc.ExitCode)."
}
Write-Ok "Pilotes VirtIO et qemu-ga installés. / Drivers VirtIO y qemu-ga instalados."

Write-Info "Vérification du service QEMU Guest Agent... / Verificando el servicio QEMU Guest Agent..."
Start-Sleep -Seconds 5
$svc = Get-Service -Name 'QEMU-GA' -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') {
    Write-Ok "Service QEMU-GA actif. / Servicio QEMU-GA activo."
} elseif ($svc) {
    Write-Info "Service QEMU-GA présent mais à l'état '$($svc.Status)' — un redémarrage peut être nécessaire."
    Write-Info "Servicio QEMU-GA presente pero en estado '$($svc.Status)' — puede requerir reiniciar."
} else {
    Write-Info "Service QEMU-GA non trouvé — redémarrer la VM puis revérifier. / Servicio QEMU-GA no encontrado — reiniciar la VM y volver a comprobar."
}
