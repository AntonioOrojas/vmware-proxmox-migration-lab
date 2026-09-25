# 07 — Post-migration Windows

Une VM Windows importée depuis VMware démarre presque toujours dès l'import (disque
présenté en SATA/IDE émulé), mais elle tourne en émulation complète tant que les
pilotes VirtIO ne sont pas installés et que le contrôleur disque n'est pas basculé en
VirtIO SCSI. Cette page décrit la séquence complète, dans l'ordre.

## Ordre des opérations

| # | Action | Où |
|---|--------|----|
| 1 | `Pre-Migration-Check.ps1` — export JSON de l'état réseau, disques, BitLocker, services, firmware | Dans la VM, **avant** l'arrêt pour migration |
| 2 | `Remove-VMwareTools.ps1` | Dans la VM, **avant** l'arrêt pour migration |
| 3 | Suspendre/déchiffrer BitLocker si actif | Dans la VM, **avant** l'arrêt pour migration |
| 4 | Import de la VM (voir [04](04-migration-assistant.md), [05](05-migration-ovf.md), [06](06-migration-disk-import.md)) | Hôte Proxmox |
| 5 | `05-windows-virtio.sh <vmid> to-sata` | Hôte Proxmox |
| 6 | Démarrage Windows, installation `virtio-win-guest-tools.exe` (ou `Install-VirtIO.ps1`) | Dans la VM |
| 7 | `05-windows-virtio.sh <vmid> prepare` | Hôte Proxmox |
| 8 | Démarrage Windows, vérifier « Red Hat VirtIO SCSI controller » dans le Gestionnaire de périphériques, arrêt | Dans la VM |
| 9 | `05-windows-virtio.sh <vmid> finalize` | Hôte Proxmox |
| 10 | Démarrage Windows, `Restore-NetworkConfig.ps1`, `Post-Migration-Validate.ps1` | Dans la VM |

## Pourquoi ne pas quitter VMware Tools après migration

VMware Tools ne peut pas être désinstallé proprement une fois la VM sortie de VMware
(le service de désinstallation dépend de l'hyperviseur d'origine). `Remove-VMwareTools.ps1`
doit donc tourner **avant** l'arrêt qui précède l'export/import, pendant que la VM est
encore sous ESXi.

## BitLocker et vTPM

Le vTPM VMware ne migre pas vers Proxmox : aucun équivalent n'est transféré lors de
l'import. Si un volume est protégé par BitLocker lié au TPM, la VM migrée demandera la
clé de récupération (ou refusera de démarrer) au premier boot. `Pre-Migration-Check.ps1`
détecte l'état BitLocker ; si actif, suspendre la protection (`Suspend-BitLocker`) ou la
désactiver complètement avant l'arrêt de pré-migration.

## La bascule VirtIO SCSI en 3 phases (`05-windows-virtio.sh`)

Windows ne peut pas démarrer directement sur un contrôleur SCSI qu'il ne reconnaît pas :
au premier boot après import il n'a pas le pilote `vioscsi`. Le script gère donc trois
phases distinctes, à exécuter dans l'ordre exact ci-dessous :

```bash
./05-windows-virtio.sh <vmid> to-sata    # 1. tous les disques passent en SATA (boot garanti)
./05-windows-virtio.sh <vmid> prepare    # 2. ajoute un disque factice scsi30 -> Windows charge vioscsi
./05-windows-virtio.sh <vmid> finalize   # 3. déplace les disques SATA vers SCSI, retire le disque factice
```

- **to-sata** : rattache tous les disques (scsi/virtio/ide détectés) sur bus SATA avec
  `discard=on,ssd=1`, ajuste l'ordre de boot. Windows démarre normalement puisque SATA
  est nativement supporté.
- **prepare** : ajoute un disque factice de 1 Go sur `scsi30` avec `scsihw=virtio-scsi-single`.
  Au boot suivant, Windows détecte le contrôleur VirtIO SCSI et charge (ou installe, si
  `virtio-win-guest-tools.exe` a déjà tourné) le pilote `vioscsi`. Vérifier dans le
  Gestionnaire de périphériques que « Red Hat VirtIO SCSI controller » apparaît sans
  point d'exclamation avant de couper la VM.
- **finalize** : déplace les disques réels de SATA vers `scsi` (`discard=on,ssd=1,iothread=1`),
  supprime le disque factice `scsi30`, remet l'ordre de boot sur le nouveau slot.

Entre les phases 1 et 2, il faut démarrer Windows et installer les pilotes VirtIO
(`virtio-win-guest-tools.exe`, présent à la racine de l'ISO `virtio-win`, ou via
`Install-VirtIO.ps1` qui l'exécute en mode silencieux et installe aussi `qemu-ga`).

## Réseau : cartes fantômes et reconfiguration

Le passage de l'adaptateur réseau VMware (vmxnet3/e1000) à VirtIO change l'identité de
l'interface. Windows conserve l'ancienne carte comme périphérique fantôme (non présent
mais toujours listé). `Restore-NetworkConfig.ps1` :

1. Supprime les cartes fantômes via `pnputil` (`pnputil /remove-device` sur les
   périphériques réseau non présents).
2. Réapplique la configuration réseau exportée par `Pre-Migration-Check.ps1`
   (IP statique, DNS, routes) sur la nouvelle carte VirtIO.

## Validation finale

`Post-Migration-Validate.ps1` vérifie : démarrage propre, service `qemu-ga` actif,
connectivité réseau restaurée, services critiques démarrés, absence d'alerte BitLocker.
Voir aussi [09-validation-rollback.md](09-validation-rollback.md).
