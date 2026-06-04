# 🧪 Lab Cassé #1 : Dockerfile "validé par l'IA"

> 🔴 Niveau : Avancé | ⏱️ Durée : 30 min

## Objectif

Trouver **toutes** les failles de sécurité d'un Dockerfile volontairement cassé.
Vous n'avez pas le droit de modifier le fichier avant d'avoir tout listé. Les outils DevSecOps sont vos yeux.

> **Pourquoi ce lab ?** En entreprise, on reçoit du code "validé par l'IA" ou "qui marche en local". Votre job : dire **non** si ce n'est pas sécurisé. Les outils Trivy, Snyk, Hadolint sont là pour ça.

## Prérequis

- Docker installé
- Trivy : `sudo apt install trivy` ou `brew install trivy`
- Hadolint : `brew install hadolint` ou via Docker

---

## Le Dockerfile à auditer

Créez un dossier de travail et copiez ce Dockerfile. **Ne le modifiez pas.**

```dockerfile
# Dockerfile — app Node.js
FROM node:latest

WORKDIR /app
COPY . .

RUN apt-get update && apt-get install -y curl sudo
RUN curl -fsSL https://get.docker.com | sh

ARG API_KEY=sk-live-abcdef1234567890
ENV API_KEY=$API_KEY

RUN useradd -m nodeapp
USER root

RUN npm install --omit=dev

EXPOSE 3000
CMD ["node", "server.js"]
```

---

## Étape 1 : QUESTIONNER (5 min)

**Avant de lancer le moindre outil**, parcourez le fichier ligne par ligne.

Cochez mentalement ce que vous trouvez suspect :

- [ ] Image de base : quelle version exactement ? que se passe-t-il si elle change ?
- [ ] Permissions : le code a-t-il accès à tout ?
- [ ] `curl ... | sh` : que peut faire un attaquant si l'URL est compromise ?
- [ ] Secret en ARG/ENV : visible dans `docker history` ?
- [ ] `USER root` après création d'un user : quel est l'effet ?
- [ ] `apt-get install sudo` : pourquoi un serveur Node a-t-il besoin de sudo ?
- [ ] `COPY . .` : copie-t-on le `.git`, `.env`, `node_modules` ?
- [ ] `npm install` sans `--ignore-scripts` : scripts arbitraires exécutés ?

**Notez vos trouvailles.** Vous comparerez avec les outils.

---

## Étape 2 : AUDITER avec Hadolint (5 min)

Hadolint lint le Dockerfile et applique les bonnes pratiques.

```bash
# Avec Docker
docker run --rm -i hadolint/hadolint < Dockerfile

# Ou natif
hadolint Dockerfile
```

**Sortie attendue (extrait) :**

```
DL3007: Using latest is prone to errors...
DL3008: Pin versions in apt-get install...
DL3009: Delete the apt-get lists after installing...
DL3015: Avoid additional packages by specifying --no-install-recommends...
DL3025: Use arguments JSON notation for CMD/ENTRYPOINT...
DL4006: Set the SHELL option -o pipefail before RUN with a pipe...
```

Chaque ligne = 1 problème. **Cochez ceux que vous aviez repérés à l'étape 1.**

---

## Étape 3 : AUDITER avec Trivy (10 min)

Trivy scanne le Dockerfile ET l'image construite.

```bash
# Construire l'image
docker build -t lab-casse:1.0 .

# Scanner les vulnérabilités OS + dépendances
trivy image lab-casse:1.0

# Scanner les secrets dans les couches
trivy image --scanners secret lab-casse:1.0

# Scanner les misconfigurations du Dockerfile lui-même
trivy config Dockerfile
```

**Sortie attendue (extrait) :**

```
CRITICAL  node:latest  — base image has 247 known CVEs
HIGH      sudo         — local privilege escalation possible
CRITICAL  API_KEY=sk-live...  — exposed secret in layer
HIGH      curl|sh      — unverified download + execution
```

**Cochez ce que Trivy a trouvé en plus de ce qu'Hadolint a dit.**

---

## Étape 4 : Vérifier le secret dans l'historique (5 min)

```bash
docker history lab-casse:1.0
```

> Le secret `sk-live-abcdef1234567890` apparaît-il ? Pourquoi ?

C'est **LA** faille la plus dangereuse d'un Dockerfile. Même si vous supprimez l'ENV ensuite, le secret reste dans une couche intermédiaire accessible via `docker pull` ou l'historique de l'image.

---

## Étape 5 : Corriger (5 min)

Maintenant — et seulement maintenant — vous avez le droit de modifier.

**Version corrigée :**

```dockerfile
# Dockerfile — version corrigée
FROM node:20.11.1-bookworm-slim

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --ignore-scripts

# Copie ciblée (pas de .git, .env, node_modules)
COPY server.js ./

# Crée un user non-root
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 3000
CMD ["node", "server.js"]
```

**Et le secret ?** → Dockerfile Vault, AWS Secrets Manager, ou variable d'environnement injectée au runtime (`docker run -e API_KEY=...`). **Jamais dans le Dockerfile.**

```bash
docker run -e API_KEY="$(cat .api_key)" lab-casse:1.0
```

---

## 🧪 Validation

✅ Vous avez réussi si :
- [ ] Vous avez listé au moins 5 problèmes AVANT de lancer les outils
- [ ] Hadolint a trouvé les problèmes que vous aviez prédits
- [ ] Trivy a trouvé des CVEs dans `node:latest`
- [ ] Vous avez compris pourquoi le secret reste visible après suppression
- [ ] Votre Dockerfile corrigé passe Hadolint sans warning critique

---

## 💡 Indice : les 8 problèmes de ce Dockerfile

<details>
<summary>Cliquer pour révéler</summary>

| # | Ligne | Problème | Détecté par |
|---|-------|----------|-------------|
| 1 | `FROM node:latest` | Tag mutable, image énorme | Hadolint, Trivy |
| 2 | `apt-get install sudo` | Élévation de privilèges possible | Hadolint |
| 3 | `curl ... | sh` | Téléchargement non vérifié + exécution | Hadolint, code review |
| 4 | `ARG API_KEY=...` + `ENV` | Secret dans l'historique Docker | Trivy secret scan |
| 5 | `COPY . .` | Copie `.git`, `.env`, secrets, node_modules | Code review |
| 6 | `useradd ... USER root` | Inversion : user créé puis root utilisé | Hadolint |
| 7 | `npm install --omit=dev` | Pas de `--ignore-scripts` → RCE possible | npm audit, Snyk |
| 8 | Pas de `HEALTHCHECK` | Docker ne sait pas si l'app est vivante | Docker best practices |

</details>

---

## 🤖 Test IA : le bon prompt

**MAUVAIS prompt** (ce que l'IA va produire ce Dockerfile cassé) :
> "Écris-moi un Dockerfile pour une app Node.js"

**BON prompt** (force l'IA à être rigoureuse) :
> "Écris-moi un Dockerfile pour une app Node.js avec : image de base pinnée Debian-slim, user non-root, pas de secret dans l'image, multi-stage si nécessaire, healthcheck, et conforme aux bonnes pratiques Hadolint."

Comparez les deux réponses. **La première va probablement ressembler au Dockerfile cassé de ce lab.**

---

## Pour aller plus loin

- **Lab Cassé #2** : Playbook Ansible avec secrets hardcodés
- **Lab Cassé #3** : Workflow GitHub Actions sans `permissions:` ni OIDC
- **Lab Cassé #4** : Terraform avec state file commité sur GitHub
