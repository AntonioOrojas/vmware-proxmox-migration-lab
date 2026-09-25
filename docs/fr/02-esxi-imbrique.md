# 02 — Construire l'ESXi imbriqué

## Choix techniques

`scripts/proxmox/02-create-nested-esxi.sh` crée la VM qui hébergera ESXi 8
avec les réglages suivants (voir les commentaires du script pour le détail
de chaque choix) :

| Réglage | Valeur | Pourquoi |
|---|---|---|
| `--cpu` | `host` | Expose VT-x/AMD-V à l'intérieur de la VM : indispensable pour qu'ESXi imbriqué puisse lui-même virtualiser. |
| `--machine` | `q35` | Chipset PCIe moderne, requis par ESXi 8. |
| `--bios` | `seabios` | ESXi installateur démarre en BIOS legacy par défaut. |
| Réseau | `vmxnet3` | ESXi 8 n'a plus de pilote `e1000` fiable ; `vmxnet3` est le pilote natif attendu. Utiliser `e1000` fait échouer le réseau. |
| Disque | `sata0` | ESXi n'embarque pas de pilote VirtIO ; SATA (AHCI) est natif et garanti au boot. |
| `--balloon 0` | désactivé | ESXi gère sa propre mémoire ; laisser le ballooning Proxmox actif crée des conflits. |
| `--onboot 0` | désactivé | La VM ESXi ne démarre pas automatiquement avec l'hôte (labo, pas de service). |

Deux interfaces réseau sont créées : `net0` sur `vmbr0` (accès de gestion) et
`net1` sur `vmbr1` (réseau isolé du labo, derrière OPNsense — voir
[00-architecture.md](00-architecture.md)).

```bash
./scripts/proxmox/02-create-nested-esxi.sh
```

## CPU non supporté par ESXi 8

Si le CPU physique de l'hôte est trop ancien pour la liste de compatibilité
officielle d'ESXi 8, ajouter `allowLegacyCPU=true` au démarrage de
l'installeur (touche Shift+O sur l'écran de boot, puis compléter la ligne de
commande du noyau).

## vSwitch : préparer le trafic imbriqué

Une fois ESXi installé, sur `vSwitch0` (ou le vSwitch qui porte le
portgroup des VM de test), activer en mode « Accepter » :

- **Mode promiscuous**
- **Transmissions forgées (forged transmits)**
- **Changements d'adresse MAC (MAC address changes)**

Ces trois réglages sont nécessaires parce que les VM de test à l'intérieur
d'ESXi imbriqué utilisent des adresses MAC différentes de celle de la carte
virtuelle vue par Proxmox — sans eux, leur trafic est filtré silencieusement.

## Installation automatisée (kickstart)

Pour éviter de rejouer l'installation manuelle à chaque fois, `scripts/esxi/ks.cfg`
fournit un fichier kickstart :

- `install --firstdisk --overwritevmfs --systemMediaSize=min` : installation
  sur le premier disque détecté, datastore VMFS minimal pour laisser le
  reste de l'espace à `datastore1`.
- Configuration réseau statique (IP, masque, passerelle, DNS, hostname —
  valeurs alignées sur `lab.env`).
- Activation de SSH dans la section `%firstboot`, pour permettre
  l'automatisation post-installation.

Au boot de l'installeur ESXi, presser Shift+O et ajouter :

```
ks=http://<IP-serveur-HTTP>:8000/ks.cfg
```

en servant `ks.cfg` par un simple serveur HTTP temporaire (par exemple
`python3 -m http.server 8000` depuis le dossier `scripts/esxi/`).

`scripts/esxi/postinstall.sh` complète l'installation après le premier
démarrage : synchronisation NTP, politique de sécurité du vSwitch0 (les
trois réglages ci-dessus appliqués par script plutôt qu'à la main), et
création du portgroup `LAB` sur `vmnic1` (l'interface reliée à `vmbr1`).

## Suite

[03-vms-de-test.md](03-vms-de-test.md) — créer les VM de test à l'intérieur
de cet ESXi imbriqué.
