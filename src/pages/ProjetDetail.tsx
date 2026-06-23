import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ArrowRight, ArrowLeft, Plus, Check, X, Trash2 } from 'lucide-react';
import { v4 as uuid } from 'uuid';
import { useApp } from '../context/AppContext';
import type { Depense, DepenseCategorie } from '../types';
import Badge from '../components/ui/Badge';
import Modal from '../components/ui/Modal';
import ConfirmDialog from '../components/ui/ConfirmDialog';

function DepenseForm({ projetId, depense, onSave, onClose }: {
  projetId: string;
  depense?: Depense;
  onSave: (d: Depense) => void;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const { state } = useApp();
  const today = new Date().toISOString().split('T')[0];
  const [form, setForm] = useState<Partial<Depense>>(depense ?? {
    projetId, categorie: 'materiel', date: today, statut: 'soumise',
  });
  const set = (k: keyof Depense, v: unknown) => setForm(f => ({ ...f, [k]: v }));

  const cats: DepenseCategorie[] = ['materiel', 'deplacement', 'communication', 'restauration', 'autre'];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.description || !form.montant || !form.date || !form.membreId) return;
    onSave({
      id: depense?.id ?? uuid(),
      projetId,
      membreId: form.membreId!,
      description: form.description!,
      montant: Number(form.montant),
      date: form.date!,
      categorie: form.categorie as DepenseCategorie,
      statut: depense?.statut ?? 'soumise',
      commentaire: form.commentaire,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="form-label">{t('expenses.description')} *</label>
        <input className="form-input" value={form.description ?? ''} onChange={e => set('description', e.target.value)} required />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('expenses.amount')} *</label>
          <input type="number" min={1} className="form-input" value={form.montant ?? ''} onChange={e => set('montant', e.target.value)} required />
        </div>
        <div>
          <label className="form-label">{t('expenses.date')} *</label>
          <input type="date" className="form-input" value={form.date ?? ''} onChange={e => set('date', e.target.value)} required />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('expenses.category')} *</label>
          <select className="form-input" value={form.categorie} onChange={e => set('categorie', e.target.value)}>
            {cats.map(c => <option key={c} value={c}>{t(`expenses.categories.${c}`)}</option>)}
          </select>
        </div>
        <div>
          <label className="form-label">{t('expenses.submittedBy')} *</label>
          <select className="form-input" value={form.membreId ?? ''} onChange={e => set('membreId', e.target.value)} required>
            <option value="">{t('common.selectMember')}</option>
            {state.members.filter(m => m.statut === 'actif').map(m => (
              <option key={m.id} value={m.id}>{m.prenom} {m.nom}</option>
            ))}
          </select>
        </div>
      </div>
      <div className="flex gap-3 pt-2">
        <button type="button" onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button type="submit" className="flex-1 btn-primary justify-center">{t('common.save')}</button>
      </div>
    </form>
  );
}

function RejectForm({ onReject, onClose }: { onReject: (reason: string) => void; onClose: () => void }) {
  const { t } = useTranslation();
  const [reason, setReason] = useState('');
  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">{t('expenses.rejectionReason')} *</label>
        <textarea className="form-input" rows={3} value={reason} onChange={e => setReason(e.target.value)} />
      </div>
      <div className="flex gap-3">
        <button onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button onClick={() => reason && onReject(reason)} className="flex-1 btn-danger justify-center">{t('expenses.reject')}</button>
      </div>
    </div>
  );
}

export default function ProjetDetail() {
  const { id } = useParams<{ id: string }>();
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const { state, dispatch, getProjectSpent, canValidateExpense, getMemberName } = useApp();

  const project = state.projects.find(p => p.id === id);
  const depenses = state.depenses.filter(d => d.projetId === id);
  const [showForm, setShowForm] = useState(false);
  const [rejectId, setRejectId] = useState<string | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<'all' | 'soumise' | 'approuvee' | 'rejetee'>('all');

  if (!project) return (
    <div className="card text-center py-16">
      <p className="text-slate-400">{t('common.noData')}</p>
      <Link to="/projets" className="btn-primary mt-4 inline-flex">{t('common.back')}</Link>
    </div>
  );

  const spent = getProjectSpent(id!);
  const pct = project.budget > 0 ? Math.min(Math.round((spent / project.budget) * 100), 100) : 0;
  const over = spent > project.budget;
  const manager = state.members.find(m => m.id === project.responsableId);

  const filtered = depenses.filter(d => filterStatus === 'all' || d.statut === filterStatus);

  const statusBadge = (s: string) => {
    if (s === 'soumise') return <Badge variant="warning">{t('expenses.submitted')}</Badge>;
    if (s === 'approuvee') return <Badge variant="success">{t('expenses.approved')}</Badge>;
    return <Badge variant="danger">{t('expenses.rejected')}</Badge>;
  };

  const BackIcon = isRTL ? ArrowRight : ArrowLeft;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Link to="/projets" className="p-2 rounded-xl text-slate-500 hover:bg-slate-100 transition-colors">
          <BackIcon size={20} />
        </Link>
        <h1 className="text-2xl font-bold text-slate-800">{project.nom}</h1>
      </div>

      {/* Project info */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card md:col-span-2">
          <p className="text-slate-500 text-sm mb-4">{project.description}</p>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-slate-400">{t('projects.manager')}: </span>
              <span className="font-medium">{manager?.prenom} {manager?.nom}</span>
            </div>
            <div>
              <span className="text-slate-400">{t('projects.type')}: </span>
              <span className="font-medium">{project.type === 'periodique' ? t('projects.periodic') : t('projects.standard')}</span>
            </div>
            <div>
              <span className="text-slate-400">{t('projects.startDate')}: </span>
              <span className="font-medium">{project.dateDebut}</span>
            </div>
            {project.dateFin && (
              <div>
                <span className="text-slate-400">{t('projects.endDate')}: </span>
                <span className="font-medium">{project.dateFin}</span>
              </div>
            )}
          </div>
        </div>
        <div className="card bg-slate-50 border-0">
          <p className="text-sm text-slate-500 mb-2">{t('projects.budgetUsage')}</p>
          <div className="text-3xl font-bold mb-1" style={{ color: over ? '#f43f5e' : '#10b981' }}>
            {pct}%
          </div>
          <div className="h-3 bg-slate-200 rounded-full overflow-hidden mb-2">
            <div
              className={`h-full rounded-full ${over ? 'bg-rose-500' : pct > 75 ? 'bg-amber-400' : 'bg-emerald-500'}`}
              style={{ width: `${pct}%` }}
            />
          </div>
          <div className="text-xs text-slate-500">
            <span className="font-medium text-slate-800">{spent.toLocaleString()} {t('common.currency')}</span>
            <span className="text-slate-400"> / {project.budget.toLocaleString()} {t('common.currency')}</span>
          </div>
          {over && <p className="text-xs text-rose-500 font-medium mt-1">{t('projects.budgetOver')}</p>}
        </div>
      </div>

      {/* Expenses */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-slate-800">{t('expenses.title')}</h2>
          <button onClick={() => setShowForm(true)} className="btn-primary text-sm">
            <Plus size={16} /> {t('expenses.add')}
          </button>
        </div>

        {/* Filter tabs */}
        <div className="flex gap-2 mb-4 flex-wrap">
          {(['all', 'soumise', 'approuvee', 'rejetee'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilterStatus(f)}
              className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${filterStatus === f ? 'bg-primary-600 text-white' : 'bg-slate-100 text-slate-600 hover:bg-slate-200'}`}
            >
              {f === 'all' ? t('common.all') : f === 'soumise' ? t('expenses.submitted') : f === 'approuvee' ? t('expenses.approved') : t('expenses.rejected')}
              <span className="ms-1 opacity-60">
                ({f === 'all' ? depenses.length : depenses.filter(d => d.statut === f).length})
              </span>
            </button>
          ))}
        </div>

        {filtered.length === 0 ? (
          <p className="text-center text-slate-400 py-8">{t('expenses.noExpenses')}</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-100">
                  <th className="table-header text-start">{t('expenses.description')}</th>
                  <th className="table-header text-start">{t('expenses.submittedBy')}</th>
                  <th className="table-header text-start">{t('expenses.category')}</th>
                  <th className="table-header text-start">{t('expenses.date')}</th>
                  <th className="table-header text-start">{t('expenses.amount')}</th>
                  <th className="table-header text-start">{t('expenses.status')}</th>
                  <th className="table-header text-start">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(d => (
                  <tr key={d.id} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="table-cell">
                      <div>
                        <p className="font-medium">{d.description}</p>
                        {d.commentaire && <p className="text-xs text-slate-400 mt-0.5">{d.commentaire}</p>}
                      </div>
                    </td>
                    <td className="table-cell">{getMemberName(d.membreId)}</td>
                    <td className="table-cell">{t(`expenses.categories.${d.categorie}`)}</td>
                    <td className="table-cell">{d.date}</td>
                    <td className="table-cell font-medium">{d.montant.toLocaleString()} {t('common.currency')}</td>
                    <td className="table-cell">{statusBadge(d.statut)}</td>
                    <td className="table-cell">
                      <div className="flex gap-1">
                        {d.statut === 'soumise' && canValidateExpense(id!) && (
                          <>
                            <button
                              onClick={() => dispatch({ type: 'APPROVE_DEPENSE', payload: { id: d.id } })}
                              className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition-colors"
                              title={t('expenses.approve')}
                            >
                              <Check size={15} />
                            </button>
                            <button
                              onClick={() => setRejectId(d.id)}
                              className="p-1.5 rounded-lg bg-rose-50 text-rose-500 hover:bg-rose-100 transition-colors"
                              title={t('expenses.reject')}
                            >
                              <X size={15} />
                            </button>
                          </>
                        )}
                        <button
                          onClick={() => setDeleteId(d.id)}
                          className="p-1.5 rounded-lg text-slate-300 hover:text-rose-500 hover:bg-rose-50 transition-colors"
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-slate-200 bg-slate-50">
                  <td colSpan={4} className="table-cell font-semibold">{t('common.total')}</td>
                  <td className="table-cell font-bold text-primary-700">
                    {filtered.reduce((s, d) => s + d.montant, 0).toLocaleString()} {t('common.currency')}
                  </td>
                  <td colSpan={2} />
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={t('expenses.add')}>
        <DepenseForm
          projetId={id!}
          onSave={d => { dispatch({ type: 'ADD_DEPENSE', payload: d }); setShowForm(false); }}
          onClose={() => setShowForm(false)}
        />
      </Modal>

      <Modal open={!!rejectId} onClose={() => setRejectId(null)} title={t('expenses.reject')}>
        <RejectForm
          onReject={reason => {
            if (rejectId) dispatch({ type: 'REJECT_DEPENSE', payload: { id: rejectId, commentaire: reason } });
            setRejectId(null);
          }}
          onClose={() => setRejectId(null)}
        />
      </Modal>

      <ConfirmDialog
        open={!!deleteId}
        message={t('common.confirmDelete')}
        onConfirm={() => { if (deleteId) dispatch({ type: 'DELETE_DEPENSE', payload: deleteId }); setDeleteId(null); }}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}
