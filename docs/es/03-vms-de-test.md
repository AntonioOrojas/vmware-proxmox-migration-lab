# 03 — VM de prueba dentro del ESXi anidado

## Presupuesto de espacio

El ESXi anidado dispone de un disco único de 200 GB thin-provisioned
(`ESXI_DISK_GB` en `lab.env`). El propio ESXi ocupa una fracción mínima de
ese disco (el kickstart usa `--systemMediaSize=min`), el resto forma
`datastore1`. Para tres VM de prueba conviviendo cómodamente:

| VM | Rol | Disco sugerido | RAM sugerida |
|---|---|---|---|
| Windows Server 2019 (BIOS) | Migración Windows en firmware legacy | 40 GB thin | 4 GB |
| Windows Server 2022 o 2025 (UEFI) | Migración Windows en firmware moderno, con o sin vTPM/BitLocker | 40 GB thin | 4 GB |
| Debian 12 o 13 | Migración Linux, preparación VirtIO/initramfs | 20 GB thin | 2 GB |

El thin-provisioning permite que estas tres VM convivan en los 200 GB aunque
su suma nominal (100 GB) parezca justa — el espacio realmente usado es
mucho menor para instalaciones nuevas.

## Windows Server 2019 — BIOS legacy

Elegir el firmware BIOS (no UEFI) para representar el caso más común de VM
Windows heredadas a migrar: controlador de disco LSI Logic SAS o
paravirtual según los drivers disponibles en la instalación, red
`vmxnet3`. Este es el escenario donde
[05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh) y su
cambio SATA → VirtIO en tres fases son más directamente relevantes.

## Windows Server 2022 o 2025 — UEFI

Elegir el firmware EFI. Este escenario permite probar en particular el caso
del vTPM: si BitLocker está activado en esta VM, habrá que suspenderlo o
descifrarlo antes de la migración (el vTPM no migra — ver
[04-migration-assistant.md](04-migration-assistant.md)).

## Debian 12/13

Sirve para validar la ruta Linux: sustitución de `open-vm-tools` por
`qemu-guest-agent`, regeneración del initramfs para cargar los módulos
VirtIO, y el cambio de nombre de interfaz de red (`ens192` bajo VMware
suele convertirse en `ens18` bajo Proxmox) — ver
[08-linux-post-migration.md](08-linux-post-migration.md).

## Siguiente

[04-migration-assistant.md](04-migration-assistant.md) — migrar estas VM
con el asistente de importación ESXi de Proxmox.
