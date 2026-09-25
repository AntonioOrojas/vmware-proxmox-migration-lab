# Checklist de migration VMware → Proxmox

> Gabarit à dupliquer pour chaque VM migrée. Cocher au fur et à mesure.
> VM concernée : `<nom de la VM>` — Date : `<jj/mm/aaaa>` — Opérateur : `<nom>`

## Pré-migration

### Inventaire et audit

- [ ] VM identifiée dans l'inventaire RVTools / export vCenter (`inventory/vms.example.csv` ou équivalent réel)
- [ ] Datastore source noté : `<nom du datastore>`
- [ ] Taille totale des disques relevée : `<X Go>`
- [ ] RAM / vCPU relevés : `<X Go RAM> / <X vCPU>`
- [ ] Système d'exploitation et version confirmés : `<OS + version>`
- [ ] Criticité métier de la VM évaluée : `<faible / moyenne / haute>`
- [ ] Propriétaire / référent métier identifié : `<nom / service>`

### Vérifications bloquantes

- [ ] Datastore source ne contient **pas** de vSAN (import Proxmox non supporté)
- [ ] Disques **non chiffrés** (VM Encryption vSphere désactivée ou déchiffrée avant migration)
- [ ] Nom du datastore vérifié : **absence du caractère `+`** (fait échouer l'import)
- [ ] Snapshots recensés : `<nombre de snapshots>` — si présents, prévoir consolidation (l'import sera plus lent)
- [ ] Snapshots consolidés / supprimés après validation avec le référent métier
- [ ] Statut vTPM vérifié : `<présent / absent>`
- [ ] Si vTPM présent : BitLocker (ou chiffrement équivalent) **suspendu ou déchiffré AVANT migration** (le vTPM ne migre pas)
- [ ] Clé de récupération BitLocker sauvegardée en lieu sûr (hors VM)

### Préparation de l'invité

- [ ] VMware Tools **désinstallés depuis l'intérieur de l'invité, AVANT la migration** (pas de désinstallation possible une fois sortie de VMware)
- [ ] Configuration réseau relevée et sauvegardée (IP, masque, passerelle, DNS, routes statiques)
- [ ] Liste des disques et lettres/points de montage relevée
- [ ] Services critiques / applicatifs recensés (pour validation post-migration)
- [ ] Sauvegarde / snapshot de secours externe pris avant toute opération (hors périmètre Proxmox)
- [ ] Fenêtre de maintenance validée avec le métier

## Migration

### Choix de la méthode

- [ ] Méthode retenue : `<assistant d'import ESXi / import OVF / disk import>`
- [ ] Justification du choix de méthode notée : `<raison>`

**Assistant d'import ESXi** (`pvesm add esxi` + `qm import`)
- [ ] Stockage ESXi ajouté (`pvesm add esxi <id> --server ... --skip-cert-verification 1`)
- [ ] VM listée correctement dans l'assistant d'import Proxmox
- [ ] Commande `qm import <vmid> <storage>:ha-datacenter/<datastore>/<vm>/<vm>.vmx --storage <dst>` exécutée
- [ ] Stockage cible Proxmox choisi : `<nom du storage>`

**Import OVF** (`qm importovf`)
- [ ] Export OVF/OVA généré et transféré vers le nœud Proxmox
- [ ] Commande `qm importovf <vmid> <file.ovf> <storage>` exécutée

**Disk import** (`qm disk import`)
- [ ] Fichier(s) VMDK récupéré(s) et transférés vers le nœud Proxmox
- [ ] VM cible créée sur Proxmox (matériel : CPU, RAM, réseau) avant import du disque
- [ ] Commande `qm disk import <vmid> <file.vmdk> <storage>` exécutée
- [ ] Disque attaché à la VM Proxmox après import

### Vérifications post-import immédiates

- [ ] VM démarre sans erreur sur Proxmox
- [ ] Type de BIOS correct (SeaBIOS pour BIOS legacy, OVMF/UEFI pour UEFI) — cohérent avec la VM source
- [ ] Disque(s) visibles et de la bonne taille dans Proxmox
- [ ] Carte réseau configurée (`vmxnet3`/`e1000` source → `virtio` recommandé côté Proxmox après pilotes)
- [ ] Durée totale de la migration consignée : `<hh:mm>`

## Post-migration Windows

- [ ] ISO `virtio-win` (version stable notée : `<ex. 0.1.271>`) montée sur la VM
- [ ] Pilotes VirtIO installés (stockage, réseau) via `virtio-win-guest-tools.exe` (silencieux si possible)
- [ ] `qemu-guest-agent` (service QEMU Guest Agent) installé et démarré
- [ ] Disque basculé en contrôleur VirtIO (le cas échéant, procédure `to-sata` → disque dummy `scsi30` → `finalize`)
- [ ] Cartes réseau fantômes supprimées (Gestionnaire de périphériques → afficher périphériques cachés / `pnputil`)
- [ ] Configuration réseau restaurée (IP statique, DNS, routes) selon relevé pré-migration
- [ ] Activation Windows vérifiée (licence toujours valide / réactivation si nécessaire)
- [ ] Services et applicatifs redémarrés et fonctionnels
- [ ] BitLocker réactivé si applicable (après validation complète)
- [ ] Redémarrage de contrôle effectué sans erreur

## Post-migration Linux

- [ ] `open-vm-tools` désinstallé
- [ ] `qemu-guest-agent` installé et démarré (`systemctl enable --now qemu-guest-agent`)
- [ ] Modules VirtIO présents dans l'initramfs (`dracut` sur RHEL/Fedora ou `update-initramfs` sur Debian/Ubuntu)
- [ ] Renommage d'interface réseau anticipé (`ens192` → `ens18` ou équivalent) — configuration réseau adaptée en conséquence
- [ ] Fichiers de configuration réseau (netplan / interfaces / NetworkManager) mis à jour avec le nouveau nom d'interface
- [ ] Table de partitions et `fstab` vérifiés (UUID inchangés, montage correct)
- [ ] Services critiques redémarrés et fonctionnels

## Validation

- [ ] Connectivité réseau confirmée (ping, DNS, passerelle)
- [ ] Accès applicatif testé par le référent métier
- [ ] Performances comparées au périmètre attendu (CPU/RAM/disque)
- [ ] QEMU Guest Agent répond correctement (`qm agent <vmid> ping`)
- [ ] Sauvegarde Proxmox (vzdump/PBS) planifiée pour la VM migrée
- [ ] Validation formelle signée par le référent métier : `<nom / date>`
- [ ] VM source (ESXi) mise en pause / isolée réseau (pas de suppression immédiate)

## Plan de rollback

- [ ] VM source ESXi conservée éteinte (non supprimée) pendant la période de garantie post-migration : `<durée, ex. 7 jours>`
- [ ] Critère de déclenchement du rollback défini : `<ex. service indisponible > X min>`
- [ ] Procédure de rollback documentée : `<remise en route VM source, réintégration réseau>`
- [ ] Responsable de la décision de rollback identifié : `<nom>`
- [ ] Date de fin de la période de garantie / suppression définitive de la VM source : `<jj/mm/aaaa>`
- [ ] Communication de clôture envoyée au métier après période de garantie

---
*Gabarit fourni par Intermovil TEC — à adapter selon le contexte du client. Aucune donnée réelle ne doit rester dans ce document une fois complété pour un usage public.*
