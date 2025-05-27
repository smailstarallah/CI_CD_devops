# Guide de Déploiement EduPlatform

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Configuration initiale](#configuration-initiale)
- [Déploiement automatisé avec Azure DevOps](#déploiement-automatisé-avec-azure-devops)
- [Déploiement manuel](#déploiement-manuel)
- [Tests et validation](#tests-et-validation)
- [Troubleshooting](#troubleshooting)

## 🔧 Prérequis

### Comptes et services requis

1. **Compte Azure** avec souscription active
2. **Organisation Azure DevOps** 
3. **Repository Git** (Azure Repos, GitHub, ou GitLab)

### Outils locaux

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Node.js (pour les tests)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Git
sudo apt-get install git
```

### Vérification des prérequis

```bash
# Vérifier Azure CLI
az --version

# Se connecter à Azure
az login

# Vérifier la souscription active
az account show

# Vérifier Node.js
node --version
npm --version
```

## ⚙️ Configuration initiale

### 1. Créer les ressources Azure

#### Méthode 1: Script automatisé

```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Configurer les ressources
./deploy.sh setup
```

#### Méthode 2: Commandes manuelles

```bash
# Variables
RESOURCE_GROUP="rg-eduplatform"
LOCATION="West Europe"
STORAGE_PROD="steduplatform"
STORAGE_DEV="steduplatformdev"

# Créer le groupe de ressources
az group create \
  --name $RESOURCE_GROUP \
  --location "$LOCATION"

# Créer les storage accounts
az storage account create \
  --name $STORAGE_PROD \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

az storage account create \
  --name $STORAGE_DEV \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

# Activer les sites web statiques
az storage blob service-properties update \
  --account-name $STORAGE_PROD \
  --static-website \
  --index-document index.html \
  --404-document 404.html

az storage blob service-properties update \
  --account-name $STORAGE_DEV \
  --static-website \
  --index-document index.html \
  --404-document 404.html
```

### 2. Obtenir les URLs des sites

```bash
# URL de production
az storage account show \
  --name steduplatform \
  --query "primaryEndpoints.web" \
  --output tsv

# URL de développement
az storage account show \
  --name steduplatformdev \
  --query "primaryEndpoints.web" \
  --output tsv
```

## 🚀 Déploiement automatisé avec Azure DevOps

### 1. Configuration du projet Azure DevOps

1. **Créer un nouveau projet**
   - Aller sur https://dev.azure.com
   - Créer un nouveau projet "EduPlatform"
   - Choisir Git comme système de contrôle de version

2. **Importer le code**
   ```bash
   # Cloner le repository
   git clone <your-azure-devops-repo-url>
   cd your-project
   
   # Ajouter les fichiers
   git add .
   git commit -m "Initial commit"
   git push origin main
   ```

### 2. Créer la Service Connection

1. Aller dans **Project Settings** > **Service connections**
2. Créer une nouvelle connection **Azure Resource Manager**
3. Sélectionner **Service principal (automatic)**
4. Choisir votre souscription et groupe de ressources
5. Nommer la connection `azure-connection`

### 3. Configurer les variables

1. Aller dans **Pipelines** > **Library**
2. Créer un **Variable Group** nommé `EduPlatform-Variables`
3. Ajouter les variables :

```yaml
azureSubscription: 'azure-connection'
resourceGroupName: 'rg-eduplatform'
storageAccountName: 'steduplatform'
storageAccountNameDev: 'steduplatformdev'
location: 'West Europe'
```

### 4. Créer les pipelines

#### Pipeline CI/CD principal

1. Aller dans **Pipelines** > **Create Pipeline**
2. Sélectionner votre repository
3. Choisir **Existing Azure Pipelines YAML file**
4. Sélectionner `/azure-pipelines.yml`
5. **Save and run**

#### Pipeline de tests de qualité

1. Créer un nouveau pipeline
2. Sélectionner `/azure-quality-pipeline.yml`
3. Configurer pour **Manual trigger only**

### 5. Configurer les environnements

1. Aller dans **Pipelines** > **Environments**
2. Créer l'environnement `development`
3. Créer l'environnement `production`
4. Configurer les **approvals** pour production :
   - Ajouter des **reviewers**
   - Configurer les **branch policies**

## 🛠️ Déploiement manuel

### Déploiement en développement

```bash
# Méthode 1: Script automatisé
./deploy.sh deploy-dev

# Méthode 2: Azure CLI
az storage blob upload-batch \
  --account-name steduplatformdev \
  --destination '$web' \
  --source . \
  --pattern "*.html" \
  --overwrite

az storage blob upload-batch \
  --account-name steduplatformdev \
  --destination '$web/css' \
  --source ./css \
  --overwrite

az storage blob upload-batch \
  --account-name steduplatformdev \
  --destination '$web/js' \
  --source ./js \
  --overwrite
```

### Déploiement en production

```bash
# Script automatisé (avec confirmation)
./deploy.sh deploy-prod

# Ou manuellement
az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web' \
  --source . \
  --pattern "*.html" \
  --overwrite

az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web/css' \
  --source ./css \
  --overwrite

az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web/js' \
  --source ./js \
  --overwrite
```

## 🧪 Tests et validation

### Tests automatisés

```bash
# Installer les dépendances de test
npm install

# Exécuter tous les tests
npm test

# Tests spécifiques
npm run test:html      # Validation HTML
npm run test:css       # Validation CSS
npm run test:js        # Linting JavaScript
npm run test:accessibility  # Tests d'accessibilité
npm run test:performance   # Tests de performance
```

### Tests manuels

#### Validation HTML
```bash
html-validate index.html
```

#### Tests d'accessibilité
```bash
# Démarrer un serveur local
npm run serve

# Tester l'accessibilité
pa11y http://localhost:8000 --standard WCAG2AA
```

#### Tests de performance
```bash
# Lighthouse
lighthouse http://localhost:8000 --output json

# Test de vitesse simple
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://steduplatform.z6.web.core.windows.net/
```

### Vérification post-déploiement

```bash
# Vérifier que le site est accessible
curl -I https://steduplatform.z6.web.core.windows.net/

# Vérifier les en-têtes de sécurité
curl -I https://steduplatform.z6.web.core.windows.net/ | grep -E "(X-Frame-Options|Content-Security-Policy|Strict-Transport-Security)"

# Test de performance simple
time curl -s https://steduplatform.z6.web.core.windows.net/ > /dev/null
```

## 🔧 Configuration avancée

### CDN (optionnel)

```bash
# Créer un profil CDN
az cdn profile create \
  --name cdn-eduplatform \
  --resource-group rg-eduplatform \
  --sku Standard_Microsoft

# Créer un endpoint CDN
STORAGE_ENDPOINT=$(az storage account show \
  --name steduplatform \
  --query "primaryEndpoints.web" \
  --output tsv | sed 's|https://||' | sed 's|/||')

az cdn endpoint create \
  --name eduplatform \
  --profile-name cdn-eduplatform \
  --resource-group rg-eduplatform \
  --origin $STORAGE_ENDPOINT

# Configurer HTTPS
az cdn endpoint update \
  --name eduplatform \
  --profile-name cdn-eduplatform \
  --resource-group rg-eduplatform \
  --https-redirect Enabled
```

### Domaine personnalisé

```bash
# Ajouter un domaine personnalisé
az cdn endpoint add-custom-domain \
  --endpoint-name eduplatform \
  --profile-name cdn-eduplatform \
  --resource-group rg-eduplatform \
  --custom-domain-name www-eduplatform-com \
  --hostname www.eduplatform.com

# Activer HTTPS pour le domaine personnalisé
az cdn endpoint enable-custom-https \
  --endpoint-name eduplatform \
  --profile-name cdn-eduplatform \
  --resource-group rg-eduplatform \
  --custom-domain-name www-eduplatform-com
```

## 📊 Monitoring et logs

### Application Insights (optionnel)

```bash
# Créer une ressource Application Insights
az monitor app-insights component create \
  --app ai-eduplatform \
  --location "West Europe" \
  --resource-group rg-eduplatform \
  --application-type web

# Obtenir la clé d'instrumentation
az monitor app-insights component show \
  --app ai-eduplatform \
  --resource-group rg-eduplatform \
  --query "instrumentationKey" \
  --output tsv
```

### Logs de déploiement

```bash
# Voir les logs du storage account
az storage account show \
  --name steduplatform \
  --resource-group rg-eduplatform

# Voir les blobs uploadés
az storage blob list \
  --account-name steduplatform \
  --container-name '$web' \
  --output table
```

## 🔄 Rollback

### Rollback automatique via Azure DevOps

1. Aller dans **Pipelines** > **Releases**
2. Sélectionner une release précédente
3. Cliquer sur **Redeploy**

### Rollback manuel

```bash
# Sauvegarder la version actuelle
mkdir backup-$(date +%Y%m%d-%H%M%S)
az storage blob download-batch \
  --account-name steduplatform \
  --source '$web' \
  --destination ./backup-$(date +%Y%m%d-%H%M%S)

# Restaurer depuis une sauvegarde
az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web' \
  --source ./path-to-previous-version \
  --overwrite
```

## 🚨 Troubleshooting

### Problèmes courants

#### 1. Erreur d'authentification Azure
```bash
# Rafraîchir la connexion
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
```

#### 2. Storage account introuvable
```bash
# Vérifier l'existence
az storage account show --name steduplatform --resource-group rg-eduplatform

# Recréer si nécessaire
az storage account create \
  --name steduplatform \
  --resource-group rg-eduplatform \
  --location "West Europe" \
  --sku Standard_LRS \
  --kind StorageV2
```

#### 3. Site web statique non activé
```bash
# Réactiver
az storage blob service-properties update \
  --account-name steduplatform \
  --static-website \
  --index-document index.html \
  --404-document 404.html
```

#### 4. Pipeline qui échoue
- Vérifier les **service connections**
- Contrôler les **variables** dans la library
- Examiner les **logs** détaillés du pipeline
- Vérifier les **permissions** Azure

### Logs et debugging

```bash
# Logs Azure CLI avec debug
az storage blob upload-batch \
  --account-name steduplatform \
  --destination '$web' \
  --source . \
  --debug

# Vérifier la connectivité
nslookup steduplatform.z6.web.core.windows.net
ping steduplatform.z6.web.core.windows.net
```

### Support

- **Documentation Azure** : https://docs.microsoft.com/azure/
- **Azure DevOps Docs** : https://docs.microsoft.com/azure/devops/
- **Azure CLI Reference** : https://docs.microsoft.com/cli/azure/

---

*Ce guide couvre les aspects principaux du déploiement. Pour des configurations spécifiques, consultez la documentation officielle Azure.*
