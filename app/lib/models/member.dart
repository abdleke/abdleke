enum MemberStatus { actif, inactif, suspendu }

enum MemberRole { admin, tresorier, chefProjet, membre }

class Member {
  final String id;
  final String prenom;
  final String nom;
  final String? email;
  final String? telephone;
  final String dateAdhesion;
  final MemberStatus statut;
  final MemberRole role;
  final String motDePasse;

  const Member({
    required this.id,
    required this.prenom,
    required this.nom,
    this.email,
    this.telephone,
    String? dateAdhesion,
    required this.statut,
    required this.role,
    String? motDePasse,
  })  : dateAdhesion = dateAdhesion ?? '',
        motDePasse = motDePasse ?? '1234';

  String get fullName => '$prenom $nom';
  String get initials =>
      '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';

  // Login identifier: phone if available, otherwise email, otherwise id
  String get loginId =>
      (telephone?.isNotEmpty == true) ? telephone! : (email?.isNotEmpty == true ? email! : id);

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: (json['id'] ?? '').toString(),
        prenom: (json['prenom'] ?? '').toString(),
        nom: (json['nom'] ?? '').toString(),
        email: (json['email'])?.toString(),
        telephone: (json['telephone'])?.toString(),
        dateAdhesion: (json['dateAdhesion'] ?? json['date_adhesion'] ?? '').toString(),
        statut: MemberStatus.values.firstWhere(
          (e) => e.name == (json['statut'] ?? '').toString(),
          orElse: () => MemberStatus.actif,
        ),
        role: _roleFromString((json['role'] ?? 'membre').toString()),
        motDePasse: (json['motDePasse'] ?? json['mot_de_passe'] ?? '1234').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'prenom': prenom,
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'dateAdhesion': dateAdhesion,
        'statut': statut.name,
        'role': _roleToString(role),
        'motDePasse': motDePasse,
      };

  Member copyWith({
    String? id,
    String? prenom,
    String? nom,
    String? email,
    String? telephone,
    String? dateAdhesion,
    MemberStatus? statut,
    MemberRole? role,
    String? motDePasse,
  }) =>
      Member(
        id: id ?? this.id,
        prenom: prenom ?? this.prenom,
        nom: nom ?? this.nom,
        email: email ?? this.email,
        telephone: telephone ?? this.telephone,
        dateAdhesion: dateAdhesion ?? this.dateAdhesion,
        statut: statut ?? this.statut,
        role: role ?? this.role,
        motDePasse: motDePasse ?? this.motDePasse,
      );

  static MemberRole _roleFromString(String s) {
    switch (s) {
      case 'admin': return MemberRole.admin;
      case 'tresorier': return MemberRole.tresorier;
      case 'chef_projet':
      case 'chefProjet': return MemberRole.chefProjet;
      default: return MemberRole.membre;
    }
  }

  static String _roleToString(MemberRole r) {
    switch (r) {
      case MemberRole.admin: return 'admin';
      case MemberRole.tresorier: return 'tresorier';
      case MemberRole.chefProjet: return 'chef_projet';
      case MemberRole.membre: return 'membre';
    }
  }
}
