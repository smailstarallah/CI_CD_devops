# EduPlatform - Plateforme d'E-learning

## 📚 Description

EduPlatform est une plateforme d'e-learning moderne développée avec des technologies web statiques (HTML, CSS, JavaScript). Ce projet démontre l'implémentation complète d'un pipeline CI/CD avec Azure DevOps pour le déploiement automatisé sur Azure Storage.

## 🚀 Fonctionnalités

- **Interface moderne et responsive** : Design adaptatif pour tous les appareils
- **Performance optimisée** : Temps de chargement rapide et optimisation SEO
- **Accessibilité** : Conforme aux standards WCAG 2.1 AA
- **PWA Ready** : Support pour les Progressive Web Apps
- **CI/CD automatisé** : Déploiement automatique avec Azure DevOps

## 🛠️ Technologies utilisées

- **Frontend** : HTML5, CSS3, JavaScript (ES6+)
- **Frameworks CSS** : CSS Grid, Flexbox
- **Icons** : Font Awesome
- **DevOps** : Azure DevOps, Azure Storage, Azure CDN
- **Tests** : Lighthouse, Pa11y, HTML Validator

## 📁 Structure du projet

```
devops_git/
├── index.html                    # Page principale
├── css/
│   ├── style.css                # Styles principaux
│   └── responsive.css           # Styles responsive
├── js/
│   └── script.js               # Scripts JavaScript
├── azure-pipelines.yml         # Pipeline CI/CD principal
├── azure-quality-pipeline.yml  # Pipeline de tests de qualité
├── azure-variables.yml         # Variables d'environnement
├── docs/                       # Documentation
│   ├── deployment-guide.md     # Guide de déploiement
│   └── azure-setup.md         # Configuration Azure
└── README.md                   # Ce fichier
```

## ⚡ Démarrage rapide

### Prérequis

- Compte Azure avec souscription active
- Organisation Azure DevOps
- Git installé localement

### Installation locale

1. **Cloner le repository**
   ```bash
   git clone <your-repo-url>
   cd devops_git
   ```

2. **Ouvrir avec un serveur local**
   ```bash
   # Avec Python
   python -m http.server 8000
   
   # Avec Node.js (http-server)
   npx http-server
   
   # Avec VS Code Live Server
   # Installer l'extension Live Server et cliquer sur "Go Live"
   ```

3. **Accéder à l'application**
   Ouvrir http://localhost:8000 dans votre navigateur

## 🔧 Configuration Azure DevOps

### 1. Créer les ressources Azure

```bash
# Se connecter à Azure
az login

# Créer un groupe de ressources
az group create --name rg-eduplatform --location "West Europe"

# Créer un storage account pour la production
az storage account create \
  --name steduplatform \
  --resource-group rg-eduplatform \
  --location "West Europe" \
  --sku Standard_LRS \
  --kind StorageV2

# Créer un storage account pour le développement
az storage account create \
  --name steduplatformdev \
  --resource-group rg-eduplatform \
  --location "West Europe" \
  --sku Standard_LRS \
  --kind StorageV2

# Activer le site web statique
az storage blob service-properties update \
  --account-name steduplatform \
  --static-website \
  --index-document index.html \
  --404-document 404.html

az storage blob service-properties update \
  --account-name steduplatformdev \
  --static-website \
  --index-document index.html \
  --404-document 404.html
```

### 2. Configurer Azure DevOps

1. **Créer un nouveau projet** dans Azure DevOps
2. **Importer le repository** Git
3. **Créer une Service Connection** pour Azure
   - Aller dans Project Settings > Service connections
   - Créer une nouvelle connection Azure Resource Manager
   - Sélectionner votre souscription et groupe de ressources

4. **Configurer les variables** dans Azure DevOps
   - Aller dans Pipelines > Library
   - Créer un nouveau Variable Group "EduPlatform-Variables"
   - Ajouter les variables depuis `azure-variables.yml`

### 3. Créer les pipelines

#### Pipeline principal (CI/CD)
1. Aller dans Pipelines > Create Pipeline
2. Sélectionner votre repository
3. Choisir "Existing Azure Pipelines YAML file"
4. Sélectionner `/azure-pipelines.yml`
5. Sauvegarder et exécuter

#### Pipeline de qualité
1. Créer un nouveau pipeline
2. Sélectionner `/azure-quality-pipeline.yml`
3. Configurer pour déclenchement manuel

### 4. Configuration des environnements

1. **Créer les environnements**
   - Aller dans Pipelines > Environments
   - Créer "development" et "production"
   - Configurer les approbations pour production

2. **Configurer les notifications**
   - Aller dans Project Settings > Notifications
   - Configurer les alertes pour les échecs de build

## 📊 Pipelines CI/CD

### Pipeline Principal (`azure-pipelines.yml`)

**Déclencheurs:**
- Push sur `main` → Déploiement en production
- Push sur `develop` → Déploiement en développement

**Stages:**
1. **Build** : Validation HTML/CSS, tests de base
2. **Deploy Dev** : Déploiement automatique sur environnement de développement
3. **Deploy Prod** : Déploiement en production (avec approbation)
4. **Post Deploy** : Tests de performance et qualité

### Pipeline de Qualité (`azure-quality-pipeline.yml`)

**Déclencheurs:**
- Pull Requests
- Déclenchement manuel

**Tests inclus:**
- **Lighthouse** : Performance, Accessibilité, SEO, Best Practices
- **Pa11y** : Tests d'accessibilité détaillés
- **Security** : Vérification des en-têtes de sécurité
- **Performance** : Tests de temps de réponse

### Seuils de Qualité

| Métrique | Seuil | Description |
|----------|-------|-------------|
| Performance | ≥ 80 | Score Lighthouse |
| Accessibilité | ≥ 90 | Score Lighthouse + Pa11y |
| SEO | ≥ 85 | Score Lighthouse |
| Temps de réponse | ≤ 2s | Temps de chargement moyen |

## 🔍 Tests et Qualité

### Tests automatisés

```bash
# Validation HTML
html-validate index.html

# Tests d'accessibilité
pa11y http://localhost:8000 --standard WCAG2AA

# Tests de performance
lighthouse http://localhost:8000 --output json
```

### Métriques surveillées

- **Core Web Vitals** : LCP, FID, CLS
- **Accessibilité** : Contraste, navigation clavier, lecteurs d'écran
- **SEO** : Meta tags, structure sémantique, vitesse
- **Sécurité** : HTTPS, en-têtes de sécurité

## 🚀 Déploiement

### URLs des environnements

- **Production** : https://steduplatform.z6.web.core.windows.net/
- **Développement** : https://steduplatformdev.z6.web.core.windows.net/

### Process de déploiement

1. **Développement** : Commit sur `develop` → Déploiement automatique
2. **Production** : Commit sur `main` → Approbation requise → Déploiement

### Rollback

En cas de problème, rollback possible via :
```bash
# Restaurer une version précédente
az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web' \
  --source ./backup-folder
```

## 📈 Monitoring et Observabilité

### Application Insights (optionnel)

```javascript
// Ajouter dans index.html
<script>
  var appInsights = window.appInsights || function(config) {
    // Configuration Application Insights
  };
</script>
```

### Métriques surveillées

- Temps de chargement des pages
- Erreurs JavaScript
- Parcours utilisateur
- Performance réseau

## 🛡️ Sécurité

### Bonnes pratiques implémentées

- **HTTPS** : Forcé pour tous les environnements
- **En-têtes de sécurité** : CSP, HSTS, X-Frame-Options
- **Validation** : HTML et CSS validés
- **Dépendances** : Audit des dépendances externes

### Configuration des en-têtes

```json
{
  "headers": {
    "X-Frame-Options": "DENY",
    "X-Content-Type-Options": "nosniff",
    "Strict-Transport-Security": "max-age=31536000"
  }
}
```

## 📚 Documentation

- [Guide de déploiement](docs/deployment-guide.md)
- [Configuration Azure](docs/azure-setup.md)
- [Tests de qualité](docs/quality-testing.md)
- [Troubleshooting](docs/troubleshooting.md)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push sur la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Standards de code

- **HTML** : HTML5 valide, sémantique
- **CSS** : BEM methodology, CSS Grid/Flexbox
- **JavaScript** : ES6+, pas de jQuery
- **Accessibilité** : WCAG 2.1 AA minimum

## 📝 Changelog

### v1.0.0 (2025-05-27)
- ✨ Version initiale
- 🚀 Pipeline CI/CD complet
- 📱 Design responsive
- ♿ Accessibilité conforme WCAG
- 🔧 Tests automatisés

## 📞 Support

- **Email** : support@eduplatform.com
- **Documentation** : [Wiki du projet](wiki-url)
- **Issues** : [GitHub Issues](issues-url)

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

**Développé avec ❤️ pour démontrer les capacités DevOps avec Azure**
