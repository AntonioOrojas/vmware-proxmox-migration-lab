#!/usr/bin/env bash
# Prépare un invité Debian/Ubuntu ou RHEL/Fedora (sous VMware) pour le premier démarrage
# sous VirtIO (Proxmox) : injecte les modules virtio dans l'initramfs, remplace
# open-vm-tools par qemu-guest-agent. À exécuter AVANT la migration, pendant que la VM
# démarre encore sous VMware (le noyau doit pouvoir trouver la racine au premier boot VirtIO).
#
# Prepara un invitado Debian/Ubuntu o RHEL/Fedora (bajo VMware) para el primer arranque
# bajo VirtIO (Proxmox): inyecta los módulos virtio en el initramfs y reemplaza
# open-vm-tools por qemu-guest-agent. Ejecutar ANTES de la migración, mientras la VM
# todavía arranca bajo VMware.
#
# Usage : sudo ./prep-virtio-initramfs.sh

set -euo pipefail

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ATTENTION]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[ECHEC]\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Exécuter en root (sudo). / Ejecutar como root (sudo)."

VIRTIO_MODULES=(virtio_blk virtio_scsi virtio_net virtio_pci virtio_ring)

# --- Détection de l'outillage initramfs / Detección de la herramienta initramfs ---------
INITRAMFS_TOOL=""
if command -v update-initramfs >/dev/null 2>&1 && [[ -d /etc/initramfs-tools ]]; then
  INITRAMFS_TOOL="update-initramfs"
elif command -v dracut >/dev/null 2>&1; then
  INITRAMFS_TOOL="dracut"
else
  die "Ni update-initramfs (Debian/Ubuntu) ni dracut (RHEL/Fedora) trouvés. / No se encontró update-initramfs ni dracut."
fi
log "Outil détecté : $INITRAMFS_TOOL / Herramienta detectada: $INITRAMFS_TOOL"

# --- Ajout des modules VirtIO à l'initramfs / Añadir los módulos VirtIO al initramfs ----
case "$INITRAMFS_TOOL" in
  update-initramfs)
    MODULES_FILE="/etc/initramfs-tools/modules"
    log "Ajout des modules VirtIO dans $MODULES_FILE... / Añadiendo módulos VirtIO en $MODULES_FILE..."
    [[ -f "$MODULES_FILE" ]] || touch "$MODULES_FILE"
    for mod in "${VIRTIO_MODULES[@]}"; do
      if ! grep -qxF "$mod" "$MODULES_FILE"; then
        echo "$mod" >> "$MODULES_FILE"
        log "  + $mod"
      fi
    done
    log "Régénération de l'initramfs (update-initramfs -u)... / Regenerando el initramfs (update-initramfs -u)..."
    update-initramfs -u -k all
    ok "Initramfs régénéré avec les modules VirtIO. / Initramfs regenerado con los módulos VirtIO."
    ;;
  dracut)
    DROPIN="/etc/dracut.conf.d/virtio.conf"
    log "Ajout des modules VirtIO via $DROPIN... / Añadiendo módulos VirtIO vía $DROPIN..."
    printf 'add_drivers+=" %s "\n' "${VIRTIO_MODULES[*]}" > "$DROPIN"
    log "Régénération de l'initramfs (dracut --force)... / Regenerando el initramfs (dracut --force)..."
    if command -v uname >/dev/null 2>&1; then
      dracut --force --add-drivers "${VIRTIO_MODULES[*]}" "/boot/initramfs-$(uname -r).img" "$(uname -r)"
    else
      dracut --force --add-drivers "${VIRTIO_MODULES[*]}"
    fi
    ok "Initramfs régénéré avec les modules VirtIO. / Initramfs regenerado con los módulos VirtIO."
    ;;
esac

# --- Remplacement open-vm-tools -> qemu-guest-agent / Reemplazo open-vm-tools -> qemu-guest-agent --
log "Suppression d'open-vm-tools et installation de qemu-guest-agent... / Eliminando open-vm-tools e instalando qemu-guest-agent..."
if command -v apt-get >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get remove -y open-vm-tools open-vm-tools-desktop 2>/dev/null || true
  DEBIAN_FRONTEND=noninteractive apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-guest-agent
elif command -v dnf >/dev/null 2>&1; then
  dnf remove -y open-vm-tools open-vm-tools-desktop 2>/dev/null || true
  dnf install -y qemu-guest-agent
elif command -v yum >/dev/null 2>&1; then
  yum remove -y open-vm-tools open-vm-tools-desktop 2>/dev/null || true
  yum install -y qemu-guest-agent
else
  die "Aucun gestionnaire de paquets pris en charge (apt-get/dnf/yum) trouvé. / No se encontró un gestor de paquetes compatible."
fi
ok "open-vm-tools supprimé, qemu-guest-agent installé. / open-vm-tools eliminado, qemu-guest-agent instalado."

log "Activation et démarrage de qemu-guest-agent... / Habilitando e iniciando qemu-guest-agent..."
systemctl enable --now qemu-guest-agent
ok "Service qemu-guest-agent actif. / Servicio qemu-guest-agent activo."

# --- Avertissement renommage d'interface / Advertencia sobre el renombrado de interfaz --
warn "IMPORTANT : sous VMware l'interface est souvent nommée ens192 (PCI vmxnet3)."
warn "Après la migration vers Proxmox (bus PCI virtio différent), elle sera renommée"
warn "(ex. ens18, eno1...) — l'ancien nom ne sera PLUS disponible au démarrage."
warn "IMPORTANTE: bajo VMware la interfaz suele llamarse ens192 (PCI vmxnet3)."
warn "Tras la migración a Proxmox (bus PCI virtio distinto), se renombrará"
warn "(ej. ens18, eno1...) — el nombre antiguo YA NO estará disponible al arrancar."
warn "Avant de redémarrer sous Proxmox, vérifier et adapter si besoin :"
warn "Antes de reiniciar bajo Proxmox, revisar y adaptar si es necesario:"
warn "  - /etc/network/interfaces (Debian classique / Debian clásico)"
warn "  - /etc/netplan/*.yaml (Ubuntu netplan)"
warn "  - les profils NetworkManager (nmcli con show) / los perfiles de NetworkManager"
warn "Envisager de fixer les interfaces par nom générique (ens*/eno*) ou par MAC plutôt"
warn "que par nom exact, ou d'utiliser DHCP temporairement pour valider le boot."
warn "Considere fijar las interfaces por patrón genérico (ens*/eno*) o por MAC en vez de"
warn "por nombre exacto, o usar DHCP temporalmente para validar el arranque."

ok "Préparation VirtIO terminée. Éteindre la VM puis lancer la migration. / Preparación VirtIO finalizada. Apagar la VM y lanzar la migración."
