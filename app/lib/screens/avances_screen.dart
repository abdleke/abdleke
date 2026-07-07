import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/depense.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class AvancesScreen extends StatelessWidget {
  const AvancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    final avances = prov.visibleDepenses
        .where((d) => d.isAvance)
        .toList()
      ..sort((a, b) => a.rembourse == b.rembourse ? b.date.compareTo(a.date) : (a.rembourse ? 1 : -1));

    final pending = avances.where((d) => !d.rembourse).toList();
    final reimbursed = avances.where((d) => d.rembourse).toList();
    final canReimburse = prov.canValidateCotisation();

    final totalPending = pending.fold(0.0, (sum, d) => sum + d.montant);

    return Scaffold(
      appBar: AppBar(title: Text(s('avances.title'))),
      body: avances.isEmpty
          ? EmptyState(icon: Icons.account_balance_wallet_rounded, message: s('avances.noAvances'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                if (pending.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.warning, AppTheme.warning.withValues(alpha: 0.75)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s('avances.nonRembourse'),
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
                              Text('${totalPending.toStringAsFixed(0)} ${prov.currency}',
                                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                              Text('${pending.length} ${s('avances.title').toLowerCase()}',
                                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Pending advances
                if (pending.isNotEmpty) ...[
                  _sectionHeader(s('avances.nonRembourse'), AppTheme.warning),
                  const SizedBox(height: 8),
                  ...pending.map((d) => _AvanceCard(
                        depense: d, prov: prov, lang: lang, canReimburse: canReimburse)),
                  const SizedBox(height: 16),
                ],

                // Reimbursed advances
                if (reimbursed.isNotEmpty) ...[
                  _sectionHeader(s('avances.rembourse'), AppTheme.success),
                  const SizedBox(height: 8),
                  ...reimbursed.map((d) => _AvanceCard(
                        depense: d, prov: prov, lang: lang, canReimburse: false)),
                ],
              ],
            ),
    );
  }

  Widget _sectionHeader(String label, Color color) => Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _AvanceCard extends StatelessWidget {
  final Depense depense;
  final AppProvider prov;
  final String lang;
  final bool canReimburse;

  const _AvanceCard({
    required this.depense,
    required this.prov,
    required this.lang,
    required this.canReimburse,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final d = depense;
    final memberName = prov.getMemberName(d.membreId);
    final projectName = prov.getProjectName(d.projetId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: d.rembourse ? AppTheme.border : AppTheme.warning.withValues(alpha: 0.4),
          width: d.rembourse ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(d.description,
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              StatusBadge(
                label: d.rembourse ? s('avances.rembourse') : s('avances.nonRembourse'),
                variant: d.rembourse ? BadgeVariant.success : BadgeVariant.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(memberName, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.folder_outlined, size: 13, color: AppTheme.primary),
              const SizedBox(width: 4),
              Expanded(child: Text(projectName,
                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600))),
              Text('${d.montant.toStringAsFixed(0)} ${prov.currency}',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.warning)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(d.date, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.category_outlined, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(s('expenses.cat.${d.categorie.name}'),
                  style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          if (canReimburse && !d.rembourse) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmReimburse(context, d, s),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(s('avances.marquerRembourse'), style: GoogleFonts.cairo(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmReimburse(BuildContext context, Depense d, String Function(String) s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.account_balance_wallet_rounded, color: AppTheme.success, size: 22),
          const SizedBox(width: 8),
          Text(s('avances.marquerRembourse'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s('avances.confirmMsg'), style: GoogleFonts.cairo()),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    context.read<AppProvider>().getMemberName(d.membreId),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppTheme.primary),
                  )),
                  Text('${d.montant.toStringAsFixed(0)} ${context.read<AppProvider>().currency}',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text(s('common.cancel'), style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () {
              context.read<AppProvider>().marquerRembourse(d.id);
              Navigator.pop(ctx);
            },
            child: Text(s('common.confirm'), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}
