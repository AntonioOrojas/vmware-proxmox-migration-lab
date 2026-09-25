# Offre de services — Intermovil TEC

Accompagnement à la migration **VMware → Proxmox VE**, pour les collectivités,
administrations, entreprises et MSP francophones (France, Belgique, Suisse, Québec,
Afrique francophone) confrontés à la fin de support de vSphere 8 (11/10/2027) et aux
évolutions de licensing consécutives au rachat de VMware par Broadcom.

L'approche est méthodique et progressive : on ne migre pas un datacenter de production
en une nuit. Chaque étape ci-dessous est conçue pour réduire le risque avant d'aborder
la suivante.

## 1. Diagnostic initial

Audit du parc VMware existant (inventaire des VMs, dépendances, volumétrie de stockage,
réseau, licences en cours), typiquement à partir d'un export RVTools ou équivalent.
Objectif : identifier les VMs éligibles à un import direct (assistant ESXi, OVF, import
de disque), celles qui posent des contraintes particulières (vSAN, disques chiffrés,
vTPM/BitLocker, snapshots), et produire une feuille de route de migration priorisée.

## 2. Preuve de concept (PoC)

Migration pilote sur un périmètre réduit et non critique, dans des conditions proches du
réel, afin de valider la méthode, les scripts et les procédures de restauration réseau
avant tout engagement à plus grande échelle. Le PoC sert de base de référence pour
chiffrer et planifier les vagues suivantes.

## 3. Migration par vagues

Découpage du parc en vagues successives, chacune limitée en nombre de VMs et en durée,
avec validation fonctionnelle après chaque vague avant de passer à la suivante. Cette
approche limite l'exposition au risque et permet d'ajuster la méthode en cours de route.

## 4. Fenêtres de coupure programmées

Les fenêtres de coupure (cutover) sont programmées de nuit, en horaire français, pour
minimiser l'impact sur les utilisateurs. Un point notable de l'organisation
Intermovil TEC : la nuit française correspond à l'après-midi à Lima, au Pérou (UTC-5),
ce qui permet un suivi de l'opération en heures de bureau côté prestataire, sans
astreinte de nuit improvisée — un avantage opérationnel pour la réactivité pendant la
fenêtre de coupure.

## 5. Formation des équipes

Transfert de compétences vers les équipes internes : prise en main de Proxmox VE au
quotidien (gestion des VMs, sauvegardes, mises à jour), procédures post-migration
Windows et Linux (pilotes VirtIO, agents invités), et bonnes pratiques de validation.

## 6. Support post-migration

Accompagnement après bascule pour la stabilisation : suivi des correctifs
post-migration (réseau, pilotes, services), assistance en cas d'anomalie, et
consolidation de la documentation (checklists, rapport de migration) remise au client.

---

**Sur les résultats et références** : les indicateurs de résultat (durées de migration,
taux de réussite, etc.) ne sont pas encore publiés — ce dépôt public sert de
démonstration technique du laboratoire et de la méthode, pas de recueil de cas clients.
Un gabarit de restitution des résultats est prévu dans `results/` (« à mesurer »), sans
métriques, clients ni certifications inventés.

## Contact

[email professionnel]
