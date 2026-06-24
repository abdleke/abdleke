// ⚠️  CONFIGURATION REQUISE — voir SUPABASE_SETUP.md
//
// Remplacez les deux valeurs ci-dessous par celles de votre projet Supabase.
// Supabase Dashboard → Settings → API → Project URL & anon key
//
// Tant que ces valeurs ne sont pas renseignées, l'application fonctionne
// en mode hors-ligne (données locales uniquement).

const supabaseUrl     = 'VOTRE_SUPABASE_URL';
const supabaseAnonKey = 'VOTRE_SUPABASE_ANON_KEY';

// Ne pas modifier — utilisé pour détecter si Supabase est configuré.
const supabaseConfigured = supabaseUrl != 'VOTRE_SUPABASE_URL';
