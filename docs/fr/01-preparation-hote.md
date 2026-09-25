# 01 — Préparation de l'hôte

## Prérequis

- Proxmox VE 9.2 ou supérieur (vérifié : sorti le 21/05/2026).
- CPU avec extensions de virtualisation matérielle : Intel VT-x ou AMD-V,
  activées dans le BIOS/UEFI (souvent désactivées par défaut sur du matériel
  grand public).
- Au moins 32 Go de RAM recommandés (16 Go pour l'ESXi imbriqué, le reste
  pour l'hôte et les VM Proxmox natives après migration). En dessous de
  24 Go, ESXi 8 lui-même n'a pas la marge nécessaire.
- Deux bridges réseau configurés : `vmbr0` (gestion) et `vmbr1` (réseau
  isolé du labo, derrière OPNsense).

## Étape 1 : vérifier l'hôte

```bash
./scripts/proxmox/00-check-host.sh
```

Ce script (voir son code — il ne fait que constater l'état, il ne modifie
rien) vérifie dans l'ordre :

1. La version de Proxmox VE installée (`pveversion`).
2. La présence d'extensions VT-x (`vmx`) ou AMD-V (`svm`) dans
   `/proc/cpuinfo` — arrêt immédiat si aucune des deux n'est présente.
3. L'état de la virtualisation imbriquée via
   `/sys/module/kvm_<intel|amd>/parameters/nested`.
4. La RAM totale de l'hôte, avec un seuil d'avertissement à 24 Go et un
   seuil bloquant à 32 Go (en dessous, le script recommande de réduire
   `ESXI_MEMORY_MB` à 12288 dans `lab.env`).
5. Les stockages disponibles (`pvesm status`).
6. La présence des bridges `vmbr0` et `vmbr1`.
7. La disponibilité de l'assistant d'import ESXi
   (`pve-esxi-import-tools`), nécessaire pour
   [04-migration-assistant.md](04-migration-assistant.md).

## Étape 2 : activer la virtualisation imbriquée

Si l'étape précédente signale `nested` inactif :

```bash
./scripts/proxmox/01-enable-nested.sh
```

Ce script détecte le module KVM utilisé (`kvm_intel` ou `kvm_amd`), écrit
`options <module> nested=1` dans
`/etc/modprobe.d/<module>-nested.conf` pour rendre le réglage persistant, puis
tente de recharger le module à chaud — mais uniquement si aucune VM n'est en
cours d'exécution sur l'hôte (`modprobe -r` échouerait sinon). Si des VM
tournent, un redémarrage de l'hôte (ou l'arrêt des VM suivi d'un nouveau
lancement du script) est nécessaire pour appliquer le réglage.

## Étape 3 : configuration du labo

```bash
cp lab.env.example lab.env
```

Adapter `lab.env` : nœud Proxmox, stockages, bridges, VMID et
caractéristiques de l'ESXi imbriqué, IP de gestion de l'ESXi. Ce fichier
n'est jamais commité (voir `.gitignore`) puisqu'il peut contenir, à terme,
des identifiants.

## Suite

[02-esxi-imbrique.md](02-esxi-imbrique.md) — créer la VM ESXi imbriquée.
