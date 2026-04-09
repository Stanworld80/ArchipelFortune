<#
.SYNOPSIS
    Build and Deploy script for ArchipelFortune.
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
    [switch]$NoGit
)

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$Config = @{
    dev = @{
        ProjectId          = 'archipel-fortune-dev'
        AndroidAppId       = '1:83241971458:android:dde10259edb60d45711c1b'
        DartDefines        = 'APP_ENV=dev,SUPER_ADMIN_EMAIL=tester-admin@archipel-fortune.net'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.dev.json'
    }
    staging = @{
        ProjectId          = 'archipel-fortune-staging'
        AndroidAppId       = '1:344541548510:android:631fa078fb9926677d174f'
        DartDefines        = 'APP_ENV=staging,SUPER_ADMIN_EMAIL=stanworld@gmail.com'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.staging.json'
    }
    prod    = @{
        ProjectId          = 'archipel-fortune-prod'
        AndroidAppId       = '1:48301164525:android:c3713960cdefdbb28589e4'
        DartDefines        = 'APP_ENV=prod,SUPER_ADMIN_EMAIL=stanworld@gmail.com'
        Flavor             = ''
        EntryPoint         = 'lib/main.dart'
        GoogleServicesPath = 'android/app/google-services.prod.json'
    }
}

if ([string]::IsNullOrWhiteSpace($BuildMode)) {
    if ($Environment -eq 'prod') { $BuildMode = 'release' } else { $BuildMode = 'debug' }
}

Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' Archipel Fortune Build & Deploy ' -ForegroundColor Cyan
Write-Host '=================================================='
Write-Host "  Environment : $Environment"
Write-Host "  Platform    : $Platform"
Write-Host "  Build Mode  : $BuildMode"
Write-Host '--------------------------------------------------'

$RootPath = Get-Location
$AppPath = Join-Path $RootPath 'app'

if (Test-Path $AppPath) {
    Set-Location -Path $AppPath
}

if (-not $NoClean) {
    Write-Host '-> Step 1: Cleaning...' -ForegroundColor Yellow
    flutter clean
    flutter pub get
}

Write-Host '-> Step 2: Version Logic...' -ForegroundColor Yellow
$PubspecPath = 'pubspec.yaml'
$PubspecContent = Get-Content $PubspecPath
$VersionLine = $PubspecContent | Select-String 'version:' | Select-Object -First 1
$CurrentVersion = $VersionLine.ToString().Split(':')[1].Trim()
$VersionName = $CurrentVersion.Split('+')[0]
$NewBuildNumber = (git rev-list --count HEAD).Trim()
$NewVersion = "$VersionName+$NewBuildNumber"

Write-Host "   Version: $VersionName" -ForegroundColor Green
Write-Host "   Build Number (Git): $NewBuildNumber" -ForegroundColor Green

if ($Environment -eq 'prod' -or (-not $BypassTest)) {
    Write-Host '🧪 Running Tests...' -ForegroundColor Cyan
    if (Test-Path 'test') {
        $testFiles = Get-ChildItem -Path 'test' -Filter '*_test.dart' -Recurse -ErrorAction SilentlyContinue
        if ($testFiles) {
            flutter test
            if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
        } else {
            Write-Host 'ℹ️ No test files found, skipping.' -ForegroundColor Yellow
        }
    } else {
        Write-Host '   No tests found.' -ForegroundColor Gray
    }
}

Write-Host '-> Step 4: Building...' -ForegroundColor Yellow
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
    Write-Host '   Building Web...'
    flutter build web @CommonArgs
    if ($LASTEXITCODE -ne 0) { throw 'Web Build Failed' }
}

if ($Platform -eq 'android' -or $Platform -eq 'all') {
    $AndroidArgs = $CommonArgs
    if (-not [string]::IsNullOrWhiteSpace($EnvConfig.Flavor)) {
        $AndroidArgs += '--flavor', $EnvConfig.Flavor
    }
    
    if ($BuildMode -eq 'release') {
        Write-Host '   Building Android AppBundle...'
        flutter build appbundle @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw 'Android AAB Build Failed' }
    } else {
        Write-Host '   Building Android APK...'
        flutter build apk @AndroidArgs
        if ($LASTEXITCODE -ne 0) { throw 'Android APK Build Failed' }
    }
}

if ($NoDeploy) {
    Write-Host 'Build Only successful.' -ForegroundColor Green
    Set-Location -Path $RootPath
    Exit 0
}

if (-not $NoGit) {
    Write-Host '-> Step 5: Git Operations...' -ForegroundColor Yellow
    $TagExists = git tag -l "v$NewVersion"
    if (-not $TagExists) {
        Write-Host "   Tagging v$NewVersion..."
        git tag -a "v$NewVersion" -m "Release $NewVersion ($Environment)"
    }
}

Write-Host '-> Step 6: Deploying...' -ForegroundColor Yellow
Set-Location -Path $RootPath

if ($Platform -eq 'web' -or $Platform -eq 'all') {
    Write-Host "   Deploying to Firebase Project: $($EnvConfig.ProjectId)"
    firebase deploy --only 'hosting,functions,firestore' --project $EnvConfig.ProjectId
}

Write-Host ''
Write-Host '==================================================' -ForegroundColor Cyan
Write-Host ' ALL DONE - Happy Sailing!' -ForegroundColor Green
Write-Host '=================================================='
