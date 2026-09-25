# 09 — Validación post-migración y rollback

Una migración solo termina cuando se valida. Esta página aporta la checklist de
validación y la estrategia de reversión a aplicar mientras la validación no se ha
superado.

## Checklist de validación

| Ámbito | Verificación | Windows | Linux |
|---|---|---|---|
| Arranque | La VM arranca sin intervención manual (sin pantalla de recuperación, sin espera de BitLocker) | ✅ | ✅ |
| Agente invitado | `qemu-ga` activo, Proxmox muestra la IP en la pestaña Resumen | `Post-Migration-Validate.ps1` | `systemctl is-active qemu-guest-agent` |
| Red | IP, gateway, DNS conformes al export pre-migración; sin tarjeta fantasma | `Restore-NetworkConfig.ps1` | `ip a`, comparar con la nota pre-migración |
| Almacenamiento | Disco de sistema en VirtIO SCSI (Windows) o VirtIO block (Linux), sin disco ficticio residual | `qm config <vmid> \| grep scsi` | ídem |
| Servicios | Servicios/demonios críticos de la aplicación iniciados | Administrador de servicios | `systemctl --failed` |
| Rendimiento | Throughput de disco coherente con la carga esperada (sin fallback IDE) | `iothread=1` visible en config | ídem |
| Aplicación | Prueba funcional de extremo a extremo (login, transacción típica, acceso a datos) | Según la aplicación | Según la aplicación |

No dar una migración por cerrada hasta que todas las filas estén en verde y la
aplicación haya sido probada por un usuario de negocio o una prueba automatizada
equivalente.

## Estrategia de rollback

El principio: **nunca destruir la fuente antes de la validación completa.**

1. No eliminar ni reutilizar el VMID/nombre de la VM fuente bajo ESXi mientras la VM
   migrada no esté validada.
2. Mantener la VM fuente **apagada** (no hace falta encenderla, solo no eliminarla)
   durante todo el periodo de validación — de algunas horas a varios días según la
   criticidad.
3. En caso de fallo de validación:
   - Apagar la VM migrada en Proxmox (no eliminarla de inmediato — sirve como material
     de diagnóstico).
   - Volver a encender la VM fuente bajo ESXi; permaneció intacta y vuelve a ser el
     sistema de producción.
   - Diagnosticar el fallo sobre la copia en Proxmox (ver
     [10-depannage.md](10-depannage.md)) sin presión de volver a producción.
4. Una vez superada definitivamente la validación (periodo de observación sin
   incidentes), la VM fuente en ESXi puede apagarse de forma definitiva, archivarse y
   eliminarse según la política de retención del cliente.

## Ventana de observación recomendada

- VM poco crítica / de prueba: bastan unas horas.
- VM de producción: como mínimo un ciclo de negocio completo (p. ej. una jornada
  laboral, o un proceso batch nocturno completo) antes de considerar innecesario el
  rollback.

Ver [11-methodologie-projet.md](11-methodologie-projet.md) para integrar esta
checklist en un plan de olas de migración multi-VM.
