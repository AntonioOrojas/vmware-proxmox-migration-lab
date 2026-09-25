#!/usr/bin/env bash
# Active la virtualisation imbriquée de façon persistante.
# Activa la virtualización anidada de forma persistente.
source "$(dirname "$0")/lib.sh"
require_pve

if grep -qw vmx /proc/cpuinfo; then MOD="kvm_intel"; else MOD="kvm_amd"; fi
CONF="/etc/modprobe.d/${MOD}-nested.conf"

if [[ "$(cat /sys/module/${MOD}/parameters/nested)" =~ ^(Y|1)$ ]]; then
  ok "Déjà actif : rien à faire"; exit 0
fi

echo "options ${MOD} nested=1" > "$CONF"
ok "Écrit : $CONF"

# Rechargement à chaud seulement si aucune VM ne tourne
if [[ -z "$(qm list | awk 'NR>1 && $3=="running"')" ]]; then
  modprobe -r "$MOD" && modprobe "$MOD"
  ok "Module $MOD rechargé : nested=$(cat /sys/module/${MOD}/parameters/nested)"
else
  warn "Des VM sont démarrées : redémarrer l'hôte pour appliquer (ou arrêter les VM et relancer ce script)"
fi
