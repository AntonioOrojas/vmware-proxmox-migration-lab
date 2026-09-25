# Informe de migración VMware → Proxmox

## 1. Identificación

| Campo | Valor |
|---|---|
| Nombre de la VM | `<a completar>` |
| ID de VM en Proxmox (vmid) | `<a completar>` |
| Datastore de origen (VMware) | `<a completar>` |
| Storage destino (Proxmox) | `<a completar>` |
| Sistema operativo | `<a completar>` |
| Criticidad de negocio | `<baja / media / alta>` |
| Cliente / entorno | `<a completar>` |
| Referente de negocio | `<a completar>` |
| Operador(es) de la migración | `<a completar>` |
| Fecha de la migración | `<dd/mm/aaaa>` |

## 2. Características de la VM

| Característica | Antes (VMware) | Después (Proxmox) |
|---|---|---|
| vCPU | `<a completar>` | `<a completar>` |
| RAM | `<a completar>` | `<a completar>` |
| Disco(s) | `<a completar>` | `<a completar>` |
| Tarjeta(s) de red | `<a completar>` | `<a completar>` |
| BIOS / UEFI | `<a completar>` | `<a completar>` |
| vTPM | `<sí / no>` | `<sí / no — no soportado por el import>` |

## 3. Método utilizado

- [ ] Asistente de import ESXi (`pvesm add esxi` + `qm import`)
- [ ] Import OVF (`qm importovf`)
- [ ] Disk import (`qm disk import`)

**Detalle / comandos ejecutados:**

```
<a completar>
```

**Justificación de la elección del método:** `<a completar>`

## 4. Duración

| Etapa | Inicio | Fin | Duración |
|---|---|---|---|
| Preparación (apagado VM origen, verificaciones) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Transferencia / import de discos | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Configuración post-import (hardware, red) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Post-migración (drivers, validación) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| **Duración total** | | | `<hh:mm>` |

## 5. Incidentes encontrados

| # | Descripción del incidente | Impacto | Resolución | Duración del impacto |
|---|---|---|---|---|
| 1 | `<a completar>` | `<a completar>` | `<a completar>` | `<a completar>` |
| 2 | `<a completar>` | `<a completar>` | `<a completar>` | `<a completar>` |

*(Agregar filas si es necesario. Indicar «Sin incidentes» si corresponde.)*

## 6. Resultados de la validación post-migración

| Punto de control | Resultado | Comentario |
|---|---|---|
| Arranque de la VM sin errores | `<OK / KO>` | `<a completar>` |
| Conectividad de red (IP, DNS, puerta de enlace) | `<OK / KO>` | `<a completar>` |
| QEMU Guest Agent operativo | `<OK / KO>` | `<a completar>` |
| Drivers VirtIO instalados (almacenamiento/red) | `<OK / KO>` | `<a completar>` |
| Tarjetas de red fantasma limpiadas (Windows) | `<OK / KO / no aplica>` | `<a completar>` |
| Renombramiento de interfaz aplicado (Linux) | `<OK / KO / no aplica>` | `<a completar>` |
| Servicios / aplicaciones funcionando | `<OK / KO>` | `<a completar>` |
| Validación funcional por el referente de negocio | `<OK / KO>` | `<a completar>` |
| Copia de seguridad Proxmox planificada | `<OK / KO>` | `<a completar>` |

## 7. Plan de rollback aplicado

- [ ] Rollback no necesario
- [ ] Rollback parcial: `<a completar>`
- [ ] Rollback completo: `<a completar>`

**Detalle:** `<a completar>`

## 8. Recomendaciones / próximos pasos

`<a completar>`

## 9. Firma

| Rol | Nombre | Fecha | Firma |
|---|---|---|---|
| Operador técnico | `<a completar>` | `<dd/mm/aaaa>` | `<a completar>` |
| Referente de negocio / cliente | `<a completar>` | `<dd/mm/aaaa>` | `<a completar>` |

---
*Plantilla proporcionada por Intermovil TEC. Este documento no debe contener ningún dato real antes de compartirse públicamente.*
