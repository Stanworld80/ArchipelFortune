<#
.SYNOPSIS
    Build and Deploy script for ArchipelFortune.
.DESCRIPTION
    Handles version bumping, building (APK/AppBundle/Web), and deploying to Firebase.
    Created for Windows PowerShell environments.
.PARAMETER Environment
    Target environment: 'dev' (default), 'staging' or 'prod'.
.PARAMETER Platform
    Target platform: 'web', 'android', or 'all'. Default is 'web'.
.PARAMETER BuildMode
    Flutter build mode: 'debug', 'profile', or 'release'.
.PARAMETER NoDeploy
    If set, skips the deployment step.
.PARAMETER NoClean
    If set, skips 'flutter clean'.
.PARAMETER BypassTest
    If set, skips unit tests.
#>
param(
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",

    [ValidateSet("web", "android", "all")]
    [string]$Platform = "web",

    [ValidateSet("debug", "profile", "release")]
    [string]$BuildMode = "",

    [switch]$NoDeploy,
    [switch]$NoClean,
    [switch]$BypassTest,
    [switch]$NoGit,
    [string]$WebRenderer = "html"
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$Config = @{
    dev = @{
        ProjectId          = "archipel-fortune-dev"
        AndroidAppId       = "1:83241971458:android:dde10259edb60d45711c1b"
        DartDefines        = "APP_ENV=dev,SUPER_ADMIN_EMAIL=stanworld@gmail.com"
        Flavor             = "" # ArchipelFortune might not use flavors yet
        EntryPoint         = "lib/main.dart"
        GoogleServicesPath = "android/app/google-services.dev.json"
    }
    staging = @{
        ProjectId          = "archipel-fortune-staging"
        AndroidAppId       = "1:344541548510:android:631fa078fb9926677d174f"
        DartDefines        = "APP_ENV=staging,SUPER_ADMIN_EMAIL=stanworld@gmail.com"
        Flavor             = ""
        EntryPoint         = "lib/main.dart"
        GoogleServicesPath = "android/app/google-services.staging.json"
    }
    prod    = @{
        ProjectId          = "archipel-fortune-prod"
        AndroidAppId       = "1:48301164525:android:c3713960cdefdbb28589e4"
        DartDefines        = "APP_ENV=prod,SUPER_ADMIN_EMAIL=stanworld@gmail.com"
        Flavor             = ""
        EntryPoint         = "lib/main.dart"
        GoogleServicesPath = "android/app/google-services.prod.json"
    }
}

# --- Defaults ---
if ([string]::IsNullOrWhiteSpace($BuildMode)) {
    if ($Environment -eq "prod") { $BuildMode = "release" } else { $BuildMode = "debug" }
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Archipel Fortune Build & Deploy " -ForegroundColor Cyan
Write-Host "=================================================="
Write-Host "  Environment : $Environment"
Write-Host "  Platform    : $Platform"
Write-Host "  Build Mode  : $BuildMode"
Write-Host "--------------------------------------------------"

# L'application Flutter est dans le sous-dossier 'app'
Set-Location -Path "app"

# 1. Clean
if (-not $NoClean) {
    Write-Host "-> Step 1: Cleaning..." -ForegroundColor Yellow
    flutter clean
}

# 2. Extract Version and Calculate Build Number
Write-Host "-> Step 2: Version Logic..." -ForegroundColor Yellow
$PubspecPath = "pubspec.yaml"
$PubspecContent = Get-Content $PubspecPath
$VersionLine = $PubspecContent | Select-String "version:" | Select-Object -First 1
$CurrentVersion = $VersionLine.ToString().Split(":")[1].Trim()
$VersionName = $CurrentVersion.Split("+")[0]
# We use Git commit count as the Build Number
$NewBuildNumber = (git rev-list --count HEAD).Trim()
$NewVersion = "$VersionName+$NewBuildNumber"

Write-Host "   Version: $VersionName" -ForegroundColor Green
Write-Host "   Build Number (Git): $NewBuildNumber" -ForegroundColor Green

# 3. Tests
if ($Environment -eq "prod" -or (-not $BypassTest)) {
    Write-Host "-> Step 3: Running Tests..." -ForegroundColor Yellow
    if (Test-Path "test") {
        flutter test
        if ($LASTEXITCODE -ne 0) { throw "Tests failed." }
    } else {
        Write-Host "   No tests found." -ForegroundColor Gray
    }
}
else {
    Write-Host "-> Step 3: Tests Skipped." -ForegroundColor Gray
}

# 3.b Configure Android Google Services
if ($Platform -eq "android" -or $Platform -eq "all") {
    $EnvConfig = $Config[$Environment]
    if (Test-Path $EnvConfig.GoogleServicesPath) {
        Write-Host "-> Configuring Android for $($Environment)..." -ForegroundColor Yellow
        Copy-Item -Path $EnvConfig.GoogleServicesPath -Destination "android/app/google-services.json" -Force
        Write-Host "   Copied $($EnvConfig.GoogleServicesPath) to android/app/google-services.json"
    }
}

# 4. Build
Write-Host "-> Step 4: Building..." -ForegroundColor Yellow
$EnvConfig = $Config[$Environment]

# Prepare Dart Defines
$Defines = $EnvConfig.DartDefines -split ","
$DartDefineArgs = @()
foreach ($d in $Defines) {
    $DartDefineArgs += "--dart-define"
    $DartDefineArgs += $d
}

$CommonArgs = $DartDefineArgs + @(
    "--$BuildMode",
    "-t", $EnvConfig.EntryPoint,
    "--build-name", $VersionName,
    "--build-number", $NewBuildNumber.ToString()
)

if ($Platform -eq "web" -or $Platform -eq "all") {
    Write-Host "   Building Web..."
    $WebArgs = $CommonArgs
    if (-not [string]::IsNullOrWhiteSpace($WebRenderer)) {
        $WebArgs += "--web-renderer", $WebRenderer
    }
    flutter build web @WebArgs
    if ($LASTEXITCODE -ne 0) { throw "Web Build Failed" }
}

if ($Platform -eq "android" -or $Platform -eq "all") {
    $AndroidArgs = $CommonArgs
    if (![string]::IsNullOrWhiteSpace($EnvConfig.Flavor)) {
        $AndroidArgs += "--flavor", $EnvConfig.Flavor
    }
    
    if ($BuildMode -eq "release") {
        Write-Host "   Building Android AppBundle..."
        flutter build appbundle @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw "Android AAB Build Failed" }
    }
    else {
        Write-Host "   Building Android APK..."
        flutter build apk @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw "Android APK Build Failed" }
    }
}

if ($NoDeploy) {
    Write-Host "Build Only. process finished." -ForegroundColor Green
    Exit 0
}

# 5. Git Operations
if (-not $NoGit) {
    Write-Host "-> Step 5: Git Operations..." -ForegroundColor Yellow
    # Check if tag already exists to avoid failure
    $TagExists = git tag -l "v$NewVersion"
    if (-not $TagExists) {
        Write-Host "   Tagging v$NewVersion..."
        git tag -a "v$NewVersion" -m "Release $NewVersion ($Environment)"
        # Note: push might fail if no origin or auth needed
        # git push origin "v$NewVersion"
    }
}

# 6. Deploy
Write-Host "-> Step 6: Deploying..." -ForegroundColor Yellow
Set-Location -Path ".." # Back to root for firebase CLI

# Web/Backend Deploy
if ($Platform -eq "web" -or $Platform -eq "all") {
    Write-Host "   Deploying Hosting, Functions and Firestore to $($EnvConfig.ProjectId)..."
    firebase deploy --only "hosting,functions,firestore" --project $EnvConfig.ProjectId
}

# Android Deploy (APK to App Distribution)
if ($Platform -eq "android" -or $Platform -eq "all") {
    if ($BuildMode -eq "debug") {
        # Adjust path based on flavors if used
        $Suffix = if ($EnvConfig.Flavor) { "-$($EnvConfig.Flavor)" } else { "" }
        $ApkPath = "app/build/app/outputs/flutter-apk/app$($Suffix)-$BuildMode.apk"
        if (Test-Path $ApkPath) {
            Write-Host "   Uploading APK to App Distribution..."
            firebase appdistribution:distribute "$ApkPath" --app $EnvConfig.AndroidAppId --release-notes "Ver $NewVersion" --groups "dev-testers" --project $EnvConfig.ProjectId
        }
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " ALL DONE - Happy Sailing!" -ForegroundColor Green
Write-Host "=================================================="
