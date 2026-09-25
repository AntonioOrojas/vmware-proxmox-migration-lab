# 12 — Soberanía digital: el contexto

Este laboratorio no es un ejercicio académico aislado: responde a un movimiento de
fondo observable desde la compra de VMware por Broadcom.

## El detonante: Broadcom y VMware

Desde la adquisición de VMware por Broadcom, los cambios en la política de
licenciamiento (fin de las licencias perpetuas, bundling forzado en suites, subidas
de precio reportadas por numerosos clientes e integradores) empujan a un gran número
de organizaciones — administraciones y entidades locales francesas, empresas, MSP, y
más ampliamente el ecosistema francófono (Bélgica, Suiza, Quebec, África francófona) y
también el mundo hispanohablante — a reevaluar su dependencia de VMware.

## Un gesto simbólico, no una solución: ESXi gratis de nuevo

Desde abril de 2025, Broadcom volvió a poner ESXi 8.0U3e disponible gratuitamente. En
este laboratorio, esta versión se usa en **modo evaluación (60 días)** — una elección
pragmática para construir y probar el entorno de demostración, no una vía de
licenciamiento de producción. La gratuidad de ESXi por sí sola no resuelve la
dependencia del ecosistema vSphere/vCenter para uso profesional: aquí solo sirve como
base anidada para reproducir migraciones realistas.

## El plazo: fin de soporte de vSphere 8

El soporte general de vSphere 8 termina el **11 de octubre de 2027**. Pasada esa
fecha, los entornos que permanezcan en esa versión dejan de recibir parches de
seguridad estándar, lo que convierte una cuestión de estrategia en un plazo operativo
concreto para cualquier organización que siga en VMware.

## Un punto de contexto francófono concreto: CoTer Numérique 2026

**CoTer Numérique 2026** (Reims, 23-24 de junio de 2026) es un evento donde las
entidades locales francesas intercambian sobre sus proyectos digitales, incluida la
migración de infraestructuras a raíz del fin de soporte anunciado de vSphere 8. Es un
ejemplo concreto de la dinámica en curso en el sector público territorial francófono,
no una afirmación de participación o alianza por parte de Intermovil TEC.

## La alternativa alineada con la soberanía: Proxmox VE

Proxmox VE está desarrollado por **Proxmox Server Solutions GmbH**, empresa con sede
en **Viena (Austria, Unión Europea)**. El software se distribuye bajo licencia
**AGPLv3**, una licencia libre que garantiza:

- Auditabilidad completa del código fuente (sin caja negra).
- Ausencia de dependencia de un único fabricante para el soporte (cualquier
  integrador puede intervenir sobre software libre).
- Un editor alojado en la UE, relevante para los criterios de soberanía digital que
  aplican algunas administraciones y sectores regulados.

## Lo que esta página no pretende

Aquí no se aportan métricas de migración, clientes ni certificaciones. Este documento
expone el contexto factual que motiva el proyecto; los resultados concretos de
misiones con clientes se documentan caso por caso en `results/`, nunca generalizados
aquí.
