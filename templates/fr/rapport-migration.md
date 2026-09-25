# Rapport de migration VMware → Proxmox

## 1. Identification

| Champ | Valeur |
|---|---|
| Nom de la VM | `<à compléter>` |
| ID VM Proxmox (vmid) | `<à compléter>` |
| Datastore source (VMware) | `<à compléter>` |
| Stockage cible (Proxmox) | `<à compléter>` |
| Système d'exploitation | `<à compléter>` |
| Criticité métier | `<faible / moyenne / haute>` |
| Client / environnement | `<à compléter>` |
| Référent métier | `<à compléter>` |
| Opérateur(s) de la migration | `<à compléter>` |
| Date de la migration | `<jj/mm/aaaa>` |

## 2. Caractéristiques de la VM

| Caractéristique | Avant (VMware) | Après (Proxmox) |
|---|---|---|
| vCPU | `<à compléter>` | `<à compléter>` |
| RAM | `<à compléter>` | `<à compléter>` |
| Disque(s) | `<à compléter>` | `<à compléter>` |
| Carte(s) réseau | `<à compléter>` | `<à compléter>` |
| BIOS / UEFI | `<à compléter>` | `<à compléter>` |
| vTPM | `<oui / non>` | `<oui / non — non supporté par l'import>` |

## 3. Méthode utilisée

- [ ] Assistant d'import ESXi (`pvesm add esxi` + `qm import`)
- [ ] Import OVF (`qm importovf`)
- [ ] Disk import (`qm disk import`)

**Détail / commandes exécutées :**

```
<à compléter>
```

**Justification du choix de méthode :** `<à compléter>`

## 4. Durée

| Étape | Début | Fin | Durée |
|---|---|---|---|
| Préparation (arrêt VM source, vérifications) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Transfert / import des disques | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Configuration post-import (matériel, réseau) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| Post-migration (pilotes, validation) | `<hh:mm>` | `<hh:mm>` | `<hh:mm>` |
| **Durée totale** | | | `<hh:mm>` |

## 5. Incidents rencontrés

| # | Description de l'incident | Impact | Résolution | Durée d'impact |
|---|---|---|---|---|
| 1 | `<à compléter>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| 2 | `<à compléter>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |

*(Ajouter des lignes si nécessaire. Indiquer « Aucun incident » si applicable.)*

## 6. Résultats de la validation post-migration

| Point de contrôle | Résultat | Commentaire |
|---|---|---|
| Démarrage de la VM sans erreur | `<OK / KO>` | `<à compléter>` |
| Connectivité réseau (IP, DNS, passerelle) | `<OK / KO>` | `<à compléter>` |
| QEMU Guest Agent opérationnel | `<OK / KO>` | `<à compléter>` |
| Pilotes VirtIO installés (stockage/réseau) | `<OK / KO>` | `<à compléter>` |
| Cartes réseau fantômes nettoyées (Windows) | `<OK / KO / non applicable>` | `<à compléter>` |
| Renommage d'interface pris en compte (Linux) | `<OK / KO / non applicable>` | `<à compléter>` |
| Services / applicatifs fonctionnels | `<OK / KO>` | `<à compléter>` |
| Validation fonctionnelle par le référent métier | `<OK / KO>` | `<à compléter>` |
| Sauvegarde Proxmox planifiée | `<OK / KO>` | `<à compléter>` |

## 7. Plan de rollback appliqué

- [ ] Rollback non nécessaire
- [ ] Rollback partiel : `<à compléter>`
- [ ] Rollback complet : `<à compléter>`

**Détail :** `<à compléter>`

## 8. Recommandations / suites à donner

`<à compléter>`

## 9. Signature

| Rôle | Nom | Date | Signature |
|---|---|---|---|
| Opérateur technique | `<à compléter>` | `<jj/mm/aaaa>` | `<à compléter>` |
| Référent métier / client | `<à compléter>` | `<jj/mm/aaaa>` | `<à compléter>` |

---
*Gabarit fourni par Intermovil TEC. Ce document ne doit contenir aucune donnée réelle avant d'être partagé publiquement.*
