<#
.SYNOPSIS
    Build and Deploy script for ArchipelFortune (Windows / local dev).

.DESCRIPTION
    Gère la compilation, les tests et le déploiement de l'application sur
    différents environnements (dev, staging, prod) et plateformes (web, android).
    Les tests E2E Playwright ne s'exécutent que pour dev et staging.

.PARAMETER Environment
    'dev' (défaut), 'staging', ou 'prod'.

.PARAMETER Platform
    'web' (défaut), 'android', ou 'all'.

.PARAMETER BuildMode
    'debug', 'profile', ou 'release'. Déduit de l'environnement si omis.

.PARAMETER RunE2E
    Lance les tests Playwright E2E après le build web (dev/staging uniquement).

.EXAMPLE
    .\build_deploy.ps1 -Environment staging -Platform web -RunE2E
#>
param(
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',

    [ValidateSet('web', 'android', 'all')]
    [string]$Platform = 'web',

    [ValidateSet('debug', 'profile', 'release')]
    [string]$BuildMode = '',

    [switch]$NoDeploy,
    [switch]$NoClean,
    [switch]$BypassTest,
    [switch]$NoGit,
    [switch]$RunE2E
)

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$Config = @{
    dev     = @{
        ProjectId          = 'archipel-fortune-dev'
        AndroidAppId       = '1:83241971458:android:dde10259edb60d45711c1b'
        GoogleSignInClientId = '83241971458-14tiragdibb39tnm9op5nd6fqnm4ct53.apps.googleusercontent.com'
        DartDefines        = 'APP_ENV=dev,SUPER_ADMIN_EMAIL=stantest@stanworld.org'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.dev.json'
        PlaywrightBaseURL  = 'https://archipel-fortune-dev.web.app'
    }
    staging = @{
        ProjectId          = 'archipel-fortune-staging'
        AndroidAppId       = '1:344541548510:android:631fa078fb9926677d174f'
        GoogleSignInClientId = '344541548510-k1vncr9ufjii7r3k4425p8sqgq5p47r6.apps.googleusercontent.com'
        DartDefines        = 'APP_ENV=staging,SUPER_ADMIN_EMAIL=stanworld@gmail.com'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.staging.json'
        PlaywrightBaseURL  = 'https://archipel-fortune-staging.web.app'
    }
    prod    = @{
        ProjectId          = 'archipel-fortune-prod'
        AndroidAppId       = '1:417958901427:android:afebbbc0aa7ded9b0762c6'
        GoogleSignInClientId = '48301164525-6lqqh5tc0m0jpsm4ovdpgalosve17a1m.apps.googleusercontent.com'
        DartDefines        = 'APP_ENV=prod,SUPER_ADMIN_EMAIL=stanworld@gmail.com'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.prod.json'
        PlaywrightBaseURL  = ''  # Pas de tests E2E en prod
    }
}

# Valider : pas de tests E2E en prod
if ($RunE2E -and $Environment -eq 'prod') {
    Write-Warning "Les tests E2E ne sont pas autorisés en environnement 'prod'. Paramètre -RunE2E ignoré."
    $RunE2E = $false
}

if ([string]::IsNullOrWhiteSpace($BuildMode)) {
    if ($Environment -eq 'prod') { $BuildMode = 'release' } else { $BuildMode = 'debug' }
}

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' Archipel Fortune Build & Deploy ' -ForegroundColor Cyan
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host "  Environment : $Environment"
Write-Host "  Platform    : $Platform"
Write-Host "  Build Mode  : $BuildMode"
Write-Host "  Tests E2E   : $(if ($RunE2E) { 'Oui (Playwright)' } else { 'Non' })"
Write-Host '--------------------------------------------------'

$RootPath = Get-Location
$AppPath = Join-Path $RootPath 'app'
$E2EPath = Join-Path $RootPath 'tests_e2e'

if (Test-Path $AppPath) {
    Set-Location -Path $AppPath
}

# --- Step 1: Clean ---
if (-not $NoClean) {
    Write-Host '--> Step 1: Cleaning...' -ForegroundColor Yellow
    flutter clean
    flutter pub get
}

# --- Step 2: Version ---
Write-Host '--> Step 2: Version...' -ForegroundColor Yellow
$PubspecPath = 'pubspec.yaml'
$PubspecContent = Get-Content $PubspecPath
$VersionLine = $PubspecContent | Select-String 'version:' | Select-Object -First 1
$CurrentVersion = $VersionLine.ToString().Split(':')[1].Trim()
$VersionName = $CurrentVersion.Split('+')[0]
$NewBuildNumber = (git rev-list --count HEAD).Trim()
$NewVersion = "$VersionName+$NewBuildNumber"

Write-Host "   Version: $VersionName  |  Build: $NewBuildNumber" -ForegroundColor Green

# --- Step 3: Unit Tests ---
# Tests unitaires bloquants pour prod, optionnels (--BypassTest) pour dev/staging
$RunUnitTests = ($Environment -eq 'prod') -or (-not $BypassTest)
if ($RunUnitTests) {
    Write-Host '--> Step 3: Unit Tests...' -ForegroundColor Yellow
    if (Test-Path 'test') {
        $testFiles = Get-ChildItem -Path 'test' -Filter '*_test.dart' -Recurse -ErrorAction SilentlyContinue
        if ($testFiles) {
            flutter test
            if ($LASTEXITCODE -ne 0) { throw '❌ Unit tests failed.' }
            Write-Host '   ✅ Unit tests passed.' -ForegroundColor Green
        } else {
            Write-Host '   ℹ️ No test files found, skipping.' -ForegroundColor Yellow
        }
    } else {
        Write-Host '   ⚠️ No test/ folder found.' -ForegroundColor Gray
    }
} else {
    Write-Host '--> Step 3: Unit Tests skipped (--BypassTest).' -ForegroundColor Gray
}

# --- Step 4: Build ---
Write-Host '--> Step 4: Building...' -ForegroundColor Yellow
$EnvConfig = $Config[$Environment]

$Defines = $EnvConfig.DartDefines -split ','
$DartDefineArgs = @()
foreach ($d in $Defines) {
    $DartDefineArgs += '--dart-define'
    $DartDefineArgs += $d
}

$CommonArgs = $DartDefineArgs + @(
    "--$BuildMode",
    '-t', $EnvConfig.EntryPoint,
    '--build-name', $VersionName,
    '--build-number', $NewBuildNumber.ToString()
)

if ($Platform -eq 'web' -or $Platform -eq 'all') {
    Write-Host '   Configuring Web index.html...' -ForegroundColor Yellow
    flutter create . --platforms web
    $templatePath = 'web/index-template.html'
    $indexPath = 'web/index.html'
    if (Test-Path $templatePath) {
        $content = Get-Content $templatePath -Raw
        $content = $content -replace '##GOOGLE_SIGNIN_CLIENT_ID_PLACEHOLDER##', $EnvConfig.GoogleSignInClientId
        $content | Out-File -FilePath $indexPath -Encoding utf8 -Force
        Write-Host "   ✅ index.html generated with Client ID: $($EnvConfig.GoogleSignInClientId)" -ForegroundColor Green
    } else {
        Write-Warning "web/index-template.html not found. Using existing index.html."
    }

    Write-Host '   Building Web...' -ForegroundColor Yellow
    flutter build web @CommonArgs
    if ($LASTEXITCODE -ne 0) { throw '❌ Web Build Failed' }
    Write-Host '   ✅ Web build done.' -ForegroundColor Green
}

if ($Platform -eq 'android' -or $Platform -eq 'all') {
    # Copier le bon google-services.json avant le build Android
    $gsSource = $EnvConfig.GoogleServicesPath
    $gsTarget = 'android/app/google-services.json'
    if (Test-Path $gsSource) {
        Write-Host "   Copying $gsSource -> $gsTarget"
        Copy-Item -Path $gsSource -Destination $gsTarget -Force
    } else {
        Write-Warning "google-services source '$gsSource' not found. Android build may fail."
    }

    $AndroidArgs = $CommonArgs
    if (-not [string]::IsNullOrWhiteSpace($EnvConfig.Flavor)) {
        $AndroidArgs += '--flavor', $EnvConfig.Flavor
    }

    if ($BuildMode -eq 'release') {
        Write-Host '   Building Android AppBundle...' -ForegroundColor Yellow
        flutter build appbundle @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw '❌ Android AAB Build Failed' }
        Write-Host '   ✅ AAB build done.' -ForegroundColor Green
    } else {
        Write-Host '   Building Android APK...' -ForegroundColor Yellow
        flutter build apk @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw '❌ Android APK Build Failed' }
        Write-Host '   ✅ APK build done.' -ForegroundColor Green
    }
}

# --- Step 5: E2E Tests (Playwright) — dev/staging uniquement ---
if ($RunE2E -and ($Platform -eq 'web' -or $Platform -eq 'all')) {
    Write-Host '--> Step 5: E2E Tests (Playwright)...' -ForegroundColor Yellow
    if (Test-Path $E2EPath) {
        $baseURL = $EnvConfig.PlaywrightBaseURL
        Write-Host "   Target URL: $baseURL"
        Push-Location $E2EPath
        $env:PLAYWRIGHT_BASE_URL = $baseURL
        npx playwright test
        $e2eExit = $LASTEXITCODE
        Remove-Item Env:\PLAYWRIGHT_BASE_URL -ErrorAction SilentlyContinue
        Pop-Location
        if ($e2eExit -ne 0) {
            Write-Warning "⚠️ E2E tests failed (exit $e2eExit). Build continues."
            # Non bloquant : les E2E peuvent échouer sans bloquer le deploy
        } else {
            Write-Host '   ✅ E2E tests passed.' -ForegroundColor Green
        }
    } else {
        Write-Warning "tests_e2e/ directory not found. Skipping E2E tests."
    }
} else {
    Write-Host '--> Step 5: E2E Tests skipped.' -ForegroundColor Gray
}

if ($NoDeploy) {
    Write-Host '✅ Build Only mode — stopping here.' -ForegroundColor Green
    Set-Location -Path $RootPath
    Exit 0
}

# --- Step 6: Git ---
if (-not $NoGit) {
    Write-Host '--> Step 6: Git Operations...' -ForegroundColor Yellow
    $TagExists = git tag -l "v$NewVersion"
    if (-not $TagExists) {
        Write-Host "   Tagging v$NewVersion..."
        git tag -a "v$NewVersion" -m "Release $NewVersion ($Environment)"
    }
}

# --- Step 7: Deploy ---
Write-Host '--> Step 7: Deploying...' -ForegroundColor Yellow
Set-Location -Path $RootPath

if ($Platform -eq 'web' -or $Platform -eq 'all') {
    $deployTargets = if ($Environment -eq 'prod') { 'hosting,firestore' } else { 'hosting,functions,firestore' }
    Write-Host "   Deploying [$deployTargets] to Firebase Project: $($EnvConfig.ProjectId)"
    # Use --force to automatically set up cleanup policies and avoid soft failures
    firebase deploy --only $deployTargets --project $EnvConfig.ProjectId --force
    if ($LASTEXITCODE -ne 0) { throw '❌ Firebase deploy failed.' }
    Write-Host '   ✅ Firebase deploy done.' -ForegroundColor Green
}

Write-Host ''
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' ALL DONE - Happy Sailing! ⛵' -ForegroundColor Green
Write-Host '==================================================' -ForegroundColor Cyan
