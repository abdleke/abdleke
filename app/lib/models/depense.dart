enum DepenseStatus { soumise, approuvee, rejetee }

enum DepenseCategorie { materiel, deplacement, communication, restauration, autre }

class Depense {
  final String id;
  final String projetId;
  final String membreId;
  final String description;
  final double montant;
  final String date;
  final DepenseCategorie categorie;
  final DepenseStatus statut;
  final String? commentaire;
  final bool isAvance;
  final bool rembourse;

  const Depense({
    required this.id,
    required this.projetId,
    required this.membreId,
    required this.description,
    required this.montant,
    required this.date,
    required this.categorie,
    required this.statut,
    this.commentaire,
    this.isAvance = false,
    this.rembourse = false,
  });

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
        id: (json['id'] ?? '').toString(),
        projetId: (json['projetId'] ?? json['projet_id'] ?? '').toString(),
        membreId: (json['membreId'] ?? json['membre_id'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        montant: ((json['montant'] ?? 0) as num).toDouble(),
        date: (json['date'] ?? '').toString(),
        categorie: DepenseCategorie.values.firstWhere(
          (e) => e.name == json['categorie'],
          orElse: () => DepenseCategorie.autre,
        ),
        statut: DepenseStatus.values.firstWhere(
          (e) => e.name == json['statut'],
          orElse: () => DepenseStatus.soumise,
        ),
        commentaire: json['commentaire']?.toString(),
        isAvance: (json['isAvance'] ?? json['is_avance'] ?? false) == true,
        rembourse: (json['rembourse'] ?? false) == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projetId': projetId,
        'membreId': membreId,
        'description': description,
        'montant': montant,
        'date': date,
        'categorie': categorie.name,
        'statut': statut.name,
        'commentaire': commentaire,
        'isAvance': isAvance,
        'rembourse': rembourse,
      };

  Depense copyWith({
    String? id,
    String? projetId,
    String? membreId,
    String? description,
    double? montant,
    String? date,
    DepenseCategorie? categorie,
    DepenseStatus? statut,
    String? commentaire,
    bool? isAvance,
    bool? rembourse,
  }) =>
      Depense(
        id: id ?? this.id,
        projetId: projetId ?? this.projetId,
        membreId: membreId ?? this.membreId,
        description: description ?? this.description,
        montant: montant ?? this.montant,
        date: date ?? this.date,
        categorie: categorie ?? this.categorie,
        statut: statut ?? this.statut,
        commentaire: commentaire ?? this.commentaire,
        isAvance: isAvance ?? this.isAvance,
        rembourse: rembourse ?? this.rembourse,
      );
}
