# Script de configuration automatique de Jamiyati
# Lancer depuis le dossier app/ avec PowerShell :
# .\setup.ps1

Write-Host "=== Jamiyati - Configuration automatique ===" -ForegroundColor Cyan

# 1. Générer le scaffolding Flutter natif
Write-Host "`n[1/4] Génération du scaffolding Flutter..." -ForegroundColor Yellow
flutter create . --project-name jamiyati --org com.jamiyati
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter create" -ForegroundColor Red; exit 1 }

# 2. Patcher AndroidManifest.xml pour url_launcher (WhatsApp + appels)
Write-Host "`n[2/4] Configuration AndroidManifest.xml..." -ForegroundColor Yellow
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
Write-Host "`n[3/4] Configuration iOS Info.plist..." -ForegroundColor Yellow
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

# 4. Installer les dépendances
Write-Host "`n[4/4] Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter pub get" -ForegroundColor Red; exit 1 }

Write-Host "`n=== Configuration terminée ! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines étapes pour activer la synchronisation :" -ForegroundColor White
Write-Host "  1. Suivez les instructions dans SUPABASE_SETUP.md" -ForegroundColor Yellow
Write-Host "  2. Mettez à jour lib\supabase_config.dart avec vos clés" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour builder l'APK :" -ForegroundColor White
Write-Host "  flutter build apk --release" -ForegroundColor Green
Write-Host ""
Write-Host "L'APK sera disponible dans :" -ForegroundColor White
Write-Host "  build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
