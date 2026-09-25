#!/usr/bin/env bash
# Bascule le disque système d'une VM Windows migrée vers VirtIO SCSI, en 3 phases sûres.
# Cambia el disco de sistema de una VM Windows migrada a VirtIO SCSI, en 3 fases seguras.
#
#   to-sata  : met tous les disques sur SATA (premier boot garanti)
#   prepare  : ajoute un disque factice VirtIO SCSI de 1 Go -> Windows charge vioscsi
#   finalize : déplace les disques SATA vers SCSI, supprime le disque factice
#
# Usage : ./05-windows-virtio.sh <vmid> <to-sata|prepare|finalize>
source "$(dirname "$0")/lib.sh"
require_pve
load_env

VMID="${1:?VMID requis}"
PHASE="${2:?Phase requise : to-sata | prepare | finalize}"
DUMMY_SLOT="scsi30"

vm_running "$VMID" && die "Arrêter la VM $VMID avant (qm shutdown $VMID)"

# Liste des disques (hors cdrom et EFI/TPM) d'un bus donné
disks_on_bus() {
  qm config "$VMID" | awk -F': ' -v bus="$1" '
    $1 ~ "^"bus"[0-9]+$" && $2 !~ /media=cdrom/ {print $1}'
}

next_free() {
  local bus="$1" i=0
  while [[ -n "$(vm_cfg "$VMID" "${bus}${i}")" ]]; do i=$((i+1)); done
  echo "${bus}${i}"
}

move_disk() {  # move_disk <slot-src> <bus-dst> [options]
  local src="$1" dst_bus="$2" opts="${3:-}" raw vol dst
  raw="$(vm_cfg "$VMID" "$src")"; vol="$(volid_of "$raw")"
  [[ "$src" == "$DUMMY_SLOT" ]] && return 0
  dst="$(next_free "$dst_bus")"
  log "$src ($vol) -> $dst"
  qm set "$VMID" --delete "$src" >/dev/null
  # le volume passe en unusedN ; on le rattache / el volumen pasa a unusedN; se reasigna
  qm set "$VMID" "--${dst}" "${vol}${opts}" >/dev/null
  # retirer la référence unusedN éventuelle / quitar la referencia unusedN
  for u in $(qm config "$VMID" | awk -F': ' -v v="$vol" '$1 ~ /^unused/ && $2==v {print $1}'); do
    qm set "$VMID" --delete "$u" >/dev/null
  done
  echo "$dst"
}

case "$PHASE" in
  to-sata)
    first=""
    for d in $(disks_on_bus scsi) $(disks_on_bus virtio) $(disks_on_bus ide); do
      new="$(move_disk "$d" sata ",discard=on,ssd=1" | tail -n1)"
      [[ -z "$first" ]] && first="$new"
    done
    [[ -n "$first" ]] && qm set "$VMID" --boot "order=${first}" >/dev/null
    ok "Disques sur SATA. Démarrer, installer virtio-win-guest-tools.exe, éteindre, puis phase 'prepare'."
    ;;
  prepare)
    qm set "$VMID" --scsihw virtio-scsi-single "--${DUMMY_SLOT}" "${PVE_STORAGE}:1" >/dev/null
    ok "Disque factice ${DUMMY_SLOT} ajouté. Démarrer Windows, vérifier « Red Hat VirtIO SCSI » dans le Gestionnaire de périphériques, éteindre, puis phase 'finalize'."
    ;;
  finalize)
    first=""
    for d in $(disks_on_bus sata); do
      new="$(move_disk "$d" scsi ",discard=on,ssd=1,iothread=1" | tail -n1)"
      [[ -z "$first" ]] && first="$new"
    done
    if [[ -n "$(vm_cfg "$VMID" "$DUMMY_SLOT")" ]]; then
      qm disk unlink "$VMID" --idlist "$DUMMY_SLOT" --force 1
      ok "Disque factice supprimé"
    fi
    [[ -n "$first" ]] && qm set "$VMID" --boot "order=${first}" >/dev/null
    ok "Disque système sur VirtIO SCSI (${first}). Démarrer et valider."
    ;;
  *) die "Phase inconnue : $PHASE" ;;
esac

qm config "$VMID" | grep -E '^(boot|scsihw|sata[0-9]+|scsi[0-9]+|unused[0-9]+):' || true
