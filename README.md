# Denv-r Template Project

> [!TIP]
> **🎓 Formation DevSecOps disponible !**
> Ce repo sert de support à un workshop de 4 jours. Consultez [WORKSHOP.md](./WORKSHOP.md) pour le programme complet.

## 📚 Ressources Formation

| Ressource | Description |
|-----------|-------------|
| [WORKSHOP.md](./WORKSHOP.md) | Programme structuré Jour 1 + Jour 2 |
| [theory/](./theory/) | Modules théoriques (DevOps, Cloud, GitOps) |
| [exercises/](./exercises/) | Exercices pratiques progressifs |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Guide de résolution d'erreurs |
| [AI_TRAPS.md](./AI_TRAPS.md) | Pièges IA pour développer l'esprit critique |

---

This project is a template to:

- Build and push a containerized NextJS app to GitHub registry
- Manage VMs in Denv-r cloud environment using Terraform
- Deploy the containerized app on VMs using Ansible

> [!NOTE]
> This Terraform project is configured for Denv-r cloud using the Warren provider.
> You can also use the CI and Ansible to build, publish and deploy your NextJS app on your own VMs accessible via SSH.


## Prerequisites

Using the CI/CD only, to build, push and deploy, you just need to install :
- Terraform

If you want to run all this actions locally first then you need :
- npm : build and run locally the NextJS application following the README.md file on "my-app" sub-directory
- Docker with docker compose : build and run contenerized version of the app
- Terraform : deploy VMs in your Denv-r cloud environment
- Ansible : deploy the contenerized app on your VMs

## 📥 Setup & Submodules

This repository uses Git submodules (specifically the `capstone` project). 
Use the following commands to ensure you have all the necessary code:

**Clone with submodules:**
```bash
# SSH
git clone --recursive git@github.com:dis-bzh/formations-devops.git

# ou HTTPS
git clone --recursive https://github.com/dis-bzh/formations-devops.git
```

**If you already cloned the repo:**
```bash
git submodule update --init --recursive
```

## Github workflow

Le projet utilise 3 workflows CI/CD qui forment un pipeline DevSecOps complet :

| Workflow | Déclencheur | Rôle |
|----------|-------------|------|
| `security.yml` | Push/PR → `main` | Scans de sécurité : dépendances (Snyk), secrets (Gitleaks), code (CodeQL) |
| `build.yml` | Push d'un **tag** `v*` | Build Docker, push sur GHCR, scan Trivy — déclenche `deploy-app.yml` |
| `deploy-infra.yml` | Manuel (`workflow_dispatch`) | Terraform plan → approbation manuelle → apply |
| `deploy-config.yml` | Manuel (`workflow_dispatch`) | Ansible hardening & configuration des VMs |
| `deploy-app.yml` | Manuel ou après `build.yml` | Ansible déploiement applicatif (Docker Compose) |

> 📖 Voir [Exercice 02 — Premier Workflow](./exercises/devops-j1/02-premier-workflow.md) pour une analyse détaillée de chaque workflow.

### Secrets (Settings → Secrets and variables → Actions)

| Secret | Workflow | Usage |
|--------|----------|-------|
| `SNYK_TOKEN` | security.yml | Token API [snyk.io](https://snyk.io) pour scan des dépendances |
| `S3_ACCESS_KEY_ID` | deploy-infra.yml | Accès au backend S3 (state Terraform) |
| `S3_SECRET_ACCESS_KEY` | deploy-infra.yml | Accès au backend S3 (state Terraform) |
| `API_TOKEN` | deploy-infra.yml | Token API du provider cloud (Denv-r) |
| `SSH_PRIVATE_KEY` | deploy-config.yml, deploy-app.yml | Clé SSH pour Ansible |
| `ANSIBLE_USER` | deploy-config.yml, deploy-app.yml | Utilisateur SSH sur les VMs |
| `OPENAI_API_KEY` | deploy-app.yml | Clé API OpenAI (optionnel — LLM Shield) |
| `ANTHROPIC_API_KEY` | deploy-app.yml | Clé API Anthropic (optionnel — LLM Shield) |
| `GEMINI_API_KEY` | deploy-app.yml | Clé API Gemini (optionnel — LLM Shield) |

### Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Workflow | Usage |
|----------|----------|-------|
| `S3_BUCKET` | deploy-infra.yml | Nom du bucket S3 pour le state Terraform |
| `S3_KEY` | deploy-infra.yml | Chemin du fichier state dans le bucket |
| `S3_REGION` | deploy-infra.yml | Région du bucket S3 |
| `S3_ENDPOINT_URL` | deploy-infra.yml | Endpoint S3 (Denv-r, OVH, Scaleway…) |
| `DOMAIN_NAME` | deploy-app.yml | Nom de domaine pour le certificat SSL (ex: `ai.example.com`) |
| `LETSENCRYPT_EMAIL` | deploy-app.yml | Email pour Let's Encrypt |
| `TF_APPROVER` | deploy-infra.yml | GitHub username autorisé à approuver le Terraform apply |

### Secrets automatiques (fournis par GitHub)

| Secret | Usage |
|--------|-------|
| `GITHUB_TOKEN` | Login GHCR, push d'images, approbations manuelles, Gitleaks |

## Ansible

Template to manage VMs configuration. It uses the inventory created by Terraform.
It can be run locally, automatically triggered in the CI when "Build and Push" workflow is "completed", manually in the CI.

To run it locally, use the following command :
```bash
ansible-playbook -i path/to/inventory path/to/playbook.yml \
--private-key path/to/sshPrivateKey \
-u username \
--ssh-common-args='-o StrictHostKeyChecking=no' \
--extra-vars ansible_user=username \
--extra-vars registry_username=github_username \
--extra-vars registry_token=github_access_token \
--extra-vars image_name=containerImage:tag
--extra-vars host_port=80
--extra-vars container_port=80
```

## Terraform

Terraform est intégré au CI via le workflow `deploy-infra.yml` (plan → approbation manuelle → apply).
Pour gérer l'infrastructure localement, un token API Denv-r est nécessaire ([interface utilisateur](https://app.denv-r.com/)).

### S3 backend

Le state Terraform (tfstate) contient des informations sensibles. L'utiliser dans un backend S3 est la bonne pratique.

Créer un bucket S3 via l'API Denv-r :

```bash
curl --location --request PUT "https://api.denv-r.com/v1/storage/bucket" \
    -H "apikey: <votre-token>" \
    -d "name=<nom-bucket>" \
    -d "billing_account_id=<votre-billing-id>"
```

Récupérer les clés d'accès S3 :

```bash
curl "https://api.denv-r.com/v1/storage/user/keys" \
    -H "apikey: <votre-token>" \
    -X GET
```

### Variables

`backend.tfvars` contient la configuration du backend S3 (chargé en premier par Terraform).
`terraform.tfvars` contient la configuration de l'infrastructure (VMs, réseau, etc.).

```bash
cd terraform
cp backend.tfvars.example backend.tfvars   # puis éditer les valeurs S3
cp terraform.tfvars.example terraform.tfvars  # puis éditer prefix, ssh_public_key...
```

Pour déployer :

```bash
export TF_VAR_api_token="<votre-token-denv-r>"
# $env:TF_VAR_api_token="<votre-token>" en PowerShell

terraform init -backend-config=backend.tfvars
terraform plan -out tf.plan
terraform apply "tf.plan"
```

### Ansible — configuration locale

Pour configurer les VMs localement (hardening, utilisateurs, firewall) :

```bash
cd ansible
cp group_vars/all/custom.yml.example group_vars/all/custom.yml
# Éditer custom.yml : ajouter votre username et clé SSH publique

ansible-playbook -i inventory.ini playbook.yml \
  --private-key ~/.ssh/id_ed25519 \
  -u ansible \
  --ssh-common-args='-o StrictHostKeyChecking=no'
```

Pour déployer l'application :

```bash
ansible-playbook -i inventory.ini deploy-app.yml \
  --private-key ~/.ssh/id_ed25519 \
  -u ansible \
  --ssh-common-args='-o StrictHostKeyChecking=no' \
  --extra-vars "image_tag=latest" \
  --extra-vars "domain_name=ai.example.com" \
  --extra-vars "letsencrypt_email=admin@example.com"
```
