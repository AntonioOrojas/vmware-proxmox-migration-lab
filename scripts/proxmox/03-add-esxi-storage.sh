#!/usr/bin/env bash
# Déclare l'ESXi comme source d'import dans Proxmox (stockage de type "esxi").
# Declara el ESXi como origen de importación en Proxmox (almacenamiento tipo "esxi").
source "$(dirname "$0")/lib.sh"
require_pve
load_env

if [[ -z "${ESXI_PASSWORD}" ]]; then
  read -r -s -p "Mot de passe root ESXi : " ESXI_PASSWORD; echo
fi

if pvesm status | awk '{print $1}' | grep -qx "$ESXI_STORAGE_ID"; then
  warn "Le stockage $ESXI_STORAGE_ID existe déjà"
else
  log "Ajout du stockage d'import $ESXI_STORAGE_ID -> $ESXI_IP"
  pvesm add esxi "$ESXI_STORAGE_ID" \
    --server "$ESXI_IP" \
    --username "$ESXI_USER" \
    --password "$ESXI_PASSWORD" \
    --skip-cert-verification 1
  ok "Stockage ajouté"
fi

log "VM visibles sur l'ESXi :"
pvesm list "$ESXI_STORAGE_ID" | grep -E '\.vmx' || warn "Aucune VM listée (vérifier l'accès HTTPS 443 et les identifiants)"
