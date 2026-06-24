# supabase_auto_setup.ps1
# Lancer depuis le dossier app/ :  .\supabase_auto_setup.ps1

$Token = if ($env:SUPABASE_TOKEN) { $env:SUPABASE_TOKEN } else {
    Read-Host "Collez votre Supabase Personal Access Token"
}
$ProjName = "jam3yati"
$Region   = "eu-west-1"

$H = @{ "Authorization" = "Bearer $Token"; "Content-Type" = "application/json" }

function Req($Method, $Url, $Body = $null) {
    $params = @{ Uri = $Url; Method = $Method; Headers = $H; ErrorAction = "Stop" }
    if ($Body) { $params.Body = ($Body | ConvertTo-Json -Depth 10) }
    try { return Invoke-RestMethod @params }
    catch { Write-Host "  ERREUR : $_" -ForegroundColor Red; exit 1 }
}

Write-Host "=== Jamiyati - Configuration Supabase ===" -ForegroundColor Cyan

# 1. Organisation
Write-Host "`n[1/6] Recuperation de l'organisation..." -ForegroundColor Yellow
$orgs = Req "GET" "https://api.supabase.com/v1/organizations"
if ($orgs.Count -eq 0) { Write-Host "Aucune organisation trouvee." -ForegroundColor Red; exit 1 }
$OrgId = $orgs[0].id
Write-Host "  Org : $($orgs[0].name) ($OrgId)" -ForegroundColor Green

# 2. Projet existant ou creation
Write-Host "`n[2/6] Verification du projet..." -ForegroundColor Yellow
$projects = Req "GET" "https://api.supabase.com/v1/projects"
$existing = $projects | Where-Object { $_.name -eq $ProjName } | Select-Object -First 1

$Ref = ""
if ($existing) {
    $Ref = $existing.id
    Write-Host "  Projet existant : $ProjName ($Ref)" -ForegroundColor Green
} else {
    Write-Host "  Creation du projet '$ProjName'..." -ForegroundColor Yellow
    $chars = (65..90) + (97..122) + (48..57)
    $DbPass = (-join ($chars | Get-Random -Count 20 | ForEach-Object { [char]$_ })) + "!Aa1"
    $proj = Req "POST" "https://api.supabase.com/v1/projects" @{
        name            = $ProjName
        organization_id = $OrgId
        plan            = "free"
        region          = $Region
        db_pass         = $DbPass
    }
    $Ref = $proj.id
    Write-Host "  Projet cree : $Ref - attente demarrage..." -ForegroundColor Green

    $ready = $false
    for ($i = 0; $i -lt 24; $i++) {
        Start-Sleep -Seconds 5
        $s = Req "GET" "https://api.supabase.com/v1/projects/$Ref"
        Write-Host "  Statut : $($s.status)" -ForegroundColor Gray
        if ($s.status -eq "ACTIVE_HEALTHY") { $ready = $true; break }
    }
    if (-not $ready) { Write-Host "Projet pas pret. Relancez le script." -ForegroundColor Red; exit 1 }
    Write-Host "  Projet operationnel !" -ForegroundColor Green
}

# 3. Tables + RLS + Realtime
Write-Host "`n[3/6] Creation des tables..." -ForegroundColor Yellow

$SQL = @'
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
'@

Req "POST" "https://api.supabase.com/v1/projects/$Ref/database/query" @{ query = $SQL } | Out-Null
Write-Host "  Tables creees, RLS desactive, Realtime actif." -ForegroundColor Green

# 4. Cles API
Write-Host "`n[4/6] Recuperation des cles API..." -ForegroundColor Yellow
$keys    = Req "GET" "https://api.supabase.com/v1/projects/$Ref/api-keys"
$AnonKey = ($keys | Where-Object { $_.name -eq "anon" } | Select-Object -First 1).api_key
$ProjUrl = "https://$Ref.supabase.co"
Write-Host "  URL : $ProjUrl" -ForegroundColor Green
Write-Host "  Key : $($AnonKey.Substring(0,20))..." -ForegroundColor Green

# 5. Mise a jour de supabase_config.dart
Write-Host "`n[5/6] Mise a jour de lib\supabase_config.dart..." -ForegroundColor Yellow
$ConfigPath = "lib\supabase_config.dart"
$Config = "// Configuration Supabase - genere par supabase_auto_setup.ps1`n`nconst supabaseUrl     = '$ProjUrl';`nconst supabaseAnonKey = '$AnonKey';`n`nconst supabaseConfigured = supabaseUrl != 'VOTRE_SUPABASE_URL';`n"
[System.IO.File]::WriteAllText((Resolve-Path $ConfigPath), $Config, [System.Text.Encoding]::UTF8)
Write-Host "  supabase_config.dart mis a jour." -ForegroundColor Green

# 6. flutter pub get
Write-Host "`n[6/6] flutter pub get..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "Erreur flutter pub get" -ForegroundColor Red; exit 1 }

Write-Host "`n=== Termine ! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Projet  : $ProjUrl" -ForegroundColor White
Write-Host "Dashboard : https://supabase.com/dashboard/project/$Ref" -ForegroundColor White
Write-Host ""
Write-Host "Prochaine etape :" -ForegroundColor White
Write-Host "  flutter build apk --release" -ForegroundColor Green
