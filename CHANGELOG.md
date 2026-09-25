# Changelog

Tous les changements notables de ce projet sont documentés dans ce fichier.

Le format s'inspire de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet vise à respecter le [Semantic Versioning](https://semver.org/lang/fr/)
une fois une première version publique stabilisée.

## [Non publié] - 2026-09-25

### Ajouté

- Structure initiale publique du dépôt **vmware-proxmox-migration-lab**.
- Scripts Proxmox pour la préparation de l'hôte, l'activation de la
  virtualisation imbriquée, la création d'un ESXi imbriqué, l'ajout de
  stockage ESXi, l'import de VM, la préparation VirtIO pour Windows, l'import
  OVF et l'import de disque (`scripts/proxmox/`).
- Scripts pour l'ESXi imbriqué (kickstart et post-installation)
  (`scripts/esxi/`).
- Scripts Windows PowerShell de pré-migration, retrait de VMware Tools,
  installation VirtIO, restauration de la configuration réseau et validation
  post-migration (`scripts/windows/`).
- Scripts Linux de préparation VirtIO / initramfs pour la post-migration
  (`scripts/linux/`).
- Documentation pas-à-pas bilingue français/espagnol (`docs/fr/`, `docs/es/`).
- Gabarits de migration (checklist, rapport, plan de vagues) et modèle
  d'inventaire de VM (`templates/`, `inventory/`).
- Pages de présentation `README.md` (français) et `README.es.md` (español),
  ainsi que la présentation de l'offre de services (`OFFRE.md` /
  `SERVICIOS.md`).
- Intégration continue GitHub Actions (ShellCheck, PSScriptAnalyzer,
  vérification des liens Markdown), gabarits d'issue et de pull request.
- Licences : code sous MIT (`LICENSE`), documentation sous CC BY 4.0
  (`LICENSE-DOCS.md`).
