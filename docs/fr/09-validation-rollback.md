# 09 — Validation post-migration et rollback

Une migration n'est terminée que lorsqu'elle est validée. Cette page fournit la
checklist de validation et la stratégie de retour arrière à appliquer tant que la
validation n'est pas passée.

## Checklist de validation

| Domaine | Vérification | Windows | Linux |
|---|---|---|---|
| Démarrage | La VM boot sans intervention manuelle (pas d'écran de récupération, pas d'attente BitLocker) | ✅ | ✅ |
| Agent invité | `qemu-ga` actif, Proxmox affiche l'IP dans l'onglet Résumé | `Post-Migration-Validate.ps1` | `systemctl is-active qemu-guest-agent` |
| Réseau | IP, passerelle, DNS conformes à l'export pré-migration ; pas de carte fantôme | `Restore-NetworkConfig.ps1` | `ip a`, comparer à la note pré-migration |
| Stockage | Disque système sur VirtIO SCSI (Windows) ou VirtIO block (Linux), pas de disque factice résiduel | `qm config <vmid> \| grep scsi` | idem |
| Services | Services/démons critiques de l'application démarrés | Gestionnaire de services | `systemctl --failed` |
| Performance | Débit disque cohérent avec la charge attendue (pas de fallback IDE) | `iothread=1` visible en config | idem |
| Application | Test fonctionnel de bout en bout (connexion, transaction type, accès aux données) | Selon l'application | Selon l'application |

Ne considérer une migration comme close que lorsque toutes les lignes sont vertes et
que l'application a été testée par un utilisateur métier ou un test automatisé
équivalent.

## Stratégie de rollback

Le principe : **ne jamais détruire la source avant validation complète.**

1. Ne pas supprimer ni réutiliser le VMID/nom de la VM source sous ESXi tant que la
   VM migrée n'est pas validée.
2. Conserver la VM source **éteinte** (pas besoin de la relancer, juste de ne pas la
   supprimer) pendant toute la période de validation — quelques heures à quelques
   jours selon la criticité.
3. En cas d'échec de validation :
   - Couper la VM migrée sur Proxmox (ne pas la supprimer immédiatement — elle sert de
     matériel de diagnostic).
   - Rallumer la VM source sous ESXi ; elle est restée intacte et redevient le
     système de production.
   - Diagnostiquer l'échec sur la copie Proxmox (voir
     [10-depannage.md](10-depannage.md)) sans pression de remise en production.
4. Une fois la validation définitivement passée (période d'observation écoulée sans
   incident), la VM source ESXi peut être arrêtée définitivement, archivée, puis
   supprimée selon la politique de rétention du client.

## Fenêtre d'observation recommandée

- VM peu critique / test : quelques heures suffisent.
- VM de production : au minimum un cycle métier complet (ex. une journée ouvrée, ou un
  traitement batch nocturne complet) avant de considérer le rollback comme non
  nécessaire.

Voir [11-methodologie-projet.md](11-methodologie-projet.md) pour l'intégration de cette
checklist dans un plan de vagues de migration multi-VM.
