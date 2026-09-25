# 08 — Post-migración Linux (Debian)

Una VM Linux migrada suele arrancar sin problemas (el kernel Linux maneja los
controladores de disco de forma genérica), pero dos puntos impiden una integración
limpia: el initramfs no siempre contiene los módulos VirtIO necesarios para arrancar,
y `open-vm-tools` sigue activo aunque ya no sirve de nada bajo Proxmox.

## Secuencia recomendada

1. **Antes de migrar**, en la VM bajo ESXi: anotar la configuración de red (`ip a`,
   `/etc/network/interfaces` o archivos netplan); desinstalar `open-vm-tools` no es
   obligatorio en este punto pero puede hacerse aquí.
2. **Tras el import**, si el disco no arranca o se queda en initramfs busybox: usar
   `scripts/linux/prep-virtio-initramfs.sh` en chroot desde un live CD/ISO Debian, o
   directamente en la VM si logró arrancar una primera vez en un bus compatible
   (SATA/IDE) antes de pasar a VirtIO.
3. Instalar `qemu-guest-agent`, desinstalar `open-vm-tools`.
4. Reconstruir el initramfs (`update-initramfs -u` en Debian/Ubuntu, `dracut -f` en
   RHEL/Fedora-likes) para incluir los módulos `virtio_blk`, `virtio_scsi`,
   `virtio_net`.
5. Corregir la configuración de red si la interfaz fue renombrada (ver abajo).
6. Reiniciar en el bus VirtIO definitivo.

## `scripts/linux/prep-virtio-initramfs.sh`

Script previsto para automatizar esta preparación: detecta la distribución
(Debian/Ubuntu vs RHEL-like), regenera el initramfs con los módulos VirtIO
(`dracut --add-drivers "virtio_blk virtio_scsi virtio_net"` o
`update-initramfs -u -k all`), desinstala `open-vm-tools`, instala y activa
`qemu-guest-agent`, y muestra un aviso sobre el renombrado de interfaz
`ens192` → `ens18`.

## `open-vm-tools` → `qemu-guest-agent`

```bash
apt purge -y open-vm-tools open-vm-tools-desktop
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

Sin `qemu-guest-agent`, Proxmox no puede obtener la IP de la VM en su interfaz, ni
disparar un apagado limpio (`qm shutdown`) sin recurrir a ACPI puro.

## Trampa del renombrado de interfaz: `ens192` → `ens18`

Los nombres de interfaz de red «predecibles» (systemd) se derivan del bus y la
ubicación PCI del dispositivo. Bajo VMware, la tarjeta vmxnet3 suele verse como
`ens192`; bajo QEMU/Proxmox (VirtIO), el mismo slot lógico suele dar `ens18`. Como
consecuencia, la configuración de red estática referenciada por el nombre de interfaz
antiguo deja de aplicarse tras la migración, y la VM puede perder conectividad al
arrancar.

A verificar/corregir tras la migración:

- `/etc/network/interfaces` (Debian clásico): reemplazar `ens192` por `ens18` (o el
  nombre real observado con `ip a`).
- Netplan (`/etc/netplan/*.yaml`): igual en la clave de la interfaz, o usar un
  matcher por MAC en vez de por nombre si el renombrado se repite.
- `/etc/udev/rules.d/70-persistent-net.rules` si existe (sistemas antiguos): puede
  fijar un nombre que ya no existe.

## Verificación final

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep -E 'virtio_(blk|scsi|net)'
systemctl is-active qemu-guest-agent
ip a   # confirmar el nombre real de la interfaz y la presencia de la IP esperada
```

Ver [09-validation-rollback.md](09-validation-rollback.md) para la checklist de
validación completa y [10-depannage.md](10-depannage.md) para las averías frecuentes.
