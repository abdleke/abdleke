import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Plus, Check, X, Trash2, CreditCard } from 'lucide-react';
import { v4 as uuid } from 'uuid';
import { useApp } from '../context/AppContext';
import type { Cotisation, CotisationFrequence, CotisationType } from '../types';
import Badge from '../components/ui/Badge';
import Modal from '../components/ui/Modal';
import ConfirmDialog from '../components/ui/ConfirmDialog';

function CotisationForm({ onSave, onClose }: {
  onSave: (c: Cotisation) => void;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const { state, currentUser } = useApp();
  const today = new Date().toISOString().split('T')[0];
  const currentYear = new Date().getFullYear();

  const [form, setForm] = useState({
    membreId: currentUser?.id ?? '',
    montant: '',
    frequence: 'annuelle' as CotisationFrequence,
    annee: currentYear,
    dateEcheance: '',
    type: 'normale' as CotisationType,
    projetId: '',
    commentaire: '',
  });
  const set = (k: string, v: unknown) => setForm(f => ({ ...f, [k]: v }));

  const periodicProjects = state.projects.filter(p => p.type === 'periodique' && p.statut === 'actif');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.membreId || !form.montant || !form.dateEcheance) return;
    onSave({
      id: uuid(),
      membreId: form.membreId,
      montant: Number(form.montant),
      frequence: form.frequence,
      annee: Number(form.annee),
      dateDeclaration: today,
      dateEcheance: form.dateEcheance,
      statut: 'en_attente',
      type: form.type,
      projetId: form.type === 'dediee' ? form.projetId : undefined,
      commentaire: form.commentaire || undefined,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="form-label">{t('cotisations.member')} *</label>
        <select className="form-input" value={form.membreId} onChange={e => set('membreId', e.target.value)} required>
          <option value="">{t('common.selectMember')}</option>
          {state.members.filter(m => m.statut === 'actif').map(m => (
            <option key={m.id} value={m.id}>{m.prenom} {m.nom}</option>
          ))}
        </select>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('cotisations.amount')} *</label>
          <input type="number" min={1} className="form-input" value={form.montant} onChange={e => set('montant', e.target.value)} required />
        </div>
        <div>
          <label className="form-label">{t('cotisations.frequency')} *</label>
          <select className="form-input" value={form.frequence} onChange={e => set('frequence', e.target.value)}>
            <option value="mensuelle">{t('cotisations.monthly')}</option>
            <option value="trimestrielle">{t('cotisations.quarterly')}</option>
            <option value="annuelle">{t('cotisations.annual')}</option>
          </select>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('cotisations.year')} *</label>
          <input type="number" className="form-input" value={form.annee} onChange={e => set('annee', e.target.value)} />
        </div>
        <div>
          <label className="form-label">{t('cotisations.dueDate')} *</label>
          <input type="date" className="form-input" value={form.dateEcheance} onChange={e => set('dateEcheance', e.target.value)} required />
        </div>
      </div>
      <div>
        <label className="form-label">{t('cotisations.type')} *</label>
        <select className="form-input" value={form.type} onChange={e => set('type', e.target.value)}>
          <option value="normale">{t('cotisations.normal')}</option>
          <option value="dediee">{t('cotisations.dedicated')}</option>
        </select>
      </div>
      {form.type === 'dediee' && (
        <div>
          <label className="form-label">{t('cotisations.project')}</label>
          <select className="form-input" value={form.projetId} onChange={e => set('projetId', e.target.value)}>
            <option value="">{t('common.selectProject')}</option>
            {periodicProjects.map(p => <option key={p.id} value={p.id}>{p.nom}</option>)}
          </select>
        </div>
      )}
      <div>
        <label className="form-label">{t('common.optional')}</label>
        <textarea className="form-input" rows={2} value={form.commentaire} onChange={e => set('commentaire', e.target.value)} />
      </div>
      <div className="flex gap-3 pt-2">
        <button type="button" onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button type="submit" className="flex-1 btn-primary justify-center">{t('common.save')}</button>
      </div>
    </form>
  );
}

function ValidateForm({ onValidate, onClose }: { onValidate: (date: string) => void; onClose: () => void }) {
  const { t } = useTranslation();
  const today = new Date().toISOString().split('T')[0];
  const [date, setDate] = useState(today);
  return (
    <div className="space-y-4">
      <div>
        <label className="form-label">{t('cotisations.paymentDate')} *</label>
        <input type="date" className="form-input" value={date} onChange={e => setDate(e.target.value)} />
      </div>
      <div className="flex gap-3">
        <button onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button onClick={() => onValidate(date)} className="flex-1 btn-success justify-center">{t('cotisations.validate')}</button>
      </div>
    </div>
  );
}

export default function Cotisations() {
  const { t } = useTranslation();
  const { state, dispatch, getMemberName, getProjectName, canValidateCotisation } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [validateId, setValidateId] = useState<string | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<'all' | 'en_attente' | 'validee' | 'en_retard'>('all');
  const [filterType, setFilterType] = useState<'all' | 'normale' | 'dediee'>('all');
  const [search, setSearch] = useState('');

  const filtered = state.cotisations.filter(c => {
    const name = getMemberName(c.membreId).toLowerCase();
    const matchSearch = name.includes(search.toLowerCase());
    const matchStatus = filterStatus === 'all' || c.statut === filterStatus;
    const matchType = filterType === 'all' || c.type === filterType;
    return matchSearch && matchStatus && matchType;
  });

  const statusBadge = (s: string) => {
    if (s === 'validee') return <Badge variant="success">{t('cotisations.validated')}</Badge>;
    if (s === 'en_attente') return <Badge variant="warning">{t('cotisations.pending')}</Badge>;
    return <Badge variant="danger">{t('cotisations.overdue')}</Badge>;
  };

  const totalCollected = state.cotisations.filter(c => c.statut === 'validee').reduce((s, c) => s + c.montant, 0);
  const totalPending = state.cotisations.filter(c => c.statut === 'en_attente').reduce((s, c) => s + c.montant, 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">{t('cotisations.title')}</h1>
        <button onClick={() => setShowForm(true)} className="btn-primary">
          <Plus size={18} /> {t('cotisations.add')}
        </button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4">
        <div className="card bg-emerald-50 border-0 text-center">
          <p className="text-xs text-emerald-600 font-medium">{t('cotisations.validated')}</p>
          <p className="text-2xl font-bold text-emerald-800 mt-1">{totalCollected.toLocaleString()} {t('common.currency')}</p>
        </div>
        <div className="card bg-amber-50 border-0 text-center">
          <p className="text-xs text-amber-600 font-medium">{t('cotisations.pending')}</p>
          <p className="text-2xl font-bold text-amber-800 mt-1">{totalPending.toLocaleString()} {t('common.currency')}</p>
        </div>
        <div className="card bg-rose-50 border-0 text-center">
          <p className="text-xs text-rose-600 font-medium">{t('cotisations.overdue')}</p>
          <p className="text-2xl font-bold text-rose-800 mt-1">
            {state.cotisations.filter(c => c.statut === 'en_retard').length}
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-2 items-center">
        <input
          className="form-input max-w-xs"
          placeholder={t('common.search')}
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <div className="flex gap-2">
          {(['all', 'en_attente', 'validee', 'en_retard'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilterStatus(f)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${filterStatus === f ? 'bg-primary-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}`}
            >
              {f === 'all' ? t('common.all') : f === 'en_attente' ? t('cotisations.pending') : f === 'validee' ? t('cotisations.validated') : t('cotisations.overdue')}
            </button>
          ))}
        </div>
        <div className="flex gap-2">
          {(['all', 'normale', 'dediee'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilterType(f)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${filterType === f ? 'bg-slate-700 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}`}
            >
              {f === 'all' ? t('common.all') : f === 'normale' ? t('cotisations.normal') : t('cotisations.dedicated')}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-16">
            <CreditCard size={48} className="mx-auto text-slate-200 mb-3" />
            <p className="text-slate-400">{t('cotisations.noCotisations')}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-100">
                  <th className="table-header text-start">{t('cotisations.member')}</th>
                  <th className="table-header text-start">{t('cotisations.type')}</th>
                  <th className="table-header text-start">{t('cotisations.frequency')}</th>
                  <th className="table-header text-start">{t('cotisations.amount')}</th>
                  <th className="table-header text-start">{t('cotisations.dueDate')}</th>
                  <th className="table-header text-start">{t('cotisations.paymentDate')}</th>
                  <th className="table-header text-start">{t('cotisations.status')}</th>
                  <th className="table-header text-start">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(c => (
                  <tr key={c.id} className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                    <td className="table-cell font-medium">{getMemberName(c.membreId)}</td>
                    <td className="table-cell">
                      {c.type === 'dediee'
                        ? <span className="text-xs text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full">{getProjectName(c.projetId ?? '')}</span>
                        : <span className="text-xs text-slate-500">{t('cotisations.normal')}</span>
                      }
                    </td>
                    <td className="table-cell text-slate-500">
                      {c.frequence === 'mensuelle' ? t('cotisations.monthly') : c.frequence === 'trimestrielle' ? t('cotisations.quarterly') : t('cotisations.annual')}
                    </td>
                    <td className="table-cell font-semibold">{c.montant.toLocaleString()} {t('common.currency')}</td>
                    <td className="table-cell text-slate-500">{c.dateEcheance}</td>
                    <td className="table-cell text-slate-500">{c.datePaiement ?? '—'}</td>
                    <td className="table-cell">{statusBadge(c.statut)}</td>
                    <td className="table-cell">
                      <div className="flex gap-1">
                        {c.statut === 'en_attente' && canValidateCotisation() && (
                          <button
                            onClick={() => setValidateId(c.id)}
                            className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600 hover:bg-emerald-100 transition-colors"
                            title={t('cotisations.validate')}
                          >
                            <Check size={15} />
                          </button>
                        )}
                        {c.statut === 'en_attente' && canValidateCotisation() && (
                          <button
                            onClick={() => dispatch({ type: 'REJECT_COTISATION', payload: { id: c.id, commentaire: '' } })}
                            className="p-1.5 rounded-lg bg-rose-50 text-rose-500 hover:bg-rose-100 transition-colors"
                            title={t('common.cancel')}
                          >
                            <X size={15} />
                          </button>
                        )}
                        <button
                          onClick={() => setDeleteId(c.id)}
                          className="p-1.5 rounded-lg text-slate-300 hover:text-rose-500 hover:bg-rose-50 transition-colors"
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={t('cotisations.add')} size="lg">
        <CotisationForm
          onSave={c => { dispatch({ type: 'ADD_COTISATION', payload: c }); setShowForm(false); }}
          onClose={() => setShowForm(false)}
        />
      </Modal>

      <Modal open={!!validateId} onClose={() => setValidateId(null)} title={t('cotisations.validate')}>
        <ValidateForm
          onValidate={date => {
            if (validateId) dispatch({ type: 'VALIDATE_COTISATION', payload: { id: validateId, datePaiement: date } });
            setValidateId(null);
          }}
          onClose={() => setValidateId(null)}
        />
      </Modal>

      <ConfirmDialog
        open={!!deleteId}
        message={t('common.confirmDelete')}
        onConfirm={() => { if (deleteId) dispatch({ type: 'DELETE_COTISATION', payload: deleteId }); setDeleteId(null); }}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}
