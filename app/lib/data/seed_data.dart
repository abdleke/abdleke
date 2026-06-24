import '../models/member.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/cotisation.dart';

class SeedData {
  static const String defaultUserId = 'm1';

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
          type: ProjectType.standard, budget: 50000,
          dateDebut: '2025-11-01', dateFin: '2026-03-31',
          statut: ProjectStatus.actif, responsableId: 'm3',
        ),
        const Project(
          id: 'p2', nom: 'مهرجان الثقافة والتراث',
          description: 'تنظيم مهرجان ثقافي سنوي يحتفي بالتراث المحلي',
          type: ProjectType.periodique, budget: 80000,
          dateDebut: '2026-04-01', dateFin: '2026-06-30',
          statut: ProjectStatus.actif, responsableId: 'm1',
          cotisationDediee: 500,
        ),
        const Project(
          id: 'p3', nom: 'برنامج التعليم المستمر',
          description: 'دورات تدريبية وتعليمية لأعضاء الجمعية',
          type: ProjectType.standard, budget: 30000,
          dateDebut: '2025-09-01',
          statut: ProjectStatus.actif, responsableId: 'm3',
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

  static List<Cotisation> cotisations() => [
        const Cotisation(
          id: 'c1', membreId: 'm1', montant: 2400,
          frequence: CotisationFrequence.mensuelle, annee: 2026,
          dateDeclaration: '2026-01-05', dateEcheance: '2026-01-31',
          datePaiement: '2026-01-15', statut: CotisationStatus.validee,
          type: CotisationType.normale,
        ),
        const Cotisation(
          id: 'c2', membreId: 'm2', montant: 2400,
          frequence: CotisationFrequence.mensuelle, annee: 2026,
          dateDeclaration: '2026-01-03', dateEcheance: '2026-01-31',
          datePaiement: '2026-01-10', statut: CotisationStatus.validee,
          type: CotisationType.normale,
        ),
        const Cotisation(
          id: 'c3', membreId: 'm3', montant: 2400,
          frequence: CotisationFrequence.trimestrielle, annee: 2026,
          dateDeclaration: '2026-01-08', dateEcheance: '2026-03-31',
          datePaiement: '2026-01-20', statut: CotisationStatus.validee,
          type: CotisationType.normale,
        ),
        const Cotisation(
          id: 'c4', membreId: 'm4', montant: 2400,
          frequence: CotisationFrequence.annuelle, annee: 2026,
          dateDeclaration: '2026-01-12', dateEcheance: '2026-03-31',
          statut: CotisationStatus.enAttente, type: CotisationType.normale,
        ),
        const Cotisation(
          id: 'c5', membreId: 'm5', montant: 2400,
          frequence: CotisationFrequence.mensuelle, annee: 2026,
          dateDeclaration: '2026-01-20', dateEcheance: '2026-02-28',
          statut: CotisationStatus.enRetard, type: CotisationType.normale,
        ),
        const Cotisation(
          id: 'c6', membreId: 'm1', montant: 500,
          frequence: CotisationFrequence.annuelle, annee: 2026,
          dateDeclaration: '2026-04-01', dateEcheance: '2026-04-30',
          datePaiement: '2026-04-05', statut: CotisationStatus.validee,
          type: CotisationType.dediee, projetId: 'p2',
        ),
        const Cotisation(
          id: 'c7', membreId: 'm3', montant: 500,
          frequence: CotisationFrequence.annuelle, annee: 2026,
          dateDeclaration: '2026-04-02', dateEcheance: '2026-04-30',
          statut: CotisationStatus.enAttente,
          type: CotisationType.dediee, projetId: 'p2',
        ),
      ];
}
