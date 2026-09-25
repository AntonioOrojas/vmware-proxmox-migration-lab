# 11 — Metodología del proyecto

Este laboratorio técnico reproduce las etapas de una migración real. A continuación
la metodología genérica que aplica Intermovil TEC en un proyecto cliente de migración
VMware → Proxmox. Esta página describe un enfoque, no un historial: no se menciona
ninguna misión, cliente ni métrica (ver `results/` para las plantillas «a medir» que
se completan proyecto a proyecto).

## 1. Auditoría del entorno existente (RVTools)

Antes de cualquier presupuesto, un export de RVTools del entorno vCenter/ESXi de
origen da el inventario exhaustivo: VM, vCPU/RAM asignados vs. consumidos, discos y
datastores, snapshots en curso, VM Tools instalados, configuración de red y
dependencias visibles (carpetas, clústeres, tags). Este inventario es la base de la
plantilla [`inventory/vms.example.csv`](../../inventory/vms.example.csv) y sirve para:

- Identificar las VM que usan funcionalidades no soportadas por el import de Proxmox
  (vSAN, discos cifrados — ver [10-depannage.md](10-depannage.md)).
- Estimar el dimensionamiento destino (almacenamiento, red) según el consumo real y
  no la asignación.
- Detectar las VM con snapshots sin consolidar que hay que tratar antes de migrar.

## 2. Piloto

Seleccionar 1 o 2 VM de bajo riesgo (no críticas, redundantes, o con un entorno de
respaldo sencillo) para validar la cadena completa: export/import, post-migración
(VirtIO, red), validación. El piloto sirve para:

- Validar los scripts y procedimientos sobre la infraestructura real del cliente (no
  solo en el laboratorio).
- Medir una duración de referencia por VM (tamaño de disco, método de import) para
  afinar el planning de las siguientes olas.
- Detectar particularidades locales (proxy, firewall, DNS interno) antes de escalar.

## 3. Olas de migración

Agrupar las VM restantes en olas según el riesgo y las dependencias, no simplemente
por orden alfabético:

- Agrupar en la misma ola las VM ligadas a nivel de aplicación (p. ej. un frontal web
  y su base de datos migran juntos) para limitar las ventanas en las que la
  aplicación corre repartida entre dos hipervisores.
- Aislar las VM más críticas en una ola tardía, una vez probado el método en olas
  anteriores sin incidentes.
- Dimensionar cada ola según la capacidad real de validación (ver
  [09-validation-rollback.md](09-validation-rollback.md)): no migrar más VM de las
  que el equipo puede validar seriamente en la ventana disponible.

## 4. Cutover

Cada ola sigue una ventana de corte planificada:

- Comunicación previa a los usuarios/negocio afectados (fecha, duración de
  indisponibilidad esperada).
- Corte técnico: apagado en origen, migración, post-migración, validación (ver
  doc 09), y puesta en servicio.
- Ventana de rollback mantenida abierta (VM fuente intacta, apagada) hasta el final
  del periodo de observación.

## 5. MCO (mantenimiento en condición operativa)

Una vez terminada la migración, la misión no acaba en el corte:

- Supervisión de las VM migradas durante un periodo definido contractualmente.
- Ajustes de dimensionamiento (CPU/RAM/almacenamiento) a partir de las métricas
  reales observadas en Proxmox.
- Formación de los equipos internos del cliente en la administración de Proxmox VE
  (interfaz, backups, snapshots, actualización).
- Documentación de salida: inventario final, procedimientos específicos del entorno
  del cliente, contactos de soporte.

Ver [SERVICIOS.md](../../SERVICIOS.md) / `OFFRE.md` para el detalle de la oferta
comercial asociada a esta metodología.
