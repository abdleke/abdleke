import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/exercice_annuel.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_bar.dart';

class ExerciceDetailScreen extends StatelessWidget {
  final String exerciceId;
  const ExerciceDetailScreen({super.key, required this.exerciceId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);
    final currency = prov.currency;

    final exercice = prov.exercices.cast<ExerciceAnnuel?>()
        .firstWhere((e) => e?.id == exerciceId, orElse: () => null);

    if (exercice == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s('exercice.history'))),
        body: Center(child: Text(s('common.noData'), style: GoogleFonts.cairo())),
      );
    }

    final budgetReel = prov.budgetExercice(exerciceId);
    final collecte = prov.collecteExercice(exerciceId);
    final budgetAlloue = prov.budgetAlloueExercice(exerciceId);
    final depensesTotales = prov.depensesTotalesExercice(exerciceId);
    final projets = prov.projetsResume(exerciceId);
    final pctCollecte = budgetReel > 0 ? (collecte / budgetReel).clamp(0.0, 1.0) : 0.0;
    final pctDepenses = budgetAlloue > 0 ? (depensesTotales / budgetAlloue).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(exercice.libelle, style: GoogleFonts.cairo(fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Résumé global ────────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(exercice.periode,
                      style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  _StatusChip(exercice.statut),
                ]),
                const SizedBox(height: 16),
                // Budget provisoire vs réel
                if (exercice.budgetProvisoireTotal > 0) ...[
                  _StatRow(
                    label: s('exercice.budgetProvisoire'),
                    value: '${_fmt(exercice.budgetProvisoireTotal)} $currency',
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 6),
                ],
                _StatRow(
                  label: s('exercice.budgetReel'),
                  value: '${_fmt(budgetReel)} $currency',
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  label: s('exercice.collected'),
                  value: '${_fmt(collecte)} $currency',
                  color: AppTheme.success,
                ),
                const SizedBox(height: 10),
                Text(
                  '${s('cotisations.totalCollected')}: ${(pctCollecte * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pctCollecte,
                    minHeight: 8,
                    backgroundColor: AppTheme.primaryLight,
                    valueColor: AlwaysStoppedAnimation(
                        pctCollecte >= 1.0 ? AppTheme.success : AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Dépenses projets ─────────────────────────────────────
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s('projects.budgetByExercice'),
                        style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('${projets.length} ${s('projects.title')}',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [
                  _Pill(label: '${s('projects.budget')}: ${_fmt(budgetAlloue)} $currency',
                      color: AppTheme.primary),
                  const SizedBox(width: 8),
                  _Pill(label: '${s('expenses.title')}: ${_fmt(depensesTotales)} $currency',
                      color: depensesTotales > budgetAlloue ? AppTheme.danger : AppTheme.success),
                ]),
                if (budgetAlloue > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pctDepenses,
                      minHeight: 6,
                      backgroundColor: AppTheme.primaryLight,
                      valueColor: AlwaysStoppedAnimation(
                          pctDepenses >= 1.0 ? AppTheme.danger : AppTheme.success),
                    ),
                  ),
                ],
                if (projets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(s('projects.noProjects'),
                          style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13)),
                    ),
                  )
                else ...[
                  const SizedBox(height: 16),
                  ...projets.map((r) => _ProjetRow(
                        nom: r.projet.nom,
                        budget: r.budget,
                        depenses: r.depenses,
                        currency: currency,
                        statut: r.projet.statut.name,
                        lang: lang,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v.toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      );
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );
}

class _StatusChip extends StatelessWidget {
  final ExerciceStatus statut;
  const _StatusChip(this.statut);

  @override
  Widget build(BuildContext context) {
    final isActive = statut == ExerciceStatus.actif;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.success : AppTheme.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive
            ? AppStrings.get('projects.active', 'fr')
            : AppStrings.get('exercice.closed', 'fr'),
        style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.success : AppTheme.textSecondary),
      ),
    );
  }
}

class _ProjetRow extends StatelessWidget {
  final String nom, statut, currency, lang;
  final double budget, depenses;

  const _ProjetRow({
    required this.nom, required this.budget, required this.depenses,
    required this.currency, required this.statut, required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = budget > 0 && depenses > budget;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isOver ? AppTheme.danger.withValues(alpha: 0.4) : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(nom,
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppStrings.get('projects.over', lang),
                    style: GoogleFonts.cairo(
                        fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          BudgetBar(spent: depenses, budget: budget, currency: currency),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.get('projects.budget', lang)}: ${depenses.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)} $currency',
                style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary),
              ),
              Text(
                budget > 0
                    ? '${((depenses / budget) * 100).toStringAsFixed(0)}%'
                    : '—',
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOver ? AppTheme.danger : AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
