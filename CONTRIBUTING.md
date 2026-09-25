# Contribuer / Contribuir

*(Français — voir note en bas de page pour l'espagnol)*

Merci de votre intérêt pour ce laboratoire **VMware → Proxmox** publié par
**Intermovil TEC**. Ce dépôt sert avant tout de vitrine et de documentation
d'un laboratoire réel, mais les contributions (corrections, améliorations,
traductions) sont les bienvenues.

## Comment contribuer

1. **Forkez** le dépôt sur votre compte GitHub.
2. Créez une **branche** dédiée à votre changement :
   ```bash
   git checkout -b fix/nom-du-correctif
   ```
3. Faites vos modifications en respectant les [conventions de code](#conventions-de-code)
   ci-dessous.
4. Vérifiez que **ShellCheck** et **PSScriptAnalyzer** passent (voir plus bas).
5. Ouvrez une **pull request** vers la branche `main`, en utilisant le
   gabarit fourni. Décrivez clairement le problème résolu ou la
   fonctionnalité ajoutée.

## Conventions de code

- Les **messages affichés par les scripts** (sorties utilisateur, `echo`,
  invites) sont rédigés **en français**.
- Les **commentaires** dans le code sont **bilingues FR/ES** (une ligne en
  français, suivie de la traduction en espagnol si utile).
- **ShellCheck** et **PSScriptAnalyzer** doivent passer sans erreur avant
  qu'une pull request soit acceptée (le workflow CI les exécute
  automatiquement).
- Ne jamais committer `lab.env`, des mots de passe, clés API ou tout autre
  secret. Utilisez `lab.env.example` comme modèle.
- Respectez la structure existante du dépôt (`scripts/proxmox/`,
  `scripts/esxi/`, `scripts/windows/`, `scripts/linux/`, `docs/fr/`,
  `docs/es/`, `templates/`).

## Lancer ShellCheck localement

Depuis la racine du dépôt (nécessite [ShellCheck](https://www.shellcheck.net/)
installé localement) :

```bash
shellcheck scripts/**/*.sh
```

Sous Bash, activez au besoin le globbing récursif :

```bash
shopt -s globstar
shellcheck scripts/**/*.sh
```

## Lancer PSScriptAnalyzer localement

Depuis PowerShell :

```powershell
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
Invoke-ScriptAnalyzer -Path scripts/windows -Recurse
```

## Licences

- Le code (scripts) est sous licence **MIT** ([`LICENSE`](LICENSE)).
- La documentation (`docs/`, `README.md`, `README.es.md`, `templates/`) est
  sous licence **CC BY 4.0** ([`LICENSE-DOCS.md`](LICENSE-DOCS.md)).

En contribuant à ce dépôt, vous acceptez que vos contributions soient
publiées sous ces mêmes licences.

---

**Nota en español** : las contribuciones (correcciones, mejoras,
traducciones) son bienvenidas. El flujo es el mismo: fork, rama, pull
request. Los mensajes de los scripts se mantienen en francés y los
comentarios en formato bilingüe FR/ES. ShellCheck y PSScriptAnalyzer deben
pasar antes de que una PR sea aceptada.
