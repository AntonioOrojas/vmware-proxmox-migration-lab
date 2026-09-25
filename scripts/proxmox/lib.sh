#!/usr/bin/env bash
# Fonctions communes / Funciones comunes
# shellcheck disable=SC2034

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

load_env() {
  local env_file="${LAB_ENV:-$REPO_ROOT/lab.env}"
  [[ -f "$env_file" ]] || die "Fichier $env_file introuvable. cp lab.env.example lab.env"
  # shellcheck source=/dev/null
  source "$env_file"
}

require_pve() {
  command -v qm >/dev/null 2>&1 || die "Ce script doit être exécuté sur un hôte Proxmox VE (commande 'qm' absente)."
  [[ $EUID -eq 0 ]] || die "Exécuter en root / Ejecutar como root."
}

vm_exists() { qm status "$1" >/dev/null 2>&1; }

vm_running() { [[ "$(qm status "$1" 2>/dev/null | awk '{print $2}')" == "running" ]]; }

# Retourne la valeur brute d'une clé de config (ex. sata0) / Devuelve el valor de una clave
vm_cfg() { qm config "$1" | awk -F': ' -v k="$2" '$1==k {print $2}'; }

# Extrait l'identifiant de volume (avant la première virgule) / Extrae el volid
volid_of() { printf '%s' "${1%%,*}"; }

confirm() {
  [[ "${ASSUME_YES:-0}" == "1" ]] && return 0
  read -r -p "$1 [o/N] " ans
  [[ "$ans" =~ ^[oOyYsS]$ ]]
}
