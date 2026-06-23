# جمعيتي – Jamiyati

Application Flutter de gestion financière pour associations (dépenses, cotisations, rappels).

## Prérequis

- Flutter SDK ≥ 3.3.0 ([installation](https://docs.flutter.dev/get-started/install))
- Android Studio + NDK (pour APK Android)
- Xcode (pour iOS, Mac uniquement)

## Installation & Build

### 1. Cloner le dépôt et aller dans le dossier app

```bash
cd app/
```

### 2. Générer le scaffolding natif

```bash
flutter create . --project-name jamiyati --org com.jamiyati
```

> ⚠️ Répondez **"y"** si Flutter demande de remplacer des fichiers existants.

### 3. Installer les dépendances

```bash
flutter pub get
```

### 4. Configurer url_launcher (WhatsApp & appels)

Ouvrez `android/app/src/main/AndroidManifest.xml` et ajoutez dans la balise `<manifest>` (avant `<application>`) :

```xml
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
```

Pour iOS, dans `ios/Runner/Info.plist`, ajoutez avant `</dict>` :

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
    <string>tel</string>
</array>
```

### 5. Builder l'APK (Android)

```bash
# Debug (test rapide)
flutter build apk --debug

# Release (optimisé)
flutter build apk --release
```

L'APK se trouve dans : `build/app/outputs/flutter-apk/app-release.apk`

### 6. Builder pour iOS

```bash
flutter build ios --release
# Puis ouvrir dans Xcode pour archiver et distribuer
```

## Fonctionnalités

- **Dashboard** – Statistiques, alertes retards, dépenses en attente
- **Projets** – Gestion budgets, types standard/périodique
- **Dépenses** – Soumission et validation par chef de projet
- **Cotisations** – Déclaration et validation par trésorier
- **Rappels** – WhatsApp (wa.me) + appel direct
- **Rapports** – Bilan financier par catégorie et par projet
- **Langues** – Arabe (RTL), Français, Anglais

## Rôles & Permissions

| Rôle         | Gérer membres | Gérer projets | Valider dépenses | Valider cotisations |
|--------------|:---:|:---:|:---:|:---:|
| Admin        | ✅ | ✅ | ✅ | ✅ |
| Trésorier    | ❌ | ✅ | ❌ | ✅ |
| Chef Projet  | ❌ | ❌ | ✅* | ❌ |
| Membre       | ❌ | ❌ | ❌ | ❌ |

*Chef de projet : valide uniquement les dépenses de ses projets
