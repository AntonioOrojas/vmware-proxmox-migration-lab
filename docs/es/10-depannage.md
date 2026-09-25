# 10 — Solución de problemas

Fallos encontrados o documentados durante este laboratorio, clasificados por fase.

## Import (asistente ESXi / OVF / disk import)

**Datastore vSAN no soportado**
El asistente de import ESXi de Proxmox no puede leer un datastore vSAN. Solución:
exportar la VM en OVF desde vCenter/ESXi (`ovftool`) y usar
[05-migration-ovf.md](05-migration-ovf.md), o migrar el disco fuera de vSAN antes de
importar.

**Discos cifrados no soportados**
Un disco de VM cifrado (VM Encryption en vSphere) no puede importarse tal cual.
Descifrar el disco en VMware antes de exportar, o recurrir a una copia en caliente del
contenido (backup/restore a nivel de aplicación) en vez de un import de disco.

**Import lento desde una VM con snapshots**
Cada snapshot añade una capa de delta que consolidar durante el import. Antes de
migrar, consolidar los snapshots en VMware (`Delete All` en el gestor de snapshots o
`vim-cmd vmsvc/snapshot.removeall`) para acelerar notablemente la transferencia.

**Nombre de datastore con `+` provoca fallo**
Los datastores ESXi cuyo nombre contiene un carácter `+` hacen fallar algunos comandos
de import (problema de escapado en la ruta `ha-datacenter/<datastore>/...`). Renombrar
el datastore sin caracteres especiales antes de importar, o migrar vía OVF, que evita
el problema.

## ESXi anidado (nested)

**Tarjeta de red e1000 no funciona / inestable**
Usar `vmxnet3` para la propia VM de ESXi anidado; `e1000` presenta problemas de
estabilidad y rendimiento en configuración anidada. Ver
`scripts/proxmox/02-create-nested-esxi.sh`.

**Incompatibilidad de CPU en hardware antiguo**
Si el host físico es demasiado antiguo para el microcódigo esperado por ESXi 8, añadir
`allowLegacyCPU=true` (típicamente como parámetro de arranque de ESXi o variable
avanzada) para permitir la instalación pese al aviso de compatibilidad de CPU.

**VMs internas al ESXi anidado sin red**
El vSwitch del ESXi anidado debe aceptar modo promiscuo, forged transmits y cambios de
dirección MAC (`accept` en los tres), o de lo contrario el tráfico de las VM internas
(cuyas MAC difieren de la de la VM ESXi vista por Proxmox) se filtra silenciosamente.

## Windows

**Pantalla negra / BSOD tras el cambio a VirtIO SCSI**
Señal de que la fase `prepare` se saltó o de que el driver `vioscsi` no se instaló
antes de `finalize`. No hay reversión automatizada: reasignar manualmente el disco a
SATA (`qm set <vmid> --sata0 <volid>`) para poder arrancar, y retomar la secuencia en
la fase `prepare`. Ver
[07-windows-post-migration.md](07-windows-post-migration.md).

**Solicitud de clave de recuperación BitLocker al arrancar**
El vTPM no migra. Si BitLocker no se suspendió/descifró antes de migrar (ver doc 07),
proporcionar la clave de recuperación para este primer boot y luego desactivar o
volver a suspender BitLocker correctamente una vez estabilizada la VM en Proxmox.

## Varios

**Fin de soporte general vSphere 8**
Fin de soporte general el 11/10/2027: a partir de esa fecha, un entorno VMware que
siga en vSphere 8 deja de recibir parches de seguridad, lo que refuerza la urgencia de
migrar en vez de seguir actualizando indefinidamente del lado VMware.

¿No encuentra la causa aquí? Revisar primero la sección «Hechos verificados» de
`CLAUDE.md` y después la documentación oficial de Proxmox VE (asistente de import
ESXi, pve-esxi-import-tools).
