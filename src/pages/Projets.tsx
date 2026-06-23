import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Plus, Pencil, Trash2, ChevronRight, FolderOpen } from 'lucide-react';
import { Link } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import { useApp } from '../context/AppContext';
import type { Project, ProjectType, ProjectStatus } from '../types';
import Badge from '../components/ui/Badge';
import Modal from '../components/ui/Modal';
import ConfirmDialog from '../components/ui/ConfirmDialog';

function ProjectForm({ project, onSave, onClose }: {
  project?: Project;
  onSave: (p: Project) => void;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const { state } = useApp();
  const [form, setForm] = useState<Partial<Project>>(project ?? {
    type: 'standard', statut: 'actif', budget: 0,
  });

  const set = (k: keyof Project, v: unknown) => setForm(f => ({ ...f, [k]: v }));

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.nom || !form.dateDebut || !form.responsableId || !form.budget) return;
    onSave({
      id: project?.id ?? uuid(),
      nom: form.nom!,
      description: form.description ?? '',
      type: form.type as ProjectType,
      budget: Number(form.budget),
      dateDebut: form.dateDebut!,
      dateFin: form.dateFin,
      statut: form.statut as ProjectStatus,
      responsableId: form.responsableId!,
      cotisationDediee: form.type === 'periodique' ? Number(form.cotisationDediee ?? 0) : undefined,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="form-label">{t('projects.name')} *</label>
        <input className="form-input" value={form.nom ?? ''} onChange={e => set('nom', e.target.value)} required />
      </div>
      <div>
        <label className="form-label">{t('projects.description')}</label>
        <textarea className="form-input" rows={2} value={form.description ?? ''} onChange={e => set('description', e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('projects.type')} *</label>
          <select className="form-input" value={form.type} onChange={e => set('type', e.target.value)}>
            <option value="standard">{t('projects.standard')}</option>
            <option value="periodique">{t('projects.periodic')}</option>
          </select>
        </div>
        <div>
          <label className="form-label">{t('projects.status')} *</label>
          <select className="form-input" value={form.statut} onChange={e => set('statut', e.target.value)}>
            <option value="actif">{t('projects.active')}</option>
            <option value="termine">{t('projects.completed')}</option>
            <option value="suspendu">{t('projects.suspended')}</option>
          </select>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('projects.budget')} *</label>
          <input type="number" min={0} className="form-input" value={form.budget ?? ''} onChange={e => set('budget', e.target.value)} required />
        </div>
        {form.type === 'periodique' && (
          <div>
            <label className="form-label">{t('projects.dedicatedFee')}</label>
            <input type="number" min={0} className="form-input" value={form.cotisationDediee ?? ''} onChange={e => set('cotisationDediee', e.target.value)} />
          </div>
        )}
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('projects.startDate')} *</label>
          <input type="date" className="form-input" value={form.dateDebut ?? ''} onChange={e => set('dateDebut', e.target.value)} required />
        </div>
        <div>
          <label className="form-label">{t('projects.endDate')}</label>
          <input type="date" className="form-input" value={form.dateFin ?? ''} onChange={e => set('dateFin', e.target.value)} />
        </div>
      </div>
      <div>
        <label className="form-label">{t('projects.manager')} *</label>
        <select className="form-input" value={form.responsableId ?? ''} onChange={e => set('responsableId', e.target.value)} required>
          <option value="">{t('common.selectMember')}</option>
          {state.members.filter(m => m.statut === 'actif').map(m => (
            <option key={m.id} value={m.id}>{m.prenom} {m.nom}</option>
          ))}
        </select>
      </div>
      <div className="flex gap-3 pt-2">
        <button type="button" onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button type="submit" className="flex-1 btn-primary justify-center">{t('common.save')}</button>
      </div>
    </form>
  );
}

export default function Projets() {
  const { t } = useTranslation();
  const { state, dispatch, getProjectSpent, canManageProjects } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [editProject, setEditProject] = useState<Project | undefined>();
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'actif' | 'termine' | 'suspendu'>('all');

  const filtered = state.projects.filter(p => filter === 'all' || p.statut === filter);

  const statusBadge = (s: string) => {
    if (s === 'actif') return <Badge variant="success">{t('projects.active')}</Badge>;
    if (s === 'termine') return <Badge variant="info">{t('projects.completed')}</Badge>;
    return <Badge variant="neutral">{t('projects.suspended')}</Badge>;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">{t('projects.title')}</h1>
        {canManageProjects() && (
          <button onClick={() => { setEditProject(undefined); setShowForm(true); }} className="btn-primary">
            <Plus size={18} /> {t('projects.add')}
          </button>
        )}
      </div>

      {/* Filter */}
      <div className="flex gap-2 flex-wrap">
        {(['all', 'actif', 'termine', 'suspendu'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${filter === f ? 'bg-primary-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}`}
          >
            {f === 'all' ? t('common.all') : f === 'actif' ? t('projects.active') : f === 'termine' ? t('projects.completed') : t('projects.suspended')}
          </button>
        ))}
      </div>

      {/* Grid */}
      {filtered.length === 0 ? (
        <div className="card text-center py-16">
          <FolderOpen size={48} className="mx-auto text-slate-200 mb-3" />
          <p className="text-slate-400">{t('projects.noProjects')}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
          {filtered.map(p => {
            const spent = getProjectSpent(p.id);
            const pct = p.budget > 0 ? Math.min(Math.round((spent / p.budget) * 100), 100) : 0;
            const over = spent > p.budget;
            const manager = state.members.find(m => m.id === p.responsableId);
            const pendingCount = state.depenses.filter(d => d.projetId === p.id && d.statut === 'soumise').length;
            return (
              <div key={p.id} className="card hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${p.type === 'periodique' ? 'bg-purple-100 text-purple-700' : 'bg-cyan-100 text-cyan-700'}`}>
                        {p.type === 'periodique' ? t('projects.periodic') : t('projects.standard')}
                      </span>
                      {statusBadge(p.statut)}
                    </div>
                    <h3 className="font-semibold text-slate-800 leading-tight">{p.nom}</h3>
                    <p className="text-xs text-slate-400 mt-1 line-clamp-2">{p.description}</p>
                  </div>
                  {canManageProjects() && (
                    <div className="flex gap-1 ms-2">
                      <button onClick={() => { setEditProject(p); setShowForm(true); }} className="p-1.5 rounded-lg text-slate-400 hover:text-primary-600 hover:bg-primary-50 transition-colors">
                        <Pencil size={15} />
                      </button>
                      <button onClick={() => setDeleteId(p.id)} className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 transition-colors">
                        <Trash2 size={15} />
                      </button>
                    </div>
                  )}
                </div>

                {/* Budget bar */}
                <div className="mb-3">
                  <div className="flex justify-between text-xs text-slate-500 mb-1">
                    <span>{t('projects.budgetUsage')}</span>
                    <span className={over ? 'text-rose-600 font-semibold' : ''}>{pct}%</span>
                  </div>
                  <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${over ? 'bg-rose-500' : pct > 75 ? 'bg-amber-400' : 'bg-emerald-500'}`}
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs mt-1">
                    <span className="text-slate-500">{spent.toLocaleString()} {t('common.currency')}</span>
                    <span className="text-slate-400">/ {p.budget.toLocaleString()} {t('common.currency')}</span>
                  </div>
                </div>

                <div className="flex items-center justify-between pt-3 border-t border-slate-100">
                  <div className="text-xs text-slate-400">
                    {manager && <span>{manager.prenom} {manager.nom}</span>}
                    {pendingCount > 0 && (
                      <span className="ms-2 bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full text-xs font-medium">
                        {pendingCount} {t('expenses.submitted')}
                      </span>
                    )}
                  </div>
                  <Link to={`/projets/${p.id}`} className="flex items-center gap-1 text-xs text-primary-600 hover:underline font-medium">
                    {t('common.details')} <ChevronRight size={14} />
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Form Modal */}
      <Modal
        open={showForm}
        onClose={() => setShowForm(false)}
        title={editProject ? t('common.edit') : t('projects.add')}
        size="lg"
      >
        <ProjectForm
          project={editProject}
          onSave={p => {
            dispatch(editProject ? { type: 'UPDATE_PROJECT', payload: p } : { type: 'ADD_PROJECT', payload: p });
            setShowForm(false);
          }}
          onClose={() => setShowForm(false)}
        />
      </Modal>

      <ConfirmDialog
        open={!!deleteId}
        message={t('common.confirmDelete')}
        onConfirm={() => { if (deleteId) dispatch({ type: 'DELETE_PROJECT', payload: deleteId }); setDeleteId(null); }}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}
