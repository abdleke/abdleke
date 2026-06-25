enum ExerciceStatus { actif, cloture }

class ExerciceAnnuel {
  final String id;
  final String libelle;
  final int annee;
  final int moisDebut; // 1-12
  final String dateDebut;
  final String dateFin;
  final ExerciceStatus statut;

  const ExerciceAnnuel({
    required this.id,
    required this.libelle,
    required this.annee,
    required this.moisDebut,
    required this.dateDebut,
    required this.dateFin,
    required this.statut,
  });

  factory ExerciceAnnuel.fromJson(Map<String, dynamic> json) => ExerciceAnnuel(
        id: json['id'] as String,
        libelle: json['libelle'] as String,
        annee: json['annee'] as int,
        moisDebut: json['moisDebut'] as int? ?? 1,
        dateDebut: json['dateDebut'] as String,
        dateFin: json['dateFin'] as String,
        statut: (json['statut'] as String?) == 'cloture'
            ? ExerciceStatus.cloture
            : ExerciceStatus.actif,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'libelle': libelle,
        'annee': annee,
        'moisDebut': moisDebut,
        'dateDebut': dateDebut,
        'dateFin': dateFin,
        'statut': statut.name,
      };

  ExerciceAnnuel copyWith({
    String? id, String? libelle, int? annee, int? moisDebut,
    String? dateDebut, String? dateFin, ExerciceStatus? statut,
  }) => ExerciceAnnuel(
    id: id ?? this.id, libelle: libelle ?? this.libelle,
    annee: annee ?? this.annee, moisDebut: moisDebut ?? this.moisDebut,
    dateDebut: dateDebut ?? this.dateDebut, dateFin: dateFin ?? this.dateFin,
    statut: statut ?? this.statut,
  );

  String get periode => '$dateDebut → $dateFin';
}
