import { createContext, useContext, useReducer, useEffect, type ReactNode } from 'react';
import type { AppState, Member, Project, Depense, Cotisation } from '../types';
import { seedData } from '../data/seed';

type Action =
  | { type: 'SET_USER'; payload: string }
  | { type: 'ADD_MEMBER'; payload: Member }
  | { type: 'UPDATE_MEMBER'; payload: Member }
  | { type: 'DELETE_MEMBER'; payload: string }
  | { type: 'ADD_PROJECT'; payload: Project }
  | { type: 'UPDATE_PROJECT'; payload: Project }
  | { type: 'DELETE_PROJECT'; payload: string }
  | { type: 'ADD_DEPENSE'; payload: Depense }
  | { type: 'UPDATE_DEPENSE'; payload: Depense }
  | { type: 'DELETE_DEPENSE'; payload: string }
  | { type: 'APPROVE_DEPENSE'; payload: { id: string } }
  | { type: 'REJECT_DEPENSE'; payload: { id: string; commentaire: string } }
  | { type: 'ADD_COTISATION'; payload: Cotisation }
  | { type: 'UPDATE_COTISATION'; payload: Cotisation }
  | { type: 'DELETE_COTISATION'; payload: string }
  | { type: 'VALIDATE_COTISATION'; payload: { id: string; datePaiement: string } }
  | { type: 'REJECT_COTISATION'; payload: { id: string; commentaire: string } };

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'SET_USER':
      return { ...state, currentUserId: action.payload };

    case 'ADD_MEMBER':
      return { ...state, members: [...state.members, action.payload] };
    case 'UPDATE_MEMBER':
      return { ...state, members: state.members.map(m => m.id === action.payload.id ? action.payload : m) };
    case 'DELETE_MEMBER':
      return { ...state, members: state.members.filter(m => m.id !== action.payload) };

    case 'ADD_PROJECT':
      return { ...state, projects: [...state.projects, action.payload] };
    case 'UPDATE_PROJECT':
      return { ...state, projects: state.projects.map(p => p.id === action.payload.id ? action.payload : p) };
    case 'DELETE_PROJECT':
      return { ...state, projects: state.projects.filter(p => p.id !== action.payload) };

    case 'ADD_DEPENSE':
      return { ...state, depenses: [...state.depenses, action.payload] };
    case 'UPDATE_DEPENSE':
      return { ...state, depenses: state.depenses.map(d => d.id === action.payload.id ? action.payload : d) };
    case 'DELETE_DEPENSE':
      return { ...state, depenses: state.depenses.filter(d => d.id !== action.payload) };
    case 'APPROVE_DEPENSE':
      return { ...state, depenses: state.depenses.map(d => d.id === action.payload.id ? { ...d, statut: 'approuvee' as const } : d) };
    case 'REJECT_DEPENSE':
      return { ...state, depenses: state.depenses.map(d => d.id === action.payload.id ? { ...d, statut: 'rejetee' as const, commentaire: action.payload.commentaire } : d) };

    case 'ADD_COTISATION':
      return { ...state, cotisations: [...state.cotisations, action.payload] };
    case 'UPDATE_COTISATION':
      return { ...state, cotisations: state.cotisations.map(c => c.id === action.payload.id ? action.payload : c) };
    case 'DELETE_COTISATION':
      return { ...state, cotisations: state.cotisations.filter(c => c.id !== action.payload) };
    case 'VALIDATE_COTISATION':
      return { ...state, cotisations: state.cotisations.map(c => c.id === action.payload.id ? { ...c, statut: 'validee' as const, datePaiement: action.payload.datePaiement } : c) };
    case 'REJECT_COTISATION':
      return { ...state, cotisations: state.cotisations.map(c => c.id === action.payload.id ? { ...c, statut: 'en_retard' as const, commentaire: action.payload.commentaire } : c) };

    default:
      return state;
  }
}

const STORAGE_KEY = 'jamiyati_data';

function loadState(): AppState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return JSON.parse(raw) as AppState;
  } catch {
    // ignore
  }
  return seedData;
}

interface AppContextType {
  state: AppState;
  dispatch: React.Dispatch<Action>;
  currentUser: Member | undefined;
  canValidateExpense: (projetId: string) => boolean;
  canValidateCotisation: () => boolean;
  canManageMembers: () => boolean;
  canManageProjects: () => boolean;
  getProjectSpent: (projetId: string) => number;
  getMemberName: (id: string) => string;
  getProjectName: (id: string) => string;
}

const AppContext = createContext<AppContextType | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, loadState);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  }, [state]);

  const currentUser = state.members.find(m => m.id === state.currentUserId);

  const canValidateExpense = (projetId: string) => {
    if (!currentUser) return false;
    if (currentUser.role === 'admin') return true;
    const project = state.projects.find(p => p.id === projetId);
    return project?.responsableId === currentUser.id;
  };

  const canValidateCotisation = () =>
    currentUser?.role === 'tresorier' || currentUser?.role === 'admin';

  const canManageMembers = () => currentUser?.role === 'admin';

  const canManageProjects = () =>
    currentUser?.role === 'admin' || currentUser?.role === 'tresorier';

  const getProjectSpent = (projetId: string) =>
    state.depenses
      .filter(d => d.projetId === projetId && d.statut === 'approuvee')
      .reduce((sum, d) => sum + d.montant, 0);

  const getMemberName = (id: string) => {
    const m = state.members.find(m => m.id === id);
    return m ? `${m.prenom} ${m.nom}` : '—';
  };

  const getProjectName = (id: string) => {
    const p = state.projects.find(p => p.id === id);
    return p?.nom ?? '—';
  };

  return (
    <AppContext.Provider value={{
      state, dispatch, currentUser,
      canValidateExpense, canValidateCotisation,
      canManageMembers, canManageProjects,
      getProjectSpent, getMemberName, getProjectName,
    }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used inside AppProvider');
  return ctx;
}
