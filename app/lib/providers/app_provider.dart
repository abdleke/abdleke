import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/cotisation.dart';
import '../data/seed_data.dart';

const _uuid = Uuid();

class AppProvider extends ChangeNotifier {
  List<Member> _members = [];
  List<Project> _projects = [];
  List<Depense> _depenses = [];
  List<Cotisation> _cotisations = [];
  String _currentUserId = '';
  String _language = 'ar';
  bool _isLoggedIn = false;
  bool _firestoreAvailable = false;

  FirebaseFirestore? _db;
  StreamSubscription<QuerySnapshot>? _membersSub;
  StreamSubscription<QuerySnapshot>? _projectsSub;
  StreamSubscription<QuerySnapshot>? _depensesSub;
  StreamSubscription<QuerySnapshot>? _cotisationsSub;

  List<Member> get members => List.unmodifiable(_members);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<Cotisation> get cotisations => List.unmodifiable(_cotisations);
  String get currentUserId => _currentUserId;
  String get language => _language;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOnlineMode => _firestoreAvailable;

  Member? get currentUser =>
      _members.cast<Member?>().firstWhere((m) => m?.id == _currentUserId, orElse: () => null);

  // ── Initialization ────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('jamiyati_lang') ?? 'ar';

    try {
      _firestoreAvailable = Firebase.apps.isNotEmpty;
    } catch (_) {
      _firestoreAvailable = false;
    }

    if (_firestoreAvailable) {
      await _initWithFirestore(prefs);
    } else {
      await _initLocal(prefs);
    }
  }

  Future<void> _initWithFirestore(SharedPreferences prefs) async {
    _db = FirebaseFirestore.instance;
    _db!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    try {
      // Initial fetch to seed if empty and enable session restore
      final membersSnap = await _db!.collection('members').get();

      if (membersSnap.docs.isEmpty) {
        await _seedFirestore();
        final seeded = await _db!.collection('members').get();
        _members = _parseDocs<Member>(seeded, Member.fromJson);
      } else {
        _members = _parseDocs<Member>(membersSnap, Member.fromJson);
      }

      final results = await Future.wait([
        _db!.collection('projects').get(),
        _db!.collection('depenses').get(),
        _db!.collection('cotisations').get(),
      ]);
      _projects = _parseDocs<Project>(results[0], Project.fromJson);
      _depenses = _parseDocs<Depense>(results[1], Depense.fromJson);
      _cotisations = _parseDocs<Cotisation>(results[2], Cotisation.fromJson);
    } catch (e) {
      debugPrint('[Jamiyati] Firestore indisponible, basculement hors-ligne: $e');
      _firestoreAvailable = false;
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

    _membersSub = _db!.collection('members').snapshots().listen((snap) {
      _members = _parseDocs<Member>(snap, Member.fromJson);
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream members: $e'));

    _projectsSub = _db!.collection('projects').snapshots().listen((snap) {
      _projects = _parseDocs<Project>(snap, Project.fromJson);
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream projects: $e'));

    _depensesSub = _db!.collection('depenses').snapshots().listen((snap) {
      _depenses = _parseDocs<Depense>(snap, Depense.fromJson);
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream depenses: $e'));

    _cotisationsSub = _db!.collection('cotisations').snapshots().listen((snap) {
      _cotisations = _parseDocs<Cotisation>(snap, Cotisation.fromJson);
      notifyListeners();
    }, onError: (e) => debugPrint('[Jamiyati] Stream cotisations: $e'));
  }

  List<T> _parseDocs<T>(QuerySnapshot snap, T Function(Map<String, dynamic>) fromJson) =>
      snap.docs.map((d) => fromJson({...d.data() as Map<String, dynamic>, 'id': d.id})).toList();

  Future<void> _seedFirestore() async {
    final db = _db!;
    final batch = db.batch();
    for (final m in SeedData.members()) {
      batch.set(db.collection('members').doc(m.id), m.toJson());
    }
    for (final p in SeedData.projects()) {
      batch.set(db.collection('projects').doc(p.id), p.toJson());
    }
    for (final d in SeedData.depenses()) {
      batch.set(db.collection('depenses').doc(d.id), d.toJson());
    }
    for (final c in SeedData.cotisations()) {
      batch.set(db.collection('cotisations').doc(c.id), c.toJson());
    }
    await batch.commit();
    debugPrint('[Jamiyati] Données initiales envoyées vers Firestore.');
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

  bool canManageProjects() =>
      currentUser?.role == MemberRole.admin ||
      currentUser?.role == MemberRole.tresorier;

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
    _write('members', m.id, m.toJson());
  }

  void updateMember(Member m) {
    final i = _members.indexWhere((x) => x.id == m.id);
    if (i < 0) return;
    _members = List.of(_members)..[i] = m;
    notifyListeners();
    _write('members', m.id, m.toJson());
  }

  void deleteMember(String id) {
    _members = _members.where((m) => m.id != id).toList();
    notifyListeners();
    _delete('members', id);
  }

  // ── Projects ──────────────────────────────────────────────────

  void addProject(Project p) {
    _projects = [..._projects, p];
    notifyListeners();
    _write('projects', p.id, p.toJson());
  }

  void updateProject(Project p) {
    final i = _projects.indexWhere((x) => x.id == p.id);
    if (i < 0) return;
    _projects = List.of(_projects)..[i] = p;
    notifyListeners();
    _write('projects', p.id, p.toJson());
  }

  void deleteProject(String id) {
    _projects = _projects.where((p) => p.id != id).toList();
    notifyListeners();
    _delete('projects', id);
  }

  // ── Dépenses ──────────────────────────────────────────────────

  void addDepense(Depense d) {
    _depenses = [..._depenses, d];
    notifyListeners();
    _write('depenses', d.id, d.toJson());
  }

  void approveDepense(String id) {
    _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.approuvee));
  }

  void rejectDepense(String id, String reason) {
    _updateDepense(id, (d) => d.copyWith(statut: DepenseStatus.rejetee, commentaire: reason));
  }

  void deleteDepense(String id) {
    _depenses = _depenses.where((d) => d.id != id).toList();
    notifyListeners();
    _delete('depenses', id);
  }

  void _updateDepense(String id, Depense Function(Depense) fn) {
    final i = _depenses.indexWhere((d) => d.id == id);
    if (i < 0) return;
    final updated = fn(_depenses[i]);
    _depenses = List.of(_depenses)..[i] = updated;
    notifyListeners();
    _write('depenses', id, updated.toJson());
  }

  // ── Cotisations ───────────────────────────────────────────────

  void addCotisation(Cotisation c) {
    _cotisations = [..._cotisations, c];
    notifyListeners();
    _write('cotisations', c.id, c.toJson());
  }

  void validateCotisation(String id) {
    _updateCotisation(id, (c) => c.copyWith(
      statut: CotisationStatus.validee,
      datePaiement: DateTime.now().toIso8601String().split('T')[0],
    ));
  }

  void markCotisationOverdue(String id) {
    _updateCotisation(id, (c) => c.copyWith(statut: CotisationStatus.enRetard));
  }

  void rejectCotisation(String id) => markCotisationOverdue(id);

  void deleteCotisation(String id) {
    _cotisations = _cotisations.where((c) => c.id != id).toList();
    notifyListeners();
    _delete('cotisations', id);
  }

  void _updateCotisation(String id, Cotisation Function(Cotisation) fn) {
    final i = _cotisations.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final updated = fn(_cotisations[i]);
    _cotisations = List.of(_cotisations)..[i] = updated;
    notifyListeners();
    _write('cotisations', id, updated.toJson());
  }

  // ── Storage helpers ───────────────────────────────────────────

  void _write(String collection, String id, Map<String, dynamic> data) {
    if (_firestoreAvailable) {
      _db!.collection(collection).doc(id).set(data).catchError(
        (e) => debugPrint('[Jamiyati] Firestore write error ($collection/$id): $e'));
    } else {
      _persistLocal();
    }
  }

  void _delete(String collection, String id) {
    if (_firestoreAvailable) {
      _db!.collection(collection).doc(id).delete().catchError(
        (e) => debugPrint('[Jamiyati] Firestore delete error ($collection/$id): $e'));
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
