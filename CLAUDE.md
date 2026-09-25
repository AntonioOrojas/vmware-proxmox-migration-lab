# CLAUDE.md — Contexto para continuar en Claude Code

## Objetivo del proyecto
Repositorio público bilingüe (**francés principal + español**) firmado por **Intermovil TEC**
que documenta un laboratorio real: **VMware ESXi 8 anidado sobre Proxmox VE** y migraciones
completas **VMware → Proxmox**, incluidas **VMs Windows**. Sirve como vitrina comercial
para clientes de TI francófonos (administración francesa/colectividades, empresas, MSP,
Bélgica, Suiza, Quebec, África francófona) y del mundo hispano, en el contexto de la
soberanía digital y la salida de VMware tras Broadcom.

## Laboratorio del autor
- Host Proxmox: Core i7, 32 GB RAM, 1 TB, sin GPU. OPNsense aísla la red del lab (vmbr1).
- Presupuesto: ESXi anidado 16 GB / 4 vCPU / disco único 200 GB thin; dentro:
  Windows Server 2019 (BIOS), Windows Server 2022 o 2025 (UEFI), Debian 12/13.
- ESXi 8.0U3e es gratuito de nuevo (Broadcom, abril 2025); en el lab usar modo evaluación 60 días.

## Hechos verificados (sept. 2026)
- Proxmox VE 9.2 (21/05/2026). Asistente de importación ESXi desde PVE 8.2 (pve-esxi-import-tools).
- CLI: `pvesm add esxi <id> --server --username --password --skip-cert-verification 1`;
  `qm import <vmid> <storage>:ha-datacenter/<datastore>/<vm>/<vm>.vmx --storage <dst>`;
  `qm importovf <vmid> <file.ovf> <storage>`; `qm disk import <vmid> <file.vmdk> <storage>`.
- Límites del import: no vSAN, no discos cifrados, snapshots = más lento, datastores con '+' fallan.
- vTPM no migra → suspender/descifrar BitLocker antes. Quitar VMware Tools ANTES (no desinstala fuera de VMware).
- VirtIO: virtio-win 0.1.271 estable (fedorapeople archive-virtio); `virtio-win-guest-tools.exe` en la raíz de la ISO.
- ESXi anidado: CPU `host`, NIC `vmxnet3` (e1000 falla), disco SATA, `allowLegacyCPU=true` si CPU antigua;
  vSwitch ESXi con promiscuous/forged transmits/MAC changes = accept.
- vSphere 8: fin de soporte general 11/10/2027 (motor de demanda).
- Contexto FR: CoTer Numérique 2026 (Reims, 23-24/06/2026) — colectividades migrando a Proxmox por fin de soporte vSphere 8.
- Proxmox Server Solutions GmbH (Viena, UE), licencia AGPLv3.

## Hecho
- `lab.env.example`, `scripts/proxmox/lib.sh`, `00-check-host.sh`, `01-enable-nested.sh`,
  `02-create-nested-esxi.sh`, `03-add-esxi-storage.sh`, `04-import-vm.sh`,
  `05-windows-virtio.sh` (to-sata → prepare con disco dummy scsi30 → finalize),
  `06-ovf-import.sh`, `07-disk-import.sh`. Comentarios FR/ES.

## Pendiente (en orden)
1. `scripts/esxi/ks.cfg` (kickstart ESXi 8: `install --firstdisk --overwritevmfs --systemMediaSize=min`,
   red estática, SSH en %firstboot) y `scripts/esxi/postinstall.sh` (NTP, política de seguridad vSwitch0, portgroup LAB en vmnic1).
2. `scripts/windows/`: `Pre-Migration-Check.ps1` (exporta JSON: IP/DNS/rutas, discos, BitLocker, VMware Tools, servicios, firmware),
   `Remove-VMwareTools.ps1`, `Install-VirtIO.ps1` (silencioso, qemu-ga), `Restore-NetworkConfig.ps1`
   (elimina NICs fantasma con pnputil y reaplica el JSON), `Post-Migration-Validate.ps1`.
3. `scripts/linux/prep-virtio-initramfs.sh` (dracut / update-initramfs, quitar open-vm-tools, instalar qemu-guest-agent, aviso ens192→ens18).
4. Docs `docs/fr/` y `docs/es/` (misma numeración): 00-architecture (Mermaid), 01-preparation-hote,
   02-esxi-imbrique, 03-vms-de-test, 04-migration-assistant, 05-migration-ovf, 06-migration-disk-import,
   07-windows-post-migration, 08-linux-post-migration, 09-validation-rollback, 10-depannage,
   11-methodologie-projet (auditoría RVTools, piloto, olas, cutover, MCO), 12-souverainete-contexte.
5. `README.md` (FR, vitrina: problema → prueba → método → oferta → contacto, badges, diagrama),
   `README.es.md`, `OFFRE.md` / `SERVICIOS.md` (Intermovil TEC: diagnóstico, PoC, migración por olas,
   ventanas de corte en horario nocturno francés = tarde en Lima UTC-5, formación, soporte).
   **No inventar métricas, clientes ni certificaciones**: resultados en `results/` como plantilla “à mesurer”.
   Contacto: dejar marcador `[email profesional]` hasta que el autor lo confirme.
6. `templates/fr|es/`: checklist de migración, informe de migración, plan de olas; `inventory/vms.example.csv`.
7. `.github/`: workflow CI (shellcheck + PSScriptAnalyzer + markdown link check), issue templates, PR template.
   `LICENSE` (MIT código; docs CC BY 4.0), `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, `assets/banner.svg` original.
8. Verificar: `shellcheck scripts/**/*.sh`, enlaces internos.
9. Publicar: repo público `vmware-proxmox-migration-lab`, descripción FR, topics
   (proxmox, vmware, esxi, migration, virtualization, souverainete-numerique, windows-server, virtio, homelab, devops).

## Convenciones
- Mensajes de script en francés; comentarios bilingües FR/ES.
- Nunca subir `lab.env` (añadir a `.gitignore`) ni contraseñas.
