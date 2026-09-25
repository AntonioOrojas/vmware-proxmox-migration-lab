#!/usr/bin/env bash
# Importe une VM depuis l'ESXi (équivalent CLI de l'assistant d'import, PVE >= 8.2).
# Importa una VM desde ESXi (equivalente CLI del asistente de importación, PVE >= 8.2).
#
# Usage : ./04-import-vm.sh <nom-vm-esxi> [vmid] [windows|linux]
#   ex.   ./04-import-vm.sh WS2022-UEFI 201 windows
#
# La VM source DOIT être éteinte / La VM origen DEBE estar apagada.
source "$(dirname "$0")/lib.sh"
require_pve
load_env

SRC_NAME="${1:?Nom de la VM ESXi requis}"
VMID="${2:-$(pvesh get /cluster/nextid)}"
OS_FAMILY="${3:-linux}"

vm_exists "$VMID" && die "VMID $VMID déjà utilisée"

# Recherche du .vmx correspondant / Búsqueda del .vmx
VMX="$(pvesm list "$ESXI_STORAGE_ID" | awk '{print $1}' | grep -E "/${SRC_NAME}/${SRC_NAME}\.vmx$" | head -n1 || true)"
[[ -n "$VMX" ]] || die "VMX introuvable pour '$SRC_NAME'. Lister : pvesm list $ESXI_STORAGE_ID"
log "Source : $VMX"

START=$(date +%s)
log "Import vers VMID $VMID sur $PVE_STORAGE ..."
qm import "$VMID" "$VMX" --storage "$PVE_STORAGE"
ELAPSED=$(( $(date +%s) - START ))
ok "Import terminé en ${ELAPSED}s"

# Réglages communs / Ajustes comunes
qm set "$VMID" --agent enabled=1 --cpu x86-64-v2-AES --scsihw virtio-scsi-single

# Réseau : remplacer vmxnet3 par VirtIO sur le bridge du labo
for nic in $(qm config "$VMID" | awk -F: '/^net[0-9]+:/ {print $1}'); do
  qm set "$VMID" "--${nic}" "virtio,bridge=${BRIDGE_LAB}"
done

if [[ "$OS_FAMILY" == "windows" ]]; then
  # Premier démarrage sur SATA : Windows n'a pas encore le pilote vioscsi actif
  log "Windows : disque système basculé sur SATA pour le premier démarrage"
  "$(dirname "$0")/05-windows-virtio.sh" "$VMID" to-sata
  # ISO VirtIO en lecteur CD
  qm set "$VMID" --ide2 "${PVE_ISO_STORAGE}:iso/${VIRTIO_ISO},media=cdrom"
fi

# Traçabilité pour le rapport / Trazabilidad para el informe
mkdir -p "$REPO_ROOT/results"
printf '%s;%s;%s;%s;%ss\n' "$(date -Iseconds)" "$SRC_NAME" "$VMID" "$OS_FAMILY" "$ELAPSED" \
  >> "$REPO_ROOT/results/imports.csv"

qm config "$VMID"
ok "Prochaine étape : qm start $VMID (voir docs/fr/07-windows-post-migration.md)"
