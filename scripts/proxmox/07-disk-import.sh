#!/usr/bin/env bash
# Méthode C : import d'un VMDK dans une VM créée à la main (qm disk import).
# Método C: importar un VMDK en una VM creada manualmente (qm disk import).
# Cas d'usage : datastore NFS partagé, copie de VMDK par scp, sauvegarde restaurée.
#
# Usage : ./07-disk-import.sh <vmid> <fichier.vmdk> [windows|linux] [ovmf|seabios]
source "$(dirname "$0")/lib.sh"
require_pve
load_env

VMID="${1:?VMID requis}"
VMDK="${2:?Chemin du .vmdk (descripteur) requis}"
OS_FAMILY="${3:-linux}"
FIRMWARE="${4:-seabios}"

[[ -f "$VMDK" ]] || die "Fichier introuvable : $VMDK"
[[ -f "${VMDK%.vmdk}-flat.vmdk" ]] || warn "Pas de *-flat.vmdk à côté : vérifier que le descripteur et les données sont présents"

if ! vm_exists "$VMID"; then
  OSTYPE="l26"; [[ "$OS_FAMILY" == "windows" ]] && OSTYPE="win11"
  log "Création de la VM $VMID ($OSTYPE, $FIRMWARE)"
  qm create "$VMID" --name "import-${VMID}" --ostype "$OSTYPE" --machine q35 \
    --bios "$FIRMWARE" --cpu x86-64-v2-AES --cores 2 --memory 4096 \
    --scsihw virtio-scsi-single --net0 "virtio,bridge=${BRIDGE_LAB}" --agent enabled=1
  if [[ "$FIRMWARE" == "ovmf" ]]; then
    qm set "$VMID" --efidisk0 "${PVE_STORAGE}:1,efitype=4m,pre-enrolled-keys=0"
  fi
fi

log "Conversion et import de $VMDK"
qm disk import "$VMID" "$VMDK" "$PVE_STORAGE"
UNUSED="$(qm config "$VMID" | awk -F': ' '/^unused[0-9]+:/ {print $1; exit}')"
VOL="$(vm_cfg "$VMID" "$UNUSED")"

BUS="scsi0"; [[ "$OS_FAMILY" == "windows" ]] && BUS="sata0"
qm set "$VMID" --delete "$UNUSED" >/dev/null
qm set "$VMID" "--${BUS}" "${VOL},discard=on,ssd=1" --boot "order=${BUS}"
ok "Disque rattaché sur $BUS. Démarrer : qm start $VMID"
