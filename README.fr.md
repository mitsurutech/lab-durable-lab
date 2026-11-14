# Laboratoire d'exécution durable avec Docker Compose : un moteur de workflow, un journal d'étapes dans PostgreSQL, le rejeu, les clés d'idempotence et les sagas

[English](README.md) | [Français](README.fr.md) | [Español](README.es.md) | [日本語](README.ja.md) | [Deutsch](README.de.md)

[![check](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-durable-lab/actions/workflows/check.yml)

Un laboratoire prêt à l'emploi pour la classe, proposé par la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning), où écoles, lycées, établissements supérieurs et universités donnent à chaque étudiant ses propres bases de données, conteneurs et terminal dans le navigateur. Il enseigne l'exécution durable (*durable execution*) en partant de zéro : comment un traitement long ou un workflow survit à un plantage. Un moteur de workflow d'une centaine de lignes de Python inscrit chaque étape terminée dans une table de journal PostgreSQL, et une relance après un plantage rejoue ces lignes puis continue. Les étudiants font planter des workflows exprès et les reprennent : un traitement naïf qui débite une carte deux fois, une commande qui rejoue son journal, un débit protégé par une clé d'idempotence, des nouvelles tentatives avec attente exponentielle et gigue, un minuteur durable et un voyage réservé sous forme de saga. Aucun moteur commercial (Temporal, Restate, DBOS ou les fonctions durables d'AWS Lambda) n'y tourne : le labo montre l'idée qu'ils partagent. C'est le labo du module [Durable execution](https://mitsurutech.co.uk/resources/university/durable-execution).

Il tient dans un seul fichier `docker-compose`, `compose.yaml`, et fonctionne de la même façon sur votre machine que sur la plateforme, où chaque étudiant dispose d'une copie privée sans aucun accès à internet.

## Utilisation sur la plateforme

La plateforme donne à chaque étudiant sa propre copie d'un labo, dans le navigateur, avec un terminal à côté.

**Pour l'essayer :** ouvrez la [page des conteneurs](https://mitsurutech.co.uk/container), trouvez ce labo dans **Sample labs** et appuyez sur Start. Un compte gratuit est nécessaire.

**Pour le donner comme travail à une classe :**

1. Dans votre module, créez une tâche de type **Lab** et choisissez **In a GitHub repository**.
2. Indiquez `https://github.com/mitsurutech/lab-durable-lab` avec la branche `main`. Le fichier compose par défaut est `compose.yaml`. Faites d'abord un fork du dépôt si vous voulez le modifier.
3. Publiez. La copie de chaque étudiant part du commit publié : une modification ultérieure ici ne change pas un labo déjà donné.

La [page de ce labo](https://mitsurutech.co.uk/help/lab-durable-lab) dans le manuel et son [guide des labos en conteneur](https://mitsurutech.co.uk/help/labs) expliquent le reste. La leçon de base associée s'appelle **Durable Execution Basics**. Pas encore de compte d'établissement ? [La première année est gratuite](https://mitsurutech.co.uk/pricing) jusqu'à 50 étudiants, et [l'inscription](https://mitsurutech.co.uk/signup) ne demande qu'une adresse e-mail.

## Ce qu'il contient

Deux services. `db` est PostgreSQL : il garde le journal et les tables où écrivent les workflows. `worker` est Python, avec ces fichiers dans `/tmp`, tous écrits par le fichier compose au démarrage :

| Fichier | Ce que c'est |
|---|---|
| `pg.py` | Un tout petit client PostgreSQL écrit pour le labo, car aucune image Python standard ne contient de pilote de base de données |
| `engine.py` | Le moteur : une étape s'exécute une fois, son résultat va dans le journal, une relance le rejoue |
| `shop.py` | Le monde extérieur : stock, prestataire de paiement, e-mail, transporteur et réservations, chacun écrit une ligne |
| `naive.py` | La commande sans journal, pour voir ce qu'une simple relance répète |
| `order.py` | La commande en workflow durable, avec `--crash-after`, `--crash-inside`, `--keyed` et `--v2` |
| `retry.py` | L'attente exponentielle avec plafond et gigue tirée d'une graine fixe |
| `remind.py` | Un minuteur durable sur une horloge que vous donnez avec `--now` |
| `saga.py` | Un voyage réservé en saga, compensé du plus récent au plus ancien |

## Le lancer sur votre machine

Il vous faut Docker avec le plugin Compose.

```bash
docker compose up -d --wait
docker compose exec worker python3 order.py order-7 --fresh --crash-after 2
docker compose exec worker python3 order.py order-7
docker compose exec db psql -U durable -c "SELECT workflow, seq, step, result FROM journal"
```

La première commande exécute deux étapes puis s'arrête sur un plantage voulu. La deuxième rejoue ces deux étapes depuis le journal et exécute les deux autres. Chaque exécution affiche toujours la même chose : rien ne lit l'horloge et le seul tirage aléatoire a une graine fixe. Le labo ne publie aucun port. La base ne demande pas de mot de passe, car rien hors du labo ne peut l'atteindre : ne faites jamais tourner PostgreSQL ainsi ailleurs. Supprimez-le avec `docker compose down -v`.

## Ce qui ne marche pas dans un labo

Le labo n'a aucun accès à internet : rien ne peut y être installé ni téléchargé. **Rien n'est conservé** : arrêter le labo efface le journal et tous les fichiers écrits, alors copiez d'abord depuis le terminal ce que vous rendez. Le commentaire en tête de `compose.yaml` dit ce qu'est le labo et ce qu'il n'est pas.

## Vérifier le labo

`test/check.sh` démarre le labo comme le fait l'exécuteur de la plateforme pour chaque service (toutes les capacités retirées, `no-new-privileges`, une limite de processus, des limites de mémoire et aucun accès à internet), puis fait planter et reprend chaque workflow et vérifie ce qu'il affiche et ce que contient la base. Il demande Docker et tourne à chaque push : c'est le badge en haut.

```bash
test/check.sh
```

## Licence

Cette œuvre est sous licence [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr). Vous pouvez la partager et l'adapter pour apprendre et enseigner, à condition de citer Mitsuru Technologies Ltd, de ne pas en faire un usage commercial et de partager vos adaptations sous la même licence. Le texte complet est dans le fichier `LICENSE`. PostgreSQL et Python tournent sans modification depuis leurs images officielles, sous leurs propres licences.

## À propos

Réalisé par [Mitsuru Technologies](https://mitsurutech.co.uk) pour la [MitsuruTech Learning Platform](https://mitsurutech.co.uk/learning) : Python, Java, Go, Node, SQL et Linux dans le navigateur pour les écoles et les établissements, avec des labos en conteneur, des applications web déployées depuis GitHub et des quiz qui se corrigent tout seuls. Essayez du code sans compte dans le [bac à sable](https://mitsurutech.co.uk/playground).
