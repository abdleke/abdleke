// ignore_for_file: lines_longer_than_80_chars
//
// ⚠️  CONFIGURATION REQUISE — voir FIREBASE_SETUP.md
//
// Remplacez TOUTES les valeurs "VOTRE_..." par celles de votre projet Firebase.
// Firebase Console → Paramètres du projet → Vos applications → SDK setup.
//
// Tant que ces valeurs ne sont pas renseignées, l'application fonctionne
// en mode hors-ligne (données locales uniquement).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plateforme non supportée: $defaultTargetPlatform');
    }
  }

  // ── Android ────────────────────────────────────────────────────
  // Trouvez ces valeurs dans google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'VOTRE_ANDROID_API_KEY',
    appId:             'VOTRE_ANDROID_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId:         'VOTRE_PROJECT_ID',
    storageBucket:     'VOTRE_PROJECT_ID.firebasestorage.app',
  );

  // ── iOS ────────────────────────────────────────────────────────
  // Trouvez ces valeurs dans GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'VOTRE_IOS_API_KEY',
    appId:             'VOTRE_IOS_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId:         'VOTRE_PROJECT_ID',
    storageBucket:     'VOTRE_PROJECT_ID.firebasestorage.app',
    iosClientId:       'VOTRE_IOS_CLIENT_ID',
    iosBundleId:       'com.jamiyati.app',
  );

  // ── Web (optionnel) ────────────────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'VOTRE_WEB_API_KEY',
    appId:             'VOTRE_WEB_APP_ID',
    messagingSenderId: 'VOTRE_SENDER_ID',
    projectId:         'VOTRE_PROJECT_ID',
    authDomain:        'VOTRE_PROJECT_ID.firebaseapp.com',
    storageBucket:     'VOTRE_PROJECT_ID.firebasestorage.app',
  );
}
