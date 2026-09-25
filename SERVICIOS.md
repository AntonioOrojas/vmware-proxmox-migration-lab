# Oferta de servicios — Intermovil TEC

Acompañamiento en la migración **VMware → Proxmox VE**, para colectividades,
administraciones, empresas y MSP del mundo hispanohablante enfrentados al fin del
soporte de vSphere 8 (11/10/2027) y a los cambios de licenciamiento derivados de la
compra de VMware por Broadcom.

El enfoque es metódico y progresivo: no se migra un centro de datos de producción en
una sola noche. Cada etapa siguiente está diseñada para reducir el riesgo antes de
abordar la siguiente.

## 1. Diagnóstico inicial

Auditoría del parque VMware existente (inventario de VMs, dependencias, volumen de
almacenamiento, red, licencias vigentes), típicamente a partir de una exportación
RVTools o equivalente. Objetivo: identificar las VMs aptas para una importación directa
(asistente ESXi, OVF, importación de disco), aquellas con restricciones particulares
(vSAN, discos cifrados, vTPM/BitLocker, snapshots), y producir una hoja de ruta de
migración priorizada.

## 2. Prueba de concepto (PoC)

Migración piloto sobre un alcance reducido y no crítico, en condiciones cercanas a las
reales, con el fin de validar el método, los scripts y los procedimientos de
restauración de red antes de cualquier compromiso a mayor escala. La PoC sirve de base
de referencia para presupuestar y planificar las siguientes olas.

## 3. Migración por olas

División del parque en olas sucesivas, cada una limitada en número de VMs y en
duración, con validación funcional tras cada ola antes de pasar a la siguiente. Este
enfoque limita la exposición al riesgo y permite ajustar el método sobre la marcha.

## 4. Ventanas de corte programadas

Las ventanas de corte (cutover) se programan de noche, en horario francés, para
minimizar el impacto en los usuarios. Un punto destacable de la organización de
Intermovil TEC: la noche francesa corresponde a la tarde en Lima, Perú (UTC-5), lo que
permite un seguimiento de la operación en horario de oficina del lado del proveedor,
sin guardia nocturna improvisada — una ventaja operativa para la capacidad de reacción
durante la ventana de corte.

## 5. Formación de los equipos

Transferencia de competencias hacia los equipos internos: manejo diario de Proxmox VE
(gestión de VMs, copias de seguridad, actualizaciones), procedimientos post-migración
Windows y Linux (controladores VirtIO, agentes invitados) y buenas prácticas de
validación.

## 6. Soporte post-migración

Acompañamiento tras el cambio para la estabilización: seguimiento de correcciones
post-migración (red, controladores, servicios), asistencia ante incidencias, y
consolidación de la documentación (checklists, informe de migración) entregada al
cliente.

---

**Sobre resultados y referencias**: los indicadores de resultado (duración de las
migraciones, tasa de éxito, etc.) aún no se publican — este repositorio público sirve
como demostración técnica del laboratorio y del método, no como recopilación de casos
de clientes. Se prevé una plantilla de resultados en `results/` ("por medir"), sin
métricas, clientes ni certificaciones inventados.

## Contacto

[correo profesional]
