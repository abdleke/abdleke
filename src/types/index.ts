export type Role = 'admin' | 'tresorier' | 'chef_projet' | 'membre';
export type MemberStatus = 'actif' | 'inactif';
export type ProjectType = 'standard' | 'periodique';
export type ProjectStatus = 'actif' | 'termine' | 'suspendu';
export type DepenseStatus = 'soumise' | 'approuvee' | 'rejetee';
export type DepenseCategorie = 'materiel' | 'deplacement' | 'communication' | 'restauration' | 'autre';
export type CotisationFrequence = 'mensuelle' | 'trimestrielle' | 'annuelle';
export type CotisationStatus = 'en_attente' | 'validee' | 'en_retard';
export type CotisationType = 'normale' | 'dediee';

export interface Member {
  id: string;
  prenom: string;
  nom: string;
  email: string;
  telephone: string;
  dateAdhesion: string;
  statut: MemberStatus;
  role: Role;
}

export interface Project {
  id: string;
  nom: string;
  description: string;
  type: ProjectType;
  budget: number;
  dateDebut: string;
  dateFin?: string;
  statut: ProjectStatus;
  responsableId: string;
  cotisationDediee?: number;
}

export interface Depense {
  id: string;
  projetId: string;
  membreId: string;
  description: string;
  montant: number;
  date: string;
  categorie: DepenseCategorie;
  statut: DepenseStatus;
  commentaire?: string;
}

export interface Cotisation {
  id: string;
  membreId: string;
  montant: number;
  frequence: CotisationFrequence;
  annee: number;
  dateDeclaration: string;
  dateEcheance: string;
  datePaiement?: string;
  statut: CotisationStatus;
  projetId?: string;
  type: CotisationType;
  commentaire?: string;
}

export interface AppState {
  members: Member[];
  projects: Project[];
  depenses: Depense[];
  cotisations: Cotisation[];
  currentUserId: string;
}
