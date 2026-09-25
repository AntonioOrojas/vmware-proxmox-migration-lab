#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Contrôles post-migration sur Proxmox : réseau, qemu-ga, disques/volumes, services VMware
    résiduels et journal d'événements Système. Résumé PASS/FAIL, code de sortie = nb d'anomalies.
    Comprobaciones post-migración en Proxmox: red, qemu-ga, discos, servicios VMware residuales y eventos.
#>
[CmdletBinding()]
param(
    [string]$PreMigrationJson
)

$ErrorActionPreference = 'Stop'

function Write-Info  { param([string]$Msg) Write-Host "[INFO] $Msg" -ForegroundColor Cyan }
function Write-Ok    { param([string]$Msg) Write-Host "[ OK ] $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "[ATTENTION] $Msg" -ForegroundColor Yellow }

$issues = 0
$report = $null

Write-Info "Vérification de la connectivité réseau... / Verificando conectividad de red..."
$currentIpCfg = Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object -First 1
if ($currentIpCfg -and $currentIpCfg.IPv4Address) {
    Write-Ok "Adresse IP attribuée : $($currentIpCfg.IPv4Address.IPAddress). / Dirección IP asignada: $($currentIpCfg.IPv4Address.IPAddress)."
    $gw = $currentIpCfg.IPv4DefaultGateway.NextHop
    if ($gw) {
        if (Test-Connection -ComputerName $gw -Count 2 -Quiet -ErrorAction SilentlyContinue) {
            Write-Ok "Passerelle $gw joignable. / Gateway $gw accesible."
        } else {
            Write-Warn2 "Passerelle $gw injoignable. / Gateway $gw inaccesible."
            $issues++
        }
    } else {
        Write-Warn2 "Aucune passerelle par défaut configurée. / Sin gateway por defecto configurado."
        $issues++
    }
} else {
    Write-Warn2 "Aucune adresse IPv4 attribuée. / Sin dirección IPv4 asignada."
    $issues++
}

Write-Info "Vérification du service QEMU Guest Agent... / Verificando el servicio QEMU Guest Agent..."
$svc = Get-Service -Name 'QEMU-GA' -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') {
    Write-Ok "QEMU-GA actif. / QEMU-GA activo."
} else {
    Write-Warn2 "QEMU-GA absent ou arrêté — installer VirtIO avec Install-VirtIO.ps1."
    Write-Warn2 "QEMU-GA ausente o detenido — instalar VirtIO con Install-VirtIO.ps1."
    $issues++
}

Write-Info "Vérification des périphériques en erreur... / Verificando dispositivos con error..."
$errorDevices = Get-PnpDevice -Status Error -ErrorAction SilentlyContinue
if ($errorDevices) {
    foreach ($dev in $errorDevices) {
        Write-Warn2 "Périphérique en erreur : $($dev.FriendlyName)"
        Write-Warn2 "Dispositivo con error: $($dev.FriendlyName)"
    }
    $issues++
} else {
    Write-Ok "Aucun périphérique en erreur. / Sin dispositivos con error."
}

Write-Info "Vérification BitLocker... / Comprobando BitLocker..."
try {
    $bitlockerIssues = Get-BitLockerVolume | Where-Object { $_.VolumeStatus -eq 'FullyEncrypted' -and $_.LockStatus -eq 'Locked' }
    if ($bitlockerIssues) {
        foreach ($vol in $bitlockerIssues) {
            Write-Warn2 "Volume $($vol.MountPoint) verrouillé — clé de récupération requise."
            Write-Warn2 "Volumen $($vol.MountPoint) bloqueado — se requiere clave de recuperación."
        }
        $issues++
    } else {
        Write-Ok "BitLocker sain. / BitLocker en buen estado."
    }
} catch {
    Write-Info "BitLocker non disponible sur ce système. / BitLocker no disponible en este sistema."
}

if ($PreMigrationJson -and (Test-Path $PreMigrationJson)) {
    Write-Info "Comparaison de la configuration IP avec le rapport pré-migration... / Comparando la configuración IP con el informe pre-migración..."
    $report = Get-Content -Path $PreMigrationJson -Raw | ConvertFrom-Json
    $expectedIp = ($report.IPConfiguration | Where-Object { $_.IPv4Address } | Select-Object -First 1).IPv4Address.IPAddress
    $currentIp  = (Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | Select-Object -First 1).IPv4Address.IPAddress
    if ($expectedIp -and $currentIp -eq $expectedIp) {
        Write-Ok "Adresse IP conforme : $currentIp. / Dirección IP conforme: $currentIp."
    } elseif ($expectedIp) {
        Write-Warn2 "IP attendue $expectedIp, IP actuelle $currentIp — vérifier Restore-NetworkConfig.ps1."
        Write-Warn2 "IP esperada $expectedIp, IP actual $currentIp — revisar Restore-NetworkConfig.ps1."
        $issues++
    }
} else {
    Write-Info "Pas de rapport pré-migration fourni — comparaison IP ignorée. / Sin informe pre-migración — comparación de IP omitida."
}

Write-Info "Vérification des disques et volumes... / Verificando discos y volúmenes..."
$offlineDisks = Get-Disk | Where-Object { $_.OperationalStatus -ne 'Online' }
if ($offlineDisks) {
    foreach ($d in $offlineDisks) {
        Write-Warn2 "Disque hors ligne : $($d.Number) - $($d.FriendlyName). / Disco fuera de línea: $($d.Number) - $($d.FriendlyName)."
    }
    $issues++
} else {
    Write-Ok "Tous les disques sont en ligne. / Todos los discos están en línea."
}
if ($report) {
    $expectedVolCount = @($report.Volumes | Where-Object { $_.DriveLetter }).Count
    $currentVolCount  = @(Get-Volume | Where-Object { $_.DriveLetter }).Count
    if ($currentVolCount -ge $expectedVolCount) {
        Write-Ok "Nombre de volumes conforme ($currentVolCount, attendu >= $expectedVolCount). / Número de volúmenes conforme ($currentVolCount, esperado >= $expectedVolCount)."
    } else {
        Write-Warn2 "Volumes manquants : $currentVolCount trouvés, $expectedVolCount attendus. / Faltan volúmenes: $currentVolCount encontrados, $expectedVolCount esperados."
        $issues++
    }
}

Write-Info "Recherche de services VMware résiduels... / Buscando servicios VMware residuales..."
$vmwareLeftover = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like '*vmware*' -or $_.Name -like '*vmtools*' }
if ($vmwareLeftover) {
    foreach ($svc in $vmwareLeftover) {
        Write-Warn2 "Service VMware résiduel : $($svc.Name) ($($svc.State)). / Servicio VMware residual: $($svc.Name) ($($svc.State))."
    }
    $issues++
} else {
    Write-Ok "Aucun service VMware résiduel. / Ningún servicio VMware residual."
}

Write-Info "Vérification du journal d'événements Système (dernières 24h)... / Verificando el registro de eventos Sistema (últimas 24h)..."
try {
    $since = (Get-Date).AddHours(-24)
    $criticalEvents = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1,2; StartTime = $since } -ErrorAction Stop
    if ($criticalEvents) {
        Write-Warn2 "$($criticalEvents.Count) événement(s) Critique/Erreur dans les dernières 24h — vérifier l'Observateur d'événements."
        Write-Warn2 "$($criticalEvents.Count) evento(s) Crítico/Error en las últimas 24h — revisar el Visor de eventos."
        $issues++
    } else {
        Write-Ok "Aucun événement Critique/Erreur récent. / Sin eventos Crítico/Error recientes."
    }
} catch {
    Write-Ok "Aucun événement Critique/Erreur récent trouvé. / No se encontraron eventos Crítico/Error recientes."
}

if ($issues -eq 0) {
    Write-Ok "Validation post-migration : OK. / Validación post-migración: OK."
} else {
    Write-Warn2 "Validation post-migration : $issues point(s) à corriger."
    Write-Warn2 "Validación post-migración: $issues punto(s) por corregir."
}
exit $issues
