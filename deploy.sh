#!/bin/bash

# Script de déploiement pour EduPlatform
# Ce script configure et déploie l'application sur Azure Storage

set -e  # Arrêter en cas d'erreur

# Configuration des couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration par défaut
RESOURCE_GROUP="rg-eduplatform"
LOCATION="West Europe"
STORAGE_ACCOUNT_PROD="steduplatform"
STORAGE_ACCOUNT_DEV="steduplatformdev"
CDN_PROFILE="cdn-eduplatform"
CDN_ENDPOINT="eduplatform"

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] COMMAND

Commands:
    setup       - Configure les ressources Azure
    deploy-dev  - Déploie en environnement de développement
    deploy-prod - Déploie en environnement de production
    test        - Exécute les tests de validation
    cleanup     - Supprime toutes les ressources

Options:
    -g, --resource-group NAME    Nom du groupe de ressources (défaut: $RESOURCE_GROUP)
    -l, --location LOCATION      Région Azure (défaut: $LOCATION)
    -h, --help                   Affiche cette aide

Examples:
    $0 setup
    $0 deploy-dev
    $0 deploy-prod
    $0 test
EOF
}

# Vérifier si Azure CLI est installé
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI n'est pas installé. Veuillez l'installer depuis https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Vérifier si connecté
    if ! az account show &> /dev/null; then
        log_error "Vous n'êtes pas connecté à Azure. Exécutez 'az login' d'abord."
        exit 1
    fi
    
    log_success "Azure CLI configuré et connecté"
}

# Configuration initiale des ressources Azure
setup_azure_resources() {
    log_info "Configuration des ressources Azure..."
    
    # Créer le groupe de ressources
    log_info "Création du groupe de ressources: $RESOURCE_GROUP"
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output table
    
    # Créer le storage account de production
    log_info "Création du storage account de production: $STORAGE_ACCOUNT_PROD"
    az storage account create \
        --name "$STORAGE_ACCOUNT_PROD" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --output table
    
    # Créer le storage account de développement
    log_info "Création du storage account de développement: $STORAGE_ACCOUNT_DEV"
    az storage account create \
        --name "$STORAGE_ACCOUNT_DEV" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --output table
    
    # Activer le site web statique pour la production
    log_info "Activation du site web statique (production)"
    az storage blob service-properties update \
        --account-name "$STORAGE_ACCOUNT_PROD" \
        --static-website \
        --index-document index.html \
        --404-document 404.html
    
    # Activer le site web statique pour le développement
    log_info "Activation du site web statique (développement)"
    az storage blob service-properties update \
        --account-name "$STORAGE_ACCOUNT_DEV" \
        --static-website \
        --index-document index.html \
        --404-document 404.html
    
    # Obtenir les URLs des sites web
    PROD_URL=$(az storage account show \
        --name "$STORAGE_ACCOUNT_PROD" \
        --query "primaryEndpoints.web" \
        --output tsv)
    
    DEV_URL=$(az storage account show \
        --name "$STORAGE_ACCOUNT_DEV" \
        --query "primaryEndpoints.web" \
        --output tsv)
    
    log_success "Configuration terminée !"
    log_info "URL de production: $PROD_URL"
    log_info "URL de développement: $DEV_URL"
}

# Déploiement en environnement de développement
deploy_development() {
    log_info "Déploiement en environnement de développement..."
    
    # Vérifier que les fichiers existent
    if [ ! -f "index.html" ]; then
        log_error "index.html introuvable. Assurez-vous d'être dans le bon répertoire."
        exit 1
    fi
    
    # Upload des fichiers
    log_info "Upload des fichiers vers le storage de développement..."
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_DEV" \
        --destination '$web' \
        --source . \
        --pattern "*.html" \
        --overwrite \
        --output table
    
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_DEV" \
        --destination '$web/css' \
        --source ./css \
        --overwrite \
        --output table
    
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_DEV" \
        --destination '$web/js' \
        --source ./js \
        --overwrite \
        --output table
    
    # Obtenir l'URL
    DEV_URL=$(az storage account show \
        --name "$STORAGE_ACCOUNT_DEV" \
        --query "primaryEndpoints.web" \
        --output tsv)
    
    log_success "Déploiement en développement terminé !"
    log_info "Site accessible à: $DEV_URL"
    
    # Test de santé basique
    log_info "Test de santé du site..."
    if curl -s -f "$DEV_URL" > /dev/null; then
        log_success "✅ Site accessible"
    else
        log_warning "⚠️ Le site pourrait ne pas être encore accessible"
    fi
}

# Déploiement en production
deploy_production() {
    log_warning "⚠️ Déploiement en PRODUCTION"
    read -p "Êtes-vous sûr de vouloir déployer en production ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Déploiement annulé"
        exit 0
    fi
    
    log_info "Déploiement en environnement de production..."
    
    # Vérifier que les fichiers existent
    if [ ! -f "index.html" ]; then
        log_error "index.html introuvable. Assurez-vous d'être dans le bon répertoire."
        exit 1
    fi
    
    # Upload des fichiers
    log_info "Upload des fichiers vers le storage de production..."
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_PROD" \
        --destination '$web' \
        --source . \
        --pattern "*.html" \
        --overwrite \
        --output table
    
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_PROD" \
        --destination '$web/css' \
        --source ./css \
        --overwrite \
        --output table
    
    az storage blob upload-batch \
        --account-name "$STORAGE_ACCOUNT_PROD" \
        --destination '$web/js' \
        --source ./js \
        --overwrite \
        --output table
    
    # Obtenir l'URL
    PROD_URL=$(az storage account show \
        --name "$STORAGE_ACCOUNT_PROD" \
        --query "primaryEndpoints.web" \
        --output tsv)
    
    log_success "Déploiement en production terminé !"
    log_info "Site accessible à: $PROD_URL"
    
    # Test de santé
    log_info "Test de santé du site..."
    if curl -s -f "$PROD_URL" > /dev/null; then
        log_success "✅ Site accessible"
    else
        log_warning "⚠️ Le site pourrait ne pas être encore accessible"
    fi
    
    # Optionnel: Purger le CDN si configuré
    # log_info "Purge du cache CDN..."
    # az cdn endpoint purge \
    #     --resource-group "$RESOURCE_GROUP" \
    #     --name "$CDN_ENDPOINT" \
    #     --profile-name "$CDN_PROFILE" \
    #     --content-paths "/*"
}

# Tests de validation
run_tests() {
    log_info "Exécution des tests de validation..."
    
    # Test HTML
    if command -v html-validate &> /dev/null; then
        log_info "Validation HTML..."
        if html-validate *.html; then
            log_success "✅ HTML valide"
        else
            log_error "❌ Erreurs de validation HTML"
        fi
    else
        log_warning "html-validate non installé, validation HTML ignorée"
    fi
    
    # Test CSS
    if command -v stylelint &> /dev/null; then
        log_info "Validation CSS..."
        if stylelint "css/**/*.css"; then
            log_success "✅ CSS valide"
        else
            log_error "❌ Erreurs de validation CSS"
        fi
    else
        log_warning "stylelint non installé, validation CSS ignorée"
    fi
    
    # Test des liens
    log_info "Vérification des fichiers requis..."
    required_files=("index.html" "css/style.css" "css/responsive.css" "js/script.js")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_success "✅ $file"
        else
            log_error "❌ $file manquant"
        fi
    done
}

# Nettoyage des ressources
cleanup_resources() {
    log_warning "⚠️ ATTENTION: Cette action supprimera TOUTES les ressources"
    read -p "Êtes-vous sûr de vouloir supprimer toutes les ressources ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Nettoyage annulé"
        exit 0
    fi
    
    log_info "Suppression du groupe de ressources: $RESOURCE_GROUP"
    az group delete \
        --name "$RESOURCE_GROUP" \
        --yes \
        --no-wait
    
    log_success "Nettoyage lancé (peut prendre quelques minutes)"
}

# Parsing des arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        setup)
            COMMAND="setup"
            shift
            ;;
        deploy-dev)
            COMMAND="deploy-dev"
            shift
            ;;
        deploy-prod)
            COMMAND="deploy-prod"
            shift
            ;;
        test)
            COMMAND="test"
            shift
            ;;
        cleanup)
            COMMAND="cleanup"
            shift
            ;;
        *)
            log_error "Option inconnue: $1"
            show_help
            exit 1
            ;;
    esac
done

# Vérifier Azure CLI
check_azure_cli

# Exécuter la commande
case $COMMAND in
    setup)
        setup_azure_resources
        ;;
    deploy-dev)
        deploy_development
        ;;
    deploy-prod)
        deploy_production
        ;;
    test)
        run_tests
        ;;
    cleanup)
        cleanup_resources
        ;;
    *)
        log_error "Commande requise"
        show_help
        exit 1
        ;;
esac
