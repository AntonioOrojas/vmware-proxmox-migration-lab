# 04 — Migration avec l'assistant d'import ESXi

## Prérequis

- Proxmox VE 8.2 ou supérieur, avec le paquet `pve-esxi-import-tools`
  (vérifié par [00-check-host.sh](../../scripts/proxmox/00-check-host.sh)).
- La VM source doit être **éteinte**.
- Avant de migrer une VM Windows : **désinstaller VMware Tools depuis
  l'intérieur de la VM, avant la migration.** VMware Tools ne se désinstalle
  pas proprement une fois la VM sortie de VMware ; le faire après laisse des
  pilotes et services fantômes.

## Étape 1 : déclarer l'ESXi comme stockage d'import

```bash
./scripts/proxmox/03-add-esxi-storage.sh
```

Équivalent à :

```bash
pvesm add esxi <id> --server <ip-esxi> --username root --password *** --skip-cert-verification 1
```

Le script lit `ESXI_STORAGE_ID`, `ESXI_IP`, `ESXI_USER` depuis `lab.env`,
demande le mot de passe de façon interactive s'il n'est pas déjà défini
(il n'est jamais stocké en clair dans le dépôt), et liste ensuite les `.vmx`
visibles sur l'ESXi pour confirmer que la connexion fonctionne.

## Étape 2 : importer la VM

```bash
./scripts/proxmox/04-import-vm.sh <nom-vm-esxi> [vmid] [windows|linux]
```

Équivalent à :

```bash
qm import <vmid> <storage>:ha-datacenter/<datastore>/<vm>/<vm>.vmx --storage <dst>
```

Le script retrouve automatiquement le chemin `.vmx` correspondant au nom de
VM donné, exécute l'import, puis applique des réglages communs : agent
QEMU activé, type de CPU `x86-64-v2-AES`, contrôleur `virtio-scsi-single`,
et remplacement des interfaces réseau `vmxnet3` par `virtio` sur `vmbr1`
(réseau du labo). Si `windows` est passé en troisième argument, il bascule
aussi le disque système sur SATA pour le premier démarrage (voir
[05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh) — la VM
Windows fraîchement importée n'a pas encore de pilote `vioscsi` chargé, un
attachement direct en SCSI virtio l'empêcherait de démarrer) et monte l'ISO
VirtIO en lecteur CD. Chaque import est tracé dans `results/imports.csv`
(nom source, VMID, famille d'OS, durée).

## Limites de l'assistant d'import

- **Pas de vSAN** : les datastores vSAN ne sont pas supportés en source.
- **Pas de disques chiffrés** (VM Encryption côté vSphere).
- **Snapshots** : une VM avec des snapshots s'importe, mais nettement plus
  lentement (l'import doit consolider la chaîne).
- **Datastores avec un `+` dans leur nom** : l'import échoue. Renommer le
  datastore côté ESXi avant de migrer les VM qu'il contient.

## vTPM et BitLocker

Le vTPM ne migre pas vers Proxmox. Si BitLocker est actif sur la VM
Windows à migrer, il faut le **suspendre ou le déchiffrer avant** la
migration — sans quoi le volume système sera illisible au redémarrage
(le TPM qui détenait la clé de scellement n'existe plus).

## Suite

- [05-migration-ovf.md](05-migration-ovf.md) — méthode alternative si l'API
  ESXi n'est pas joignable.
- [07-windows-post-migration.md](07-windows-post-migration.md) — après
  l'import d'une VM Windows.
