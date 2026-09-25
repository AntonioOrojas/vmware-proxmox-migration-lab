#!/usr/bin/env bash
# Crée la VM qui hébergera VMware ESXi 8 en mode imbriqué.
# Crea la VM que alojará VMware ESXi 8 en modo anidado.
#
# Choix techniques / Decisiones técnicas :
#   --cpu host        : expose VT-x/AMD-V à ESXi (indispensable)
#   --machine q35     : chipset PCIe moderne
#   net = vmxnet3     : ESXi 8 n'a plus de pilote e1000 fiable -> vmxnet3 natif
#   disque = SATA     : pilote AHCI natif d'ESXi (pas de pilote VirtIO dans ESXi)
#   --balloon 0       : pas de ballooning (ESXi gère sa propre mémoire)
source "$(dirname "$0")/lib.sh"
require_pve
load_env

vm_exists "$ESXI_VMID" && die "La VMID $ESXI_VMID existe déjà"

ISO_VOL="${PVE_ISO_STORAGE}:iso/${ESXI_ISO}"
pvesm list "$PVE_ISO_STORAGE" --content iso | grep -q "$ESXI_ISO" \
  || die "ISO introuvable : $ISO_VOL (téléverser l'ISO ESXi dans ${PVE_ISO_STORAGE})"

log "Création de la VM $ESXI_VMID ($ESXI_NAME)"
qm create "$ESXI_VMID" \
  --name "$ESXI_NAME" \
  --ostype other \
  --machine q35 \
  --bios seabios \
  --cpu host \
  --sockets 1 --cores "$ESXI_CORES" \
  --memory "$ESXI_MEMORY_MB" --balloon 0 \
  --sata0 "${PVE_STORAGE}:${ESXI_DISK_GB},ssd=1,discard=on" \
  --ide2 "${ISO_VOL},media=cdrom" \
  --net0 "vmxnet3,bridge=${BRIDGE_MGMT}" \
  --net1 "vmxnet3,bridge=${BRIDGE_LAB}" \
  --boot "order=sata0;ide2" \
  --onboot 0 \
  --description "ESXi 8 imbriqué - laboratoire de migration VMware -> Proxmox"

ok "VM créée."
qm config "$ESXI_VMID"

cat <<EOF

Étapes suivantes / Siguientes pasos :
  1. qm start $ESXI_VMID  puis ouvrir la console noVNC
  2. Installation manuelle, ou automatique avec kickstart :
       - servir scripts/esxi/ks.cfg en HTTP (voir docs/fr/02-esxi-imbrique.md)
       - au boot de l'installeur : Shift+O puis ajouter  ks=http://<IP>:8000/ks.cfg
  3. Si le CPU n'est pas supporté par ESXi 8 : ajouter  allowLegacyCPU=true
EOF
