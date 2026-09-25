# 06 — Migration par import direct de disque

## Quand utiliser cette méthode

Cas d'usage typiques : un datastore NFS partagé accessible directement
depuis Proxmox, un fichier `.vmdk` copié par `scp`, ou une sauvegarde déjà
restaurée sur disque. Contrairement aux deux autres méthodes, celle-ci ne
crée pas automatiquement une VM à partir des métadonnées d'une VM ESXi
existante : la VM cible est créée (ou doit déjà exister) avec ses propres
réglages, puis le disque `.vmdk` y est importé et attaché.

## Utilisation

```bash
./scripts/proxmox/07-disk-import.sh <vmid> <fichier.vmdk> [windows|linux] [ovmf|seabios]
```

Équivalent, pour la partie import, à :

```bash
qm disk import <vmid> <file.vmdk> <storage>
```

Si `<vmid>` n'existe pas encore, le script crée une VM minimale (2 vCPU,
4 Go RAM, `virtio-scsi-single`, réseau `virtio` sur `vmbr1`, agent QEMU
activé) avec le type d'OS et le firmware demandés — `--efidisk0` est ajouté
automatiquement en cas de firmware `ovmf`. Le disque importé apparaît
d'abord comme volume `unusedN` ; le script le détecte, le détache de cet
état temporaire et le rattache explicitement :

- sur `sata0` pour une VM Windows (premier démarrage sans pilote `vioscsi`
  encore chargé — voir
  [05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh)) ;
- sur `scsi0` pour une VM Linux.

Le fichier `.vmdk` fourni doit être le **descripteur** (le petit fichier
texte), avec son fichier de données `*-flat.vmdk` associé dans le même
dossier — le script avertit s'il ne le trouve pas à côté.

## Limites

Cette méthode importe un disque, pas une VM entière : aucune métadonnée
(CPU, RAM, réseau d'origine) n'est reprise depuis l'ESXi. Les mêmes
contraintes de contenu s'appliquent (pas de disque chiffré). Elle convient
bien pour rejouer une migration sur une VM dont les caractéristiques cibles
sont déjà connues et différentes de la source (redimensionnement, firmware
changé de BIOS à UEFI, etc.).

## Suite

- [07-windows-post-migration.md](07-windows-post-migration.md) — finaliser
  une VM Windows migrée.
- [08-linux-post-migration.md](08-linux-post-migration.md) — finaliser une
  VM Linux migrée.
