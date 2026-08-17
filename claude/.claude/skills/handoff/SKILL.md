---
name: handoff
description: Écrit le prompt de reprise de la conversation en cours dans un fichier, avant un /clear.
argument-hint: "[chemin de destination]"
disable-model-invocation: true
allowed-tools: Write
---

Construis le prompt de reprise de cette conversation et écris-le dans un fichier.

Destination : `$ARGUMENTS` s'il est fourni, sinon
`~/.claude/handoffs/<nom du dossier courant>-<AAAA-MM-JJ-hhmm>.md`. Jamais dans un
dépôt git : un handoff n'a pas à être versionné, et le dossier courant en est
souvent un.

Le fichier contient ceci, dans cet ordre, et rien d'autre :

1. **Objectif** — ce que la session cherchait à obtenir, en une phrase.
2. **État** — ce qui est fait, ce qui ne l'est pas, ce qui est en cours.
3. **Décisions et pourquoi** — y compris les pistes écartées et leur raison.
4. **Fichiers touchés** — chemins exacts, et ce qui a changé dans chacun.
5. **Vérifications** — commandes lancées et leur résultat ; celles qui restent.
6. **Prochaine étape** — une seule action, à l'impératif, la plus utile.
7. **Modèle et effort** recommandés pour la suite, avec la raison.

Règles d'écriture :

- Chemins, identifiants, commandes, messages d'erreur et chiffres **verbatim**.
- Omettre un fait incertain plutôt que le reconstruire de mémoire.
- Écrit pour une conversation qui ne sait rien : aucun « comme vu plus haut ».
- Viser ~2k tokens.

Puis, avant de conclure, dis à Enoal laquelle des trois continuités convient ici,
et pourquoi — c'est sa décision, pas la tienne :

- ce **handoff** (~2k) si la substance tient dans ce que tu viens d'écrire ;
- un **`/export` collé** (~30k) si la substance est le raisonnement — session
  d'analyse ou de conception, où tu ne sais pas encore ce qui comptera ;
- **`--resume`** (contexte intégral) si la substance est le diff et la sortie des
  tests, c'est-à-dire précisément ce qu'un export jette.

Termine en affichant le chemin du fichier et en rappelant que `/clear` est
gratuit, et que la session suivante démarre sur `Lis <chemin> et reprends.`
