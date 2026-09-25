# 12 — Souveraineté numérique : le contexte

Ce laboratoire n'est pas un exercice académique isolé : il répond à un mouvement de
fond observable depuis le rachat de VMware par Broadcom.

## Le déclencheur : Broadcom et VMware

Depuis l'acquisition de VMware par Broadcom, les changements de politique de
licensing (fin des licences perpétuelles, bundling forcé en suites, hausses de prix
rapportées par de nombreux clients et intégrateurs) poussent un grand nombre
d'organisations — administrations et collectivités françaises, entreprises, MSP, et
plus largement l'écosystème francophone (Belgique, Suisse, Québec, Afrique
francophone) — à réévaluer leur dépendance à VMware.

## Un geste symbolique, pas une solution : ESXi gratuit à nouveau

Depuis avril 2025, Broadcom a de nouveau rendu ESXi 8.0U3e disponible gratuitement.
Dans ce laboratoire, cette version est utilisée en **mode évaluation (60 jours)** —
un choix pragmatique pour construire et tester l'environnement de démonstration, pas
une voie de licensing de production. La gratuité d'ESXi seul ne résout pas la
dépendance à l'écosystème vSphere/vCenter pour un usage professionnel : elle sert ici
uniquement de socle imbriqué pour rejouer des migrations réalistes.

## L'échéance : fin de support vSphere 8

Le support général de vSphere 8 se termine le **11 octobre 2027**. Passé cette date,
les environnements restés sur cette version cessent de recevoir des correctifs de
sécurité standards, ce qui transforme une question de stratégie en une échéance
opérationnelle concrète pour toute organisation encore sur VMware.

## Un point de contexte francophone concret : CoTer Numérique 2026

**CoTer Numérique 2026** (Reims, 23-24 juin 2026) est un événement où les
collectivités locales françaises échangent sur leurs projets numériques, dont la
migration d'infrastructures suite à la fin de support annoncée de vSphere 8. C'est un
exemple concret de la dynamique en cours dans le secteur public territorial
francophone, pas une affirmation de participation ou de partenariat de la part
d'Intermovil TEC.

## L'alternative alignée souveraineté : Proxmox VE

Proxmox VE est développé par **Proxmox Server Solutions GmbH**, société basée à
**Vienne (Autriche, Union européenne)**. Le logiciel est distribué sous licence
**AGPLv3**, une licence libre garantissant :

- L'auditabilité complète du code source (pas de boîte noire).
- L'absence de dépendance à un éditeur unique pour le support (tout intégrateur peut
  intervenir sur du logiciel libre).
- Un hébergement de l'éditeur dans l'UE, pertinent pour les critères de souveraineté
  numérique appliqués par certaines administrations et certains secteurs régulés.

## Ce que cette page ne prétend pas

Aucune métrique de migration, aucun client, aucune certification ne sont avancés ici.
Ce document expose le contexte factuel qui motive le projet ; les résultats concrets
de missions clientes sont documentés au cas par cas dans `results/`, jamais généralisés
ici.
