class BudgetProjetExercice {
  final String id;
  final String projetId;
  final String exerciceId;
  final double budget;

  const BudgetProjetExercice({
    required this.id,
    required this.projetId,
    required this.exerciceId,
    required this.budget,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory BudgetProjetExercice.fromJson(Map<String, dynamic> json) =>
      BudgetProjetExercice(
        id: (json['id'] ?? '').toString(),
        projetId: (json['projetId'] ?? json['projet_id'] ?? '').toString(),
        exerciceId: (json['exerciceId'] ?? json['exercice_id'] ?? '').toString(),
        budget: _d(json['budget']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projetId': projetId,
        'exerciceId': exerciceId,
        'budget': budget,
      };

  BudgetProjetExercice copyWith({
    String? id, String? projetId, String? exerciceId, double? budget,
  }) =>
      BudgetProjetExercice(
        id: id ?? this.id,
        projetId: projetId ?? this.projetId,
        exerciceId: exerciceId ?? this.exerciceId,
        budget: budget ?? this.budget,
      );
}
