import { useTranslation } from 'react-i18next';
import { Users, FolderOpen, Clock, TrendingUp, AlertCircle } from 'lucide-react';
import { useApp } from '../context/AppContext';
import StatCard from '../components/ui/StatCard';
import Badge from '../components/ui/Badge';
import { Link } from 'react-router-dom';

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('ar-DZ', { day: 'numeric', month: 'short', year: 'numeric' });
}

function formatAmount(n: number) {
  return n.toLocaleString('ar-DZ');
}

function daysDiff(dateStr: string) {
  const diff = Math.ceil((new Date(dateStr).getTime() - Date.now()) / 86400000);
  return diff;
}

export default function Dashboard() {
  const { t } = useTranslation();
  const { state, currentUser, getProjectSpent } = useApp();

  const activeMembers = state.members.filter(m => m.statut === 'actif');
  const activeProjects = state.projects.filter(p => p.statut === 'actif');
  const pendingValidations = [
    ...state.depenses.filter(d => d.statut === 'soumise'),
    ...state.cotisations.filter(c => c.statut === 'en_attente'),
  ];
  const collectedThisYear = state.cotisations
    .filter(c => c.statut === 'validee' && c.annee === new Date().getFullYear())
    .reduce((s, c) => s + c.montant, 0);

  const upcomingDeadlines = state.cotisations
    .filter(c => c.statut !== 'validee')
    .filter(c => { const d = daysDiff(c.dateEcheance); return d >= 0 && d <= 30; })
    .sort((a, b) => new Date(a.dateEcheance).getTime() - new Date(b.dateEcheance).getTime())
    .slice(0, 5);

  const overdueMembers = state.cotisations
    .filter(c => c.statut === 'en_retard')
    .map(c => ({ cot: c, member: state.members.find(m => m.id === c.membreId) }))
    .filter(x => x.member)
    .slice(0, 5);

  const pendingExpenses = state.depenses
    .filter(d => d.statut === 'soumise')
    .slice(0, 5);

  const memberName = currentUser ? `${currentUser.prenom} ${currentUser.nom}` : '';

  return (
    <div className="space-y-6">
      {/* Welcome */}
      <div>
        <h1 className="text-2xl font-bold text-slate-800">
          {t('dashboard.welcome')}, {memberName} 👋
        </h1>
        <p className="text-slate-400 text-sm mt-1">{new Date().toLocaleDateString('ar-DZ', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label={t('dashboard.totalMembers')}
          value={activeMembers.length}
          icon={Users}
          color="violet"
          sub={`${state.members.filter(m => m.statut === 'inactif').length} ${t('members.inactive')}`}
        />
        <StatCard
          label={t('dashboard.activeProjects')}
          value={activeProjects.length}
          icon={FolderOpen}
          color="cyan"
        />
        <StatCard
          label={t('dashboard.pendingValidations')}
          value={pendingValidations.length}
          icon={Clock}
          color="amber"
        />
        <StatCard
          label={t('dashboard.totalCollected')}
          value={`${formatAmount(collectedThisYear)} ${t('common.currency')}`}
          icon={TrendingUp}
          color="emerald"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Overdue */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-800 flex items-center gap-2">
              <AlertCircle size={18} className="text-rose-500" />
              {t('dashboard.overdueMembers')}
            </h2>
            <Link to="/rappels" className="text-xs text-primary-600 hover:underline">{t('common.details')}</Link>
          </div>
          {overdueMembers.length === 0 ? (
            <p className="text-slate-400 text-sm text-center py-6">{t('reminders.noOverdue')}</p>
          ) : (
            <div className="space-y-3">
              {overdueMembers.map(({ cot, member }) => (
                <div key={cot.id} className="flex items-center justify-between p-3 bg-rose-50 rounded-xl">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-rose-200 text-rose-700 rounded-full flex items-center justify-center text-xs font-bold">
                      {member!.prenom[0]}{member!.nom[0]}
                    </div>
                    <div>
                      <p className="text-sm font-medium text-slate-800">{member!.prenom} {member!.nom}</p>
                      <p className="text-xs text-rose-500">{Math.abs(daysDiff(cot.dateEcheance))} {t('reminders.daysOverdue')}</p>
                    </div>
                  </div>
                  <span className="text-sm font-semibold text-rose-700">{formatAmount(cot.montant)} {t('common.currency')}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Upcoming */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-800 flex items-center gap-2">
              <Clock size={18} className="text-amber-500" />
              {t('dashboard.upcomingDeadlines')}
            </h2>
            <Link to="/rappels" className="text-xs text-primary-600 hover:underline">{t('common.details')}</Link>
          </div>
          {upcomingDeadlines.length === 0 ? (
            <p className="text-slate-400 text-sm text-center py-6">{t('dashboard.noUpcoming')}</p>
          ) : (
            <div className="space-y-3">
              {upcomingDeadlines.map(cot => {
                const member = state.members.find(m => m.id === cot.membreId);
                const days = daysDiff(cot.dateEcheance);
                return (
                  <div key={cot.id} className="flex items-center justify-between p-3 bg-amber-50 rounded-xl">
                    <div>
                      <p className="text-sm font-medium text-slate-800">{member?.prenom} {member?.nom}</p>
                      <p className="text-xs text-amber-600">{formatDate(cot.dateEcheance)} — {days} {t('reminders.daysLeft')}</p>
                    </div>
                    <span className="text-sm font-semibold text-amber-700">{formatAmount(cot.montant)} {t('common.currency')}</span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Projects budget */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-800">{t('nav.projects')}</h2>
            <Link to="/projets" className="text-xs text-primary-600 hover:underline">{t('common.details')}</Link>
          </div>
          <div className="space-y-4">
            {activeProjects.slice(0, 4).map(p => {
              const spent = getProjectSpent(p.id);
              const pct = Math.min(Math.round((spent / p.budget) * 100), 100);
              const over = spent > p.budget;
              return (
                <div key={p.id}>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="font-medium text-slate-700 truncate">{p.nom}</span>
                    <span className={`font-semibold ${over ? 'text-rose-600' : 'text-slate-500'}`}>{pct}%</span>
                  </div>
                  <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all ${over ? 'bg-rose-500' : pct > 75 ? 'bg-amber-400' : 'bg-emerald-500'}`}
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-slate-400 mt-1">
                    <span>{formatAmount(spent)} {t('common.currency')}</span>
                    <span>{formatAmount(p.budget)} {t('common.currency')}</span>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Pending expenses */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-800">{t('dashboard.recentExpenses')}</h2>
            <Link to="/projets" className="text-xs text-primary-600 hover:underline">{t('common.details')}</Link>
          </div>
          {pendingExpenses.length === 0 ? (
            <p className="text-slate-400 text-sm text-center py-6">{t('dashboard.noExpenses')}</p>
          ) : (
            <div className="space-y-3">
              {pendingExpenses.map(d => {
                const member = state.members.find(m => m.id === d.membreId);
                const project = state.projects.find(p => p.id === d.projetId);
                return (
                  <div key={d.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-xl">
                    <div>
                      <p className="text-sm font-medium text-slate-800">{d.description}</p>
                      <p className="text-xs text-slate-400">{member?.prenom} · {project?.nom}</p>
                    </div>
                    <div className="text-end">
                      <p className="text-sm font-semibold text-slate-700">{formatAmount(d.montant)} {t('common.currency')}</p>
                      <Badge variant="warning">{t('expenses.submitted')}</Badge>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
