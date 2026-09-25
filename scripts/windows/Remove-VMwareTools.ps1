#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Désinstalle proprement VMware Tools AVANT la migration (à exécuter sous VMware) et
    nettoie les services/dossiers VMware résiduels éventuels.
    Desinstala VMware Tools de forma limpia ANTES de migrar y limpia restos de servicios/carpetas VMware.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "[ATTENTION] $Msg" -ForegroundColor Yellow }

$uninstallKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$vmwareTools = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like '*VMware Tools*' }

if (-not $vmwareTools) {
    Write-Ok "VMware Tools n'est pas installé, rien à faire. / VMware Tools no está instalado, nada que hacer."
    return
}

foreach ($tool in $vmwareTools) {
    Write-Info "Trouvé : $($tool.DisplayName) $($tool.DisplayVersion) / Encontrado: $($tool.DisplayName) $($tool.DisplayVersion)"

    if (-not $Force -and -not $PSCmdlet.ShouldProcess($tool.DisplayName, 'Désinstaller / Desinstalar')) {
        Write-Warn2 "Désinstallation annulée par l'utilisateur pour $($tool.DisplayName)."
        continue
    }

    $productCode = $tool.PSChildName
    if ($productCode -match '^\{[0-9A-Fa-f-]{36}\}$') {
        Write-Info "Désinstallation MSI via ProductCode $productCode... / Desinstalando MSI vía ProductCode $productCode..."
        Start-Process -FilePath 'msiexec.exe' -ArgumentList "/x $productCode /qn /norestart" -Wait -NoNewWindow
    } elseif ($tool.UninstallString) {
        Write-Info "Désinstallation via UninstallString... / Desinstalando vía UninstallString..."
        $exe, $rest = $tool.UninstallString -split ' ', 2
        Start-Process -FilePath $exe.Trim('"') -ArgumentList "$rest /S /v`"/qn REMOVE=ALL`"" -Wait -NoNewWindow
    } else {
        Write-Warn2 "Aucune méthode de désinstallation trouvée pour $($tool.DisplayName). Désinstaller manuellement."
        Write-Warn2 "No se encontró método de desinstalación para $($tool.DisplayName). Desinstalar manualmente."
        continue
    }
    Write-Ok "$($tool.DisplayName) désinstallé. / $($tool.DisplayName) desinstalado."
}

Write-Info "Recherche de services VMware résiduels... / Buscando servicios VMware residuales..."
$leftoverServices = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '*vmware*' -or $_.Name -like '*vmtools*' -or $_.PathName -like '*VMware*' }
if ($leftoverServices) {
    foreach ($svc in $leftoverServices) {
        Write-Warn2 "Service résiduel détecté : $($svc.Name) ($($svc.State)) / Servicio residual detectado: $($svc.Name) ($($svc.State))"
        if ($Force -or $PSCmdlet.ShouldProcess($svc.Name, 'Supprimer le service résiduel / Eliminar el servicio residual')) {
            try {
                if ($svc.State -eq 'Running') { Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue }
                & sc.exe delete $svc.Name | Out-Null
                Write-Ok "Service $($svc.Name) supprimé. / Servicio $($svc.Name) eliminado."
            } catch {
                Write-Warn2 "Impossible de supprimer le service $($svc.Name) : $_ / No se pudo eliminar el servicio $($svc.Name): $_"
            }
        }
    }
} else {
    Write-Ok "Aucun service VMware résiduel. / Ningún servicio VMware residual."
}

Write-Info "Recherche de dossiers VMware résiduels... / Buscando carpetas VMware residuales..."
$leftoverPaths = @(
    "$env:ProgramFiles\VMware",
    "${env:ProgramFiles(x86)}\VMware",
    "$env:ProgramData\VMware"
) | Where-Object { Test-Path $_ }
if ($leftoverPaths) {
    foreach ($p in $leftoverPaths) {
        Write-Warn2 "Dossier résiduel : $p — à vérifier avant suppression manuelle après redémarrage."
        Write-Warn2 "Carpeta residual: $p — revisar antes de eliminar manualmente tras reiniciar."
    }
} else {
    Write-Ok "Aucun dossier VMware résiduel. / Ninguna carpeta VMware residual."
}

Write-Warn2 "Redémarrer avant d'éteindre la VM pour l'export. / Reiniciar antes de apagar la VM para exportarla."
