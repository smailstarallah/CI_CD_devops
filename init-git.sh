#!/bin/bash

# Script d'initialisation Git pour EduPlatform
# Ce script configure le repository Git et prépare le premier commit

set -e

# Configuration des couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier si Git est installé
if ! command -v git &> /dev/null; then
    echo "Git n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

log_info "Initialisation du repository Git pour EduPlatform..."

# Initialiser le repository si pas déjà fait
if [ ! -d ".git" ]; then
    log_info "Initialisation du repository Git..."
    git init
    log_success "Repository Git initialisé"
else
    log_warning "Repository Git déjà existant"
fi

# Configurer Git (optionnel)
read -p "Voulez-vous configurer votre nom d'utilisateur Git ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Nom d'utilisateur: " git_username
    read -p "Email: " git_email
    git config user.name "$git_username"
    git config user.email "$git_email"
    log_success "Configuration Git mise à jour"
fi

# Ajouter tous les fichiers
log_info "Ajout des fichiers au repository..."
git add .

# Vérifier le statut
log_info "Statut du repository:"
git status

# Premier commit
if [ -z "$(git log --oneline 2>/dev/null)" ]; then
    log_info "Création du commit initial..."
    git commit -m "Initial commit: EduPlatform v1.0.0

✨ Features:
- Modern responsive e-learning platform
- Complete Azure DevOps CI/CD pipeline  
- HTML5/CSS3/JavaScript implementation
- Accessibility compliance (WCAG 2.1 AA)
- Performance optimized
- Quality gates with Lighthouse and Pa11y
- Azure Storage static website hosting
- Development and production environments

🚀 Deployment:
- Automated CI/CD with Azure DevOps
- Quality testing pipeline
- Manual deployment scripts
- Comprehensive documentation

📚 Documentation:
- Complete README with setup instructions
- Deployment guide
- Azure configuration guide
- Quality testing procedures"

    log_success "Commit initial créé"
else
    log_warning "Des commits existent déjà"
fi

# Créer les branches
log_info "Création des branches..."

# Branche develop
if ! git show-ref --verify --quiet refs/heads/develop; then
    git checkout -b develop
    log_success "Branche 'develop' créée"
    git checkout main
else
    log_warning "Branche 'develop' existe déjà"
fi

# Afficher les branches
log_info "Branches disponibles:"
git branch -a

# Instructions pour ajouter un remote
echo ""
log_info "=== PROCHAINES ÉTAPES ==="
echo ""
echo "1. Créer un repository sur votre plateforme Git préférée:"
echo "   - Azure DevOps: https://dev.azure.com"
echo "   - GitHub: https://github.com"
echo "   - GitLab: https://gitlab.com"
echo ""
echo "2. Ajouter l'origine remote:"
echo "   git remote add origin <URL_DE_VOTRE_REPOSITORY>"
echo ""
echo "3. Pousser le code:"
echo "   git push -u origin main"
echo "   git push -u origin develop"
echo ""
echo "4. Configurer Azure DevOps:"
echo "   - Créer les Service Connections"
echo "   - Configurer les Variables Groups"
echo "   - Créer les Pipelines"
echo ""
echo "5. Lancer le déploiement:"
echo "   ./deploy.sh setup    # Créer les ressources Azure"
echo "   ./deploy.sh deploy-dev    # Déployer en développement"
echo ""

log_success "Initialisation terminée !"
log_info "Repository prêt pour le développement et le déploiement"
