enum ExerciceStatus { actif, cloture }

class ExerciceAnnuel {
  final String id;
  final String libelle;
  final int annee;
  final int moisDebut; // 1-12
  final String dateDebut;
  final String dateFin;
  final ExerciceStatus statut;
  final double budgetProvisoireTotal;

  const ExerciceAnnuel({
    required this.id,
    required this.libelle,
    required this.annee,
    required this.moisDebut,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
    this.budgetProvisoireTotal = 0,
  });

  static int _i(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory ExerciceAnnuel.fromJson(Map<String, dynamic> json) => ExerciceAnnuel(
        id: (json['id'] ?? '').toString(),
        libelle: (json['libelle'] ?? '').toString(),
        annee: _i(json['annee'], DateTime.now().year),
        moisDebut: _i(json['moisDebut'] ?? json['mois_debut'], 1),
        dateDebut: (json['dateDebut'] ?? json['date_debut'] ?? '').toString(),
        dateFin: (json['dateFin'] ?? json['date_fin'] ?? '').toString(),
        statut: (json['statut'] ?? '').toString() == 'cloture'
            ? ExerciceStatus.cloture
            : ExerciceStatus.actif,
        budgetProvisoireTotal:
            _d(json['budgetProvisoireTotal'] ?? json['budget_provisoire_total']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'libelle': libelle,
        'annee': annee,
        'moisDebut': moisDebut,
        'dateDebut': dateDebut,
        'dateFin': dateFin,
        'statut': statut.name,
        'budgetProvisoireTotal': budgetProvisoireTotal,
      };

  ExerciceAnnuel copyWith({
    String? id, String? libelle, int? annee, int? moisDebut,
    String? dateDebut, String? dateFin, ExerciceStatus? statut,
    double? budgetProvisoireTotal,
  }) => ExerciceAnnuel(
    id: id ?? this.id, libelle: libelle ?? this.libelle,
    annee: annee ?? this.annee, moisDebut: moisDebut ?? this.moisDebut,
    dateDebut: dateDebut ?? this.dateDebut, dateFin: dateFin ?? this.dateFin,
    statut: statut ?? this.statut,
    budgetProvisoireTotal: budgetProvisoireTotal ?? this.budgetProvisoireTotal,
  );

  String get periode => '$dateDebut → $dateFin';
}
