# 08 — Post-migration Linux (Debian)

Une VM Linux migrée démarre généralement sans problème (le noyau Linux gère les
contrôleurs disques génériquement), mais deux points bloquent une intégration propre :
l'initramfs ne contient pas toujours les modules VirtIO nécessaires au démarrage, et
`open-vm-tools` reste actif alors qu'il ne sert plus à rien sous Proxmox.

## Séquence recommandée

1. **Avant la migration**, dans la VM sous ESXi : noter la configuration réseau
   (`ip a`, `/etc/network/interfaces` ou fichiers netplan), désinstaller
   `open-vm-tools` n'est pas obligatoire à ce stade mais peut être fait ici.
2. **Après import**, si le disque ne boot pas ou reste en initramfs busybox :
   utiliser `scripts/linux/prep-virtio-initramfs.sh` en chroot depuis un live CD/ISO
   Debian, ou directement dans la VM si elle a réussi à démarrer une première fois sur
   un bus compatible (SATA/IDE) avant de basculer en VirtIO.
3. Installer `qemu-guest-agent`, désinstaller `open-vm-tools`.
4. Reconstruire l'initramfs (`update-initramfs -u` sur Debian/Ubuntu, `dracut -f` sur
   RHEL/Fedora-likes) pour embarquer les modules `virtio_blk`, `virtio_scsi`,
   `virtio_net`.
5. Corriger la configuration réseau si l'interface a été renommée (voir ci-dessous).
6. Redémarrer sur le bus VirtIO définitif.

## `scripts/linux/prep-virtio-initramfs.sh`

Script prévu pour automatiser cette préparation : détecte la distribution
(Debian/Ubuntu vs RHEL-like), régénère l'initramfs avec les modules VirtIO
(`dracut --add-drivers "virtio_blk virtio_scsi virtio_net"` ou
`update-initramfs -u -k all`), désinstalle `open-vm-tools`, installe et active
`qemu-guest-agent`, et affiche un avertissement sur le renommage d'interface
`ens192` → `ens18`.

## `open-vm-tools` → `qemu-guest-agent`

```bash
apt purge -y open-vm-tools open-vm-tools-desktop
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

Sans `qemu-guest-agent`, Proxmox ne peut pas obtenir l'IP de la VM dans son
interface, ni déclencher un arrêt propre (`qm shutdown`) sans passer par ACPI pur.

## Piège du renommage d'interface : `ens192` → `ens18`

Les noms d'interfaces réseau « predictable » (systemd) sont dérivés du bus et de
l'emplacement PCI du périphérique. Sous VMware, la carte vmxnet3 est typiquement vue
comme `ens192` ; sous QEMU/Proxmox (VirtIO), le même slot logique donne généralement
`ens18`. Conséquence : la configuration réseau statique référencée par l'ancien nom
d'interface ne s'applique plus après migration, et la VM peut perdre sa connectivité
au boot.

À vérifier/corriger après migration :

- `/etc/network/interfaces` (Debian classique) : remplacer `ens192` par `ens18` (ou le
  nom réel constaté avec `ip a`).
- Netplan (`/etc/netplan/*.yaml`) : idem sur la clé de l'interface, ou utiliser un
  matcher par MAC plutôt que par nom si le renommage se reproduit.
- `/etc/udev/rules.d/70-persistent-net.rules` si présent (anciens systèmes) : peut
  figer un nom qui n'existe plus.

## Vérification finale

```bash
lsinitramfs /boot/initrd.img-$(uname -r) | grep -E 'virtio_(blk|scsi|net)'
systemctl is-active qemu-guest-agent
ip a   # confirmer le nom d'interface réel et la présence de l'IP attendue
```

Voir [09-validation-rollback.md](09-validation-rollback.md) pour la checklist de
validation complète et [10-depannage.md](10-depannage.md) pour les pannes fréquentes.
