# 05 — Migración por exportación OVF

## Cuándo usar este método

El asistente de importación ([04-migration-assistant.md](04-migration-assistant.md))
necesita que Proxmox alcance directamente la API HTTPS del ESXi. Cuando eso
no es posible (segmentación de red, ESXi no alcanzable desde el host
Proxmox), o para conservar un archivo portable de la VM antes de migrarla,
la exportación OVF es la alternativa: se exporta la VM a archivos
OVF/VMDK desde el ESXi, y luego se importan en Proxmox.

## Requisitos previos

- `ovftool` instalado en el host Proxmox (descargar «VMware OVF Tool Linux
  64-bit» desde el portal de Broadcom — no viene empaquetado con Proxmox).
- La VM origen debe estar apagada.
- Espacio en disco suficiente en la carpeta de exportación (por defecto
  `/var/lib/vz/ovf-export`): contar el tamaño de los discos de la VM.

## Uso

```bash
./scripts/proxmox/06-ovf-import.sh <nombre-vm-esxi> <vmid> [carpeta-export]
```

El script:

1. Exporta la VM con `ovftool --noSSLVerify vi://<usuario>@<ip-esxi>/<nombre-vm>`.
2. Calcula un `sha256sum` de todos los archivos exportados, para verificar
   la integridad de la transferencia.
3. Importa con `qm importovf <vmid> <archivo.ovf> <storage>`.
4. Aplica los mismos ajustes de red/CPU/controlador que la importación
   directa (`virtio` en `vmbr1`, `x86-64-v2-AES`, `virtio-scsi-single`,
   agente QEMU).

Para una VM Windows, continuar después con el cambio a VirtIO:

```bash
./scripts/proxmox/05-windows-virtio.sh <vmid> to-sata
```

(ver [07-windows-post-migration.md](07-windows-post-migration.md) para la
continuación completa).

## Límites propios de este método

Se aplican los mismos límites que en la importación directa al contenido
del OVF (sin vSAN como origen, sin discos cifrados). La exportación OVF
añade su propio coste: tiempo de exportación proporcional al tamaño de los
discos, y espacio en disco temporal duplicado durante la conversión
(archivos origen en el ESXi o en tránsito, más la copia local antes de
importar).

## Siguiente

[06-migration-disk-import.md](06-migration-disk-import.md) — importación
directa de un archivo `.vmdk` sin pasar por una exportación OVF completa.
