import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/cotisation.dart';
import '../models/depense.dart';
import '../models/echeance.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_bar.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    // Financial summary
    final totalCollected =
        prov.collecteExercice(prov.activeExercice?.id ?? '');
    final totalPendingCotisations = prov.echeances
        .where((e) => e.statut == EcheanceStatus.enAttente)
        .fold(0.0, (sum, e) => sum + e.montant);
    final totalExpenses = prov.visibleDepenses
        .where((d) => d.statut == DepenseStatus.approuvee)
        .fold(0.0, (sum, d) => sum + d.montant);
    final pendingExpenses = prov.visibleDepenses
        .where((d) => d.statut == DepenseStatus.soumise)
        .fold(0.0, (sum, d) => sum + d.montant);

    // Expenses by category
    final expensesByCategory = <DepenseCategorie, double>{};
    for (final d in prov.visibleDepenses.where((d) => d.statut == DepenseStatus.approuvee)) {
      expensesByCategory[d.categorie] = (expensesByCategory[d.categorie] ?? 0) + d.montant;
    }

    // Projects with budget usage
    final projectStats = prov.projects.map((p) {
      final spent = prov.getProjectSpent(p.id);
      return (p, spent);
    }).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    // Member cotisation compliance
    final memberCompliance = prov.members.map((m) {
      final memberCotisationIds = prov.cotisations
          .where((c) => c.membreId == m.id)
          .map((c) => c.id)
          .toSet();
      final paid = prov.echeances
          .where((e) => memberCotisationIds.contains(e.cotisationId) &&
              e.statut == EcheanceStatus.validee)
          .fold(0.0, (sum, e) => sum + e.montant);
      final overdue = prov.echeances
          .where((e) => memberCotisationIds.contains(e.cotisationId) &&
              e.statut == EcheanceStatus.enRetard)
          .length;
      return (m, paid, overdue);
    }).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(title: Text(s('reports.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Financial overview
          _Section(title: s('reports.financialOverview'), icon: Icons.account_balance_rounded, color: AppTheme.primary),
          const SizedBox(height: 8),
          _FinanceSummary(
            totalCollected: totalCollected,
            totalPendingCotisations: totalPendingCotisations,
            totalExpenses: totalExpenses,
            pendingExpenses: pendingExpenses,
            balance: totalCollected - totalExpenses,
            currency: prov.currency,
            lang: lang,
          ),
          const SizedBox(height: 20),

          // Expenses by category
          if (expensesByCategory.isNotEmpty) ...[
            _Section(title: s('reports.expensesByCategory'), icon: Icons.pie_chart_rounded, color: AppTheme.info),
            const SizedBox(height: 8),
            _CategoryBreakdown(categories: expensesByCategory, total: totalExpenses, currency: prov.currency, lang: lang),
            const SizedBox(height: 20),
          ],

          // Project budget usage
          if (projectStats.isNotEmpty) ...[
            _Section(title: s('reports.projectBudgets'), icon: Icons.folder_open_rounded, color: AppTheme.success),
            const SizedBox(height: 8),
            ...projectStats.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1.nom, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    BudgetBar(spent: t.$2, budget: t.$1.budget, currency: prov.currency),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],

          // Member compliance
          _Section(title: s('reports.memberCompliance'), icon: Icons.group_rounded, color: AppTheme.warning),
          const SizedBox(height: 8),
          ...memberCompliance.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
              child: Row(
                children: [
                  Expanded(child: Text(t.$1.fullName, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600))),
                  if (t.$3 > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('${t.$3} ${s('reports.overdueCount')}', style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w600)),
                    ),
                  Text(
                    '${t.$2.toStringAsFixed(0)} ${prov.currency}',
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: t.$2 > 0 ? AppTheme.success : AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _Section({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _FinanceSummary extends StatelessWidget {
  final double totalCollected, totalPendingCotisations, totalExpenses, pendingExpenses, balance;
  final String currency, lang;

  const _FinanceSummary({
    required this.totalCollected,
    required this.totalPendingCotisations,
    required this.totalExpenses,
    required this.pendingExpenses,
    required this.balance,
    required this.currency,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final isPositive = balance >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: [
          _row(s('reports.collected'), totalCollected, currency, AppTheme.success),
          _row(s('reports.pendingCotisations'), totalPendingCotisations, currency, AppTheme.warning),
          _row(s('reports.approvedExpenses'), totalExpenses, currency, AppTheme.danger),
          _row(s('reports.pendingExpenses'), pendingExpenses, currency, AppTheme.textSecondary),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s('reports.balance'), style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800)),
              Text(
                '${isPositive ? '+' : ''}${balance.toStringAsFixed(0)} $currency',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800, color: isPositive ? AppTheme.success : AppTheme.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, String currency, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
          Text('${value.toStringAsFixed(0)} $currency', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<DepenseCategorie, double> categories;
  final double total;
  final String currency, lang;

  const _CategoryBreakdown({required this.categories, required this.total, required this.currency, required this.lang});

  static const _colors = [
    AppTheme.primary, AppTheme.info, AppTheme.success, AppTheme.warning, AppTheme.danger,
  ];

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final entries = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: entries.mapIndexed((i, e) {
          final pct = total > 0 ? e.value / total : 0.0;
          final color = _colors[i % _colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text(s('expenses.cat.${e.key.name}'), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text('${e.value.toStringAsFixed(0)} $currency (${(pct * 100).toStringAsFixed(0)}%)', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

extension _IterableIndexed<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T element) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
