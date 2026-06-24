# Script de configuration automatique de Jamiyati
# Lancer depuis le dossier app/ avec PowerShell :
# .\setup.ps1

Write-Host "=== Jamiyati - Configuration automatique ===" -ForegroundColor Cyan

# 1. Générer le scaffolding Flutter natif
Write-Host "`n[1/6] Génération du scaffolding Flutter..." -ForegroundColor Yellow
flutter create . --project-name jamiyati --org com.jamiyati
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter create" -ForegroundColor Red; exit 1 }

# 2. Patcher AndroidManifest.xml pour url_launcher (WhatsApp + appels)
Write-Host "`n[2/6] Configuration AndroidManifest.xml..." -ForegroundColor Yellow
$manifestPath = "android\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw

$queries = @"
    <uses-permission android:name="android.permission.INTERNET" />
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <package android:name="com.whatsapp" />
    </queries>

"@

if ($manifest -notmatch "com.whatsapp") {
    $manifest = $manifest -replace "(<application)", "$queries`$1"
    Set-Content $manifestPath $manifest -Encoding UTF8
    Write-Host "  AndroidManifest.xml patché." -ForegroundColor Green
} else {
    Write-Host "  AndroidManifest.xml déjà configuré." -ForegroundColor Green
}

# 3. Patcher iOS Info.plist pour url_launcher
Write-Host "`n[3/6] Configuration iOS Info.plist..." -ForegroundColor Yellow
$plistPath = "ios\Runner\Info.plist"
if (Test-Path $plistPath) {
    $plist = Get-Content $plistPath -Raw
    $schemes = @"
	<key>LSApplicationQueriesSchemes</key>
	<array>
		<string>whatsapp</string>
		<string>tel</string>
	</array>
"@
    if ($plist -notmatch "LSApplicationQueriesSchemes") {
        $plist = $plist -replace "(</dict>\s*</plist>)", "$schemes`n`$1"
        Set-Content $plistPath $plist -Encoding UTF8
        Write-Host "  Info.plist patché." -ForegroundColor Green
    } else {
        Write-Host "  Info.plist déjà configuré." -ForegroundColor Green
    }
} else {
    Write-Host "  Info.plist non trouvé (normal sur Windows)." -ForegroundColor Gray
}

# 4. Patcher android/build.gradle pour Firebase Google Services
Write-Host "`n[4/6] Configuration Firebase Android (build.gradle)..." -ForegroundColor Yellow
$rootGradle = "android\build.gradle"
if (Test-Path $rootGradle) {
    $gradle = Get-Content $rootGradle -Raw
    if ($gradle -notmatch "google-services") {
        # Ajouter le classpath Google Services dans la section buildscript/dependencies
        $gradle = $gradle -replace "(classpath ['""]com.android.tools.build:gradle[^'""\n]+['""])",
            "`$1`n        classpath 'com.google.gms:google-services:4.4.2'"
        Set-Content $rootGradle $gradle -Encoding UTF8
        Write-Host "  android/build.gradle patché (Google Services classpath)." -ForegroundColor Green
    } else {
        Write-Host "  android/build.gradle déjà configuré." -ForegroundColor Green
    }
} else {
    Write-Host "  android/build.gradle non trouvé." -ForegroundColor Red
}

# 5. Patcher android/app/build.gradle pour appliquer le plugin
$appGradle = "android\app\build.gradle"
if (Test-Path $appGradle) {
    $appG = Get-Content $appGradle -Raw
    if ($appG -notmatch "com.google.gms.google-services") {
        # Ajouter apply plugin à la fin du fichier
        Add-Content $appGradle "`napply plugin: 'com.google.gms.google-services'"
        Write-Host "  android/app/build.gradle patché (apply plugin)." -ForegroundColor Green
    } else {
        Write-Host "  android/app/build.gradle déjà configuré." -ForegroundColor Green
    }
} else {
    Write-Host "  android/app/build.gradle non trouvé." -ForegroundColor Red
}

# Vérifier si google-services.json est présent
if (Test-Path "android\app\google-services.json") {
    Write-Host "  google-services.json détecté. Firebase Android prêt !" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ⚠  google-services.json MANQUANT !" -ForegroundColor Yellow
    Write-Host "     Téléchargez-le depuis Firebase Console et placez-le dans android\app\" -ForegroundColor Yellow
    Write-Host "     Voir FIREBASE_SETUP.md pour les instructions." -ForegroundColor Yellow
}

# 6. Installer les dépendances
Write-Host "`n[6/6] Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter pub get" -ForegroundColor Red; exit 1 }

Write-Host "`n=== Configuration terminée ! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor White
Write-Host "  1. Suivez les instructions dans FIREBASE_SETUP.md" -ForegroundColor Yellow
Write-Host "  2. Mettez à jour lib\firebase_options.dart avec vos clés Firebase" -ForegroundColor Yellow
Write-Host "  3. Placez google-services.json dans android\app\" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour builder l'APK :" -ForegroundColor White
Write-Host "  flutter build apk --release" -ForegroundColor Green
Write-Host ""
Write-Host "L'APK sera disponible dans :" -ForegroundColor White
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
