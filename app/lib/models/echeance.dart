enum EcheanceStatus { enAttente, validee, enRetard }

class Echeance {
  final String id;
  final String cotisationId;
  final int numero;
  final double montant;
  final String dateEcheance;
  final String? datePaiement;
  final EcheanceStatus statut;

  const Echeance({
    required this.id,
    required this.cotisationId,
    required this.numero,
    required this.montant,
    required this.dateEcheance,
    this.datePaiement,
    required this.statut,
  });

  factory Echeance.fromJson(Map<String, dynamic> json) => Echeance(
        id: json['id'] as String,
        cotisationId: json['cotisationId'] as String,
        numero: json['numero'] as int,
        montant: (json['montant'] as num).toDouble(),
        dateEcheance: json['dateEcheance'] as String,
        datePaiement: json['datePaiement'] as String?,
        statut: _statusFromString(json['statut'] as String? ?? 'en_attente'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cotisationId': cotisationId,
        'numero': numero,
        'montant': montant,
        'dateEcheance': dateEcheance,
        'datePaiement': datePaiement,
        'statut': _statusToString(statut),
      };

  Echeance copyWith({
    String? id, String? cotisationId, int? numero, double? montant,
    String? dateEcheance, String? datePaiement, EcheanceStatus? statut,
  }) => Echeance(
    id: id ?? this.id, cotisationId: cotisationId ?? this.cotisationId,
    numero: numero ?? this.numero, montant: montant ?? this.montant,
    dateEcheance: dateEcheance ?? this.dateEcheance,
    datePaiement: datePaiement ?? this.datePaiement,
    statut: statut ?? this.statut,
  );

  static EcheanceStatus _statusFromString(String s) {
    switch (s) {
      case 'validee': return EcheanceStatus.validee;
      case 'en_retard': case 'enRetard': return EcheanceStatus.enRetard;
      default: return EcheanceStatus.enAttente;
    }
  }

  static String _statusToString(EcheanceStatus s) {
    switch (s) {
      case EcheanceStatus.validee: return 'validee';
      case EcheanceStatus.enRetard: return 'en_retard';
      case EcheanceStatus.enAttente: return 'en_attente';
    }
  }

  // Génère les échéances pour un engagement (appelé depuis provider et seed_data)
  static List<Echeance> generer({
    required String cotisationId,
    required double montantTotal,
    required int nombreEcheances,
    required DateTime dateDebut,
    int totalMonths = 12,
    required String Function() newId,
  }) {
    if (nombreEcheances <= 0) return [];
    final base = double.parse((montantTotal / nombreEcheances).toStringAsFixed(2));
    final last = double.parse((montantTotal - base * (nombreEcheances - 1)).toStringAsFixed(2));

    return List.generate(nombreEcheances, (i) {
      final offset = ((totalMonths * i) / nombreEcheances).round();
      final d = DateTime(dateDebut.year, dateDebut.month + offset, 1);
      return Echeance(
        id: newId(),
        cotisationId: cotisationId,
        numero: i + 1,
        montant: i == nombreEcheances - 1 ? last : base,
        dateEcheance: '${d.year}-${d.month.toString().padLeft(2, '0')}-01',
        statut: EcheanceStatus.enAttente,
      );
    });
  }
}
