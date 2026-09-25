# 04 — Migración con el asistente de importación ESXi

## Requisitos previos

- Proxmox VE 8.2 o superior, con el paquete `pve-esxi-import-tools`
  (verificado por [00-check-host.sh](../../scripts/proxmox/00-check-host.sh)).
- La VM origen debe estar **apagada**.
- Antes de migrar una VM Windows: **desinstalar VMware Tools desde dentro de
  la VM, antes de la migración.** VMware Tools no se desinstala limpiamente
  una vez que la VM ha salido de VMware; hacerlo después deja drivers y
  servicios fantasma.

## Paso 1: declarar el ESXi como almacenamiento de importación

```bash
./scripts/proxmox/03-add-esxi-storage.sh
```

Equivalente a:

```bash
pvesm add esxi <id> --server <ip-esxi> --username root --password *** --skip-cert-verification 1
```

El script lee `ESXI_STORAGE_ID`, `ESXI_IP`, `ESXI_USER` desde `lab.env`,
pide la contraseña de forma interactiva si no está ya definida (nunca se
guarda en texto plano en el repositorio), y luego lista los `.vmx`
visibles en el ESXi para confirmar que la conexión funciona.

## Paso 2: importar la VM

```bash
./scripts/proxmox/04-import-vm.sh <nombre-vm-esxi> [vmid] [windows|linux]
```

Equivalente a:

```bash
qm import <vmid> <storage>:ha-datacenter/<datastore>/<vm>/<vm>.vmx --storage <dst>
```

El script encuentra automáticamente la ruta `.vmx` correspondiente al
nombre de VM indicado, ejecuta la importación, y luego aplica ajustes
comunes: agente QEMU activado, tipo de CPU `x86-64-v2-AES`, controlador
`virtio-scsi-single`, y sustitución de las interfaces de red `vmxnet3` por
`virtio` en `vmbr1` (red del laboratorio). Si se pasa `windows` como tercer
argumento, también cambia el disco de sistema a SATA para el primer
arranque (ver
[05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh) — la VM
Windows recién importada todavía no tiene cargado el driver `vioscsi`; una
conexión directa en SCSI virtio le impediría arrancar) y monta la ISO
VirtIO en la unidad de CD. Cada importación queda registrada en
`results/imports.csv` (nombre origen, VMID, familia de SO, duración).

## Límites del asistente de importación

- **Sin vSAN**: los datastores vSAN no están soportados como origen.
- **Sin discos cifrados** (VM Encryption del lado vSphere).
- **Snapshots**: una VM con snapshots se puede importar, pero de forma
  notablemente más lenta (la importación debe consolidar la cadena).
- **Datastores con un `+` en el nombre**: la importación falla. Renombrar
  el datastore en el ESXi antes de migrar las VM que contiene.

## vTPM y BitLocker

El vTPM no migra a Proxmox. Si BitLocker está activo en la VM Windows a
migrar, hay que **suspenderlo o descifrarlo antes** de la migración — de lo
contrario el volumen de sistema quedará ilegible al reiniciar (el TPM que
guardaba la clave de sellado ya no existe).

## Siguiente

- [05-migration-ovf.md](05-migration-ovf.md) — método alternativo si la API
  de ESXi no es alcanzable.
- [07-windows-post-migration.md](07-windows-post-migration.md) — tras
  importar una VM Windows.
