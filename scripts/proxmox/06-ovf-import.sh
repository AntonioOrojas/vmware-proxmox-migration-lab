#!/usr/bin/env bash
# Méthode B : export OVF avec ovftool puis import avec qm importovf.
# Método B: exportación OVF con ovftool e importación con qm importovf.
# Utile quand l'API ESXi n'est pas joignable depuis Proxmox, ou pour archiver la VM.
#
# Usage : ./06-ovf-import.sh <nom-vm-esxi> <vmid> [dossier-export]
source "$(dirname "$0")/lib.sh"
require_pve
load_env

SRC_NAME="${1:?Nom de la VM ESXi requis}"
VMID="${2:?VMID requis}"
EXPORT_DIR="${3:-/var/lib/vz/ovf-export}"

command -v ovftool >/dev/null || die "ovftool absent (télécharger VMware OVF Tool Linux 64-bit depuis le portail Broadcom)"
vm_exists "$VMID" && die "VMID $VMID déjà utilisée"
mkdir -p "$EXPORT_DIR"

log "Export OVF de $SRC_NAME depuis $ESXI_IP"
ovftool --noSSLVerify "vi://${ESXI_USER}@${ESXI_IP}/${SRC_NAME}" "$EXPORT_DIR/"

OVF="$(find "$EXPORT_DIR" -name "${SRC_NAME}.ovf" | head -n1)"
[[ -n "$OVF" ]] || die "Fichier OVF introuvable dans $EXPORT_DIR"
sha256sum "$(dirname "$OVF")"/* > "$EXPORT_DIR/${SRC_NAME}.sha256"

log "Import OVF -> VMID $VMID"
qm importovf "$VMID" "$OVF" "$PVE_STORAGE"
qm set "$VMID" --net0 "virtio,bridge=${BRIDGE_LAB}" --cpu x86-64-v2-AES \
  --scsihw virtio-scsi-single --agent enabled=1
ok "Importé. Pour Windows : ./05-windows-virtio.sh $VMID to-sata"
