enum CotisationFrequence { mensuelle, trimestrielle, annuelle, unique }

enum CotisationStatus { enAttente, validee, enRetard }

enum CotisationType { normale, dediee }

class Cotisation {
  final String id;
  final String membreId;
  final double montant;
  final CotisationFrequence frequence;
  final int annee;
  final String dateDeclaration;
  final String dateEcheance;
  final String? datePaiement;
  final CotisationStatus statut;
  final String? projetId;
  final CotisationType type;
  final String? commentaire;

  const Cotisation({
    required this.id,
    required this.membreId,
    required this.montant,
    required this.frequence,
    required this.annee,
    required this.dateDeclaration,
    required this.dateEcheance,
    this.datePaiement,
    required this.statut,
    this.projetId,
    required this.type,
    this.commentaire,
  });

  factory Cotisation.fromJson(Map<String, dynamic> json) => Cotisation(
        id: json['id'] as String,
        membreId: json['membreId'] as String,
        montant: (json['montant'] as num).toDouble(),
        frequence: _freqFromString(json['frequence'] as String? ?? 'annuelle'),
        annee: json['annee'] as int,
        dateDeclaration: json['dateDeclaration'] as String,
        dateEcheance: json['dateEcheance'] as String,
        datePaiement: json['datePaiement'] as String?,
        statut: _statusFromString(json['statut'] as String),
        projetId: json['projetId'] as String?,
        type: CotisationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CotisationType.normale,
        ),
        commentaire: json['commentaire'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'membreId': membreId,
        'montant': montant,
        'frequence': frequence.name,
        'annee': annee,
        'dateDeclaration': dateDeclaration,
        'dateEcheance': dateEcheance,
        'datePaiement': datePaiement,
        'statut': _statusToString(statut),
        'projetId': projetId,
        'type': type.name,
        'commentaire': commentaire,
      };

  Cotisation copyWith({
    String? id, String? membreId, double? montant, CotisationFrequence? frequence,
    int? annee, String? dateDeclaration, String? dateEcheance, String? datePaiement,
    CotisationStatus? statut, String? projetId, CotisationType? type, String? commentaire,
  }) => Cotisation(
    id: id ?? this.id, membreId: membreId ?? this.membreId, montant: montant ?? this.montant,
    frequence: frequence ?? this.frequence, annee: annee ?? this.annee,
    dateDeclaration: dateDeclaration ?? this.dateDeclaration,
    dateEcheance: dateEcheance ?? this.dateEcheance, datePaiement: datePaiement ?? this.datePaiement,
    statut: statut ?? this.statut, projetId: projetId ?? this.projetId,
    type: type ?? this.type, commentaire: commentaire ?? this.commentaire,
  );

  static CotisationFrequence _freqFromString(String s) {
    switch (s) {
      case 'mensuelle': return CotisationFrequence.mensuelle;
      case 'trimestrielle': return CotisationFrequence.trimestrielle;
      case 'unique': return CotisationFrequence.unique;
      default: return CotisationFrequence.annuelle;
    }
  }

  static CotisationStatus _statusFromString(String s) {
    switch (s) {
      case 'validee': return CotisationStatus.validee;
      case 'en_retard': case 'enRetard': return CotisationStatus.enRetard;
      default: return CotisationStatus.enAttente;
    }
  }

  static String _statusToString(CotisationStatus s) {
    switch (s) {
      case CotisationStatus.validee: return 'validee';
      case CotisationStatus.enRetard: return 'en_retard';
      case CotisationStatus.enAttente: return 'en_attente';
    }
  }
}
