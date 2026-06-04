# 🎯 Exercice 02 : GitHub Actions

> 🟡 Niveau : Intermédiaire | ⏱️ Durée : 60 min

## Objectif

Comprendre le pipeline CI/CD du projet et créer un workflow simple.

## Prérequis

- Compte GitHub
- Fork du repo `formations-devops` (ou votre propre repo)

## Instructions

### Partie 1 : Vue d'ensemble du pipeline (15 min)

Le projet utilise **5 workflows** qui forment un pipeline DevSecOps complet :

```
                    ┌─────────────────────────────────────────────┐
  push/PR → main   │            security.yml                     │
  ──────────────────│  Snyk (dépendances) + Gitleaks (secrets)    │
                    │  + CodeQL (analyse statique SAST)            │
                    └─────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────┐
  push tag v*       │            build.yml                        │
  ──────────────────│  Docker Build → Push GHCR → Trivy Scan      │
                    └──────────────────┬──────────────────────────┘
                                       │ déclenche (workflow_dispatch)
                    ┌──────────────────▼──────────────────────────┐
                    │            deploy-app.yml                   │
                    │  Ansible → Docker Compose sur les VMs [app] │
                    └─────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────┐
  Manuel            │         deploy-infra.yml                    │
  ──────────────────│  Terraform plan → ✋ Approbation → apply     │
                    └─────────────────────────────────────────────┘

                    ┌─────────────────────────────────────────────┐
  Manuel            │         deploy-config.yml                   │
  ──────────────────│  Ansible → Hardening & configuration VMs    │
                    └─────────────────────────────────────────────┘
```

**Observez :**
- La sécurité est scannée sur **chaque push** (détection précoce)
- Le build ne se fait que pour les **tags** (releases versionnées)
- L'infra et la config applicative sont **séparées** : on peut redéployer l'app sans retoucher l'infra
- Il y a une **approbation manuelle** avant d'appliquer Terraform (éviter les accidents)

---

### Partie 2 : Analyser chaque workflow en détail (30 min)

#### 2.1 — `security.yml` : Les 3 scans DevSecOps

Ouvrez le fichier :
```bash
cat .github/workflows/security.yml
```

Ce workflow contient **3 jobs indépendants** (ils s'exécutent en parallèle) :

| Job | Outil | Que scanne-t-il ? | Analogie |
|-----|-------|--------------------|----------|
| `dependency-scan` | **Snyk** | Les dépendances Node.js (`package.json`) | Vérifier que les briques du mur ne sont pas fissurées |
| `secret-scan` | **Gitleaks** | L'historique Git complet | Chercher des clés perdues dans les poches |
| `sast-scan` | **CodeQL** | Le code source (JS, Python) | Relire le plan pour trouver des erreurs de conception |

**Questions à analyser :**

| Question | Indice |
|----------|--------|
| Pourquoi `fetch-depth: 0` pour Gitleaks ? | Un secret commité puis supprimé est toujours dans l'historique ! |
| Que signifie `continue-on-error: true` sur Snyk ? | Le scan reporte mais ne bloque pas → à changer en production |
| Pourquoi `security-events: write` sur CodeQL ? | CodeQL publie ses résultats dans l'onglet Security du repo |

> [!WARNING]
> **Pré-requis** pour que ce workflow fonctionne :
> - **`SNYK_TOKEN`** (secret) : token API de [snyk.io](https://snyk.io) (gratuit). Sans lui → erreur d'authentification
> - **`my-app/package-lock.json`** : Snyk en a besoin pour résoudre l'arbre de dépendances
> - **CodeQL** : nécessite un repo **public** ou le plan **GitHub Advanced Security** (payant pour repos privés)

---

#### 2.2 — `build.yml` : Build, Push et Scan de l'image Docker

```bash
cat .github/workflows/build.yml
```

Ce workflow a **2 jobs séquentiels** :

```
version (extraction du tag) → docker (build + push + scan)
```

**Étapes du job `docker` :**

| # | Étape | Ce qu'elle fait | Pourquoi |
|---|-------|-----------------|----------|
| 1 | Setup Buildx | Configure Docker Buildx | Builder avancé, support multi-plateforme et cache |
| 2 | Login GHCR | Authentification au registre `ghcr.io` | Nécessaire pour pousser l'image |
| 3 | Build + Push | Construit l'image depuis `my-app/` et la pousse | L'image taguée avec la version du tag Git |
| 4 | Trivy Scan | Scanne l'image pour CVE CRITICAL/HIGH | Sécurité : ne pas déployer une image vulnérable |
| 5 | Upload SARIF | Publie les résultats dans l'onglet Security | Visibilité et traçabilité |

**Points importants :**

| Concept | Détail |
|---------|--------|
| `context: ./my-app` | Le Dockerfile est dans le sous-dossier `my-app/` |
| `cache-from/to: type=gha` | Cache dans GitHub Actions → builds plus rapides |
| `exit-code: '1'` (Trivy) | Le job **échoue** si des vulnérabilités CRITICAL/HIGH sont trouvées |
| `if: always()` (SARIF) | Upload le rapport même si Trivy a trouvé des vulnérabilités |

> [!WARNING]
> **Pré-requis** pour que ce workflow fonctionne :
> - Un **`Dockerfile`** dans `my-app/` — sinon le build échoue
> - Un **tag Git** poussé (`git tag v1.0 && git push --tags`) — sinon le workflow ne se déclenche pas
> - `GITHUB_TOKEN` (automatique) — utilisé pour le login GHCR et le push de l'image

---

#### 2.3 — `deploy-infra.yml` : Infrastructure (Terraform)

```bash
cat .github/workflows/deploy-infra.yml
```

Ce workflow gère **uniquement l'infrastructure** de manière manuelle (`workflow_dispatch`) :

```
terraform-plan ──► ✋ Approbation manuelle ──► terraform-apply ──► Upload inventory
```

**Jobs :**

| Job | Rôle | Dépend de |
|-----|------|-----------|
| `terraform-plan` | `terraform init` + `plan` → artefact | — |
| `manual-approval` | Issue GitHub pour approbation humaine | `terraform-plan` |
| `terraform-apply` | Applique le plan, génère l'inventaire Ansible | `manual-approval` |

> [!CAUTION]
> **Secrets/Variables requis :**
> | Type | Nom | Usage |
> |------|-----|-------|
> | Secret | `S3_ACCESS_KEY_ID` | Backend S3 pour le state Terraform |
> | Secret | `S3_SECRET_ACCESS_KEY` | Backend S3 pour le state Terraform |
> | Secret | `API_TOKEN` | Token API du provider cloud (Denv-r) |
> | Variable | `S3_BUCKET` | Nom du bucket S3 |
> | Variable | `S3_KEY` | Chemin du fichier state dans le bucket |
> | Variable | `S3_REGION` | Région du bucket S3 |
> | Variable | `S3_ENDPOINT_URL` | Endpoint S3 (Denv-r, OVH, Scaleway…) |
> | Variable | `TF_APPROVER` | GitHub username autorisé à approuver |

#### 2.4 — `deploy-config.yml` : Configuration VMs (Ansible)

```bash
cat .github/workflows/deploy-config.yml
```

Déploie la configuration (hardening, firewall, utilisateurs) — **manuel** :

```
configure (ansible-playbook playbook.yml)
```

> Secrets requis : `SSH_PRIVATE_KEY`, `ANSIBLE_USER`

#### 2.5 — `deploy-app.yml` : Déploiement applicatif (Ansible + Docker Compose)

```bash
cat .github/workflows/deploy-app.yml
```

Déploie l'application (LLM Shield via Docker Compose) — **manuel ou déclenché par build.yml** :

```
deploy (ansible-playbook deploy-app.yml)
```

> Secrets : `SSH_PRIVATE_KEY`, `ANSIBLE_USER`, `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` (optionnels)
> Variables : `DOMAIN_NAME`, `LETSENCRYPT_EMAIL`

---

### Partie 3 : Créer un workflow simple (15 min)

1. **Créer un nouveau workflow**
   ```bash
   cat > .github/workflows/hello.yml << 'EOF'
   name: Hello World

   on:
     push:
       branches: [main]
     workflow_dispatch:  # Permet de lancer manuellement

   # 🔒 Permissions explicites (bonne pratique DevSecOps)
   permissions:
     contents: read

   jobs:
     greet:
       runs-on: ubuntu-latest
       timeout-minutes: 5  # Évite les jobs qui tournent indéfiniment
       steps:
         - name: Checkout
           uses: actions/checkout@v4

         - name: Say Hello
           run: echo "Hello, ${{ github.actor }}!"

         - name: Show date
           run: date

         - name: List files
           run: ls -la
   EOF
   ```

2. **Comprendre les bonnes pratiques DevSecOps**

   ```yaml
   # ✅ Bonne pratique : permissions explicites
   permissions:
     contents: read  # Seulement ce qui est nécessaire
   
   # ✅ Bonne pratique : timeout
   timeout-minutes: 5
   
   # ✅ Bonne pratique : version pinning
   uses: actions/checkout@v4  # Pas @latest ou @main
   ```

3. **Ajouter une étape de validation**
   
   Modifiez le workflow pour ajouter :
   ```yaml
         - name: Validate Dockerfile exists
           run: |
             if [ -f Dockerfile ]; then
               echo "✅ Dockerfile found"
             else
               echo "❌ Dockerfile missing"
               exit 1
             fi
   ```

---

## 🔒 Bonnes pratiques DevSecOps dans les pipelines

### Implémentées dans ce projet

| Pratique | Fichier | Description |
|----------|---------|-------------|
| **Permissions explicites** | Tous | `permissions:` avec moindre privilège |
| **Timeouts** | Tous | Évite les jobs infinis |
| **Version pinning** | Tous | `@v4` au lieu de `@latest` |
| **Scan dépendances** | security.yml | Snyk pour Node.js |
| **Scan secrets** | security.yml | Gitleaks |
| **SAST** | security.yml | CodeQL |
| **Scan images** | build.yml | Trivy |
| **Manual approval** | deploy-infra.yml | Avant Terraform apply |
| **Condition de succès** | build.yml → deploy-app.yml | Ne déploie pas après un build échoué |
| **Infra et app séparés** | deploy-infra.yml + deploy-app.yml | Redéploiement app sans retoucher l'infra |

### À explorer (nice-to-have)

| Pratique | Outil | Description |
|----------|-------|-------------|
| **SBOM** | Syft, Docker SBOM | Inventaire des composants |
| **Image signing** | Cosign | Signature cryptographique |
| **OIDC auth** | GitHub OIDC | Authentification sans secrets |
| **Attestations** | SLSA | Provenance des artefacts |
| **Policy as Code** | OPA, Kyverno | Politiques automatisées |

> 💬 **Discussion** : Quelles pratiques nice-to-have seraient prioritaires dans votre contexte ?

---

## 🧪 Validation

✅ Vous avez réussi si :
- [ ] Vous pouvez expliquer quand chaque workflow se déclenche
- [ ] Vous pouvez lister les secrets nécessaires pour chaque workflow
- [ ] Votre workflow `hello.yml` s'exécute (si vous avez pushé)
- [ ] Vous comprenez la différence entre `uses:` et `run:`
- [ ] Vous savez pourquoi les `permissions:` sont importantes
- [ ] Vous pouvez expliquer pourquoi Terraform et l'app sont dans des workflows séparés

---

## 💡 Indice

**Différence `uses` vs `run` :**
- `uses: actions/checkout@v4` → Utilise une **Action** réutilisable (du marketplace GitHub)
- `run: echo "hello"` → Exécute une **commande shell** directe

---

## ✅ Solution

<details>
<summary>Réponses Partie 2</summary>

**security.yml :**
| Question | Réponse |
|----------|---------|
| Nombre de jobs | 3 (dependency, secret, sast) |
| Types de scan | Dépendances (Snyk), Secrets (Gitleaks), Code (CodeQL) |
| Pourquoi `fetch-depth: 0` | Scanner les secrets dans **tout** l'historique, pas juste le dernier commit |
| Pourquoi `continue-on-error` | Phase de test/early stage — à retirer en production |

**build.yml :**
| Question | Réponse |
|----------|---------|
| Déclencheur | Push d'un tag (`tags: 'v*'`) |
| Permissions | `contents: read`, `packages: write` |
| Registry | `ghcr.io` (GitHub Container Registry) |
| Scan image | Trivy (`aquasecurity/trivy-action`) — SARIF upload |
| Déclenchement | Lance `deploy-app.yml` via `workflow_dispatch` |

**deploy-infra.yml :**
| Question | Réponse |
|----------|---------|
| Déclencheur | Manuel (`workflow_dispatch`) |
| Terraform | `init` → `plan` → approval → `apply` |
| Approbation | Issue GitHub via `trstringer/manual-approval` |
| Output | Génère `inventory` (pour Ansible) → upload artifact |

**deploy-config.yml :**
| Question | Réponse |
|----------|---------|
| Déclencheur | Manuel (`workflow_dispatch`) |
| Ansible | Playbook `playbook.yml` (hardening, UFW, fail2ban, users) |

**deploy-app.yml :**
| Question | Réponse |
|----------|---------|
| Déclencheur | Manuel (`workflow_dispatch`) ou après `build.yml` |
| Ansible | Playbook `deploy-app.yml` (Docker Compose LLM Shield) |
| Vars | `image_tag`, `domain_name`, `letsencrypt_email`, API keys (optionnelles) |

</details>

---

## 🤖 Test IA

Demandez à une IA :

> *"Écris un workflow GitHub Actions qui builde une image Docker et la pousse sur Docker Hub"*

**Comparez avec `build.yml` :**
- L'IA déclare-t-elle des `permissions:` explicites ?
- Y a-t-il un scan de sécurité de l'image ?
- Les secrets sont-ils bien référencés ?
- Y a-t-il un `timeout-minutes` ?

**Leçon** : L'IA génère des workflows fonctionnels mais souvent sans les bonnes pratiques de sécurité. Toujours vérifier et compléter !
