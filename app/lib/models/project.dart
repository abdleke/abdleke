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

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        nom: json['nom'] as String,
        description: json['description'] as String,
        type: _typeFromString(json['type'] as String? ?? 'normale'),
        budget: (json['budget'] as num).toDouble(),
        dateDebut: json['dateDebut'] as String,
        dateFin: json['dateFin'] as String?,
        statut: ProjectStatus.values.firstWhere(
          (e) => e.name == json['statut'],
          orElse: () => ProjectStatus.actif,
        ),
        responsableId: json['responsableId'] as String,
        cotisationDediee: json['cotisationDediee'] != null
            ? (json['cotisationDediee'] as num).toDouble()
            : null,
        exerciceId: json['exerciceId'] as String?,
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
