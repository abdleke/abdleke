import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import { Download, Printer, BarChart3 } from 'lucide-react';
import { useApp } from '../context/AppContext';

function formatAmount(n: number) { return n.toLocaleString(); }

function exportCSV(data: string[][], filename: string) {
  const csv = data.map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

export default function Rapports() {
  const { t, i18n } = useTranslation();
  const { state, getProjectSpent, getMemberName } = useApp();
  const [year, setYear] = useState(new Date().getFullYear());
  const lang = i18n.language;

  const cotisationsYear = state.cotisations.filter(c => c.annee === year);
  const totalCollected = cotisationsYear.filter(c => c.statut === 'validee').reduce((s, c) => s + c.montant, 0);
  const totalPending = cotisationsYear.filter(c => c.statut !== 'validee').reduce((s, c) => s + c.montant, 0);
  const collectionRate = (totalCollected + totalPending) > 0
    ? Math.round((totalCollected / (totalCollected + totalPending)) * 100)
    : 0;

  const totalBudget = state.projects.reduce((s, p) => s + p.budget, 0);
  const totalSpent = state.projects.reduce((s, p) => s + getProjectSpent(p.id), 0);

  const handleExportCotisationsCSV = () => {
    const headers = [t('cotisations.member'), t('cotisations.amount'), t('cotisations.frequency'), t('cotisations.dueDate'), t('cotisations.status')];
    const rows = cotisationsYear.map(c => [
      getMemberName(c.membreId),
      c.montant.toString(),
      c.frequence,
      c.dateEcheance,
      c.statut,
    ]);
    exportCSV([headers, ...rows], `cotisations-${year}.csv`);
  };

  const handleExportExpensesCSV = () => {
    const headers = [t('expenses.description'), t('projects.name'), t('expenses.submittedBy'), t('expenses.amount'), t('expenses.date'), t('expenses.status')];
    const rows = state.depenses.map(d => {
      const project = state.projects.find(p => p.id === d.projetId);
      return [
        d.description,
        project?.nom ?? '',
        getMemberName(d.membreId),
        d.montant.toString(),
        d.date,
        d.statut,
      ];
    });
    exportCSV([headers, ...rows], `depenses-${year}.csv`);
  };

  return (
    <div className="space-y-6" id="rapports-content">
      <div className="flex items-center justify-between no-print">
        <h1 className="text-2xl font-bold text-slate-800">{t('reports.title')}</h1>
        <div className="flex items-center gap-3">
          <select
            value={year}
            onChange={e => setYear(Number(e.target.value))}
            className="form-input w-32"
          >
            {[2024, 2025, 2026, 2027].map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <button onClick={() => window.print()} className="btn-secondary">
            <Printer size={16} /> {t('reports.exportPDF')}
          </button>
        </div>
      </div>

      {/* Print header */}
      <div className="print-only text-center mb-6">
        <h1 className="text-2xl font-bold">جمعيتي — {t('reports.title')} {year}</h1>
        <p className="text-sm text-slate-500 mt-1">{new Date().toLocaleDateString(lang === 'ar' ? 'ar-DZ' : lang)}</p>
      </div>

      {/* Financial summary */}
      <div className="card">
        <h2 className="font-semibold text-slate-800 mb-5 flex items-center gap-2">
          <BarChart3 size={18} className="text-primary-600" />
          {t('reports.financialSummary')}
        </h2>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="bg-primary-50 rounded-xl p-4 text-center">
            <p className="text-xs text-primary-600 font-medium">{t('reports.totalBudget')}</p>
            <p className="text-xl font-bold text-primary-800 mt-1">{formatAmount(totalBudget)}</p>
            <p className="text-xs text-primary-400">{t('common.currency')}</p>
          </div>
          <div className="bg-amber-50 rounded-xl p-4 text-center">
            <p className="text-xs text-amber-600 font-medium">{t('reports.totalSpent')}</p>
            <p className="text-xl font-bold text-amber-800 mt-1">{formatAmount(totalSpent)}</p>
            <p className="text-xs text-amber-400">{t('common.currency')}</p>
          </div>
          <div className="bg-emerald-50 rounded-xl p-4 text-center">
            <p className="text-xs text-emerald-600 font-medium">{t('reports.totalCollected')} {year}</p>
            <p className="text-xl font-bold text-emerald-800 mt-1">{formatAmount(totalCollected)}</p>
            <p className="text-xs text-emerald-400">{t('common.currency')}</p>
          </div>
          <div className="bg-cyan-50 rounded-xl p-4 text-center">
            <p className="text-xs text-cyan-600 font-medium">{t('reports.collectionRate')}</p>
            <p className="text-xl font-bold text-cyan-800 mt-1">{collectionRate}%</p>
            <div className="h-1.5 bg-cyan-100 rounded-full mt-2 overflow-hidden">
              <div className="h-full bg-cyan-500 rounded-full" style={{ width: `${collectionRate}%` }} />
            </div>
          </div>
        </div>

        {/* Projects table */}
        <h3 className="font-medium text-slate-700 mb-3">{t('reports.byProject')}</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100">
                <th className="table-header text-start">{t('projects.name')}</th>
                <th className="table-header text-start">{t('projects.type')}</th>
                <th className="table-header text-start">{t('projects.budget')}</th>
                <th className="table-header text-start">{t('projects.spent')}</th>
                <th className="table-header text-start">{t('projects.remaining')}</th>
                <th className="table-header text-start">%</th>
              </tr>
            </thead>
            <tbody>
              {state.projects.map(p => {
                const spent = getProjectSpent(p.id);
                const pct = p.budget > 0 ? Math.round((spent / p.budget) * 100) : 0;
                const remaining = p.budget - spent;
                const over = spent > p.budget;
                return (
                  <tr key={p.id} className="border-b border-slate-50 hover:bg-slate-50">
                    <td className="table-cell font-medium">{p.nom}</td>
                    <td className="table-cell text-slate-400">{p.type === 'periodique' ? t('projects.periodic') : t('projects.standard')}</td>
                    <td className="table-cell">{formatAmount(p.budget)} {t('common.currency')}</td>
                    <td className="table-cell">{formatAmount(spent)} {t('common.currency')}</td>
                    <td className={`table-cell font-medium ${over ? 'text-rose-600' : 'text-emerald-600'}`}>
                      {over ? '-' : ''}{formatAmount(Math.abs(remaining))} {t('common.currency')}
                    </td>
                    <td className="table-cell">
                      <div className="flex items-center gap-2">
                        <div className="h-2 w-16 bg-slate-100 rounded-full overflow-hidden">
                          <div className={`h-full rounded-full ${over ? 'bg-rose-500' : pct > 75 ? 'bg-amber-400' : 'bg-emerald-500'}`} style={{ width: `${Math.min(pct, 100)}%` }} />
                        </div>
                        <span className={`text-xs ${over ? 'text-rose-600' : 'text-slate-500'}`}>{pct}%</span>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Cotisations report */}
      <div className="card">
        <div className="flex items-center justify-between mb-4 no-print">
          <h2 className="font-semibold text-slate-800">{t('reports.cotisationReport')} — {year}</h2>
          <button onClick={handleExportCotisationsCSV} className="btn-secondary text-sm">
            <Download size={15} /> {t('reports.exportCSV')}
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100">
                <th className="table-header text-start">{t('cotisations.member')}</th>
                <th className="table-header text-start">{t('cotisations.frequency')}</th>
                <th className="table-header text-start">{t('cotisations.amount')}</th>
                <th className="table-header text-start">{t('cotisations.dueDate')}</th>
                <th className="table-header text-start">{t('cotisations.paymentDate')}</th>
                <th className="table-header text-start">{t('cotisations.status')}</th>
              </tr>
            </thead>
            <tbody>
              {cotisationsYear.map(c => (
                <tr key={c.id} className="border-b border-slate-50">
                  <td className="table-cell font-medium">{getMemberName(c.membreId)}</td>
                  <td className="table-cell text-slate-400">{c.frequence}</td>
                  <td className="table-cell">{formatAmount(c.montant)} {t('common.currency')}</td>
                  <td className="table-cell">{c.dateEcheance}</td>
                  <td className="table-cell">{c.datePaiement ?? '—'}</td>
                  <td className="table-cell">
                    <span className={`text-xs font-medium ${c.statut === 'validee' ? 'text-emerald-600' : c.statut === 'en_retard' ? 'text-rose-600' : 'text-amber-600'}`}>
                      {c.statut === 'validee' ? t('cotisations.validated') : c.statut === 'en_retard' ? t('cotisations.overdue') : t('cotisations.pending')}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-slate-200 bg-slate-50">
                <td colSpan={2} className="table-cell font-semibold">{t('common.total')}</td>
                <td className="table-cell font-bold text-primary-700">{formatAmount(cotisationsYear.reduce((s, c) => s + c.montant, 0))} {t('common.currency')}</td>
                <td colSpan={3} />
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      {/* Expenses report */}
      <div className="card">
        <div className="flex items-center justify-between mb-4 no-print">
          <h2 className="font-semibold text-slate-800">{t('reports.expenseReport')}</h2>
          <button onClick={handleExportExpensesCSV} className="btn-secondary text-sm">
            <Download size={15} /> {t('reports.exportCSV')}
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100">
                <th className="table-header text-start">{t('expenses.description')}</th>
                <th className="table-header text-start">{t('projects.name')}</th>
                <th className="table-header text-start">{t('expenses.submittedBy')}</th>
                <th className="table-header text-start">{t('expenses.amount')}</th>
                <th className="table-header text-start">{t('expenses.date')}</th>
                <th className="table-header text-start">{t('expenses.status')}</th>
              </tr>
            </thead>
            <tbody>
              {state.depenses.map(d => {
                const project = state.projects.find(p => p.id === d.projetId);
                return (
                  <tr key={d.id} className="border-b border-slate-50">
                    <td className="table-cell">{d.description}</td>
                    <td className="table-cell text-slate-500">{project?.nom}</td>
                    <td className="table-cell">{getMemberName(d.membreId)}</td>
                    <td className="table-cell font-medium">{formatAmount(d.montant)} {t('common.currency')}</td>
                    <td className="table-cell text-slate-400">{d.date}</td>
                    <td className="table-cell">
                      <span className={`text-xs font-medium ${d.statut === 'approuvee' ? 'text-emerald-600' : d.statut === 'rejetee' ? 'text-rose-600' : 'text-amber-600'}`}>
                        {d.statut === 'approuvee' ? t('expenses.approved') : d.statut === 'rejetee' ? t('expenses.rejected') : t('expenses.submitted')}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
