#!/usr/bin/env bash
# Vérifie que l'hôte Proxmox peut héberger un ESXi imbriqué.
# Verifica que el host Proxmox puede alojar un ESXi anidado.
# Usage : ./00-check-host.sh
source "$(dirname "$0")/lib.sh"
require_pve

log "Version Proxmox VE : $(pveversion | head -n1)"

# 1. Extensions de virtualisation matérielle
if grep -qw vmx /proc/cpuinfo; then
  VENDOR="intel"; ok "CPU Intel VT-x détecté"
elif grep -qw svm /proc/cpuinfo; then
  VENDOR="amd"; ok "CPU AMD-V détecté"
else
  die "Aucune extension VT-x/AMD-V : activer la virtualisation dans le BIOS/UEFI"
fi
log "Modèle CPU : $(awk -F': ' '/model name/ {print $2; exit}' /proc/cpuinfo)"

# 2. Virtualisation imbriquée
NESTED_FILE="/sys/module/kvm_${VENDOR}/parameters/nested"
if [[ -f "$NESTED_FILE" ]]; then
  val="$(cat "$NESTED_FILE")"
  if [[ "$val" == "Y" || "$val" == "1" ]]; then
    ok "Virtualisation imbriquée active (kvm_${VENDOR} nested=$val)"
  else
    warn "Virtualisation imbriquée inactive -> lancer ./01-enable-nested.sh"
  fi
else
  warn "Module kvm_${VENDOR} non chargé"
fi

# 3. Mémoire
MEM_GB=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
if (( MEM_GB >= 32 )); then ok "RAM : ${MEM_GB} Go"
elif (( MEM_GB >= 24 )); then warn "RAM : ${MEM_GB} Go (juste : réduire ESXI_MEMORY_MB à 12288)"
else die "RAM : ${MEM_GB} Go (insuffisant : ESXi 8 exige 8 Go minimum + VM invitées)"
fi

# 4. Stockage
log "Stockages disponibles :"
pvesm status

# 5. Bridges
for br in vmbr0 vmbr1; do
  if ip link show "$br" >/dev/null 2>&1; then ok "Bridge $br présent"; else warn "Bridge $br absent"; fi
done

# 6. Support du stockage d'import ESXi (PVE >= 8.2)
if pvesm help add 2>/dev/null | grep -q esxi || dpkg -l pve-esxi-import-tools >/dev/null 2>&1; then
  ok "Assistant d'import ESXi disponible (pve-esxi-import-tools)"
else
  warn "pve-esxi-import-tools absent : apt update && apt install pve-esxi-import-tools"
fi
