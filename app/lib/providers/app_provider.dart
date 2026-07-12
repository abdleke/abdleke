import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/cotisation.dart';
import '../models/exercice_annuel.dart';
import '../models/echeance.dart';
import '../models/budget_projet_exercice.dart';
import '../l10n/strings.dart';
const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  List<Member> _members = [];
  List<Project> _projects = [];
  List<Depense> _depenses = [];
  List<Cotisation> _cotisations = [];
  List<ExerciceAnnuel> _exercices = [];
  List<Echeance> _echeances = [];
  List<BudgetProjetExercice> _budgetsProjets = [];
  String _currentUserId = '';
  String _language = 'ar';
  String _currency = 'درهم';
  bool _isLoggedIn = false;
  String _initStatus = 'initialisation...';
  String? _lastSaveError;

  String get initStatus => _initStatus;
  String? get lastSaveError => _lastSaveError;
  void clearLastSaveError() { _lastSaveError = null; }

  // Diagnostic: raw row counts from Supabase (before parsing)
  int _rawCotisationsCount = -1; // -1 = not yet fetched
  int get rawCotisationsCount => _rawCotisationsCount;

  StreamSubscription<List<Map<String, dynamic>>>? _membersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _projectsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _depensesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _cotisationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _exercicesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _echeancesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _budgetsProjetsSub;

  List<Member> get members => List.unmodifiable(_members);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<Cotisation> get cotisations => List.unmodifiable(_cotisations);
  List<ExerciceAnnuel> get exercices => List.unmodifiable(_exercices);
  List<Echeance> get echeances => List.unmodifiable(_echeances);
  List<BudgetProjetExercice> get budgetsProjets => List.unmodifiable(_budgetsProjets);
  String get currentUserId => _currentUserId;
  String get language => _language;
  String get currency => _currency;
  bool get isLoggedIn => _isLoggedIn;

  Member? get currentUser =>
      _members.cast<Member?>().firstWhere((m) => m?.id == _currentUserId, orElse: () => null);

  ExerciceAnnuel? get activeExercice =>
      _exercices.cast<ExerciceAnnuel?>().firstWhere(
        (e) => e?.statut == ExerciceStatus.actif, orElse: () => null);

  SupabaseClient get _db => Supabase.instance.client;

  // ── Initialization ────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('jamiyati_lang') ?? 'ar';
    _currency = prefs.getString('jamiyati_currency') ?? 'درهم';
    await _initWithSupabase(prefs);
  }

  List<T> _parseList<T>(List<Map<String, dynamic>> rows, T Function(Map<String, dynamic>) fromJson) {
    final result = <T>[];
    for (final row in rows) {
      try {
        result.add(fromJson(row));
      } catch (e) {
        debugPrint('[Jamiyati] Erreur parsing ligne: $e — $row');
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _safeSelect(String table) async {
    try {
      final data = await _db.from(table).select();
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      final msg = e.toString();
      _initStatus = 'Erreur $table: ${msg.length > 120 ? msg.substring(0, 120) : msg}';
      debugPrint('[Jamiyati] Erreur lecture $table: $e');
      return [];
    }
  }

  Future<void> _initWithSupabase(SharedPreferences prefs) async {
    // Vérifier que Supabase est bien initialisé
    try {
      Supabase.instance.client;
    } catch (e) {
      _initStatus = 'Supabase non initialisé: $e';
      notifyListeners();
      return;
    }

    try {
      await _db.from('members').select('id').limit(1);
    } catch (e) {
      _initStatus = 'Erreur connexion: $e';
      debugPrint('[Jamiyati] Erreur init membres: $e');
      notifyListeners();
    }

    // Chargement parallèle
    final results = await Future.wait([
      _safeSelect('members'),
      _safeSelect('projects'),
      _safeSelect('depenses'),
      _safeSelect('cotisations'),
      _safeSelect('exercices'),
      _safeSelect('echeances'),
      _safeSelect('budget_projet_exercice'),
    ]);

    final membersData = results[0];
    if (membersData.isNotEmpty) {
      _members = membersData.map((e) => Member.fromJson(e)).toList();
      _initStatus = '${_members.length} membre(s) chargé(s)';
    } else if (!_initStatus.startsWith('Erreur')) {
      _initStatus = 'Aucun membre chargé — vérifier Supabase';
    }

    _projects       = _parseList(results[1], Project.fromJson);
    _depenses       = _parseList(results[2], Depense.fromJson);
    _rawCotisationsCount = results[3].length;
    _cotisations    = _parseList(results[3], Cotisation.fromJson);
    debugPrint('[Jamiyati] cotisations: $_rawCotisationsCount raw rows → ${_cotisations.length} parsed');
    if (results[3].isNotEmpty && _cotisations.isEmpty) {
      debugPrint('[Jamiyati] PREMIERE LIGNE COTISATION: ${results[3].first}');
    }
    _exercices      = _parseList(results[4], ExerciceAnnuel.fromJson);
    _echeances      = _parseList(results[5], Echeance.fromJson);
    _budgetsProjets = _parseList(results[6], BudgetProjetExercice.fromJson);

    _setupStreams();
    _restoreSession(prefs);
    notifyListeners();
  }

  void _setupStreams() {
    _membersSub?.cancel(); _projectsSub?.cancel(); _depensesSub?.cancel();
    _cotisationsSub?.cancel(); _exercicesSub?.cancel(); _echeancesSub?.cancel();
    _budgetsProjetsSub?.cancel();

    void Function(Object, StackTrace) onErr(String table) =>
        (Object e, StackTrace st) => debugPrint('[Jamiyati] stream error ($table): $e');

    _membersSub = _db.from('members').stream(primaryKey: ['id']).listen(
      (data) { _members = _parseList(data, Member.fromJson); notifyListeners(); },
      onError: onErr('members'),
    );
    _projectsSub = _db.from('projects').stream(primaryKey: ['id']).listen(
      (data) { _projects = _parseList(data, Project.fromJson); notifyListeners(); },
      onError: onErr('projects'),
    );
    _depensesSub = _db.from('depenses').stream(primaryKey: ['id']).listen(
      (data) { _depenses = _parseList(data, Depense.fromJson); notifyListeners(); },
      onError: onErr('depenses'),
    );
    _cotisationsSub = _db.from('cotisations').stream(primaryKey: ['id']).listen(
      (data) {
        _rawCotisationsCount = data.length;
        _cotisations = _parseList(data, Cotisation.fromJson);
        debugPrint('[Jamiyati] cotisations stream: ${data.length} raw → ${_cotisations.length} parsed');
        notifyListeners();
      },
      onError: onErr('cotisations'),
    );
    _exercicesSub = _db.from('exercices').stream(primaryKey: ['id']).listen(
      (data) { _exercices = _parseList(data, ExerciceAnnuel.fromJson); notifyListeners(); },
      onError: onErr('exercices'),
    );
    _echeancesSub = _db.from('echeances').stream(primaryKey: ['id']).listen(
      (data) { _echeances = _parseList(data, Echeance.fromJson); notifyListeners(); },
      onError: onErr('echeances'),
    );
    _budgetsProjetsSub = _db.from('budget_projet_exercice').stream(primaryKey: ['id']).listen(
      (data) { _budgetsProjets = _parseList(data, BudgetProjetExercice.fromJson); notifyListeners(); },
      onError: onErr('budget_projet_exercice'),
    );
  }


  Future<void> resetData() async {
    // Keep members and projects, only clear financial data
    _depenses = [];
    _cotisations = [];
    _exercices = [];
    _echeances = [];
    notifyListeners();
    try {
      for (final table in ['echeances', 'cotisations', 'depenses', 'exercices']) {
        await _db.from(table).delete().neq('id', '__purge__');
      }
    } catch (e) {
      debugPrint('[Jamiyati] Erreur purge Supabase: $e');
    }
  }

  void _restoreSession(SharedPreferences prefs) {
    final savedUserId = prefs.getString('jamiyati_session');
    if (savedUserId != null && _members.any((m) => m.id == savedUserId)) {
      _currentUserId = savedUserId;
      _isLoggedIn = true;
    }
  }

  @override
  void dispose() {
    _membersSub?.cancel(); _projectsSub?.cancel(); _depensesSub?.cancel();
    _cotisationsSub?.cancel(); _exercicesSub?.cancel(); _echeancesSub?.cancel();
    _budgetsProjetsSub?.cancel();
    super.dispose();
  }

  // ── Authentication ─────────────────────────────────────────────

  String? login(String identifier, String password) {
    final id = identifier.trim();
    final pass = password.trim();
    if (id.isEmpty || pass.isEmpty) return _err('emptyFields');

    final member = _members.cast<Member?>().firstWhere(
      (m) => m != null && (m.telephone == id || m.email == id || m.id == id),
      orElse: () => null);
    if (member == null) return _err('notFound');
    if (member.statut == MemberStatus.suspendu) return _err('suspended');
    if (member.motDePasse != pass) return _err('wrongPassword');

    _currentUserId = member.id;
    _isLoggedIn = true;
    _persistAuth();
    notifyListeners();
    return null;
  }

  void logout() {
    _isLoggedIn = false; _currentUserId = '';
    _persistAuth(); notifyListeners();
  }

  String _err(String code) {
    const keys = {
      'emptyFields': 'auth.errEmpty',
      'notFound': 'auth.errNotFound',
      'suspended': 'auth.errSuspended',
      'wrongPassword': 'auth.errWrongPassword',
    };
    return AppStrings.get(keys[code] ?? code, _language);
  }

  // ── Permissions ────────────────────────────────────────────────

  bool canValidateExpense(String projetId) {
    final user = currentUser;
    if (user == null) return false;
    if (user.role == MemberRole.admin) return true;
    return _projects.cast<Project?>().firstWhere((p) => p?.id == projetId, orElse: () => null)?.responsableId == user.id;
  }

  bool canValidateCotisation() =>
      currentUser?.role == MemberRole.tresorier || currentUser?.role == MemberRole.admin;

  bool canManageMembers() => currentUser?.role == MemberRole.admin;

  bool canManageProjects() => currentUser?.role == MemberRole.admin;

  bool canAddCotisation() => _isLoggedIn;

  // ── Visibility filters ─────────────────────────────────────────

  List<Project> get visibleProjects {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.chefProjet) {
      return List.unmodifiable(_projects.where((p) => p.responsableId == user.id));
    }
    return List.unmodifiable(_projects);
  }

  List<Cotisation> get visibleCotisations {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) return List.unmodifiable(_cotisations);
    return List.unmodifiable(_cotisations.where((c) => c.membreId == user.id));
  }

  List<Member> get visibleMembers {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) return List.unmodifiable(_members);
    return List.unmodifiable(_members.where((m) => m.id == user.id));
  }

  List<Depense> get visibleDepenses {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) return List.unmodifiable(_depenses);
    if (user.role == MemberRole.chefProjet) {
      final myProjectIds = _projects.where((p) => p.responsableId == user.id).map((p) => p.id).toSet();
      return List.unmodifiable(_depenses.where((d) => myProjectIds.contains(d.projetId) || d.membreId == user.id));
    }
    return List.unmodifiable(_depenses.where((d) => d.membreId == user.id));
  }

  // ── Exercice helpers ───────────────────────────────────────────

  double budgetExercice(String exerciceId) =>
      _cotisations.where((c) => c.exerciceId == exerciceId && c.type == CotisationType.normale)
          .fold(0.0, (sum, c) => sum + c.montantTotal);

  double collecteExercice(String exerciceId) {
    final ids = _cotisations
        .where((c) => c.exerciceId == exerciceId && c.type == CotisationType.normale)
        .map((c) => c.id).toSet();
    return _echeances.where((e) => ids.contains(e.cotisationId) && e.statut == EcheanceStatus.validee)
        .fold(0.0, (sum, e) => sum + e.montant);
  }

  // Budget alloué aux projets normaux de l'exercice (table ternaire)
  double budgetAlloueExercice(String exerciceId) =>
      _budgetsProjets
          .where((b) => b.exerciceId == exerciceId)
          .fold(0.0, (sum, b) => sum + b.budget);

  // Budget disponible = budget réel (cotisations) - budget alloué aux projets normaux
  double budgetDisponibleExercice(String exerciceId) =>
      budgetExercice(exerciceId) - budgetAlloueExercice(exerciceId);

  // Budget d'un projet pour un exercice donné (table ternaire)
  double getProjectBudgetForExercice(String projetId, String? exerciceId) {
    if (exerciceId == null) return 0;
    return _budgetsProjets
        .where((b) => b.projetId == projetId && b.exerciceId == exerciceId)
        .fold(0.0, (sum, b) => sum + b.budget);
  }

  // Budget effectif d'un projet : ternaire pour normale, budget fixe pour ponctuel
  double getProjectEffectiveBudget(String projetId) {
    final p = _projects.cast<Project?>().firstWhere((x) => x?.id == projetId, orElse: () => null);
    if (p == null) return 0;
    if (p.type == ProjectType.ponctuel) return p.budget;
    return getProjectBudgetForExercice(projetId, activeExercice?.id);
  }

  List<BudgetProjetExercice> budgetsForProjet(String projetId) =>
      _budgetsProjets.where((b) => b.projetId == projetId).toList()
        ..sort((a, b) => a.exerciceId.compareTo(b.exerciceId));

  // Projets normaux liés à un exercice, avec leur budget et dépenses
  List<({Project projet, double budget, double depenses})> projetsResume(String exerciceId) {
    final entries = _budgetsProjets.where((b) => b.exerciceId == exerciceId);
    return entries.map((b) {
      final p = _projects.cast<Project?>().firstWhere((x) => x?.id == b.projetId, orElse: () => null);
      if (p == null) return null;
      final spent = _depenses
          .where((d) => d.projetId == p.id && d.statut == DepenseStatus.approuvee)
          .fold(0.0, (s, d) => s + d.montant);
      return (projet: p, budget: b.budget, depenses: spent);
    }).whereType<({Project projet, double budget, double depenses})>().toList()
      ..sort((a, b) => a.projet.nom.compareTo(b.projet.nom));
  }

  // Total dépenses approuvées sur les projets normaux d'un exercice
  double depensesTotalesExercice(String exerciceId) =>
      projetsResume(exerciceId).fold(0.0, (s, r) => s + r.depenses);

  double getProjectCommitted(String projetId) =>
      _cotisations
          .where((c) => c.projetId == projetId && c.type == CotisationType.dediee)
          .fold(0.0, (sum, c) => sum + c.montantTotal);

  double getProjectCollected(String projetId) {
    final cotIds = _cotisations
        .where((c) => c.projetId == projetId && c.type == CotisationType.dediee)
        .map((c) => c.id).toSet();
    return _echeances
        .where((e) => cotIds.contains(e.cotisationId) && e.statut == EcheanceStatus.validee)
        .fold(0.0, (sum, e) => sum + e.montant);
  }

  List<Echeance> echeancesFor(String cotisationId) =>
      _echeances.where((e) => e.cotisationId == cotisationId).toList()
        ..sort((a, b) => a.numero.compareTo(b.numero));

  List<Echeance> get overdueEcheances =>
      _echeances.where((e) => e.statut == EcheanceStatus.enRetard).toList();

  List<Echeance> upcomingEcheances({int withinDays = 30}) {
    final now = DateTime.now();
    final limit = now.add(Duration(days: withinDays));
    return _echeances.where((e) {
      if (e.statut != EcheanceStatus.enAttente) return false;
      final d = DateTime.tryParse(e.dateEcheance);
      return d != null && d.isAfter(now) && d.isBefore(limit);
    }).toList()..sort((a, b) => a.dateEcheance.compareTo(b.dateEcheance));
  }

  // ── Helpers ────────────────────────────────────────────────────

  double getProjectSpent(String projetId) => _depenses
      .where((d) => d.projetId == projetId && d.statut == DepenseStatus.approuvee)
      .fold(0, (sum, d) => sum + d.montant);

  String getMemberName(String id) {
    final m = _members.cast<Member?>().firstWhere((m) => m?.id == id, orElse: () => null);
    return m?.fullName ?? '—';
  }

  String getProjectName(String id) {
    final p = _projects.cast<Project?>().firstWhere((p) => p?.id == id, orElse: () => null);
    return p?.nom ?? '—';
  }

  String getCotisationMemberName(String cotisationId) {
    final c = _cotisations.cast<Cotisation?>().firstWhere((c) => c?.id == cotisationId, orElse: () => null);
    return c != null ? getMemberName(c.membreId) : '—';
  }

  double getCotisationMontant(String cotisationId) {
    final c = _cotisations.cast<Cotisation?>().firstWhere((c) => c?.id == cotisationId, orElse: () => null);
    return c?.montantTotal ?? 0;
  }

  // ── Language & Currency ────────────────────────────────────────

  void setLanguage(String lang) {
    _language = lang;
    SharedPreferences.getInstance().then((p) => p.setString('jamiyati_lang', lang));
    notifyListeners();
  }

  void setCurrency(String c) {
    _currency = c;
    SharedPreferences.getInstance().then((p) => p.setString('jamiyati_currency', c));
    notifyListeners();
  }

  // ── Members ────────────────────────────────────────────────────

  void addMember(Member m) {
    _members = [..._members, m]; notifyListeners(); _upsert('members', m.toJson());
  }

  void updateMember(Member m) {
    final i = _members.indexWhere((x) => x.id == m.id); if (i < 0) return;
    _members = List.of(_members)..[i] = m; notifyListeners(); _upsert('members', m.toJson());
  }

  void deleteMember(String id) {
    _members = _members.where((m) => m.id != id).toList();
    notifyListeners(); _remove('members', id);
  }

  // ── Projects ───────────────────────────────────────────────────

  void addProject(Project p) {
    _projects = [..._projects, p]; notifyListeners(); _upsert('projects', p.toJson());
  }

  void updateProject(Project p) {
    final i = _projects.indexWhere((x) => x.id == p.id); if (i < 0) return;
    _projects = List.of(_projects)..[i] = p; notifyListeners(); _upsert('projects', p.toJson());
  }

  void deleteProject(String id) {
    final budgetIds = _budgetsProjets.where((b) => b.projetId == id).map((b) => b.id).toList();
    _projects = _projects.where((p) => p.id != id).toList();
    _budgetsProjets = _budgetsProjets.where((b) => b.projetId != id).toList();
    notifyListeners();
    _remove('projects', id);
    for (final bid in budgetIds) { _remove('budget_projet_exercice', bid); }
  }

  // ── Budget Projet × Exercice (relation ternaire) ───────────────

  void addBudgetProjetExercice(BudgetProjetExercice b) {
    // Remplace si entrée déjà existante pour ce projet+exercice
    _budgetsProjets = [
      ..._budgetsProjets.where((x) => !(x.projetId == b.projetId && x.exerciceId == b.exerciceId)),
      b,
    ];
    notifyListeners();
    _upsert('budget_projet_exercice', b.toJson());
  }

  void updateBudgetProjetExercice(BudgetProjetExercice b) {
    final i = _budgetsProjets.indexWhere((x) => x.id == b.id); if (i < 0) return;
    _budgetsProjets = List.of(_budgetsProjets)..[i] = b;
    notifyListeners();
    _upsert('budget_projet_exercice', b.toJson());
  }

  void removeBudgetProjetExercice(String id) {
    _budgetsProjets = _budgetsProjets.where((b) => b.id != id).toList();
    notifyListeners();
    _remove('budget_projet_exercice', id);
  }

  // ── Dépenses ───────────────────────────────────────────────────

  void addDepense(Depense d) {
    _depenses = [..._depenses, d]; notifyListeners(); _upsert('depenses', d.toJson());
  }

  void approveDepense(String id) =>
      _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.approuvee));

  void rejectDepense(String id, String reason) =>
      _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.rejetee, commentaire: reason));

  void marquerRembourse(String id) =>
      _updateDepense(id, (d) => d.copyWith(rembourse: true));

  void deleteDepense(String id) {
    _depenses = _depenses.where((d) => d.id != id).toList();
    notifyListeners(); _remove('depenses', id);
  }

  void _updateDepense(String id, Depense Function(Depense) fn) {
    final i = _depenses.indexWhere((d) => d.id == id); if (i < 0) return;
    final updated = fn(_depenses[i]);
    _depenses = List.of(_depenses)..[i] = updated;
    notifyListeners(); _upsert('depenses', updated.toJson());
  }

  // ── Exercices ──────────────────────────────────────────────────

  void addExercice(ExerciceAnnuel e) {
    ExerciceAnnuel? closed;
    _exercices = _exercices.map((x) {
      if (x.statut == ExerciceStatus.actif) {
        closed = x.copyWith(statut: ExerciceStatus.cloture);
        return closed!;
      }
      return x;
    }).toList();
    _exercices = [..._exercices, e];
    notifyListeners();
    if (closed != null) _upsert('exercices', closed!.toJson());
    _upsert('exercices', e.toJson());
  }

  void updateExercice(ExerciceAnnuel e) {
    final i = _exercices.indexWhere((x) => x.id == e.id); if (i < 0) return;
    _exercices = List.of(_exercices)..[i] = e;
    notifyListeners(); _upsert('exercices', e.toJson());
  }

  // ── Cotisations (engagements) ──────────────────────────────────

  Future<bool> addCotisation(Cotisation c) async {
    final echeancesNouv = _generateEcheances(c);
    _cotisations = [..._cotisations, c];
    _echeances = [..._echeances, ...echeancesNouv];
    notifyListeners();
    final ok = await _upsert('cotisations', c.toJson());
    if (!ok) {
      _cotisations = _cotisations.where((x) => x.id != c.id).toList();
      _echeances = _echeances.where((e) => e.cotisationId != c.id).toList();
      notifyListeners();
      return false;
    }
    for (final e in echeancesNouv) {
      final eOk = await _upsert('echeances', e.toJson());
      if (!eOk) {
        _cotisations = _cotisations.where((x) => x.id != c.id).toList();
        _echeances = _echeances.where((e) => e.cotisationId != c.id).toList();
        notifyListeners();
        _remove('cotisations', c.id);
        return false;
      }
    }
    return true;
  }

  void updateCotisation(Cotisation c) {
    final i = _cotisations.indexWhere((x) => x.id == c.id); if (i < 0) return;
    _cotisations = List.of(_cotisations)..[i] = c;
    notifyListeners(); _upsert('cotisations', c.toJson());
  }

  void deleteCotisation(String id) {
    final echeanceIds = _echeances.where((e) => e.cotisationId == id).map((e) => e.id).toList();
    _cotisations = _cotisations.where((c) => c.id != id).toList();
    _echeances = _echeances.where((e) => e.cotisationId != id).toList();
    notifyListeners();
    _remove('cotisations', id);
    for (final eid in echeanceIds) { _remove('echeances', eid); }
  }

  List<Echeance> _generateEcheances(Cotisation c) {
    int totalMonths = 12;
    if (c.type == CotisationType.dediee && c.projetId != null) {
      final proj = _projects.cast<Project?>().firstWhere((p) => p?.id == c.projetId, orElse: () => null);
      if (proj?.dateFin != null && c.dateDebut.isNotEmpty) {
        final start = DateTime.parse(c.dateDebut);
        final end = DateTime.parse(proj!.dateFin!);
        totalMonths = (end.year - start.year) * 12 + (end.month - start.month);
        if (totalMonths < 1) totalMonths = 1;
      }
    }
    if (c.dateDebut.isEmpty) return [];
    return Echeance.generer(
      cotisationId: c.id,
      montantTotal: c.montantTotal,
      nombreEcheances: c.nombreEcheances,
      dateDebut: DateTime.parse(c.dateDebut),
      totalMonths: totalMonths,
      newId: newId,
    );
  }

  // ── Échéances ──────────────────────────────────────────────────

  void validateEcheance(String id) {
    _updateEcheance(id, (e) => e.copyWith(
      statut: EcheanceStatus.validee,
      datePaiement: DateTime.now().toIso8601String().split('T')[0],
    ));
  }

  void markEcheanceOverdue(String id) =>
      _updateEcheance(id, (e) => e.copyWith(statut: EcheanceStatus.enRetard));

  void _updateEcheance(String id, Echeance Function(Echeance) fn) {
    final i = _echeances.indexWhere((e) => e.id == id); if (i < 0) return;
    final updated = fn(_echeances[i]);
    _echeances = List.of(_echeances)..[i] = updated;
    notifyListeners(); _upsert('echeances', updated.toJson());
  }

  // ── Storage ────────────────────────────────────────────────────

  Future<bool> _upsert(String table, Map<String, dynamic> data) async {
    try {
      await _db.from(table).upsert(data);
      return true;
    } catch (e) {
      final msg = e.toString();
      _lastSaveError = 'Erreur $table: ${msg.length > 300 ? msg.substring(0, 300) : msg}';
      debugPrint('[Jamiyati] upsert error ($table): $e\nData keys: ${data.keys.toList()}');
      notifyListeners();
      return false;
    }
  }

  void _remove(String table, String id) {
    _db.from(table).delete().eq('id', id).catchError(
      (e) => debugPrint('[Jamiyati] delete error ($table/$id): $e'));
  }

  Future<void> _persistAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isLoggedIn) {
      await prefs.setString('jamiyati_session', _currentUserId);
    } else {
      await prefs.remove('jamiyati_session');
    }
  }

  String newId() => _uuid.v4();
}
