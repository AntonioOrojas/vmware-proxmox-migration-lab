# Checklist de migración VMware → Proxmox

> Plantilla a duplicar para cada VM migrada. Marcar a medida que se completa cada paso.
> VM en cuestión: `<nombre de la VM>` — Fecha: `<dd/mm/aaaa>` — Operador: `<nombre>`

## Pre-migración

### Inventario y auditoría

- [ ] VM identificada en el inventario RVTools / export de vCenter (`inventory/vms.example.csv` o equivalente real)
- [ ] Datastore de origen anotado: `<nombre del datastore>`
- [ ] Tamaño total de los discos registrado: `<X GB>`
- [ ] RAM / vCPU registrados: `<X GB RAM> / <X vCPU>`
- [ ] Sistema operativo y versión confirmados: `<SO + versión>`
- [ ] Criticidad de negocio evaluada: `<baja / media / alta>`
- [ ] Responsable / referente de negocio identificado: `<nombre / área>`

### Verificaciones bloqueantes

- [ ] El datastore de origen **no** usa vSAN (el import de Proxmox no lo soporta)
- [ ] Discos **sin cifrar** (VM Encryption de vSphere desactivado o descifrado antes de la migración)
- [ ] Nombre del datastore verificado: **sin el carácter `+`** (hace fallar el import)
- [ ] Snapshots inventariados: `<número de snapshots>` — si existen, prever su consolidación (el import será más lento)
- [ ] Snapshots consolidados / eliminados tras validación con el referente de negocio
- [ ] Estado del vTPM verificado: `<presente / ausente>`
- [ ] Si hay vTPM: BitLocker (o cifrado equivalente) **suspendido o descifrado ANTES de la migración** (el vTPM no migra)
- [ ] Clave de recuperación de BitLocker respaldada en un lugar seguro (fuera de la VM)

### Preparación del sistema invitado

- [ ] VMware Tools **desinstalados desde dentro del invitado, ANTES de la migración** (no se puede desinstalar una vez fuera de VMware)
- [ ] Configuración de red registrada y respaldada (IP, máscara, puerta de enlace, DNS, rutas estáticas)
- [ ] Lista de discos y letras/puntos de montaje registrada
- [ ] Servicios críticos / aplicaciones inventariados (para la validación posterior)
- [ ] Copia de seguridad / snapshot externo de respaldo realizado antes de cualquier operación (fuera del ámbito de Proxmox)
- [ ] Ventana de mantenimiento validada con el área de negocio

## Migración

### Elección del método

- [ ] Método elegido: `<asistente de import ESXi / import OVF / disk import>`
- [ ] Justificación de la elección registrada: `<razón>`

**Asistente de import ESXi** (`pvesm add esxi` + `qm import`)
- [ ] Storage ESXi agregado (`pvesm add esxi <id> --server ... --skip-cert-verification 1`)
- [ ] VM listada correctamente en el asistente de import de Proxmox
- [ ] Comando `qm import <vmid> <storage>:ha-datacenter/<datastore>/<vm>/<vm>.vmx --storage <dst>` ejecutado
- [ ] Storage destino de Proxmox elegido: `<nombre del storage>`

**Import OVF** (`qm importovf`)
- [ ] Export OVF/OVA generado y transferido al nodo Proxmox
- [ ] Comando `qm importovf <vmid> <file.ovf> <storage>` ejecutado

**Disk import** (`qm disk import`)
- [ ] Archivo(s) VMDK obtenidos y transferidos al nodo Proxmox
- [ ] VM destino creada en Proxmox (hardware: CPU, RAM, red) antes de importar el disco
- [ ] Comando `qm disk import <vmid> <file.vmdk> <storage>` ejecutado
- [ ] Disco adjuntado a la VM de Proxmox tras el import

### Verificaciones inmediatas post-import

- [ ] La VM arranca sin errores en Proxmox
- [ ] Tipo de BIOS correcto (SeaBIOS para BIOS legacy, OVMF/UEFI para UEFI) — coherente con la VM origen
- [ ] Disco(s) visibles y del tamaño correcto en Proxmox
- [ ] Tarjeta de red configurada (`vmxnet3`/`e1000` origen → `virtio` recomendado en Proxmox tras instalar drivers)
- [ ] Duración total de la migración registrada: `<hh:mm>`

## Post-migración Windows

- [ ] ISO `virtio-win` (versión estable anotada: `<ej. 0.1.271>`) montada en la VM
- [ ] Drivers VirtIO instalados (almacenamiento, red) mediante `virtio-win-guest-tools.exe` (silencioso si es posible)
- [ ] `qemu-guest-agent` (servicio QEMU Guest Agent) instalado e iniciado
- [ ] Disco migrado a controlador VirtIO (si corresponde, procedimiento `to-sata` → disco dummy `scsi30` → `finalize`)
- [ ] Tarjetas de red fantasma eliminadas (Administrador de dispositivos → mostrar dispositivos ocultos / `pnputil`)
- [ ] Configuración de red restaurada (IP estática, DNS, rutas) según lo registrado antes de la migración
- [ ] Activación de Windows verificada (licencia sigue válida / reactivación si es necesario)
- [ ] Servicios y aplicaciones reiniciados y funcionando
- [ ] BitLocker reactivado si corresponde (después de la validación completa)
- [ ] Reinicio de control realizado sin errores

## Post-migración Linux

- [ ] `open-vm-tools` desinstalado
- [ ] `qemu-guest-agent` instalado e iniciado (`systemctl enable --now qemu-guest-agent`)
- [ ] Módulos VirtIO presentes en el initramfs (`dracut` en RHEL/Fedora o `update-initramfs` en Debian/Ubuntu)
- [ ] Renombramiento de interfaz de red previsto (`ens192` → `ens18` o equivalente) — configuración de red adaptada en consecuencia
- [ ] Archivos de configuración de red (netplan / interfaces / NetworkManager) actualizados con el nuevo nombre de interfaz
- [ ] Tabla de particiones y `fstab` verificados (UUID sin cambios, montaje correcto)
- [ ] Servicios críticos reiniciados y funcionando

## Validación

- [ ] Conectividad de red confirmada (ping, DNS, puerta de enlace)
- [ ] Acceso aplicativo probado por el referente de negocio
- [ ] Rendimiento comparado con lo esperado (CPU/RAM/disco)
- [ ] QEMU Guest Agent responde correctamente (`qm agent <vmid> ping`)
- [ ] Copia de seguridad Proxmox (vzdump/PBS) planificada para la VM migrada
- [ ] Validación formal firmada por el referente de negocio: `<nombre / fecha>`
- [ ] VM origen (ESXi) puesta en pausa / aislada de red (sin eliminación inmediata)

## Plan de rollback

- [ ] VM origen ESXi conservada apagada (no eliminada) durante el período de garantía post-migración: `<duración, ej. 7 días>`
- [ ] Criterio de activación del rollback definido: `<ej. servicio no disponible > X min>`
- [ ] Procedimiento de rollback documentado: `<reactivación de la VM origen, reintegración a la red>`
- [ ] Responsable de la decisión de rollback identificado: `<nombre>`
- [ ] Fecha de fin del período de garantía / eliminación definitiva de la VM origen: `<dd/mm/aaaa>`
- [ ] Comunicación de cierre enviada al área de negocio tras el período de garantía

---
*Plantilla proporcionada por Intermovil TEC — adaptar según el contexto del cliente. Ningún dato real debe permanecer en este documento una vez completado para uso público.*
