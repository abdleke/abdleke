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

  factory Cotisation.fromJson(Map<String, dynamic> json) => Cotisation(
        id: (json['id'] ?? '').toString(),
        membreId: (json['membreId'] ?? json['membre_id'] ?? '').toString(),
        exerciceId: (json['exerciceId'] ?? json['exercice_id'] ?? '').toString(),
        annee: (json['annee'] as num?)?.toInt() ?? DateTime.now().year,
        montantTotal: ((json['montantTotal'] ?? json['montant_total'] ?? json['montant'] ?? 0) as num).toDouble(),
        nombreEcheances: (json['nombreEcheances'] ?? json['nombre_echeances'] as num?)?.toInt() ?? 1,
        dateDebut: (json['dateDebut'] ?? json['date_debut'] ?? '').toString(),
        type: CotisationType.values.firstWhere(
          (e) => e.name == (json['type'] ?? ''),
          orElse: () => CotisationType.normale,
        ),
        projetId: (json['projetId'] ?? json['projet_id'])?.toString(),
        commentaire: json['commentaire']?.toString(),
      );

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
