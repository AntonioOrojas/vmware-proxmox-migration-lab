# 03 — VM de test à l'intérieur de l'ESXi imbriqué

## Budget d'espace

L'ESXi imbriqué dispose d'un disque unique de 200 Go thin-provisionné
(`ESXI_DISK_GB` dans `lab.env`). ESXi lui-même occupe une fraction minime de
ce disque (le kickstart utilise `--systemMediaSize=min`), le reste forme
`datastore1`. Pour trois VM de test cohabitant confortablement :

| VM | Rôle | Disque suggéré | RAM suggérée |
|---|---|---|---|
| Windows Server 2019 (BIOS) | Migration Windows sur firmware legacy | 40 Go thin | 4 Go |
| Windows Server 2022 ou 2025 (UEFI) | Migration Windows sur firmware moderne, avec ou sans vTPM/BitLocker | 40 Go thin | 4 Go |
| Debian 12 ou 13 | Migration Linux, préparation VirtIO/initramfs | 20 Go thin | 2 Go |

Le thin-provisioning permet à ces trois VM de coexister sur les 200 Go même
si leur somme nominale (100 Go) semble juste — l'espace réellement utilisé
est bien inférieur pour des installations fraîches.

## Windows Server 2019 — BIOS legacy

Choisir le firmware BIOS (pas UEFI) pour représenter le cas le plus courant
de VM Windows héritées à migrer : disque contrôleur LSI Logic SAS ou
paravirtuel selon les pilotes disponibles à l'installation, réseau
`vmxnet3`. C'est le scénario où
[05-windows-virtio.sh](../../scripts/proxmox/05-windows-virtio.sh) et sa
bascule SATA → VirtIO en trois phases sont le plus directement pertinents.

## Windows Server 2022 ou 2025 — UEFI

Choisir le firmware EFI. Ce scénario permet de tester en particulier le cas
du vTPM : si BitLocker est activé sur cette VM, il faudra le suspendre ou le
déchiffrer avant la migration (le vTPM ne migre pas — voir
[04-migration-assistant.md](04-migration-assistant.md)).

## Debian 12/13

Sert à valider le chemin Linux : remplacement d'`open-vm-tools` par
`qemu-guest-agent`, régénération de l'initramfs pour charger les modules
VirtIO, et le changement de nom d'interface réseau (`ens192` sous VMware
devient typiquement `ens18` sous Proxmox) — voir
[08-linux-post-migration.md](08-linux-post-migration.md).

## Suite

[04-migration-assistant.md](04-migration-assistant.md) — migrer ces VM avec
l'assistant d'import ESXi de Proxmox.
