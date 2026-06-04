# 🎯 Exercice 12 : Security Scan & Esprit Critique IA

> 🟡 Niveau : Intermédiaire | ⏱️ Durée : 45 min

## Objectif

Comprendre l'importance du DevSecOps ET développer l'esprit critique face aux réponses d'une IA.
L'IA n'est pas votre senior — vous l'êtes. Les outils DevSecOps sont votre filet de sécurité.

## Prérequis

- Node.js installé
- Compte Snyk gratuit (optionnel)
- Accès à une IA (ChatGPT, Claude, Gemini, Mistral…)

## Méthode : le triptyque QUESTIONNER → IA → AUDITER

Pour chaque exercice DevSecOps, on suit ce cycle :

```
🤔 QUESTIONNER     Qu'est-ce qui peut casser ? Quels invariants ?
       ↓
🤖 IA ASSISTÉE     Demander à l'IA une solution
       ↓
🔍 AUDITER         Comparer intuition vs IA, repérer les angles morts
```

**Règle d'or :** l'IA est un stagiaire brillant et pressé. Elle livre vite, parfois juste, parfois faux. Vous êtes le senior qui relit. Les outils (Snyk, Trivy, Gitleaks, CodeQL) sont votre filet de sécurité.

---

## Partie 1 : Comprendre DevSecOps (5 min)

**DevSecOps = Dev + Sec + Ops**

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│   Dev   │────►│   Sec   │────►│   Ops   │
│  Code   │     │  Scan   │     │ Deploy  │
└─────────┘     └─────────┘     └─────────┘
     │               │               │
     └───────────────┴───────────────────┘
         Intégré, pas en silo !
```

**Types de scans :**

| Type | Cible | Outils |
|------|-------|--------|
| **SAST** | Code source | SonarQube, Snyk Code |
| **SCA** | Dépendances | Snyk, Dependabot, Trivy |
| **DAST** | App en cours d'exécution | OWASP ZAP |
| **Container** | Images Docker | Trivy, Grype |
| **IaC** | Terraform, Ansible | Checkov, tfsec |

---

## Partie 2 : QUESTIONNER — Qu'est-ce qui peut casser ? (10 min)

**Mise en situation :** un collègue vous envoie ce code en disant "c'est bon, l'IA a généré".

```python
# app.py — version "validée par l'IA"
import requests
api_key = "sk-live-1234567890abcdefghij"
response = requests.get(f"https://api.example.com/data?key={api_key}")
```

**Questions AVANT de lancer un scan :**

1. Où est stocké le secret ? Qui peut le lire ?
2. Si ce code est sur GitHub public, que se passe-t-il ?
3. Que peut faire un attaquant qui lit ce fichier ?
4. Quel outil DevSecOps attraperait ce problème **automatiquement** ?

> [!TIP]
> **Notez vos réponses.** Vous les comparerez avec ce que trouvent les outils.

---

## Partie 3 : Scanner localement (10 min)

Lancez les outils sur le projet. Comparez avec vos prédictions.

**Option A : npm audit (intégré, pas de token)**
```bash
cd my-app
npm audit --audit-level=high
```

**Option B : Snyk CLI (plus détaillé)**
```bash
npm install -g snyk
snyk auth        # optionnel : limite le scan sinon
cd my-app
snyk test
```

**Option C : Trivy (pour les images Docker)**
```bash
sudo apt install trivy
docker build -t denvr-app:test my-app
trivy image denvr-app:test
```

**Option D : Gitleaks (secrets dans l'historique git)**
```bash
docker run --rm -v "$PWD:/repo" gitleaks/gitleaks:latest detect --source /repo
```

**Remplir ce tableau :**

| Outil | Catégorie | A-t-il trouvé quelque chose ? | Quoi ? | L'avais-vous prédit ? |
|-------|-----------|------------------------------|--------|------------------------|
| npm audit | SCA | | | |
| Snyk | SCA + Code | | | |
| Trivy | Container | | | |
| Gitleaks | Secrets | | | |

---

## Partie 4 : IA ASSISTÉE — Demander à l'IA une solution (5 min)

**Prompt que vous envoyez à l'IA :**

> *"J'ai une vulnérabilité high dans lodash sur mon projet Node.js. Comment je corrige ?"*

**Notez exactement ce que l'IA répond.** Vous en aurez besoin pour la partie 5.

---

## Partie 5 : AUDITER — Comparer IA vs réalité (10 min)

**L'IA a répondu quelque chose. Maintenant on audite.**

| Critère | Ce que l'IA a dit | Ce que dit l'outil (Snyk/Trivy) | Verdict |
|---------|-------------------|--------------------------------|---------|
| Version exacte à installer | ? | (voir `npm audit fix --dry-run`) | |
| Est-ce une dépendance directe ou transitive ? | ? | `npm ls lodash` | |
| Risque de breaking change ? | ? | Snyk le mentionne dans l'advisory | |
| Y a-t-il un CVE officiel ? | ? | Lien GHSA dans le rapport Snyk | |

**Questions pièges :**

- L'IA a-t-elle donné une version précise (`4.17.21`) ou vague (`la dernière`) ?
- L'IA a-t-elle mentionné que ça peut casser le code en upgrade ?
- L'IA propose-t-elle `npm audit fix` (automatique, risqué) ou un upgrade manuel ?
- A-t-elle renvoyé vers une source officielle (GHSA, NVD) ?

**Leçon :** l'IA donne des conseils génériques. Pour les vulnérabilités spécifiques, consultez toujours l'advisory officiel (lien dans le rapport Snyk). C'est votre **filet de sécurité**.

---

## Partie 6 : Analyser le workflow security.yml (5 min)

```bash
cat .github/workflows/security.yml
```

3 jobs en parallèle : Snyk, Gitleaks, CodeQL.

**Réfléchissez :**
- Pourquoi `fetch-depth: 0` sur Gitleaks ? (Indice : un secret supprimé reste dans l'historique)
- Que signifie `continue-on-error: true` sur Snyk ? (Le scan reporte mais ne bloque pas)
- Pourquoi `security-events: write` sur CodeQL ? (Publie dans l'onglet Security)

---

## 🧪 Validation

✅ Vous avez réussi si :
- [ ] Vous avez listé des risques AVANT de scanner
- [ ] Les outils ont confirmé (ou infirmé) vos prédictions
- [ ] Vous avez noté au moins 1 chose que l'IA a dite de vague / faux / imprécis
- [ ] Vous savez expliquer pourquoi les outils DevSecOps sont un filet de sécurité indispensable

---

## 💡 Indice : niveaux de sévérité

| Niveau | Action |
|--------|--------|
| `low` | Risque minimal, peut attendre |
| `medium` | À corriger dans le sprint |
| `high` | À corriger rapidement |
| `critical` | **Immédiatement**, hors de la prod |

En production, bloquez au moins `high` et `critical`.

---

## 🤖 Test IA : la bonne question à se poser

Après avoir confronté l'IA à un problème concret, retenez cette grille :

| Question | Pourquoi c'est important |
|----------|--------------------------|
| L'IA donne-t-elle une **version précise** ? | `4.17.21` ≠ `la dernière` |
| A-t-elle vérifié la **compatibilité** ? | Une upgrade peut casser du code |
| Cite-t-elle une **source** (CVE, GHSA) ? | Si non → vérifier vous-mêmes |
| Propose-t-elle de **tester** ? | `npm audit fix --dry-run` avant `fix` |
| A-t-elle vu les **dépendances transitives** ? | `npm ls <package>` pour l'arbre |

**L'IA est un bon point de départ. Pas un point d'arrivée.**

---

## Pour aller plus loin

Voir l'exercice **[14 — Lab Cassé : Dockerfile vulnérable](../sysops-j4/14-lab-dockerfile-casse.md)** :
tout est volontairement faux, vous devez trouver les problèmes **avec les outils**.
