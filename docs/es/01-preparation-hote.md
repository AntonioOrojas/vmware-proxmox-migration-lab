# 01 — Preparación del host

## Requisitos previos

- Proxmox VE 9.2 o superior (verificado: publicado el 21/05/2026).
- CPU con extensiones de virtualización por hardware: Intel VT-x o AMD-V,
  activadas en la BIOS/UEFI (a menudo desactivadas por defecto en hardware
  de consumo).
- Se recomiendan al menos 32 GB de RAM (16 GB para el ESXi anidado, el resto
  para el host y las VM Proxmox nativas tras la migración). Por debajo de
  24 GB, el propio ESXi 8 no tiene el margen necesario.
- Dos bridges de red configurados: `vmbr0` (gestión) y `vmbr1` (red aislada
  del laboratorio, detrás de OPNsense).

## Paso 1: verificar el host

```bash
./scripts/proxmox/00-check-host.sh
```

Este script (ver su código — solo constata el estado, no modifica nada)
verifica en orden:

1. La versión de Proxmox VE instalada (`pveversion`).
2. La presencia de extensiones VT-x (`vmx`) o AMD-V (`svm`) en
   `/proc/cpuinfo` — se detiene de inmediato si no encuentra ninguna.
3. El estado de la virtualización anidada vía
   `/sys/module/kvm_<intel|amd>/parameters/nested`.
4. La RAM total del host, con un umbral de advertencia en 24 GB y un umbral
   mínimo de referencia en 32 GB (por debajo, el script recomienda reducir
   `ESXI_MEMORY_MB` a 12288 en `lab.env`).
5. Los almacenamientos disponibles (`pvesm status`).
6. La presencia de los bridges `vmbr0` y `vmbr1`.
7. La disponibilidad del asistente de importación ESXi
   (`pve-esxi-import-tools`), necesario para
   [04-migration-assistant.md](04-migration-assistant.md).

## Paso 2: activar la virtualización anidada

Si el paso anterior indica que `nested` está inactivo:

```bash
./scripts/proxmox/01-enable-nested.sh
```

Este script detecta el módulo KVM en uso (`kvm_intel` o `kvm_amd`), escribe
`options <módulo> nested=1` en
`/etc/modprobe.d/<módulo>-nested.conf` para que el ajuste sea persistente, y
luego intenta recargar el módulo en caliente — pero solo si no hay ninguna
VM en ejecución en el host (si no, `modprobe -r` fallaría). Si hay VM
corriendo, hace falta reiniciar el host (o apagar las VM y volver a lanzar
el script) para aplicar el ajuste.

## Paso 3: configuración del laboratorio

```bash
cp lab.env.example lab.env
```

Adaptar `lab.env`: nodo Proxmox, almacenamientos, bridges, VMID y
características del ESXi anidado, IP de gestión del ESXi. Este archivo
nunca se sube al repositorio (ver `.gitignore`), ya que con el tiempo puede
contener credenciales.

## Siguiente

[02-esxi-imbrique.md](02-esxi-imbrique.md) — crear la VM ESXi anidada.
