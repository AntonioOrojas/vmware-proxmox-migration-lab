# 10 — Dépannage

Pannes rencontrées ou documentées pendant ce laboratoire, classées par phase.

## Import (assistant ESXi / OVF / disk import)

**Datastore vSAN non supporté**
L'assistant d'import ESXi de Proxmox ne sait pas lire un datastore vSAN. Solution :
exporter la VM en OVF depuis vCenter/ESXi (`ovftool`) puis utiliser
[05-migration-ovf.md](05-migration-ovf.md), ou migrer le disque hors vSAN avant import.

**Disques chiffrés non supportés**
Un disque VM chiffré (VM Encryption côté vSphere) ne peut pas être importé tel quel.
Déchiffrer le disque côté VMware avant export, ou passer par une copie à chaud du
contenu (backup/restore applicatif) plutôt qu'un import de disque.

**Import lent depuis une VM avec snapshots**
Chaque snapshot ajoute une couche de delta à consolider pendant l'import. Avant de
migrer, consolider les snapshots côté VMware (`Delete All` dans le gestionnaire de
snapshots ou `vim-cmd vmsvc/snapshot.removeall`) pour accélérer significativement le
transfert.

**Nom de datastore contenant un `+` provoque un échec**
Les datastores ESXi dont le nom contient un caractère `+` font échouer certaines
commandes d'import (problème d'échappement dans le chemin `ha-datacenter/<datastore>/...`).
Renommer le datastore sans caractère spécial avant d'importer, ou migrer via OVF qui
contourne le problème.

## ESXi imbriqué (nested)

**Carte réseau e1000 ne fonctionne pas / instable**
Utiliser `vmxnet3` pour la VM ESXi imbriquée elle-même ; `e1000` pose des problèmes de
stabilité et de performance en configuration imbriquée. Voir
`scripts/proxmox/02-create-nested-esxi.sh`.

**Incompatibilité CPU sur matériel ancien**
Si l'hôte physique est trop ancien pour le microcode attendu par ESXi 8, ajouter
`allowLegacyCPU=true` (typiquement en paramètre de boot ESXi ou variable avancée) pour
autoriser l'installation malgré l'avertissement de compatibilité CPU.

**VMs internes à l'ESXi imbriqué sans réseau**
Le vSwitch de l'ESXi imbriqué doit accepter le mode promiscuous, les forged
transmits et les MAC address changes (`accept` sur les trois), sinon le trafic des VM
internes (dont les adresses MAC diffèrent de celle de la VM ESXi hôte côté Proxmox) est
filtré silencieusement.

## Windows

**Écran noir / BSOD après bascule VirtIO SCSI**
Signe que la phase `prepare` a été sautée ou que le pilote `vioscsi` n'a pas été
installé avant `finalize`. Revenir en arrière n'est pas automatisé : réattacher
manuellement le disque en SATA (`qm set <vmid> --sata0 <volid>`) pour redémarrer, puis
reprendre la séquence à la phase `prepare`. Voir
[07-windows-post-migration.md](07-windows-post-migration.md).

**Demande de clé de récupération BitLocker au démarrage**
Le vTPM ne migre pas. Si BitLocker n'a pas été suspendu/déchiffré avant la migration
(voir doc 07), fournir la clé de récupération pour ce premier boot, puis désactiver ou
re-suspendre BitLocker proprement une fois la VM stabilisée sur Proxmox.

## Divers

**Support général vSphere 8**
Fin de support général le 11/10/2027 : au-delà, la source VMware d'un environnement
resté sous vSphere 8 n'a plus de correctifs de sécurité, ce qui renforce l'urgence de
migrer plutôt que de mettre à jour indéfiniment côté VMware.

Pas de cause trouvée ici ? Vérifier d'abord la section « Hechos verificados » de
`CLAUDE.md` puis la documentation officielle Proxmox VE (assistant d'import ESXi,
pve-esxi-import-tools).
