# 05 — Migration par export OVF

## Quand utiliser cette méthode

L'assistant d'import ([04-migration-assistant.md](04-migration-assistant.md))
nécessite que Proxmox atteigne directement l'API HTTPS de l'ESXi. Quand ce
n'est pas le cas (segmentation réseau, ESXi non joignable depuis l'hôte
Proxmox), ou pour conserver une archive portable de la VM avant migration,
l'export OVF est l'alternative : on exporte la VM en fichiers OVF/VMDK
depuis l'ESXi, puis on les importe dans Proxmox.

## Prérequis

- `ovftool` installé sur l'hôte Proxmox (télécharger « VMware OVF Tool
  Linux 64-bit » depuis le portail Broadcom — ce n'est pas empaqueté par
  Proxmox).
- La VM source doit être éteinte.
- Espace disque suffisant dans le dossier d'export (par défaut
  `/var/lib/vz/ovf-export`) : compter la taille des disques de la VM.

## Utilisation

```bash
./scripts/proxmox/06-ovf-import.sh <nom-vm-esxi> <vmid> [dossier-export]
```

Le script :

1. Exporte la VM avec `ovftool --noSSLVerify vi://<user>@<ip-esxi>/<nom-vm>`.
2. Calcule un `sha256sum` de tous les fichiers exportés, pour vérifier
   l'intégrité du transfert.
3. Importe avec `qm importovf <vmid> <fichier.ovf> <storage>`.
4. Applique les mêmes réglages réseau/CPU/contrôleur que l'import direct
   (`virtio` sur `vmbr1`, `x86-64-v2-AES`, `virtio-scsi-single`, agent QEMU).

Pour une VM Windows, poursuivre ensuite avec la bascule VirtIO :

```bash
./scripts/proxmox/05-windows-virtio.sh <vmid> to-sata
```

(voir [07-windows-post-migration.md](07-windows-post-migration.md) pour la
suite complète).

## Limites propres à cette méthode

Les mêmes limites que l'import direct s'appliquent au contenu de l'OVF
(pas de vSAN comme source, pas de disques chiffrés). L'export OVF ajoute
son propre coût : temps d'export proportionnel à la taille des disques, et
espace disque temporaire doublé le temps de la conversion (fichiers
source sur l'ESXi ou en transit, plus la copie locale avant import).

## Suite

[06-migration-disk-import.md](06-migration-disk-import.md) — import direct
d'un fichier `.vmdk` sans passer par un export OVF complet.
