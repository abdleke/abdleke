enum ProjectType { normale, ponctuel }

enum ProjectStatus { actif, termine, suspendu }

class Project {
  final String id;
  final String nom;
  final String description;
  final ProjectType type;
  final double budget;
  final String dateDebut;
  final String? dateFin;
  final ProjectStatus statut;
  final String responsableId;
  final double? cotisationDediee;
  final String? exerciceId;

  const Project({
    required this.id,
    required this.nom,
    required this.description,
    required this.type,
    required this.budget,
    required this.dateDebut,
    this.dateFin,
    required this.statut,
    required this.responsableId,
    this.cotisationDediee,
    this.exerciceId,
  });

  static double _d(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: (json['id'] ?? '').toString(),
        nom: (json['nom'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        type: _typeFromString((json['type'] ?? 'normale').toString()),
        budget: _d(json['budget']),
        dateDebut: (json['dateDebut'] ?? json['date_debut'] ?? '').toString(),
        dateFin: (json['dateFin'] ?? json['date_fin'])?.toString(),
        statut: ProjectStatus.values.firstWhere(
          (e) => e.name == (json['statut'] ?? '').toString(),
          orElse: () => ProjectStatus.actif,
        ),
        responsableId: (json['responsableId'] ?? json['responsable_id'] ?? '').toString(),
        cotisationDediee: json['cotisationDediee'] ?? json['cotisation_dediee'] != null
            ? _d(json['cotisationDediee'] ?? json['cotisation_dediee'])
            : null,
        exerciceId: (json['exerciceId'] ?? json['exercice_id'])?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'description': description,
        'type': type.name,
        'budget': budget,
        'dateDebut': dateDebut,
        'dateFin': dateFin,
        'statut': statut.name,
        'responsableId': responsableId,
        'cotisationDediee': cotisationDediee,
        'exerciceId': exerciceId,
      };

  Project copyWith({
    String? id, String? nom, String? description, ProjectType? type,
    double? budget, String? dateDebut, String? dateFin,
    ProjectStatus? statut, String? responsableId, double? cotisationDediee,
    String? exerciceId,
  }) => Project(
    id: id ?? this.id, nom: nom ?? this.nom, description: description ?? this.description,
    type: type ?? this.type, budget: budget ?? this.budget,
    dateDebut: dateDebut ?? this.dateDebut, dateFin: dateFin ?? this.dateFin,
    statut: statut ?? this.statut, responsableId: responsableId ?? this.responsableId,
    cotisationDediee: cotisationDediee ?? this.cotisationDediee,
    exerciceId: exerciceId ?? this.exerciceId,
  );

  // Backward compat: 'standard' and 'periodique' stored in old data
  static ProjectType _typeFromString(String s) {
    if (s == 'ponctuel' || s == 'periodique') return ProjectType.ponctuel;
    return ProjectType.normale; // handles 'normale' and legacy 'standard'
  }
}
