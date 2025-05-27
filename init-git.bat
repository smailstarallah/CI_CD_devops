@echo off
REM Script d'initialisation Git pour Windows
REM Ce script configure le repository Git et prépare le premier commit

echo [INFO] Initialisation du repository Git pour EduPlatform...

REM Vérifier si Git est installé
git --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git n'est pas installé. Veuillez l'installer d'abord.
    exit /b 1
)

REM Initialiser le repository si pas déjà fait
if not exist ".git" (
    echo [INFO] Initialisation du repository Git...
    git init
    echo [SUCCESS] Repository Git initialisé
) else (
    echo [WARNING] Repository Git déjà existant
)

REM Configuration Git optionnelle
set /p "configure=Voulez-vous configurer votre nom d'utilisateur Git ? (y/N): "
if /i "%configure%"=="y" (
    set /p "git_username=Nom d'utilisateur: "
    set /p "git_email=Email: "
    git config user.name "%git_username%"
    git config user.email "%git_email%"
    echo [SUCCESS] Configuration Git mise à jour
)

REM Ajouter tous les fichiers
echo [INFO] Ajout des fichiers au repository...
git add .

REM Vérifier le statut
echo [INFO] Statut du repository:
git status

REM Premier commit
git log --oneline >nul 2>&1
if errorlevel 1 (
    echo [INFO] Création du commit initial...
    git commit -m "Initial commit: EduPlatform v1.0.0"
    echo [SUCCESS] Commit initial créé
) else (
    echo [WARNING] Des commits existent déjà
)

REM Créer les branches
echo [INFO] Création des branches...
git show-ref --verify --quiet refs/heads/develop >nul 2>&1
if errorlevel 1 (
    git checkout -b develop
    echo [SUCCESS] Branche 'develop' créée
    git checkout main
) else (
    echo [WARNING] Branche 'develop' existe déjà
)

REM Afficher les branches
echo [INFO] Branches disponibles:
git branch -a

echo.
echo === PROCHAINES ÉTAPES ===
echo.
echo 1. Créer un repository sur votre plateforme Git préférée:
echo    - Azure DevOps: https://dev.azure.com
echo    - GitHub: https://github.com
echo    - GitLab: https://gitlab.com
echo.
echo 2. Ajouter l'origine remote:
echo    git remote add origin ^<URL_DE_VOTRE_REPOSITORY^>
echo.
echo 3. Pousser le code:
echo    git push -u origin main
echo    git push -u origin develop
echo.
echo 4. Configurer Azure DevOps:
echo    - Créer les Service Connections
echo    - Configurer les Variables Groups
echo    - Créer les Pipelines
echo.
echo 5. Lancer le déploiement:
echo    deploy.sh setup          # Créer les ressources Azure
echo    deploy.sh deploy-dev     # Déployer en développement
echo.
echo [SUCCESS] Initialisation terminée !
echo [INFO] Repository prêt pour le développement et le déploiement

pause
