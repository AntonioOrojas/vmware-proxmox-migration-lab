# 02 — Construir el ESXi anidado

## Decisiones técnicas

`scripts/proxmox/02-create-nested-esxi.sh` crea la VM que alojará ESXi 8
con los siguientes ajustes (ver los comentarios del script para el detalle
de cada decisión):

| Ajuste | Valor | Por qué |
|---|---|---|
| `--cpu` | `host` | Expone VT-x/AMD-V dentro de la VM: indispensable para que el ESXi anidado pueda a su vez virtualizar. |
| `--machine` | `q35` | Chipset PCIe moderno, requerido por ESXi 8. |
| `--bios` | `seabios` | El instalador de ESXi arranca en BIOS legacy por defecto. |
| Red | `vmxnet3` | ESXi 8 ya no tiene un driver `e1000` fiable; `vmxnet3` es el driver nativo esperado. Usar `e1000` hace fallar la red. |
| Disco | `sata0` | ESXi no trae driver VirtIO; SATA (AHCI) es nativo y garantiza el arranque. |
| `--balloon 0` | desactivado | ESXi gestiona su propia memoria; dejar el ballooning de Proxmox activo genera conflictos. |
| `--onboot 0` | desactivado | La VM ESXi no arranca automáticamente con el host (laboratorio, no un servicio). |

Se crean dos interfaces de red: `net0` en `vmbr0` (acceso de gestión) y
`net1` en `vmbr1` (red aislada del laboratorio, detrás de OPNsense — ver
[00-architecture.md](00-architecture.md)).

```bash
./scripts/proxmox/02-create-nested-esxi.sh
```

## CPU no soportado por ESXi 8

Si el CPU físico del host es demasiado antiguo para la lista de
compatibilidad oficial de ESXi 8, añadir `allowLegacyCPU=true` al arrancar
el instalador (tecla Shift+O en la pantalla de arranque, y completar la
línea de comandos del kernel).

## vSwitch: preparar el tráfico anidado

Una vez instalado ESXi, en `vSwitch0` (o el vSwitch que porta el portgroup
de las VM de prueba), activar en modo «Aceptar»:

- **Modo promiscuo (promiscuous mode)**
- **Transmisiones forjadas (forged transmits)**
- **Cambios de dirección MAC (MAC address changes)**

Estos tres ajustes son necesarios porque las VM de prueba dentro del ESXi
anidado usan direcciones MAC distintas de la de la tarjeta virtual que ve
Proxmox — sin ellos, su tráfico se filtra silenciosamente.

## Instalación automatizada (kickstart)

Para no repetir la instalación manual cada vez, `scripts/esxi/ks.cfg`
aporta un archivo kickstart:

- `install --firstdisk --overwritevmfs --systemMediaSize=min`: instalación
  en el primer disco detectado, datastore VMFS mínimo para dejar el resto
  del espacio a `datastore1`.
- Configuración de red estática (IP, máscara, puerta de enlace, DNS,
  hostname — valores alineados con `lab.env`).
- Activación de SSH en la sección `%firstboot`, para permitir la
  automatización posterior a la instalación.

Al arrancar el instalador de ESXi, pulsar Shift+O y añadir:

```
ks=http://<IP-servidor-HTTP>:8000/ks.cfg
```

sirviendo `ks.cfg` con un servidor HTTP temporal sencillo (por ejemplo
`python3 -m http.server 8000` desde la carpeta `scripts/esxi/`).

`scripts/esxi/postinstall.sh` completa la instalación tras el primer
arranque: sincronización NTP, política de seguridad del vSwitch0 (los tres
ajustes anteriores aplicados por script en vez de a mano), y creación del
portgroup `LAB` en `vmnic1` (la interfaz conectada a `vmbr1`).

## Siguiente

[03-vms-de-test.md](03-vms-de-test.md) — crear las VM de prueba dentro de
este ESXi anidado.
