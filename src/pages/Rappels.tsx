import { useTranslation } from 'react-i18next';
import { MessageCircle, Bell, AlertCircle, CheckCircle } from 'lucide-react';
import { useApp } from '../context/AppContext';

function daysDiff(dateStr: string) {
  return Math.ceil((new Date(dateStr).getTime() - Date.now()) / 86400000);
}

function formatDate(d: string, lang: string) {
  return new Date(d).toLocaleDateString(lang === 'ar' ? 'ar-DZ' : lang === 'fr' ? 'fr-FR' : 'en-GB', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
}

export default function Rappels() {
  const { t, i18n } = useTranslation();
  const { state } = useApp();
  const lang = i18n.language;

  const overdue = state.cotisations
    .filter(c => c.statut === 'en_retard')
    .map(c => ({
      cot: c,
      member: state.members.find(m => m.id === c.membreId),
      daysLate: Math.abs(daysDiff(c.dateEcheance)),
    }))
    .filter(x => x.member)
    .sort((a, b) => b.daysLate - a.daysLate);

  const upcoming = state.cotisations
    .filter(c => c.statut !== 'validee')
    .map(c => ({ cot: c, member: state.members.find(m => m.id === c.membreId), days: daysDiff(c.dateEcheance) }))
    .filter(x => x.member && x.days >= 0 && x.days <= 30)
    .sort((a, b) => a.days - b.days);

  const buildWhatsApp = (phone: string, name: string, amount: number, year: number, dateEcheance: string) => {
    const msg = t('reminders.whatsappText', {
      name,
      year,
      amount: amount.toLocaleString(),
      date: formatDate(dateEcheance, lang),
    });
    const clean = phone.replace(/\D/g, '');
    const intl = clean.startsWith('0') ? `213${clean.slice(1)}` : clean;
    return `https://wa.me/${intl}?text=${encodeURIComponent(msg)}`;
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-slate-800">{t('reminders.title')}</h1>

      {/* Overdue */}
      <div className="card">
        <div className="flex items-center gap-2 mb-5">
          <AlertCircle size={20} className="text-rose-500" />
          <h2 className="font-semibold text-slate-800 text-lg">{t('reminders.overdue')}</h2>
          {overdue.length > 0 && (
            <span className="bg-rose-500 text-white text-xs font-bold px-2 py-0.5 rounded-full">{overdue.length}</span>
          )}
        </div>

        {overdue.length === 0 ? (
          <div className="flex flex-col items-center py-10 gap-3">
            <CheckCircle size={48} className="text-emerald-300" />
            <p className="text-slate-400">{t('reminders.noOverdue')}</p>
          </div>
        ) : (
          <div className="space-y-3">
            {overdue.map(({ cot, member, daysLate }) => (
              <div key={cot.id} className="flex items-center justify-between p-4 bg-rose-50 border border-rose-100 rounded-xl">
                <div className="flex items-center gap-4">
                  <div className="w-11 h-11 bg-rose-200 text-rose-800 rounded-full flex items-center justify-center font-bold">
                    {member!.prenom[0]}{member!.nom[0]}
                  </div>
                  <div>
                    <p className="font-semibold text-slate-800">{member!.prenom} {member!.nom}</p>
                    <p className="text-xs text-slate-500">{member!.email}</p>
                    <p className="text-xs text-rose-600 font-medium mt-0.5">
                      {daysLate} {t('reminders.daysOverdue')} — {t('cotisations.dueDate')}: {formatDate(cot.dateEcheance, lang)}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="text-end">
                    <p className="font-bold text-rose-700 text-lg">{cot.montant.toLocaleString()} {t('common.currency')}</p>
                    <p className="text-xs text-slate-400">{cot.annee}</p>
                  </div>
                  {member!.telephone && (
                    <a
                      href={buildWhatsApp(member!.telephone, `${member!.prenom} ${member!.nom}`, cot.montant, cot.annee, cot.dateEcheance)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 bg-[#25D366] hover:bg-[#1da851] text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors"
                    >
                      <MessageCircle size={16} />
                      <span className="hidden sm:inline">{t('reminders.sendWhatsApp')}</span>
                    </a>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Upcoming */}
      <div className="card">
        <div className="flex items-center gap-2 mb-5">
          <Bell size={20} className="text-amber-500" />
          <h2 className="font-semibold text-slate-800 text-lg">{t('reminders.upcoming')}</h2>
          {upcoming.length > 0 && (
            <span className="bg-amber-400 text-white text-xs font-bold px-2 py-0.5 rounded-full">{upcoming.length}</span>
          )}
        </div>

        {upcoming.length === 0 ? (
          <p className="text-slate-400 text-center py-8">{t('reminders.noUpcoming')}</p>
        ) : (
          <div className="space-y-3">
            {upcoming.map(({ cot, member, days }) => {
              const urgency = days <= 7 ? 'amber' : 'slate';
              return (
                <div key={cot.id} className={`flex items-center justify-between p-4 rounded-xl border ${days <= 7 ? 'bg-amber-50 border-amber-100' : 'bg-slate-50 border-slate-100'}`}>
                  <div className="flex items-center gap-4">
                    <div className={`w-11 h-11 rounded-full flex items-center justify-center font-bold text-sm ${days <= 7 ? 'bg-amber-200 text-amber-800' : 'bg-slate-200 text-slate-700'}`}>
                      {member!.prenom[0]}{member!.nom[0]}
                    </div>
                    <div>
                      <p className="font-semibold text-slate-800">{member!.prenom} {member!.nom}</p>
                      <p className={`text-xs font-medium mt-0.5 ${days <= 7 ? 'text-amber-600' : 'text-slate-500'}`}>
                        {formatDate(cot.dateEcheance, lang)} — {days} {t('reminders.daysLeft')}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <p className={`font-bold text-lg ${urgency === 'amber' ? 'text-amber-700' : 'text-slate-700'}`}>
                      {cot.montant.toLocaleString()} {t('common.currency')}
                    </p>
                    {member!.telephone && (
                      <a
                        href={buildWhatsApp(member!.telephone, `${member!.prenom} ${member!.nom}`, cot.montant, cot.annee, cot.dateEcheance)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2 bg-[#25D366] hover:bg-[#1da851] text-white text-sm font-medium px-4 py-2 rounded-xl transition-colors"
                      >
                        <MessageCircle size={16} />
                        <span className="hidden sm:inline">{t('reminders.sendWhatsApp')}</span>
                      </a>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
