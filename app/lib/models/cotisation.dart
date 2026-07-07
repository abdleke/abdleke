enum CotisationType { normale, dediee }

class Cotisation {
  final String id;
  final String membreId;
  final String exerciceId;
  final int annee;
  final double montantTotal;
  final int nombreEcheances; // 1-12
  final String dateDebut;
  final CotisationType type;
  final String? projetId;
  final String? commentaire;

  const Cotisation({
    required this.id,
    required this.membreId,
    required this.exerciceId,
    required this.annee,
    required this.montantTotal,
    required this.nombreEcheances,
    required this.dateDebut,
    required this.type,
    this.projetId,
    this.commentaire,
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

  factory Cotisation.fromJson(Map<String, dynamic> json) {
    final anneeRaw = json['annee'];
    final montantRaw = json['montantTotal'] ?? json['montant_total'] ?? json['montant'];
    final nEchRaw = json['nombreEcheances'] ?? json['nombre_echeances'];
    final nb = _i(nEchRaw, 1);

    return Cotisation(
      id: (json['id'] ?? '').toString(),
      membreId: (json['membreId'] ?? json['membre_id'] ?? '').toString(),
      exerciceId: (json['exerciceId'] ?? json['exercice_id'] ?? '').toString(),
      annee: _i(anneeRaw, DateTime.now().year),
      montantTotal: _d(montantRaw),
      nombreEcheances: nb > 0 ? nb : 1,
      dateDebut: (json['dateDebut'] ?? json['date_debut'] ?? '').toString(),
      type: CotisationType.values.firstWhere(
        (e) => e.name == (json['type'] ?? '').toString(),
        orElse: () => CotisationType.normale,
      ),
      projetId: (json['projetId'] ?? json['projet_id'])?.toString(),
      commentaire: json['commentaire']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'membreId': membreId,
        'exerciceId': exerciceId,
        'annee': annee,
        'montantTotal': montantTotal,
        'nombreEcheances': nombreEcheances,
        'dateDebut': dateDebut,
        'type': type.name,
        'projetId': projetId,
        'commentaire': commentaire,
      };

  Cotisation copyWith({
    String? id, String? membreId, String? exerciceId, int? annee,
    double? montantTotal, int? nombreEcheances, String? dateDebut,
    CotisationType? type, String? projetId, String? commentaire,
  }) => Cotisation(
    id: id ?? this.id, membreId: membreId ?? this.membreId,
    exerciceId: exerciceId ?? this.exerciceId, annee: annee ?? this.annee,
    montantTotal: montantTotal ?? this.montantTotal,
    nombreEcheances: nombreEcheances ?? this.nombreEcheances,
    dateDebut: dateDebut ?? this.dateDebut, type: type ?? this.type,
    projetId: projetId ?? this.projetId, commentaire: commentaire ?? this.commentaire,
  );
}
