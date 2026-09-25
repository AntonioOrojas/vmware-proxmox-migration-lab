# 11 — Méthodologie projet

Ce laboratoire technique reproduit les étapes d'une migration réelle. Voici la
méthodologie générique appliquée par Intermovil TEC pour un projet client de
migration VMware → Proxmox. Cette page décrit une démarche, pas un historique : aucune
mission, client ou métrique n'y est mentionné (voir `results/` pour les gabarits « à
mesurer » à remplir projet par projet).

## 1. Audit de l'existant (RVTools)

Avant tout chiffrage, un export RVTools de l'environnement vCenter/ESXi source
fournit l'inventaire exhaustif : VM, vCPU/RAM alloués vs consommés, disques et
datastores, snapshots en cours, VM Tools installés, configuration réseau, et
dépendances visibles (dossiers, clusters, tags). Cet inventaire est la base du
gabarit [`inventory/vms.example.csv`](../../inventory/vms.example.csv) et sert à :

- Identifier les VM utilisant des fonctionnalités non supportées par l'import Proxmox
  (vSAN, disques chiffrés — voir [10-depannage.md](10-depannage.md)).
- Estimer le dimensionnement cible (stockage, réseau) sur la base de la consommation
  réelle plutôt que de l'allocation.
- Repérer les VM avec snapshots non consolidés à traiter avant migration.

## 2. Pilote

Sélectionner 1 à 2 VM à faible risque (non critiques, redondantes, ou disposant d'un
environnement de repli simple) pour valider la chaîne complète : export/import,
post-migration (VirtIO, réseau), validation. Le pilote sert à :

- Valider les scripts et procédures sur l'infrastructure réelle du client (pas
  seulement en laboratoire).
- Mesurer une durée de référence par VM (taille de disque, méthode d'import) pour
  affiner le planning des vagues suivantes.
- Détecter les particularités locales (proxy, pare-feu, DNS interne) avant la montée
  en charge.

## 3. Vagues de migration

Regrouper les VM restantes en vagues selon le risque et les dépendances, pas
simplement par ordre alphabétique :

- Grouper les VM applicativement liées dans la même vague (ex. un frontal web et sa
  base de données migrent ensemble) pour limiter les fenêtres où l'application tourne
  à cheval sur deux hyperviseurs.
- Isoler les VM les plus critiques dans une vague tardive, une fois la méthode
  éprouvée sur des vagues précédentes sans incident.
- Dimensionner chaque vague selon la capacité de validation réelle (voir
  [09-validation-rollback.md](09-validation-rollback.md)) : ne pas migrer plus de VM
  que ce que l'équipe peut valider sérieusement dans la fenêtre disponible.

## 4. Cutover

Chaque vague suit une fenêtre de bascule planifiée :

- Communication préalable aux utilisateurs/métiers concernés (date, durée
  d'indisponibilité attendue).
- Bascule technique : arrêt côté source, migration, post-migration, validation (voir
  doc 09), puis remise en service.
- Fenêtre de rollback tenue ouverte (VM source intacte, éteinte) jusqu'à la fin de la
  période d'observation.

## 5. MCO (maintien en condition opérationnelle)

Une fois la migration terminée, la mission ne s'arrête pas à la bascule :

- Surveillance des VM migrées sur une période définie contractuellement.
- Ajustements de dimensionnement (CPU/RAM/stockage) à partir des métriques réelles
  observées sur Proxmox.
- Formation des équipes internes du client à l'administration Proxmox VE
  (interface, sauvegardes, snapshots, mise à jour).
- Documentation de sortie : inventaire final, procédures spécifiques à
  l'environnement du client, contacts de support.

Voir [SERVICIOS.md](../../SERVICIOS.md) / `OFFRE.md` pour le détail de l'offre
commerciale associée à cette méthodologie.
