import '../models/member.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/cotisation.dart';
import '../models/exercice_annuel.dart';
import '../models/echeance.dart';

class SeedData {
  static const String defaultUserId = 'm1';
  static int _counter = 0;
  static String _nextId() => 'se${++_counter}';

  static List<Member> members() => [
        const Member(
          id: 'm1', prenom: 'أحمد', nom: 'بن علي',
          email: 'ahmed.benali@email.com', telephone: '0661234567',
          dateAdhesion: '2022-01-15', statut: MemberStatus.actif,
          role: MemberRole.admin, motDePasse: 'admin123',
        ),
        const Member(
          id: 'm2', prenom: 'فاطمة', nom: 'الزهراء',
          email: 'fatima.zahra@email.com', telephone: '0662345678',
          dateAdhesion: '2022-02-20', statut: MemberStatus.actif,
          role: MemberRole.tresorier, motDePasse: 'treso123',
        ),
        const Member(
          id: 'm3', prenom: 'محمد', nom: 'أمين',
          email: 'mohammed.amine@email.com', telephone: '0663456789',
          dateAdhesion: '2022-03-10', statut: MemberStatus.actif,
          role: MemberRole.chefProjet, motDePasse: '1234',
        ),
        const Member(
          id: 'm4', prenom: 'سارة', nom: 'حمدان',
          email: 'sara.hamdan@email.com', telephone: '0664567890',
          dateAdhesion: '2022-04-05', statut: MemberStatus.actif,
          role: MemberRole.membre, motDePasse: '1234',
        ),
        const Member(
          id: 'm5', prenom: 'يوسف', nom: 'بنعمر',
          email: 'youssef.benamar@email.com', telephone: '0665678901',
          dateAdhesion: '2022-05-15', statut: MemberStatus.actif,
          role: MemberRole.membre, motDePasse: '1234',
        ),
        const Member(
          id: 'm6', prenom: 'نور', nom: 'الهدى',
          email: 'nour.elhoda@email.com', telephone: '0666789012',
          dateAdhesion: '2023-01-10', statut: MemberStatus.inactif,
          role: MemberRole.membre, motDePasse: '1234',
        ),
      ];

  static List<Project> projects() => [
        const Project(
          id: 'p1', nom: 'برنامج التضامن الشتوي',
          description: 'توزيع مساعدات على الأسر المحتاجة خلال فصل الشتاء',
          type: ProjectType.normale, budget: 15000,
          dateDebut: '2025-11-01', dateFin: '2026-03-31',
          statut: ProjectStatus.actif, responsableId: 'm3',
          exerciceId: 'ex1',
        ),
        const Project(
          id: 'p2', nom: 'مهرجان الثقافة والتراث',
          description: 'تنظيم مهرجان ثقافي سنوي يحتفي بالتراث المحلي',
          type: ProjectType.ponctuel, budget: 80000,
          dateDebut: '2026-04-01', dateFin: '2026-06-30',
          statut: ProjectStatus.actif, responsableId: 'm1',
          cotisationDediee: 500,
        ),
        const Project(
          id: 'p3', nom: 'برنامج التعليم المستمر',
          description: 'دورات تدريبية وتعليمية لأعضاء الجمعية',
          type: ProjectType.normale, budget: 10000,
          dateDebut: '2025-09-01',
          statut: ProjectStatus.actif, responsableId: 'm3',
          exerciceId: 'ex1',
        ),
      ];

  static List<Depense> depenses() => [
        const Depense(
          id: 'd1', projetId: 'p1', membreId: 'm4',
          description: 'شراء مواد غذائية للتوزيع', montant: 8500,
          date: '2025-12-10', categorie: DepenseCategorie.materiel,
          statut: DepenseStatus.approuvee,
        ),
        const Depense(
          id: 'd2', projetId: 'p1', membreId: 'm5',
          description: 'نقل البضائع', montant: 2200,
          date: '2025-12-15', categorie: DepenseCategorie.deplacement,
          statut: DepenseStatus.approuvee,
        ),
        const Depense(
          id: 'd3', projetId: 'p2', membreId: 'm1',
          description: 'طباعة المطويات والملصقات', montant: 3500,
          date: '2026-04-05', categorie: DepenseCategorie.communication,
          statut: DepenseStatus.soumise,
        ),
        const Depense(
          id: 'd4', projetId: 'p2', membreId: 'm3',
          description: 'تأجير المعدات الصوتية', montant: 12000,
          date: '2026-04-10', categorie: DepenseCategorie.materiel,
          statut: DepenseStatus.soumise,
        ),
        const Depense(
          id: 'd5', projetId: 'p3', membreId: 'm4',
          description: 'مواد تدريبية', montant: 4500,
          date: '2026-01-20', categorie: DepenseCategorie.materiel,
          statut: DepenseStatus.rejetee,
          commentaire: 'يجب الحصول على 3 عروض أسعار قبل الشراء',
        ),
        const Depense(
          id: 'd6', projetId: 'p3', membreId: 'm5',
          description: 'تكاليف استضافة المدربين', montant: 6000,
          date: '2026-02-15', categorie: DepenseCategorie.restauration,
          statut: DepenseStatus.soumise,
        ),
      ];

  // Exercice: oct 2025 → sept 2026
  static List<ExerciceAnnuel> exercices() => [
        const ExerciceAnnuel(
          id: 'ex1', libelle: 'Exercice 2026', annee: 2026,
          moisDebut: 10, dateDebut: '2025-10-01', dateFin: '2026-09-30',
          statut: ExerciceStatus.actif,
          budgetProvisoireTotal: 35000,
        ),
      ];

  // Engagements annuels des membres pour ex1
  static List<Cotisation> cotisations() => [
        const Cotisation(id: 'c1', membreId: 'm1', exerciceId: 'ex1', annee: 2026,
          montantTotal: 12000, nombreEcheances: 12, dateDebut: '2025-10-01',
          type: CotisationType.normale),
        const Cotisation(id: 'c2', membreId: 'm2', exerciceId: 'ex1', annee: 2026,
          montantTotal: 6000, nombreEcheances: 4, dateDebut: '2025-10-01',
          type: CotisationType.normale),
        const Cotisation(id: 'c3', membreId: 'm3', exerciceId: 'ex1', annee: 2026,
          montantTotal: 4800, nombreEcheances: 2, dateDebut: '2025-10-01',
          type: CotisationType.normale),
        const Cotisation(id: 'c4', membreId: 'm4', exerciceId: 'ex1', annee: 2026,
          montantTotal: 3600, nombreEcheances: 3, dateDebut: '2025-10-01',
          type: CotisationType.normale),
        const Cotisation(id: 'c5', membreId: 'm5', exerciceId: 'ex1', annee: 2026,
          montantTotal: 2400, nombreEcheances: 1, dateDebut: '2025-10-01',
          type: CotisationType.normale),
        // Dédiée projet ponctuel p2
        const Cotisation(id: 'c6', membreId: 'm1', exerciceId: 'ex1', annee: 2026,
          montantTotal: 500, nombreEcheances: 1, dateDebut: '2026-04-01',
          type: CotisationType.dediee, projetId: 'p2'),
        const Cotisation(id: 'c7', membreId: 'm3', exerciceId: 'ex1', annee: 2026,
          montantTotal: 500, nombreEcheances: 1, dateDebut: '2026-04-01',
          type: CotisationType.dediee, projetId: 'p2'),
      ];

  // Échéances pré-générées avec statuts réalistes
  static List<Echeance> echeances() {
    _counter = 0;
    return [
      // c1 : m1, 12 x 1000 DA mensuel
      Echeance(id: 'e1_1', cotisationId: 'c1', numero: 1, montant: 1000, dateEcheance: '2025-10-01', datePaiement: '2025-10-15', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_2', cotisationId: 'c1', numero: 2, montant: 1000, dateEcheance: '2025-11-01', datePaiement: '2025-11-10', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_3', cotisationId: 'c1', numero: 3, montant: 1000, dateEcheance: '2025-12-01', datePaiement: '2025-12-08', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_4', cotisationId: 'c1', numero: 4, montant: 1000, dateEcheance: '2026-01-01', datePaiement: '2026-01-12', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_5', cotisationId: 'c1', numero: 5, montant: 1000, dateEcheance: '2026-02-01', datePaiement: '2026-02-08', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_6', cotisationId: 'c1', numero: 6, montant: 1000, dateEcheance: '2026-03-01', datePaiement: '2026-03-05', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_7', cotisationId: 'c1', numero: 7, montant: 1000, dateEcheance: '2026-04-01', datePaiement: '2026-04-10', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_8', cotisationId: 'c1', numero: 8, montant: 1000, dateEcheance: '2026-05-01', datePaiement: '2026-05-07', statut: EcheanceStatus.validee),
      Echeance(id: 'e1_9', cotisationId: 'c1', numero: 9, montant: 1000, dateEcheance: '2026-06-01', statut: EcheanceStatus.enRetard),
      Echeance(id: 'e1_10', cotisationId: 'c1', numero: 10, montant: 1000, dateEcheance: '2026-07-01', statut: EcheanceStatus.enAttente),
      Echeance(id: 'e1_11', cotisationId: 'c1', numero: 11, montant: 1000, dateEcheance: '2026-08-01', statut: EcheanceStatus.enAttente),
      Echeance(id: 'e1_12', cotisationId: 'c1', numero: 12, montant: 1000, dateEcheance: '2026-09-01', statut: EcheanceStatus.enAttente),
      // c2 : m2, 4 x 1500 DA trimestriel
      Echeance(id: 'e2_1', cotisationId: 'c2', numero: 1, montant: 1500, dateEcheance: '2025-10-01', datePaiement: '2025-10-20', statut: EcheanceStatus.validee),
      Echeance(id: 'e2_2', cotisationId: 'c2', numero: 2, montant: 1500, dateEcheance: '2026-01-01', datePaiement: '2026-01-15', statut: EcheanceStatus.validee),
      Echeance(id: 'e2_3', cotisationId: 'c2', numero: 3, montant: 1500, dateEcheance: '2026-04-01', statut: EcheanceStatus.enAttente),
      Echeance(id: 'e2_4', cotisationId: 'c2', numero: 4, montant: 1500, dateEcheance: '2026-07-01', statut: EcheanceStatus.enAttente),
      // c3 : m3, 2 x 2400 DA semestriel
      Echeance(id: 'e3_1', cotisationId: 'c3', numero: 1, montant: 2400, dateEcheance: '2025-10-01', datePaiement: '2025-10-25', statut: EcheanceStatus.validee),
      Echeance(id: 'e3_2', cotisationId: 'c3', numero: 2, montant: 2400, dateEcheance: '2026-04-01', statut: EcheanceStatus.enAttente),
      // c4 : m4, 3 x 1200 DA
      Echeance(id: 'e4_1', cotisationId: 'c4', numero: 1, montant: 1200, dateEcheance: '2025-10-01', datePaiement: '2025-11-05', statut: EcheanceStatus.validee),
      Echeance(id: 'e4_2', cotisationId: 'c4', numero: 2, montant: 1200, dateEcheance: '2026-02-01', statut: EcheanceStatus.enRetard),
      Echeance(id: 'e4_3', cotisationId: 'c4', numero: 3, montant: 1200, dateEcheance: '2026-06-01', statut: EcheanceStatus.enAttente),
      // c5 : m5, 1 paiement annuel
      Echeance(id: 'e5_1', cotisationId: 'c5', numero: 1, montant: 2400, dateEcheance: '2025-10-01', statut: EcheanceStatus.enRetard),
      // c6 : m1, dediee p2 (unique)
      Echeance(id: 'e6_1', cotisationId: 'c6', numero: 1, montant: 500, dateEcheance: '2026-04-01', datePaiement: '2026-04-05', statut: EcheanceStatus.validee),
      // c7 : m3, dediee p2 (unique)
      Echeance(id: 'e7_1', cotisationId: 'c7', numero: 1, montant: 500, dateEcheance: '2026-04-01', statut: EcheanceStatus.enAttente),
    ];
  }
}
