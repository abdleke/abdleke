# Configuration Supabase pour Jamiyati

Supabase est une alternative open-source à Firebase, basée sur PostgreSQL.
Hébergement gratuit, pas de dépendance à Google, données en temps réel.

> Sans configuration, l'app fonctionne en mode hors-ligne (données locales).

---

## Étape 1 — Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com) → **Start your project**
2. Connectez-vous avec GitHub
3. Cliquez **New project**
4. Remplissez :
   - **Name** : `jamiyati` (ou le nom de votre association)
   - **Database Password** : notez ce mot de passe
   - **Region** : `West EU (Ireland)` — la plus proche d'Algérie
5. Cliquez **Create new project** → attendez ~2 minutes

---

## Étape 2 — Créer les tables

1. Dans le menu gauche → **SQL Editor** → **New query**
2. Copiez-collez le script SQL suivant et cliquez **Run** :

```sql
-- Table des membres
CREATE TABLE members (
  id              TEXT PRIMARY KEY,
  prenom          TEXT NOT NULL,
  nom             TEXT NOT NULL,
  email           TEXT,
  telephone       TEXT,
  "dateAdhesion"  TEXT NOT NULL DEFAULT '',
  statut          TEXT NOT NULL DEFAULT 'actif',
  role            TEXT NOT NULL DEFAULT 'membre',
  "motDePasse"    TEXT NOT NULL DEFAULT '1234'
);

-- Table des projets
CREATE TABLE projects (
  id                  TEXT PRIMARY KEY,
  nom                 TEXT NOT NULL,
  description         TEXT NOT NULL DEFAULT '',
  type                TEXT NOT NULL DEFAULT 'standard',
  budget              DOUBLE PRECISION NOT NULL DEFAULT 0,
  "dateDebut"         TEXT NOT NULL,
  "dateFin"           TEXT,
  statut              TEXT NOT NULL DEFAULT 'actif',
  "responsableId"     TEXT NOT NULL,
  "cotisationDediee"  DOUBLE PRECISION
);

-- Table des dépenses
CREATE TABLE depenses (
  id           TEXT PRIMARY KEY,
  "projetId"   TEXT NOT NULL,
  "membreId"   TEXT NOT NULL,
  description  TEXT NOT NULL,
  montant      DOUBLE PRECISION NOT NULL,
  date         TEXT NOT NULL,
  categorie    TEXT NOT NULL DEFAULT 'autre',
  statut       TEXT NOT NULL DEFAULT 'soumise',
  commentaire  TEXT
);

-- Table des cotisations
CREATE TABLE cotisations (
  id                 TEXT PRIMARY KEY,
  "membreId"         TEXT NOT NULL,
  montant            DOUBLE PRECISION NOT NULL,
  frequence          TEXT NOT NULL,
  annee              INTEGER NOT NULL,
  "dateDeclaration"  TEXT NOT NULL,
  "dateEcheance"     TEXT NOT NULL,
  "datePaiement"     TEXT,
  statut             TEXT NOT NULL DEFAULT 'en_attente',
  "projetId"         TEXT,
  type               TEXT NOT NULL DEFAULT 'normale',
  commentaire        TEXT
);
```

---

## Étape 3 — Activer le temps réel (Realtime)

Pour que les données se synchronisent en direct entre les téléphones :

1. Menu gauche → **Database** → **Replication**
2. Dans la section **Supabase Realtime**, activez les 4 tables :
   - `members` ✓
   - `projects` ✓
   - `depenses` ✓
   - `cotisations` ✓

---

## Étape 4 — Désactiver RLS (Row Level Security)

Pour simplifier (app interne, pas publique) :

1. Menu gauche → **Table Editor**
2. Pour chaque table → cliquez sur la table → **RLS disabled** (doit être désactivé)

Ou via SQL Editor :

```sql
ALTER TABLE members    DISABLE ROW LEVEL SECURITY;
ALTER TABLE projects   DISABLE ROW LEVEL SECURITY;
ALTER TABLE depenses   DISABLE ROW LEVEL SECURITY;
ALTER TABLE cotisations DISABLE ROW LEVEL SECURITY;
```

---

## Étape 5 — Récupérer les clés API

1. Menu gauche → **Settings** → **API**
2. Notez :
   - **Project URL** : `https://xxxxxxxx.supabase.co`
   - **anon public** key : `eyJh...` (clé longue)

---

## Étape 6 — Configurer l'application

Ouvrez `lib/supabase_config.dart` et remplacez :

```dart
const supabaseUrl     = 'https://VOTRE_ID.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

---

## Étape 7 — Builder et distribuer

```powershell
# Depuis le dossier app/
flutter clean
flutter pub get
flutter build apk --release
```

APK disponible dans : `build\app\outputs\flutter-apk\app-release.apk`

Copiez l'APK sur chaque téléphone. Au **premier lancement**, les données de
démonstration sont automatiquement créées dans Supabase. Tous les membres
voient ensuite les mêmes données en temps réel.

**Identifiants par défaut :**
- Téléphone : `0661234567`
- Mot de passe : `admin123`

---

## Problèmes courants

| Problème | Solution |
|---|---|
| "Invalid API key" | Vérifiez les valeurs dans `supabase_config.dart` |
| Les données ne se synchronisent pas | Vérifiez que Realtime est activé (Étape 3) |
| Erreur 403 | Désactivez RLS sur les tables (Étape 4) |
| Build échoue | Lancez `flutter clean` puis `flutter pub get` |
| App en mode hors-ligne après config | `supabaseConfigured` est `false` si l'URL n'est pas changée |
