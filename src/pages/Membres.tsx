import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Plus, Pencil, Trash2, Users } from 'lucide-react';
import { v4 as uuid } from 'uuid';
import { useApp } from '../context/AppContext';
import type { Member, Role, MemberStatus } from '../types';
import Badge from '../components/ui/Badge';
import Modal from '../components/ui/Modal';
import ConfirmDialog from '../components/ui/ConfirmDialog';

function MemberForm({ member, onSave, onClose }: {
  member?: Member;
  onSave: (m: Member) => void;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const today = new Date().toISOString().split('T')[0];
  const [form, setForm] = useState<Partial<Member>>(member ?? {
    role: 'membre', statut: 'actif', dateAdhesion: today,
  });
  const set = (k: keyof Member, v: unknown) => setForm(f => ({ ...f, [k]: v }));
  const roles: Role[] = ['admin', 'tresorier', 'chef_projet', 'membre'];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.prenom || !form.nom || !form.email) return;
    onSave({
      id: member?.id ?? uuid(),
      prenom: form.prenom!,
      nom: form.nom!,
      email: form.email!,
      telephone: form.telephone ?? '',
      dateAdhesion: form.dateAdhesion ?? today,
      statut: form.statut as MemberStatus,
      role: form.role as Role,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('members.firstName')} *</label>
          <input className="form-input" value={form.prenom ?? ''} onChange={e => set('prenom', e.target.value)} required />
        </div>
        <div>
          <label className="form-label">{t('members.lastName')} *</label>
          <input className="form-input" value={form.nom ?? ''} onChange={e => set('nom', e.target.value)} required />
        </div>
      </div>
      <div>
        <label className="form-label">{t('members.email')} *</label>
        <input type="email" className="form-input" value={form.email ?? ''} onChange={e => set('email', e.target.value)} required />
      </div>
      <div>
        <label className="form-label">{t('members.phone')}</label>
        <input type="tel" className="form-input" value={form.telephone ?? ''} onChange={e => set('telephone', e.target.value)} />
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="form-label">{t('members.role')} *</label>
          <select className="form-input" value={form.role} onChange={e => set('role', e.target.value)}>
            {roles.map(r => <option key={r} value={r}>{t(`members.roles.${r}`)}</option>)}
          </select>
        </div>
        <div>
          <label className="form-label">{t('members.status')} *</label>
          <select className="form-input" value={form.statut} onChange={e => set('statut', e.target.value)}>
            <option value="actif">{t('members.active')}</option>
            <option value="inactif">{t('members.inactive')}</option>
          </select>
        </div>
      </div>
      <div>
        <label className="form-label">{t('members.joinDate')}</label>
        <input type="date" className="form-input" value={form.dateAdhesion ?? ''} onChange={e => set('dateAdhesion', e.target.value)} />
      </div>
      <div className="flex gap-3 pt-2">
        <button type="button" onClick={onClose} className="flex-1 btn-secondary justify-center">{t('common.cancel')}</button>
        <button type="submit" className="flex-1 btn-primary justify-center">{t('common.save')}</button>
      </div>
    </form>
  );
}

const roleVariant: Record<string, 'purple' | 'info' | 'warning' | 'neutral'> = {
  admin: 'purple', tresorier: 'info', chef_projet: 'warning', membre: 'neutral',
};

export default function Membres() {
  const { t } = useTranslation();
  const { state, dispatch, canManageMembers } = useApp();
  const [showForm, setShowForm] = useState(false);
  const [editMember, setEditMember] = useState<Member | undefined>();
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [filterStatus, setFilterStatus] = useState<'all' | 'actif' | 'inactif'>('all');

  const filtered = state.members.filter(m => {
    const matchSearch = `${m.prenom} ${m.nom} ${m.email}`.toLowerCase().includes(search.toLowerCase());
    const matchStatus = filterStatus === 'all' || m.statut === filterStatus;
    return matchSearch && matchStatus;
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-800">{t('members.title')}</h1>
        {canManageMembers() && (
          <button onClick={() => { setEditMember(undefined); setShowForm(true); }} className="btn-primary">
            <Plus size={18} /> {t('members.add')}
          </button>
        )}
      </div>

      {/* Search + Filter */}
      <div className="flex gap-3 flex-wrap">
        <input
          className="form-input max-w-xs"
          placeholder={t('common.search')}
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <div className="flex gap-2">
          {(['all', 'actif', 'inactif'] as const).map(f => (
            <button
              key={f}
              onClick={() => setFilterStatus(f)}
              className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${filterStatus === f ? 'bg-primary-600 text-white' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}`}
            >
              {f === 'all' ? t('common.all') : f === 'actif' ? t('members.active') : t('members.inactive')}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="card p-0 overflow-hidden">
        {filtered.length === 0 ? (
          <div className="text-center py-16">
            <Users size={48} className="mx-auto text-slate-200 mb-3" />
            <p className="text-slate-400">{t('members.noMembers')}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-100">
                  <th className="table-header text-start">{t('members.firstName')} / {t('members.lastName')}</th>
                  <th className="table-header text-start">{t('members.email')}</th>
                  <th className="table-header text-start">{t('members.phone')}</th>
                  <th className="table-header text-start">{t('members.role')}</th>
                  <th className="table-header text-start">{t('members.status')}</th>
                  <th className="table-header text-start">{t('members.joinDate')}</th>
                  {canManageMembers() && <th className="table-header text-start">{t('common.actions')}</th>}
                </tr>
              </thead>
              <tbody>
                {filtered.map(m => (
                  <tr key={m.id} className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                    <td className="table-cell">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-sm font-bold shrink-0">
                          {m.prenom[0]}{m.nom[0]}
                        </div>
                        <div>
                          <p className="font-medium text-slate-800">{m.prenom} {m.nom}</p>
                        </div>
                      </div>
                    </td>
                    <td className="table-cell text-slate-500">{m.email}</td>
                    <td className="table-cell text-slate-500" dir="ltr">{m.telephone}</td>
                    <td className="table-cell">
                      <Badge variant={roleVariant[m.role] ?? 'neutral'}>{t(`members.roles.${m.role}`)}</Badge>
                    </td>
                    <td className="table-cell">
                      <Badge variant={m.statut === 'actif' ? 'success' : 'neutral'}>
                        {m.statut === 'actif' ? t('members.active') : t('members.inactive')}
                      </Badge>
                    </td>
                    <td className="table-cell text-slate-400">{m.dateAdhesion}</td>
                    {canManageMembers() && (
                      <td className="table-cell">
                        <div className="flex gap-1">
                          <button onClick={() => { setEditMember(m); setShowForm(true); }} className="p-1.5 rounded-lg text-slate-400 hover:text-primary-600 hover:bg-primary-50 transition-colors">
                            <Pencil size={15} />
                          </button>
                          <button onClick={() => setDeleteId(m.id)} className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 transition-colors">
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editMember ? t('common.edit') : t('members.add')}>
        <MemberForm
          member={editMember}
          onSave={m => {
            dispatch(editMember ? { type: 'UPDATE_MEMBER', payload: m } : { type: 'ADD_MEMBER', payload: m });
            setShowForm(false);
          }}
          onClose={() => setShowForm(false)}
        />
      </Modal>

      <ConfirmDialog
        open={!!deleteId}
        message={t('common.confirmDelete')}
        onConfirm={() => { if (deleteId) dispatch({ type: 'DELETE_MEMBER', payload: deleteId }); setDeleteId(null); }}
        onCancel={() => setDeleteId(null)}
      />
    </div>
  );
}
