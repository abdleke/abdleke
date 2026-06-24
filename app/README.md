# جمعيتي – Jamiyati

Application Flutter de gestion financière pour associations (dépenses, cotisations, rappels).

## Prérequis

- Flutter SDK ≥ 3.3.0 ([installation](https://docs.flutter.dev/get-started/install))
- Android Studio + NDK (pour APK Android)

## Installation & Build (Windows)

### Option rapide — script automatique

Ouvre PowerShell dans le dossier `app/` et lance :

```powershell
.\setup.ps1
```

Le script fait tout automatiquement : génération du projet, configuration des permissions, `flutter pub get`. Ensuite :

```powershell
flutter build apk --release
```

L'APK sera dans : `build\app\outputs\flutter-apk\app-release.apk`

---

### Étapes manuelles (si le script ne fonctionne pas)

```powershell
# 1. Générer le scaffolding natif
flutter create . --project-name jamiyati --org com.jamiyati

# 2. Installer les dépendances
flutter pub get

# 3. Builder l'APK
flutter build apk --release
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
