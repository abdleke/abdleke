# Configuration Firebase pour Jamiyati

Ce guide vous permet de connecter l'application à Firebase Firestore afin que
**toutes les données soient partagées en temps réel** entre les téléphones des membres.

> Sans Firebase, l'app fonctionne normalement en mode hors-ligne (données locales).

---

## Étape 1 — Créer un projet Firebase

1. Allez sur [console.firebase.google.com](https://console.firebase.google.com)
2. Cliquez **Ajouter un projet**
3. Nom du projet : `jamiyati` (ou le nom de votre association)
4. Désactivez Google Analytics (optionnel)
5. Cliquez **Créer le projet**

---

## Étape 2 — Activer Cloud Firestore

1. Dans le menu gauche → **Firestore Database**
2. Cliquez **Créer une base de données**
3. Choisissez **Mode production**
4. Sélectionnez la région : `europe-west1` (Europe — Belgique, la plus proche d'Algérie)
5. Cliquez **Activer**

### Règles de sécurité Firestore

Remplacez les règles par défaut par celles-ci (onglet **Règles**) :

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Seules les lectures/écritures authentifiées sont autorisées
    // Note: Jamiyati utilise une auth personnalisée, pas Firebase Auth.
    // Pour la démo, on autorise tout. En production, restreignez selon vos besoins.
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

> **Important** : Ces règles permettent l'accès à quiconque connaît votre `projectId`.
> Pour une sécurité maximale, activez Firebase Authentication ou restreignez par IP.

---

## Étape 3 — Ajouter l'application Android

1. Dans Firebase Console → **Paramètres du projet** (icône engrenage)
2. Onglet **Général** → section **Vos applications** → cliquez l'icône Android
3. **Nom du package Android** : `com.jamiyati.app`
4. Cliquez **Enregistrer l'application**
5. Téléchargez le fichier **`google-services.json`**
6. Placez-le dans le dossier : `android/app/google-services.json`

---

## Étape 4 — Mettre à jour firebase_options.dart

1. Dans Firebase Console → **Paramètres du projet** → **Vos applications**
2. Sous votre app Android, cliquez **SDK setup and configuration**
3. Copiez les valeurs et mettez à jour `lib/firebase_options.dart` :

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey:            'AIzaSy...',          // API key
  appId:             '1:123456789:android:abc...', // App ID
  messagingSenderId: '123456789',          // Sender ID
  projectId:         'jamiyati-xxxxx',     // Project ID
  storageBucket:     'jamiyati-xxxxx.firebasestorage.app',
);
```

---

## Étape 5 — Builder l'APK

```powershell
# Depuis le dossier app/
flutter clean
flutter pub get
flutter build apk --release
```

L'APK sera dans : `build\app\outputs\flutter-apk\app-release.apk`

---

## Étape 6 — Distribuer l'application

1. Copiez `app-release.apk` sur le téléphone de chaque membre
2. Sur le téléphone : **Paramètres → Sécurité → Sources inconnues** → Activer
3. Ouvrir le fichier APK pour installer
4. Se connecter avec :
   - Téléphone : `0661234567`
   - Mot de passe : `admin123`

Au premier lancement, les données de démonstration sont automatiquement
envoyées vers Firestore. Tous les membres voient ensuite les mêmes données
en temps réel.

---

## Changer le mot de passe admin

Après avoir installé l'app :
1. Connectez-vous en tant qu'admin
2. Menu **Membres** → cliquez sur votre compte → **Modifier**
3. Changez le mot de passe
4. Tous les membres doivent utiliser le nouveau mot de passe

---

## Vérifier que Firebase fonctionne

Dans Firebase Console → **Firestore Database** → vous devriez voir les
collections `members`, `projects`, `depenses`, `cotisations` après le
premier lancement de l'app.

---

## Problèmes courants

| Problème | Solution |
|---|---|
| "INVALID_API_KEY" | Vérifiez les valeurs dans `firebase_options.dart` |
| "google-services.json not found" | Placez le fichier dans `android/app/` |
| Les données ne se synchronisent pas | Vérifiez les règles Firestore (Étape 2) |
| Build failed après ajout Firebase | Lancez `flutter clean` puis `flutter pub get` |
