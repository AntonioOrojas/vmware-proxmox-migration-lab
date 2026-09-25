# Plan de olas de migración VMware → Proxmox

> Plantilla Intermovil TEC. Adaptar según el proyecto. Esta plantilla no contiene datos reales — reemplazar todos los campos `<a completar>` antes de usar.

## Lógica de secuenciación

1. **Ola piloto**: 1 a 2 VM no críticas, representativas del entorno.
   Objetivo: validar el método de import, los scripts y el proceso de extremo a extremo.
2. **Olas de bajo riesgo**: VM secundarias, pocas dependencias, alta tolerancia a fallos.
   Objetivo: ganar cadencia y afianzar el proceso.
3. **Olas críticas**: VM de producción con muchas dependencias, migradas al final,
   una vez validado el método en las olas anteriores.

Cada ola va seguida de una ventana de estabilización antes de lanzar la siguiente.
Usar `inventory/vms.example.csv` (adaptado con el inventario real) para repartir las VM
entre olas según su criticidad y dependencias.

## Nota importante sobre las ventanas horarias

La ventana de corte suele planificarse **de noche, en horario francés (Europe/Paris)**,
para minimizar el impacto sobre los usuarios de negocio. Para los participantes ubicados en
**Lima, Perú (UTC-5)**, esto corresponde a **la tarde / inicio de la noche local**
(diferencia de 6 a 7 horas según el horario de verano/invierno en Francia).
Confirmar siempre la hora exacta en ambos husos horarios antes de cada ola,
e indicarla explícitamente en la convocatoria enviada a los equipos.

| Huso horario | Ejemplo de correspondencia (indicativo, verificar según el período) |
|---|---|
| Europe/Paris (noche, ej. 22:00–02:00) | Lima, Perú UTC-5 (tarde, ej. 15:00–19:00 / 16:00–20:00) |

## Tabla de olas

| Ola | VM | Fecha / hora de corte (París) | Fecha / hora equivalente (Lima, UTC-5) | Ventana de mantenimiento | Disparador de rollback | Responsable |
|---|---|---|---|---|---|---|
| 1 | `<a completar>` | `<dd/mm/aaaa hh:mm>` | `<dd/mm/aaaa hh:mm>` | `<ej. 22:00–02:00 París>` | `<ej. indisponibilidad aplicativa > 30 min>` | `<a completar>` |
| 1 | `<a completar>` | `<dd/mm/aaaa hh:mm>` | `<dd/mm/aaaa hh:mm>` | `<a completar>` | `<a completar>` | `<a completar>` |
| 2 | `<a completar>` | `<dd/mm/aaaa hh:mm>` | `<dd/mm/aaaa hh:mm>` | `<a completar>` | `<a completar>` | `<a completar>` |
| 2 | `<a completar>` | `<dd/mm/aaaa hh:mm>` | `<dd/mm/aaaa hh:mm>` | `<a completar>` | `<a completar>` | `<a completar>` |
| 3 | `<a completar>` | `<dd/mm/aaaa hh:mm>` | `<dd/mm/aaaa hh:mm>` | `<a completar>` | `<a completar>` | `<a completar>` |

*(Agregar filas / olas según el alcance del proyecto.)*

## Criterios para armar las olas

- [ ] Ola piloto: VM(s) no críticas, con pocas dependencias, para validar el método
- [ ] Olas siguientes: agrupación por criticidad creciente y/o por dependencias aplicativas
- [ ] Última ola: VM(s) críticas, solo después del éxito validado de las olas anteriores

## Roles y responsabilidades

| Rol | Nombre | Contacto | Disponibilidad durante la ventana |
|---|---|---|---|
| Jefe de proyecto de migración | `<a completar>` | `<a completar>` | `<a completar>` |
| Operador técnico Proxmox | `<a completar>` | `<a completar>` | `<a completar>` |
| Referente de negocio / validador | `<a completar>` | `<a completar>` | `<a completar>` |
| Guardia de red / infraestructura | `<a completar>` | `<a completar>` | `<a completar>` |

## Criterios de activación del rollback (generales)

- [ ] Fallo al arrancar la VM tras la migración
- [ ] Pérdida de conectividad de red no resuelta en el plazo fijado: `<a completar>`
- [ ] Indisponibilidad aplicativa crítica constatada por el referente de negocio
- [ ] Corrupción o pérdida de datos constatada
- [ ] Otro criterio específico del proyecto: `<a completar>`

## Seguimiento post-ola

| Ola | Estado | Fecha de cierre | Comentario |
|---|---|---|---|
| 1 | `<en curso / finalizada / rollback>` | `<dd/mm/aaaa>` | `<a completar>` |
| 2 | `<en curso / finalizada / rollback>` | `<dd/mm/aaaa>` | `<a completar>` |
| 3 | `<en curso / finalizada / rollback>` | `<dd/mm/aaaa>` | `<a completar>` |

---
*Plantilla proporcionada por Intermovil TEC. Ningún dato real de cliente debe aparecer en este documento antes de su difusión pública.*
