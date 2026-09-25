# 07 — Post-migración Windows

Una VM Windows importada desde VMware casi siempre arranca justo después del import
(disco presentado en SATA/IDE emulado), pero funciona en emulación completa mientras
no se instalen los drivers VirtIO y no se cambie el controlador de disco a VirtIO SCSI.
Esta página describe la secuencia completa, en orden.

## Orden de las operaciones

| # | Acción | Dónde |
|---|--------|-------|
| 1 | `Pre-Migration-Check.ps1` — exporta JSON del estado de red, discos, BitLocker, servicios, firmware | En la VM, **antes** de apagarla para migrar |
| 2 | `Remove-VMwareTools.ps1` | En la VM, **antes** de apagarla para migrar |
| 3 | Suspender/descifrar BitLocker si está activo | En la VM, **antes** de apagarla para migrar |
| 4 | Import de la VM (ver [04](04-migration-assistant.md), [05](05-migration-ovf.md), [06](06-migration-disk-import.md)) | Host Proxmox |
| 5 | `05-windows-virtio.sh <vmid> to-sata` | Host Proxmox |
| 6 | Arrancar Windows, instalar `virtio-win-guest-tools.exe` (o `Install-VirtIO.ps1`) | En la VM |
| 7 | `05-windows-virtio.sh <vmid> prepare` | Host Proxmox |
| 8 | Arrancar Windows, verificar «Red Hat VirtIO SCSI controller» en el Administrador de dispositivos, apagar | En la VM |
| 9 | `05-windows-virtio.sh <vmid> finalize` | Host Proxmox |
| 10 | Arrancar Windows, `Restore-NetworkConfig.ps1`, `Post-Migration-Validate.ps1` | En la VM |

## Por qué no desinstalar VMware Tools después de migrar

VMware Tools no puede desinstalarse limpiamente una vez que la VM salió de VMware (el
servicio de desinstalación depende del hipervisor de origen). Por eso
`Remove-VMwareTools.ps1` debe ejecutarse **antes** del apagado previo al export/import,
mientras la VM todavía está bajo ESXi.

## BitLocker y vTPM

El vTPM de VMware no migra a Proxmox: no se transfiere ningún equivalente durante el
import. Si un volumen está protegido con BitLocker ligado al TPM, la VM migrada pedirá
la clave de recuperación (o se negará a arrancar) en el primer boot.
`Pre-Migration-Check.ps1` detecta el estado de BitLocker; si está activo, suspender la
protección (`Suspend-BitLocker`) o desactivarla por completo antes del apagado de
pre-migración.

## El cambio a VirtIO SCSI en 3 fases (`05-windows-virtio.sh`)

Windows no puede arrancar directamente sobre un controlador SCSI que no reconoce: en el
primer boot tras el import no tiene el driver `vioscsi`. El script gestiona por tanto
tres fases distintas, a ejecutar en este orden exacto:

```bash
./05-windows-virtio.sh <vmid> to-sata    # 1. todos los discos pasan a SATA (boot garantizado)
./05-windows-virtio.sh <vmid> prepare    # 2. añade un disco ficticio scsi30 -> Windows carga vioscsi
./05-windows-virtio.sh <vmid> finalize   # 3. mueve los discos de SATA a SCSI, retira el disco ficticio
```

- **to-sata**: reasigna todos los discos detectados (scsi/virtio/ide) al bus SATA con
  `discard=on,ssd=1` y ajusta el orden de arranque. Windows arranca con normalidad
  porque SATA es soportado nativamente.
- **prepare**: añade un disco ficticio de 1 GB en `scsi30` con `scsihw=virtio-scsi-single`.
  En el siguiente boot, Windows detecta el controlador VirtIO SCSI y carga (o instala,
  si ya se ejecutó `virtio-win-guest-tools.exe`) el driver `vioscsi`. Verificar en el
  Administrador de dispositivos que «Red Hat VirtIO SCSI controller» aparece sin
  signo de exclamación antes de apagar la VM.
- **finalize**: mueve los discos reales de SATA a `scsi` (`discard=on,ssd=1,iothread=1`),
  elimina el disco ficticio `scsi30` y reajusta el orden de arranque al nuevo slot.

Entre las fases 1 y 2 hay que arrancar Windows e instalar los drivers VirtIO
(`virtio-win-guest-tools.exe`, en la raíz de la ISO `virtio-win`, o mediante
`Install-VirtIO.ps1`, que lo ejecuta en modo silencioso e instala también `qemu-ga`).

## Red: tarjetas fantasma y reconfiguración

El paso del adaptador de red VMware (vmxnet3/e1000) a VirtIO cambia la identidad de la
interfaz. Windows conserva la tarjeta anterior como dispositivo fantasma (no presente
pero aún listado). `Restore-NetworkConfig.ps1`:

1. Elimina las tarjetas fantasma vía `pnputil` (`pnputil /remove-device` sobre los
   dispositivos de red no presentes).
2. Reaplica la configuración de red exportada por `Pre-Migration-Check.ps1` (IP
   estática, DNS, rutas) sobre la nueva tarjeta VirtIO.

## Validación final

`Post-Migration-Validate.ps1` verifica: arranque limpio, servicio `qemu-ga` activo,
conectividad de red restaurada, servicios críticos iniciados, ausencia de alertas de
BitLocker. Ver también [09-validation-rollback.md](09-validation-rollback.md).
