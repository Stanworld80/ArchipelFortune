#!/bin/bash

# ==============================================================================
# build_deploy.sh - Script de Build et Déploiement pour ArchipelFortune
#
# Ce script gère la compilation, les tests et le déploiement de l'application
# sur différents environnements (dev, staging, prod) et plateformes (web, android).
# Auteur: Stanislas Selle
# Version: 1.1.0
# ==============================================================================

# --- Configuration des Environnements ---
# IDs de projet Firebase
FIREBASE_PROJECT_ID_DEV="archipel-fortune-dev"
FIREBASE_PROJECT_ID_STAGING="archipel-fortune-stg"
FIREBASE_PROJECT_ID_PROD="archipel-fortune-prod"

# Fichiers de configuration Firebase pour le déploiement Hosting/Functions
FIREBASE_CONFIG_FILE_DEV="firebase.dev.json"
FIREBASE_CONFIG_FILE_STAGING="firebase.staging.json"
FIREBASE_CONFIG_FILE_PROD="firebase.prod.json"
TARGET_FIREBASE_JSON_PATH="firebase.json"

# IDs Client Web Google Sign-In par environnement
GOOGLE_SIGNIN_CLIENT_ID_WEB_DEV="83241971458-14tiragdibb39tnm9op5nd6fqnm4ct53.apps.googleusercontent.com"
GOOGLE_SIGNIN_CLIENT_ID_WEB_STAGING="344541548510-k1vncr9ufjii7r3k4425p8sqgq5p47r6.apps.googleusercontent.com"
GOOGLE_SIGNIN_CLIENT_ID_WEB_PROD="48301164525-6lqqh5tc0m0jpsm4ovdpgalosve17a1m.apps.googleusercontent.com"

# Fichiers google-services.json pour Android par environnement
GOOGLE_SERVICES_JSON_DEV_PATH="android/app/google-services.dev.json"
GOOGLE_SERVICES_JSON_STAGING_PATH="android/app/google-services.staging.json"
GOOGLE_SERVICES_JSON_PROD_PATH="android/app/google-services.prod.json"
ANDROID_TARGET_GOOGLE_SERVICES_PATH="android/app/google-services.json"

# IDs d'application Android Firebase par environnement
FIREBASE_ANDROID_APP_ID_DEV="1:1025390075112:android:a3a175d5e0c63cf26bfd5d"
FIREBASE_ANDROID_APP_ID_STAGING="1:590952422810:android:7ffb5edc9c37b3334aae23"
FIREBASE_ANDROID_APP_ID_PROD="1:417958901427:android:afebbbc0aa7ded9b0762c6"

# Groupes de testeurs pour Firebase App Distribution
TESTER_GROUPS_DEV="dev-testers"
TESTER_GROUPS_STAGING="uat-testers"
TESTER_GROUPS_PROD="prod-final-checkers"

# Fichiers de configuration et templates
WEB_INDEX_TEMPLATE_PATH="web/index-template.html"
WEB_INDEX_PATH="web/index.html"
WEB_INDEX_PLACEHOLDER="##GOOGLE_SIGNIN_CLIENT_ID_PLACEHOLDER##"
PUBSPEC_FILE="pubspec.yaml"
# --- Fin de la Configuration ---


# --- Variables de Script ---
ENVIRONMENT="dev"
PLATFORMS=()
BUILD_MODE_STAGING="" # Variable pour le mode de build spécifique à 'staging'
BUILD_ONLY=false
CLEAN_BUILD=true
BYPASS_TESTS=false
SPECIFIC_ANDROID_BUILD=""
VERBOSE_MODE=false
RUN_E2E=false
NO_GIT=false

# L'application Flutter a été générée dans le sous-dossier 'app'
cd app || exit 1


# --- Fonctions ---
print_usage() {
    echo "Usage: ./build_deploy.sh [-e <ENV>] [-m <MODE>] [-p <PLATFORM>] [-a <ANDROID_TYPE>] [--buildonly] [--noclean] [--bypasstest] [--no-git] [-v] [-h]"
    echo ""
    echo "Options:"
    echo "  -e <ENV>                Spécifie l'environnement : 'dev' (défaut), 'staging', ou 'prod'."
    echo "  -m <MODE>               Pour l'environnement 'staging' uniquement : 'debug' (défaut) ou 'release'."
    echo "  -p <PLATFORM>           Spécifie une plateforme : 'web' ou 'android'. Peut être utilisé plusieurs fois."
    echo "                          Par défaut, compile pour web ET android."
    echo "  -a <ANDROID_TYPE>       Pour Android (staging/release et prod uniquement) : 'apk' ou 'aab'. Si omis, construit les deux."
    echo "                          Pour dev, seul l'APK est construit."
    echo "  --buildonly             Compile uniquement, sans déploiement ni opérations Git."
    echo "  --noclean               Désactive 'flutter clean' avant la compilation."
    echo "  --bypasstest            Évite l'exécution des tests unitaires pour 'dev' et 'staging'. Les tests sont obligatoires pour 'prod'."
    echo "  --e2e                   Lance les tests Playwright E2E après le deploy web (dev/staging uniquement)."
    echo "  --no-git                Désactive les opérations Git (commit, tag, push)."
    echo "  -v, --verbose           Active le mode verbeux pour afficher les détails des commandes exécutées."
    echo "  -h, --help              Affiche ce message d'aide."
}

execute_verbose() {
    local cmd_description="$1"; shift
    if [ "$VERBOSE_MODE" = true ]; then
        # shellcheck disable=SC2145
        echo "  - Commande ($cmd_description): $@"
    fi
    "$@"
    return $?
}

# --- Analyse des Arguments ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e) ENVIRONMENT="$2"; shift ;;
        -p) PLATFORMS+=("$2"); shift ;;
        -a) SPECIFIC_ANDROID_BUILD="$2"; shift ;;
        -m|--mode) BUILD_MODE_STAGING="$2"; shift ;;
        --buildonly) BUILD_ONLY=true ;;
        --noclean) CLEAN_BUILD=false ;;
        --bypasstest) BYPASS_TESTS=true ;;
        --e2e) RUN_E2E=true ;;
        --no-git) NO_GIT=true ;;
        -v|--verbose) VERBOSE_MODE=true ;;
        -h|--help) print_usage; exit 0 ;;
        *) echo "Erreur : Paramètre inconnu '$1'"; print_usage; exit 1 ;;
    esac
    shift
done

if [ ${#PLATFORMS[@]} -eq 0 ]; then
    PLATFORMS=("web" "android")
fi

# --- Configuration de l'Environnement de Build ---
if [ "$ENVIRONMENT" == "prod" ]; then
    BUILD_TYPE="release"
elif [ "$ENVIRONMENT" == "staging" ]; then
    if [ "$BUILD_MODE_STAGING" == "release" ]; then
        BUILD_TYPE="release"
    elif [ -z "$BUILD_MODE_STAGING" ] || [ "$BUILD_MODE_STAGING" == "debug" ]; then
        BUILD_TYPE="debug"
    else
        echo "Erreur : Mode de build invalide '$BUILD_MODE_STAGING' pour l'environnement 'staging'. Utilisez 'debug' ou 'release'."
        exit 1
    fi
else # dev
    BUILD_TYPE="debug"
fi

# Ajustement pour le build Android
if [[ "$ENVIRONMENT" == "dev" ]]; then
    if [ "$SPECIFIC_ANDROID_BUILD" == "aab" ]; then
        echo "AVERTISSEMENT : La construction d'AAB est ignorée pour l'environnement 'dev'. Seul l'APK sera construit."
    fi
    # Pour dev, on ne construit que l'apk
    SPECIFIC_ANDROID_BUILD="apk"
fi

# Sélection des variables de configuration en fonction de l'environnement
case "$ENVIRONMENT" in
    dev)
        CURRENT_FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID_DEV"; CURRENT_GOOGLE_SIGNIN_CLIENT_ID_WEB="$GOOGLE_SIGNIN_CLIENT_ID_WEB_DEV"
        CURRENT_GOOGLE_SERVICES_JSON_SOURCE_PATH="$GOOGLE_SERVICES_JSON_DEV_PATH"; CURRENT_FIREBASE_ANDROID_APP_ID="$FIREBASE_ANDROID_APP_ID_DEV"
        CURRENT_TESTER_GROUPS="$TESTER_GROUPS_DEV"; CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH="$FIREBASE_CONFIG_FILE_DEV" ;;
    staging)
        CURRENT_FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID_STAGING"; CURRENT_GOOGLE_SIGNIN_CLIENT_ID_WEB="$GOOGLE_SIGNIN_CLIENT_ID_WEB_STAGING"
        CURRENT_GOOGLE_SERVICES_JSON_SOURCE_PATH="$GOOGLE_SERVICES_JSON_STAGING_PATH"; CURRENT_FIREBASE_ANDROID_APP_ID="$FIREBASE_ANDROID_APP_ID_STAGING"
        CURRENT_TESTER_GROUPS="$TESTER_GROUPS_STAGING"; CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH="$FIREBASE_CONFIG_FILE_STAGING" ;;
    prod)
        CURRENT_FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID_PROD"; CURRENT_GOOGLE_SIGNIN_CLIENT_ID_WEB="$GOOGLE_SIGNIN_CLIENT_ID_WEB_PROD"
        CURRENT_GOOGLE_SERVICES_JSON_SOURCE_PATH="$GOOGLE_SERVICES_JSON_PROD_PATH"; CURRENT_FIREBASE_ANDROID_APP_ID="$FIREBASE_ANDROID_APP_ID_PROD"
        CURRENT_TESTER_GROUPS="$TESTER_GROUPS_PROD"; CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH="$FIREBASE_CONFIG_FILE_PROD" ;;
esac

# --- Affichage de la Configuration ---
echo "=================================================="
echo " Démarrage du processus de Build & Déploiement"
echo "=================================================="
echo "  Environnement : $ENVIRONMENT"
echo "  Mode de Build   : $BUILD_TYPE"
echo "  Plateformes     : ${PLATFORMS[*]}"
if [[ " ${PLATFORMS[*]} " =~ " android " ]]; then
    if [ "$ENVIRONMENT" == "dev" ]; then
        echo "  Artefact Android  : apk"
    else # staging ou prod
        if [ -z "$SPECIFIC_ANDROID_BUILD" ]; then
            echo "  Artefacts Android : apk et aab"
        else
            echo "  Artefact Android  : $SPECIFIC_ANDROID_BUILD"
        fi
    fi
fi
echo "  Déploiement     : $(if $BUILD_ONLY; then echo "Non (buildonly)"; else echo "Oui"; fi)"
echo "  Nettoyage       : $(if $CLEAN_BUILD; then echo "Oui"; else echo "Non"; fi)"
if [ "$BYPASS_TESTS" == true ]; then
    echo "  Tests          : Désactivés (bypass)"
else
    echo "  Tests          : Activés"
fi
echo "  Mode Verbeux    : $VERBOSE_MODE"
echo "--------------------------------------------------"

# --- Logique de Build ---
# 1. Nettoyage (si activé)
if [ "$CLEAN_BUILD" = true ]; then
    echo "-> Étape 1/6 : Nettoyage du projet..."
    execute_verbose "Nettoyage Flutter" flutter clean
    if [ $? -ne 0 ]; then echo "Erreur lors de 'flutter clean'."; exit 1; fi
    echo "Nettoyage terminé."
fi

# 2. Mise à jour de la version
echo "-> Étape 2/6 : Mise à jour de la version..."
VERSION_LINE=$(grep '^version:' pubspec.yaml)
VERSION_NUMBER=$(echo "$VERSION_LINE" | cut -d' ' -f2)
VERSION_NAME=$(echo "$VERSION_NUMBER" | cut -d'+' -f1)
if [[ "$VERSION_NUMBER" == *"+"* ]]; then
    BUILD_NUMBER=$(echo "$VERSION_NUMBER" | cut -d'+' -f2)
else
    BUILD_NUMBER=0
fi
if [ "$NO_GIT" == false ]; then
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    NEW_VERSION="$VERSION_NAME+$NEW_BUILD_NUMBER"
    execute_verbose "Mise à jour de pubspec.yaml" sed -i.bak "s/version: $VERSION_NUMBER/version: $NEW_VERSION/" pubspec.yaml && rm pubspec.yaml.bak
    echo "Version mise à jour dans pubspec.yaml : $NEW_VERSION"
    TAG_NAME="$NEW_VERSION"
else
    echo "Versionnement Git ignoré (via --no-git). Utilisation de la version actuelle: $VERSION_NUMBER"
    TAG_NAME="$VERSION_NUMBER"
    NEW_BUILD_NUMBER="$BUILD_NUMBER"
fi

# 3. Préparation des fichiers de configuration par environnement
echo "-> Étape 3/6 : Préparation des fichiers de configuration..."
if [[ " ${PLATFORMS[*]} " =~ " web " ]]; then
    echo "   - Configuration de 'index.html' pour le web..."
    execute_verbose "Copie du template index.html" cp "$WEB_INDEX_TEMPLATE_PATH" "$WEB_INDEX_PATH"
    execute_verbose "Remplacement du placeholder Google Client ID" sed -i.bak "s|$WEB_INDEX_PLACEHOLDER|$CURRENT_GOOGLE_SIGNIN_CLIENT_ID_WEB|g" "$WEB_INDEX_PATH" && rm "$WEB_INDEX_PATH.bak"
fi
if [[ " ${PLATFORMS[*]} " =~ " android " ]]; then
    echo "   - Configuration de 'google-services.json' pour Android..."
    execute_verbose "Copie de google-services.json" cp "$CURRENT_GOOGLE_SERVICES_JSON_SOURCE_PATH" "$ANDROID_TARGET_GOOGLE_SERVICES_PATH"
fi
echo "Fichiers de configuration prêts."

# 4. Préparation de la signature Android (pour les builds 'release')
if [[ " ${PLATFORMS[*]} " =~ " android " ]] && [ "$BUILD_TYPE" == "release" ]; then
    echo "-> Étape 4/6 : Préparation de la signature Android..."
    KEY_PROPERTIES_SOURCE_FILE="android/key.${ENVIRONMENT}.properties"
    if [ -f "$KEY_PROPERTIES_SOURCE_FILE" ]; then
        execute_verbose "Copie de la configuration de signature" cp "$KEY_PROPERTIES_SOURCE_FILE" "android/key.properties"
        echo "   Configuration de signature pour '$ENVIRONMENT' prête."
    else
        echo "   AVERTISSEMENT : Fichier '$KEY_PROPERTIES_SOURCE_FILE' introuvable. La compilation 'release' pourrait échouer."
    fi
else
     echo "-> Étape 4/6 : Préparation de la signature Android ignorée (non applicable)."
fi

# 5. Exécution des tests unitaires (si nécessaire)
RUN_TESTS=true
if [[ "$BYPASS_TESTS" == true ]]; then
    RUN_TESTS=false
fi

if [ "$RUN_TESTS" = true ]; then
    echo "-> Étape 5/6 : Exécution des tests unitaires..."
    if [ -d "test" ] && [ "$(ls -A test 2>/dev/null)" ]; then
        FLUTTER_TEST_CMD=("flutter" "test")
        if [ "$VERBOSE_MODE" = true ]; then
            FLUTTER_TEST_CMD+=("--reporter" "expanded")
        fi
        execute_verbose "Exécution des tests" "${FLUTTER_TEST_CMD[@]}"
        if [ $? -ne 0 ]; then echo "ERREUR : Les tests unitaires ont échoué. Arrêt du script."; exit 1; fi
        echo "Tests unitaires réussis."
    else
        echo "Dossier 'test' manquant ou vide. Tests unitaires ignorés."
    fi
else
    echo "-> Étape 5/6 : Tests unitaires ignorés (via --bypasstest)."
fi

# 6. Compilation pour chaque plateforme
echo "-> Étape 6/6 : Compilation des plateformes..."
for PLATFORM in "${PLATFORMS[@]}"; do
    echo "   -> Lancement de la compilation pour : $PLATFORM"
    if [ "$PLATFORM" == "web" ]; then
        execute_verbose "Build Web" flutter build web --web-renderer html --"$BUILD_TYPE" --dart-define=APP_ENV="$ENVIRONMENT" --dart-define=SUPER_ADMIN_EMAIL="stanworld@gmail.com"
        if [ $? -ne 0 ]; then echo "ERREUR : La compilation web a échoué."; exit 1; fi
        echo "   Compilation web terminée avec succès."
    elif [ "$PLATFORM" == "android" ]; then
        if [ -z "$SPECIFIC_ANDROID_BUILD" ] || [ "$SPECIFIC_ANDROID_BUILD" == "apk" ]; then
            echo "      -> Construction de l'APK Android..."
            execute_verbose "Build APK" flutter build apk --"$BUILD_TYPE" --dart-define=APP_ENV="$ENVIRONMENT" --build-name "$VERSION_NAME" --build-number "$NEW_BUILD_NUMBER"
            if [ $? -ne 0 ]; then echo "ERREUR : La compilation APK a échoué."; exit 1; fi
            execute_verbose "Renommage APK" mv "build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk" "build/app/outputs/flutter-apk/ArchipelFortune-$TAG_NAME.apk"
            echo "      APK construit : build/app/outputs/flutter-apk/ArchipelFortune-$TAG_NAME.apk"
        fi
        if [[ "$BUILD_TYPE" == "release" && (-z "$SPECIFIC_ANDROID_BUILD" || "$SPECIFIC_ANDROID_BUILD" == "aab") ]]; then
            echo "      -> Construction de l'Android App Bundle (AAB)..."
            execute_verbose "Build AAB" flutter build appbundle --"$BUILD_TYPE" --dart-define=APP_ENV="$ENVIRONMENT" --build-name "$VERSION_NAME" --build-number "$NEW_BUILD_NUMBER"
            if [ $? -ne 0 ]; then echo "ERREUR : La compilation AAB a échoué."; exit 1; fi
            execute_verbose "Renommage AAB" mv "build/app/outputs/bundle/$BUILD_TYPE/app-$BUILD_TYPE.aab" "build/app/outputs/bundle/$BUILD_TYPE/ArchipelFortune-$TAG_NAME.aab"
            echo "      AAB construit : build/app/outputs/bundle/$BUILD_TYPE/ArchipelFortune-$TAG_NAME.aab"
        fi
    else
        echo "AVERTISSEMENT : Plateforme non supportée '$PLATFORM'."
    fi
done

echo ""
echo "Compilation terminée avec succès pour toutes les plateformes."
echo "=================================================="

# --- Opérations Git et Déploiement ---
if $BUILD_ONLY; then
    echo "Mode 'buildonly' activé. Le script s'arrête ici."
    exit 0
fi

echo ""
echo ">>> Démarrage des opérations Git et du Déploiement <<<"
echo "--------------------------------------------------"

# 1. Configuration du fichier firebase.json pour le déploiement
echo "-> Étape 1/3 : Configuration de Firebase pour le déploiement..."
FIREBASE_JSON_COPIED=false
if [ -f "$CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH" ]; then
    execute_verbose "Copie de la configuration Firebase" cp "$CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH" "$TARGET_FIREBASE_JSON_PATH"
    if [ $? -ne 0 ]; then echo "Erreur: Copie de '$CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH' vers '$TARGET_FIREBASE_JSON_PATH' échouée."; exit 1; fi
    echo "   '$TARGET_FIREBASE_JSON_PATH' configuré pour l'environnement '$ENVIRONMENT'."
    FIREBASE_JSON_COPIED=true
else
    echo "   AVERTISSEMENT : '$CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH' introuvable. Utilisation du fichier '$TARGET_FIREBASE_JSON_PATH' existant par défaut."
fi

# 2. Opérations Git
echo "-> Étape 2/3 : Opérations Git (commit et tag)..."
if [ "$NO_GIT" == true ]; then
    echo "   Opérations Git ignorées (via --no-git)."
elif git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    execute_verbose "Ajout pubspec.yaml" git add pubspec.yaml
    execute_verbose "Commit version" git commit -m "chore: Incrémentation de la version à $TAG_NAME"
    
    # Vérifie si le repo a un remote origin avant de push
    if git remote | grep -q "origin"; then
        execute_verbose "Push commit" git push
        if [ $? -eq 0 ]; then
            execute_verbose "Création du tag" git tag -a "$TAG_NAME" -m "Release $TAG_NAME"
            execute_verbose "Push du tag" git push origin "$TAG_NAME"
            if [ $? -eq 0 ]; then 
                echo "   pubspec.yaml poussé et tag '$TAG_NAME' créé avec succès."
            else
                echo "   AVERTISSEMENT : 'git push origin $TAG_NAME' a échoué. Le tag a été créé localement."
            fi
        else
            echo "   AVERTISSEMENT : 'git push' a échoué. Le commit a été créé localement."
        fi
    else
        echo "   AVERTISSEMENT : Aucun 'remote' configuré. Commit créé localement seulement."
    fi
else
    echo "   Dossier de projet n'est pas un dépôt Git. Les opérations Git sont ignorées."
fi

# 3. Logique de déploiement
echo "--> Étape 3/3 : Déploiement..."
if [[ " ${PLATFORMS[*]} " =~ " web " ]]; then
    if [ "$ENVIRONMENT" == "prod" ]; then
        DEPLOY_TARGETS="hosting,firestore"
    else
        DEPLOY_TARGETS="hosting,functions,firestore"
    fi
    echo "   - Déploiement Firebase [$DEPLOY_TARGETS] (Projet: $CURRENT_FIREBASE_PROJECT_ID)..."
    execute_verbose "Déploiement Firebase" firebase deploy --only "$DEPLOY_TARGETS" -P "$CURRENT_FIREBASE_PROJECT_ID"
    if [ $? -ne 0 ]; then echo "ERREUR : Le déploiement Firebase a échoué."; else echo "   Déploiement réussi."; fi
fi

if [[ " ${PLATFORMS[*]} " =~ " android " ]]; then
    if [[ "$ENVIRONMENT" == "dev" || "$ENVIRONMENT" == "staging" ]]; then
        ANDROID_ARTIFACT_PATH_FOR_DEPLOY="build/app/outputs/flutter-apk/ArchipelFortune-$TAG_NAME.apk"
        if [ -f "$ANDROID_ARTIFACT_PATH_FOR_DEPLOY" ]; then
            echo "   - Déploiement Android APK vers Firebase App Distribution (Projet: $CURRENT_FIREBASE_PROJECT_ID)..."
            execute_verbose "Distribution App Android" firebase appdistribution:distribute "$ANDROID_ARTIFACT_PATH_FOR_DEPLOY" --app "$CURRENT_FIREBASE_ANDROID_APP_ID" --project "$CURRENT_FIREBASE_PROJECT_ID" --release-notes "Build $TAG_NAME pour $ENVIRONMENT ($BUILD_TYPE)" --groups "$CURRENT_TESTER_GROUPS"
            if [ $? -ne 0 ]; then echo "ERREUR : La distribution Android a échoué."; else echo "   Distribution Android réussie."; fi
        else
            echo "   AVERTISSEMENT : Fichier APK non trouvé pour la distribution. Build non effectué pour l'APK ?"
        fi
    elif [ "$ENVIRONMENT" == "prod" ]; then
        echo "   - Déploiement Android pour 'prod' : l'artefact AAB est prêt pour une publication manuelle."
        echo "     Chemin de l'AAB : build/app/outputs/bundle/release/ArchipelFortune-$TAG_NAME.aab"
    fi
fi

# --- Tests E2E Playwright (dev/staging uniquement) ---
if [ "$RUN_E2E" = true ] && [[ " ${PLATFORMS[*]} " =~ " web " ]]; then
    if [ "$ENVIRONMENT" == "prod" ]; then
        echo "AVERTISSEMENT : Les tests E2E ne sont pas autorisés en prod. Ignoré."
    else
        echo "--> Tests E2E Playwright..."
        E2E_DIR="$(dirname "$(pwd)")/tests_e2e"
        if [ -d "$E2E_DIR" ]; then
            case "$ENVIRONMENT" in
                dev)     E2E_BASE_URL="https://archipel-fortune-dev.web.app" ;;
                staging) E2E_BASE_URL="https://archipel-fortune-stg.web.app" ;;
            esac
            echo "   Target URL: $E2E_BASE_URL"
            PLAYWRIGHT_BASE_URL="$E2E_BASE_URL" npx --prefix "$E2E_DIR" playwright test
            if [ $? -ne 0 ]; then
                echo "AVERTISSEMENT : Les tests E2E ont échoué. Consultez tests_e2e/playwright-report/"
            else
                echo "   Tests E2E réussis."
            fi
        else
            echo "   AVERTISSEMENT : Dossier tests_e2e/ introuvable. Tests E2E ignorés."
        fi
    fi
fi

# --- Nettoyage Final ---
echo ""
echo ">>> Nettoyage Final <<<"
if [ "$FIREBASE_JSON_COPIED" = true ] && [ "$CURRENT_FIREBASE_CONFIG_FILE_SOURCE_PATH" != "$TARGET_FIREBASE_JSON_PATH" ]; then
    execute_verbose "Nettoyage de firebase.json" rm -f "$TARGET_FIREBASE_JSON_PATH"
    echo " - Fichier temporaire 'firebase.json' nettoyé."
else
    echo " - Conservation de 'firebase.json' (fichier principal ou non-temporaire)."
fi

if [[ " ${PLATFORMS[*]} " =~ " android " ]] && [ "$BUILD_TYPE" == "release" ] && [ -f "android/key.properties" ]; then
    execute_verbose "Suppression de key.properties" rm "android/key.properties"
    echo " - Fichier temporaire 'android/key.properties' nettoyé."
fi

echo ""
echo "=================================================="
echo "Script terminé."
echo "=================================================="

