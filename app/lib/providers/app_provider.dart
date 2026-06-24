import 'dart:convert';
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

  List<Member> get members => List.unmodifiable(_members);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Depense> get depenses => List.unmodifiable(_depenses);
  List<Cotisation> get cotisations => List.unmodifiable(_cotisations);
  String get currentUserId => _currentUserId;
  String get language => _language;
  bool get isLoggedIn => _isLoggedIn;

  Member? get currentUser =>
      _members.cast<Member?>().firstWhere((m) => m?.id == _currentUserId, orElse: () => null);

  // ── Authentication ────────────────────────────────────────────
  // Returns null on success, error message on failure
  String? login(String identifier, String password) {
    final id = identifier.trim();
    final pass = password.trim();
    if (id.isEmpty || pass.isEmpty) return _err('emptyFields');

    final member = _members.cast<Member?>().firstWhere(
      (m) => m != null && (
        m.telephone == id ||
        m.email == id ||
        m.id == id
      ),
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
    _persist();
    notifyListeners();
  }

  // ── Members ───────────────────────────────────────────────────
  void addMember(Member m) { _members.add(m); _persist(); notifyListeners(); }
  void updateMember(Member m) {
    final i = _members.indexWhere((x) => x.id == m.id);
    if (i >= 0) { _members[i] = m; _persist(); notifyListeners(); }
  }
  void deleteMember(String id) {
    _members.removeWhere((m) => m.id == id);
    _persist(); notifyListeners();
  }

  // ── Projects ──────────────────────────────────────────────────
  void addProject(Project p) { _projects.add(p); _persist(); notifyListeners(); }
  void updateProject(Project p) {
    final i = _projects.indexWhere((x) => x.id == p.id);
    if (i >= 0) { _projects[i] = p; _persist(); notifyListeners(); }
  }
  void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    _persist(); notifyListeners();
  }

  // ── Dépenses ──────────────────────────────────────────────────
  void addDepense(Depense d) { _depenses.add(d); _persist(); notifyListeners(); }
  void approveDepense(String id) {
    final i = _depenses.indexWhere((d) => d.id == id);
    if (i >= 0) {
      _depenses[i] = _depenses[i].copyWith(statut: DepenseStatus.approuvee);
      _persist(); notifyListeners();
    }
  }
  void rejectDepense(String id, String reason) {
    final i = _depenses.indexWhere((d) => d.id == id);
    if (i >= 0) {
      _depenses[i] = _depenses[i].copyWith(
        statut: DepenseStatus.rejetee, commentaire: reason);
      _persist(); notifyListeners();
    }
  }
  void deleteDepense(String id) {
    _depenses.removeWhere((d) => d.id == id);
    _persist(); notifyListeners();
  }

  // ── Cotisations ───────────────────────────────────────────────
  void addCotisation(Cotisation c) { _cotisations.add(c); _persist(); notifyListeners(); }
  void validateCotisation(String id) {
    final i = _cotisations.indexWhere((c) => c.id == id);
    if (i >= 0) {
      _cotisations[i] = _cotisations[i].copyWith(
        statut: CotisationStatus.validee,
        datePaiement: DateTime.now().toIso8601String().split('T')[0],
      );
      _persist(); notifyListeners();
    }
  }
  void markCotisationOverdue(String id) {
    final i = _cotisations.indexWhere((c) => c.id == id);
    if (i >= 0) {
      _cotisations[i] = _cotisations[i].copyWith(statut: CotisationStatus.enRetard);
      _persist(); notifyListeners();
    }
  }
  void rejectCotisation(String id) => markCotisationOverdue(id);
  void deleteCotisation(String id) {
    _cotisations.removeWhere((c) => c.id == id);
    _persist(); notifyListeners();
  }

  // ── Persistence ───────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('jamiyati_lang') ?? 'ar';

    final raw = prefs.getString('jamiyati_data');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _members = (data['members'] as List).map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
        _projects = (data['projects'] as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
        _depenses = (data['depenses'] as List).map((e) => Depense.fromJson(e as Map<String, dynamic>)).toList();
        _cotisations = (data['cotisations'] as List).map((e) => Cotisation.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _loadSeed();
      }
    } else {
      _loadSeed();
    }

    // Restore session
    final savedUserId = prefs.getString('jamiyati_session');
    if (savedUserId != null && _members.any((m) => m.id == savedUserId)) {
      _currentUserId = savedUserId;
      _isLoggedIn = true;
    }
  }

  void _loadSeed() {
    _members = SeedData.members();
    _projects = SeedData.projects();
    _depenses = SeedData.depenses();
    _cotisations = SeedData.cotisations();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jamiyati_lang', _language);
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
