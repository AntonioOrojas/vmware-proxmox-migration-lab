# Plan de vagues de migration VMware → Proxmox

> Modèle Intermovil TEC. À adapter par projet. Ce gabarit ne contient aucune donnée réelle — remplacer tous les champs `<à compléter>` avant utilisation.

## Logique de séquencement

1. **Vague pilote** : 1 à 2 VM non critiques, représentatives de l'environnement.
   Objectif : valider la méthode d'import, les scripts et le processus de bout en bout.
2. **Vagues à faible risque** : VM secondaires, peu de dépendances, tolérance de panne
   élevée. Objectif : monter en cadence et fiabiliser le processus.
3. **Vagues critiques** : VM de production à fortes dépendances, migrées en dernier,
   une fois la méthode validée sur les vagues précédentes.

Chaque vague est suivie d'une fenêtre de stabilisation avant le lancement de la suivante.
Utiliser `inventory/vms.example.csv` (adapté avec l'inventaire réel) pour répartir les VM
entre vagues selon leur criticité et leurs dépendances.

## Rappel important sur les fenêtres horaires

La fenêtre de coupure est généralement planifiée **de nuit, en heure française (Europe/Paris)**,
pour limiter l'impact sur les utilisateurs métier. Pour les intervenants basés à **Lima, Pérou (UTC-5)**,
cela correspond à **l'après-midi / début de soirée locale** (écart de 6 à 7 heures selon l'heure d'été/hiver en France).
Toujours confirmer l'heure exacte dans les deux fuseaux avant chaque vague, et l'indiquer explicitement
dans la convocation envoyée aux équipes.

| Fuseau | Exemple de correspondance (à titre indicatif, à vérifier selon la période) |
|---|---|
| Europe/Paris (nuit, ex. 22h00–02h00) | Lima, Pérou UTC-5 (après-midi, ex. 15h00–19h00 / 16h00–20h00) |

## Tableau des vagues

| Vague | VM | Date / heure de coupure (Paris) | Date / heure équivalente (Lima, UTC-5) | Fenêtre de maintenance | Déclencheur de rollback | Responsable |
|---|---|---|---|---|---|---|
| 1 | `<à compléter>` | `<jj/mm/aaaa hh:mm>` | `<jj/mm/aaaa hh:mm>` | `<ex. 22h00–02h00 Paris>` | `<ex. indisponibilité applicative > 30 min>` | `<à compléter>` |
| 1 | `<à compléter>` | `<jj/mm/aaaa hh:mm>` | `<jj/mm/aaaa hh:mm>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| 2 | `<à compléter>` | `<jj/mm/aaaa hh:mm>` | `<jj/mm/aaaa hh:mm>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| 2 | `<à compléter>` | `<jj/mm/aaaa hh:mm>` | `<jj/mm/aaaa hh:mm>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| 3 | `<à compléter>` | `<jj/mm/aaaa hh:mm>` | `<jj/mm/aaaa hh:mm>` | `<à compléter>` | `<à compléter>` | `<à compléter>` |

*(Ajouter des lignes / vagues selon le périmètre du projet.)*

## Critères de constitution des vagues

- [ ] Vague pilote : VM(s) non critiques, faible dépendance, pour valider la méthode
- [ ] Vagues suivantes : regroupement par criticité croissante et/ou par dépendances applicatives
- [ ] Dernière vague : VM(s) critiques, uniquement après succès validé des vagues précédentes

## Rôles et responsabilités

| Rôle | Nom | Contact | Disponibilité pendant la fenêtre |
|---|---|---|---|
| Chef de projet migration | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| Opérateur technique Proxmox | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| Référent métier / validateur | `<à compléter>` | `<à compléter>` | `<à compléter>` |
| Astreinte réseau / infrastructure | `<à compléter>` | `<à compléter>` | `<à compléter>` |

## Critères de déclenchement du rollback (généraux)

- [ ] Échec de démarrage de la VM après migration
- [ ] Perte de connectivité réseau non résolue dans le délai fixé : `<à compléter>`
- [ ] Indisponibilité applicative critique constatée par le référent métier
- [ ] Corruption ou perte de données constatée
- [ ] Autre critère spécifique au projet : `<à compléter>`

## Suivi post-vague

| Vague | Statut | Date de clôture | Commentaire |
|---|---|---|---|
| 1 | `<en cours / terminée / rollback>` | `<jj/mm/aaaa>` | `<à compléter>` |
| 2 | `<en cours / terminée / rollback>` | `<jj/mm/aaaa>` | `<à compléter>` |
| 3 | `<en cours / terminée / rollback>` | `<jj/mm/aaaa>` | `<à compléter>` |

---
*Gabarit fourni par Intermovil TEC. Aucune donnée client réelle ne doit apparaître dans ce document avant diffusion publique.*
