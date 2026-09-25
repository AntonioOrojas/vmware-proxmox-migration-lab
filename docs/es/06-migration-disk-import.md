# 06 — Migración por importación directa de disco

## Cuándo usar este método

Casos de uso típicos: un datastore NFS compartido accesible directamente
desde Proxmox, un archivo `.vmdk` copiado por `scp`, o una copia de
seguridad ya restaurada en disco. A diferencia de los otros dos métodos,
este no crea automáticamente una VM a partir de los metadatos de una VM
ESXi existente: la VM destino se crea (o ya debe existir) con sus propios
ajustes, y luego el disco `.vmdk` se importa y se conecta a ella.

## Uso

```bash
./scripts/proxmox/07-disk-import.sh <vmid> <archivo.vmdk> [windows|linux] [ovmf|seabios]
```

Equivalente, para la parte de importación, a:

```bash
qm disk import <vmid> <file.vmdk> <storage>
```

Si `<vmid>` todavía no existe, el script crea una VM mínima (2 vCPU, 4 GB
RAM, `virtio-scsi-single`, red `virtio` en `vmbr1`, agente QEMU activado)
con el tipo de SO y el firmware solicitados — se añade `--efidisk0`
automáticamente si el firmware es `ovmf`. El disco importado aparece
primero como volumen `unusedN`; el script lo detecta, lo desvincula de ese
estado temporal y lo reconecta explícitamente:

- en `sata0` para una VM Windows (primer arranque sin el driver `vioscsi`
  todavía cargado — ver
  [05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh));
- en `scsi0` para una VM Linux.

El archivo `.vmdk` indicado debe ser el **descriptor** (el archivo de texto
pequeño), con su archivo de datos `*-flat.vmdk` asociado en la misma
carpeta — el script avisa si no lo encuentra junto a él.

## Límites

Este método importa un disco, no una VM completa: no se recupera ningún
metadato (CPU, RAM, red original) desde el ESXi. Se aplican las mismas
restricciones de contenido (sin disco cifrado). Es adecuado para repetir
una migración en una VM cuyas características destino ya se conocen y
difieren de las del origen (redimensionamiento, firmware cambiado de BIOS
a UEFI, etc.).

## Siguiente

- [07-windows-post-migration.md](07-windows-post-migration.md) — finalizar
  una VM Windows migrada.
- [08-linux-post-migration.md](08-linux-post-migration.md) — finalizar una
  VM Linux migrada.
