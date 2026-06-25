import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/cotisation.dart';
import '../data/seed_data.dart';
import '../supabase_config.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  List<Member> _members = [];
  List<Project> _projects = [];
  List<Depense> _depenses = [];
  List<Cotisation> _cotisations = [];
  String _currentUserId = '';
  String _language = 'ar';
  bool _isLoggedIn = false;
  bool _supabaseAvailable = false;

  StreamSubscription<List<Map<String, dynamic>>>? _membersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _projectsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _depensesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _cotisationsSub;

  List<Member> get members => List.unmodifiable(_members);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<Cotisation> get cotisations => List.unmodifiable(_cotisations);
  String get currentUserId => _currentUserId;
  String get language => _language;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOnlineMode => _supabaseAvailable;

  Member? get currentUser =>
      _members.cast<Member?>().firstWhere((m) => m?.id == _currentUserId, orElse: () => null);

  SupabaseClient get _db => Supabase.instance.client;

  // ── Initialization ────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('jamiyati_lang') ?? 'ar';

    _supabaseAvailable = supabaseConfigured;
    if (_supabaseAvailable) {
      try {
        Supabase.instance.client; // verif disponible
      } catch (_) {
        _supabaseAvailable = false;
      }
    }

    if (_supabaseAvailable) {
      await _initWithSupabase(prefs);
    } else {
      await _initLocal(prefs);
    }
  }

  Future<void> _initWithSupabase(SharedPreferences prefs) async {
    try {
      // Vérifier si la DB est vide → seeder au premier lancement
      final check = await _db.from('members').select('id').limit(1);
      if ((check as List).isEmpty) {
        await _seedSupabase();
      }

      // Récupération initiale pour restaurer la session immédiatement
      final results = await Future.wait([
        _db.from('members').select(),
        _db.from('projects').select(),
        _db.from('depenses').select(),
        _db.from('cotisations').select(),
      ]);

      _members = (results[0] as List).map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
      _projects = (results[1] as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
      _depenses = (results[2] as List).map((e) => Depense.fromJson(e as Map<String, dynamic>)).toList();
      _cotisations = (results[3] as List).map((e) => Cotisation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Jamiyati] Supabase indisponible, basculement hors-ligne: $e');
      _supabaseAvailable = false;
      await _initLocal(prefs);
      return;
    }

    _setupStreams();
    _restoreSession(prefs);
    notifyListeners();
  }

  void _setupStreams() {
    _membersSub?.cancel();
    _projectsSub?.cancel();
    _depensesSub?.cancel();
    _cotisationsSub?.cancel();

    _membersSub = _db.from('members').stream(primaryKey: ['id']).listen((data) {
      _members = data.map((e) => Member.fromJson(e)).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream members: $e'));

    _projectsSub = _db.from('projects').stream(primaryKey: ['id']).listen((data) {
      _projects = data.map((e) => Project.fromJson(e)).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream projects: $e'));

    _depensesSub = _db.from('depenses').stream(primaryKey: ['id']).listen((data) {
      _depenses = data.map((e) => Depense.fromJson(e)).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream depenses: $e'));

    _cotisationsSub = _db.from('cotisations').stream(primaryKey: ['id']).listen((data) {
      _cotisations = data.map((e) => Cotisation.fromJson(e)).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream cotisations: $e'));
  }

  Future<void> _seedSupabase() async {
    await _db.from('members').insert(SeedData.members().map((m) => m.toJson()).toList());
    await _db.from('projects').insert(SeedData.projects().map((p) => p.toJson()).toList());
    await _db.from('depenses').insert(SeedData.depenses().map((d) => d.toJson()).toList());
    await _db.from('cotisations').insert(SeedData.cotisations().map((c) => c.toJson()).toList());
    debugPrint('[Jamiyati] Données initiales envoyées vers Supabase.');
  }

  Future<void> _initLocal(SharedPreferences prefs) async {
    final raw = prefs.getString('jamiyati_data');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _members = (data['members'] as List).map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
        _projects = (data['projects'] as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
        _depenses = (data['depenses'] as List).map((e) => Depense.fromJson(e as Map<String, dynamic>)).toList();
        _cotisations = (data['cotisations'] as List).map((e) => Cotisation.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _loadSeedLocal();
      }
    } else {
      _loadSeedLocal();
    }
    _restoreSession(prefs);
    notifyListeners();
  }

  void _loadSeedLocal() {
    _members = SeedData.members();
    _projects = SeedData.projects();
    _depenses = SeedData.depenses();
    _cotisations = SeedData.cotisations();
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
    _membersSub?.cancel();
    _projectsSub?.cancel();
    _depensesSub?.cancel();
    _cotisationsSub?.cancel();
    super.dispose();
  }

  // ── Authentication ────────────────────────────────────────────

  String? login(String identifier, String password) {
    final id = identifier.trim();
    final pass = password.trim();
    if (id.isEmpty || pass.isEmpty) return _err('emptyFields');

    final member = _members.cast<Member?>().firstWhere(
      (m) => m != null && (m.telephone == id || m.email == id || m.id == id),
      orElse: () => null,
    );

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
    _isLoggedIn = false;
    _currentUserId = '';
    _persistAuth();
    notifyListeners();
  }

  String _err(String code) {
    const msgs = {
      'emptyFields': 'الرجاء ملء جميع الحقول',
      'notFound': 'المستخدم غير موجود',
      'suspended': 'هذا الحساب موقوف',
      'wrongPassword': 'كلمة المرور غير صحيحة',
    };
    return msgs[code] ?? code;
  }

  // ── Permissions ───────────────────────────────────────────────

  bool canValidateExpense(String projetId) {
    final user = currentUser;
    if (user == null) return false;
    if (user.role == MemberRole.admin) return true;
    final project = _projects.cast<Project?>().firstWhere(
      (p) => p?.id == projetId, orElse: () => null);
    return project?.responsableId == user.id;
  }

  bool canValidateCotisation() =>
      currentUser?.role == MemberRole.tresorier ||
      currentUser?.role == MemberRole.admin;

  bool canManageMembers() => currentUser?.role == MemberRole.admin;

  bool canManageProjects() => currentUser?.role == MemberRole.admin;

  bool canAddCotisation() =>
      currentUser?.role == MemberRole.admin ||
      currentUser?.role == MemberRole.tresorier;

  List<Project> get visibleProjects {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) {
      return List.unmodifiable(_projects);
    }
    return List.unmodifiable(_projects.where((p) => p.responsableId == user.id));
  }

  List<Cotisation> get visibleCotisations {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) {
      return List.unmodifiable(_cotisations);
    }
    return List.unmodifiable(_cotisations.where((c) => c.membreId == user.id));
  }

  List<Member> get visibleMembers {
    final user = currentUser;
    if (user == null) return [];
    if (user.role == MemberRole.admin || user.role == MemberRole.tresorier) {
      return List.unmodifiable(_members);
    }
    return List.unmodifiable(_members.where((m) => m.id == user.id));
  }

  // ── Helpers ───────────────────────────────────────────────────

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

  // ── Language ──────────────────────────────────────────────────

  void setLanguage(String lang) {
    _language = lang;
    SharedPreferences.getInstance().then((p) => p.setString('jamiyati_lang', lang));
    notifyListeners();
  }

  // ── Members ───────────────────────────────────────────────────

  void addMember(Member m) {
    _members = [..._members, m];
    notifyListeners();
    _upsert('members', m.toJson());
  }

  void updateMember(Member m) {
    final i = _members.indexWhere((x) => x.id == m.id);
    if (i < 0) return;
    _members = List.of(_members)..[i] = m;
    notifyListeners();
    _upsert('members', m.toJson());
  }

  void deleteMember(String id) {
    _members = _members.where((m) => m.id != id).toList();
    notifyListeners();
    _remove('members', id);
  }

  // ── Projects ──────────────────────────────────────────────────

  void addProject(Project p) {
    _projects = [..._projects, p];
    notifyListeners();
    _upsert('projects', p.toJson());
  }

  void updateProject(Project p) {
    final i = _projects.indexWhere((x) => x.id == p.id);
    if (i < 0) return;
    _projects = List.of(_projects)..[i] = p;
    notifyListeners();
    _upsert('projects', p.toJson());
  }

  void deleteProject(String id) {
    _projects = _projects.where((p) => p.id != id).toList();
    notifyListeners();
    _remove('projects', id);
  }

  // ── Dépenses ──────────────────────────────────────────────────

  void addDepense(Depense d) {
    _depenses = [..._depenses, d];
    notifyListeners();
    _upsert('depenses', d.toJson());
  }

  void approveDepense(String id) =>
      _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.approuvee));

  void rejectDepense(String id, String reason) =>
      _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.rejetee, commentaire: reason));

  void deleteDepense(String id) {
    _depenses = _depenses.where((d) => d.id != id).toList();
    notifyListeners();
    _remove('depenses', id);
  }

  void _updateDepense(String id, Depense Function(Depense) fn) {
    final i = _depenses.indexWhere((d) => d.id == id);
    if (i < 0) return;
    final updated = fn(_depenses[i]);
    _depenses = List.of(_depenses)..[i] = updated;
    notifyListeners();
    _upsert('depenses', updated.toJson());
  }

  // ── Cotisations ───────────────────────────────────────────────

  void addCotisation(Cotisation c) {
    _cotisations = [..._cotisations, c];
    notifyListeners();
    _upsert('cotisations', c.toJson());
  }

  void validateCotisation(String id) {
    _updateCotisation(id, (c) => c.copyWith(
      statut: CotisationStatus.validee,
      datePaiement: DateTime.now().toIso8601String().split('T')[0],
    ));
  }

  void markCotisationOverdue(String id) =>
      _updateCotisation(id, (c) => c.copyWith(statut: CotisationStatus.enRetard));

  void rejectCotisation(String id) => markCotisationOverdue(id);

  void deleteCotisation(String id) {
    _cotisations = _cotisations.where((c) => c.id != id).toList();
    notifyListeners();
    _remove('cotisations', id);
  }

  void _updateCotisation(String id, Cotisation Function(Cotisation) fn) {
    final i = _cotisations.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final updated = fn(_cotisations[i]);
    _cotisations = List.of(_cotisations)..[i] = updated;
    notifyListeners();
    _upsert('cotisations', updated.toJson());
  }

  // ── Storage helpers ───────────────────────────────────────────

  void _upsert(String table, Map<String, dynamic> data) {
    if (_supabaseAvailable) {
      _db.from(table).upsert(data).catchError(
        (e) => debugPrint('[Jamiyati] Supabase upsert error ($table): $e'));
    } else {
      _persistLocal();
    }
  }

  void _remove(String table, String id) {
    if (_supabaseAvailable) {
      _db.from(table).delete().eq('id', id).catchError(
        (e) => debugPrint('[Jamiyati] Supabase delete error ($table/$id): $e'));
    } else {
      _persistLocal();
    }
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jamiyati_data', jsonEncode({
      'members': _members.map((m) => m.toJson()).toList(),
      'projects': _projects.map((p) => p.toJson()).toList(),
      'depenses': _depenses.map((d) => d.toJson()).toList(),
      'cotisations': _cotisations.map((c) => c.toJson()).toList(),
    }));
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
