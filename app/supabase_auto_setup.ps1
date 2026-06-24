# supabase_auto_setup.ps1
# Lance ce script depuis le dossier app/ :  .\supabase_auto_setup.ps1
# Il crée le projet Supabase, les tables, active le realtime et met à jour supabase_config.dart

$Token   = if ($env:SUPABASE_TOKEN) { $env:SUPABASE_TOKEN } else {
    Read-Host "Collez votre Supabase Personal Access Token"
}
$ProjName = "jam3yati"
$Region  = "eu-west-1"   # Ireland — plus proche d'Algérie

$H = @{ "Authorization" = "Bearer $Token"; "Content-Type" = "application/json" }

function Req($Method, $Url, $Body = $null) {
    $params = @{ Uri = $Url; Method = $Method; Headers = $H; ErrorAction = "Stop" }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10) }
    try { return Invoke-RestMethod @params }
    catch {
        Write-Host "  ERREUR : $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "=== Jamiyati — Configuration Supabase automatique ===" -ForegroundColor Cyan

# ── 1. Organisation ───────────────────────────────────────────────
Write-Host "`n[1/6] Récupération de l'organisation..." -ForegroundColor Yellow
$orgs = Req "GET" "https://api.supabase.com/v1/organizations"
if ($orgs.Count -eq 0) { Write-Host "Aucune organisation trouvée. Créez-en une sur supabase.com." -ForegroundColor Red; exit 1 }
$OrgId = $orgs[0].id
Write-Host "  Organisation : $($orgs[0].name) ($OrgId)" -ForegroundColor Green

# ── 2. Vérifier si le projet existe déjà ─────────────────────────
Write-Host "`n[2/6] Vérification du projet..." -ForegroundColor Yellow
$projects = Req "GET" "https://api.supabase.com/v1/projects"
$existing = $projects | Where-Object { $_.name -eq $ProjName } | Select-Object -First 1

$Ref = ""
if ($existing) {
    $Ref = $existing.id
    Write-Host "  Projet existant trouvé : $ProjName ($Ref)" -ForegroundColor Green
} else {
    Write-Host "  Création du projet '$ProjName'..." -ForegroundColor Yellow
    $DbPass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | ForEach-Object { [char]$_ }) + "!Aa1"
    $proj = Req "POST" "https://api.supabase.com/v1/projects" @{
        name            = $ProjName
        organization_id = $OrgId
        plan            = "free"
        region          = $Region
        db_pass         = $DbPass
    }
    $Ref = $proj.id
    Write-Host "  Projet créé : $Ref — attente du démarrage (60s)..." -ForegroundColor Green

    # Attendre que le projet soit opérationnel
    $ready = $false
    for ($i = 0; $i -lt 24; $i++) {
        Start-Sleep -Seconds 5
        $status = Req "GET" "https://api.supabase.com/v1/projects/$Ref"
        Write-Host "  Statut : $($status.status)" -ForegroundColor Gray
        if ($status.status -eq "ACTIVE_HEALTHY") { $ready = $true; break }
    }
    if (-not $ready) { Write-Host "Le projet n'est pas prêt. Relancez le script." -ForegroundColor Red; exit 1 }
    Write-Host "  Projet opérationnel !" -ForegroundColor Green
}

# ── 3. Créer les tables ───────────────────────────────────────────
Write-Host "`n[3/6] Création des tables..." -ForegroundColor Yellow

$SQL = @"
CREATE TABLE IF NOT EXISTS members (
  id             TEXT PRIMARY KEY,
  prenom         TEXT NOT NULL,
  nom            TEXT NOT NULL,
  email          TEXT,
  telephone      TEXT,
  "dateAdhesion" TEXT NOT NULL DEFAULT '',
  statut         TEXT NOT NULL DEFAULT 'actif',
  role           TEXT NOT NULL DEFAULT 'membre',
  "motDePasse"   TEXT NOT NULL DEFAULT '1234'
);

CREATE TABLE IF NOT EXISTS projects (
  id                 TEXT PRIMARY KEY,
  nom                TEXT NOT NULL,
  description        TEXT NOT NULL DEFAULT '',
  type               TEXT NOT NULL DEFAULT 'standard',
  budget             DOUBLE PRECISION NOT NULL DEFAULT 0,
  "dateDebut"        TEXT NOT NULL,
  "dateFin"          TEXT,
  statut             TEXT NOT NULL DEFAULT 'actif',
  "responsableId"    TEXT NOT NULL,
  "cotisationDediee" DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS depenses (
  id          TEXT PRIMARY KEY,
  "projetId"  TEXT NOT NULL,
  "membreId"  TEXT NOT NULL,
  description TEXT NOT NULL,
  montant     DOUBLE PRECISION NOT NULL,
  date        TEXT NOT NULL,
  categorie   TEXT NOT NULL DEFAULT 'autre',
  statut      TEXT NOT NULL DEFAULT 'soumise',
  commentaire TEXT
);

CREATE TABLE IF NOT EXISTS cotisations (
  id                TEXT PRIMARY KEY,
  "membreId"        TEXT NOT NULL,
  montant           DOUBLE PRECISION NOT NULL,
  frequence         TEXT NOT NULL,
  annee             INTEGER NOT NULL,
  "dateDeclaration" TEXT NOT NULL,
  "dateEcheance"    TEXT NOT NULL,
  "datePaiement"    TEXT,
  statut            TEXT NOT NULL DEFAULT 'en_attente',
  "projetId"        TEXT,
  type              TEXT NOT NULL DEFAULT 'normale',
  commentaire       TEXT
);

ALTER TABLE members     DISABLE ROW LEVEL SECURITY;
ALTER TABLE projects    DISABLE ROW LEVEL SECURITY;
ALTER TABLE depenses    DISABLE ROW LEVEL SECURITY;
ALTER TABLE cotisations DISABLE ROW LEVEL SECURITY;

ALTER PUBLICATION supabase_realtime ADD TABLE members, projects, depenses, cotisations;
"@

Req "POST" "https://api.supabase.com/v1/projects/$Ref/database/query" @{ query = $SQL } | Out-Null
Write-Host "  Tables créées, RLS désactivé, realtime activé." -ForegroundColor Green

# ── 4. Récupérer les clés API ─────────────────────────────────────
Write-Host "`n[4/6] Récupération des clés API..." -ForegroundColor Yellow
$keys = Req "GET" "https://api.supabase.com/v1/projects/$Ref/api-keys"
$AnonKey = ($keys | Where-Object { $_.name -eq "anon" } | Select-Object -First 1).api_key
$ProjUrl = "https://$Ref.supabase.co"
Write-Host "  URL     : $ProjUrl" -ForegroundColor Green
Write-Host "  Anon key: $($AnonKey.Substring(0,20))..." -ForegroundColor Green

# ── 5. Mettre à jour supabase_config.dart ────────────────────────
Write-Host "`n[5/6] Mise à jour de lib\supabase_config.dart..." -ForegroundColor Yellow
$ConfigPath = "lib\supabase_config.dart"
$Config = @"
// Configuration Supabase — généré automatiquement par supabase_auto_setup.ps1

const supabaseUrl     = '$ProjUrl';
const supabaseAnonKey = '$AnonKey';

// Ne pas modifier — utilisé pour détecter si Supabase est configuré.
const supabaseConfigured = supabaseUrl != 'VOTRE_SUPABASE_URL';
"@
Set-Content $ConfigPath $Config -Encoding UTF8
Write-Host "  supabase_config.dart mis à jour." -ForegroundColor Green

# ── 6. flutter pub get ────────────────────────────────────────────
Write-Host "`n[6/6] flutter pub get..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter pub get" -ForegroundColor Red; exit 1 }

Write-Host "`n=== Configuration terminée ! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Projet Supabase   : $ProjUrl" -ForegroundColor White
Write-Host "Dashboard         : https://supabase.com/dashboard/project/$Ref" -ForegroundColor White
Write-Host ""
Write-Host "Pour builder l'APK :" -ForegroundColor White
Write-Host "  flutter build apk --release" -ForegroundColor Green
Write-Host ""
Write-Host "Au premier lancement, les données de démo seront" -ForegroundColor Gray
Write-Host "automatiquement créées dans Supabase." -ForegroundColor Gray
