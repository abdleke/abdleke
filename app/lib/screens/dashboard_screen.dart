import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/cotisation.dart';
import '../models/depense.dart';
import '../models/echeance.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/member_avatar.dart';
import 'reports_screen.dart';

int _daysDiff(String dateStr) {
  return DateTime.parse(dateStr).difference(DateTime.now()).inDays;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k, [Map<String, String>? a]) => AppStrings.get(k, lang, a);

    final activeMembers = prov.members.where((m) => m.statut.name == 'actif').toList();
    final activeProjects = prov.projects.where((p) => p.statut.name == 'actif').toList();
    final pendingExpenseCount = prov.depenses.where((d) => d.statut == DepenseStatus.soumise).length;
    final overdueEcheances = prov.overdueEcheances;
    final pending = pendingExpenseCount + overdueEcheances.length;
    final collected = prov.collecteExercice(prov.activeExercice?.id ?? '');

    Cotisation? _cotForEcheance(Echeance e) =>
        prov.cotisations.cast<Cotisation?>().firstWhere(
            (c) => c?.id == e.cotisationId, orElse: () => null);

    final overdue = overdueEcheances.map((e) {
      final cot = _cotForEcheance(e);
      final member = cot != null
          ? prov.members.cast<dynamic>().firstWhere(
              (m) => m.id == cot.membreId, orElse: () => null)
          : null;
      return (e, member);
    }).where((pair) => pair.$2 != null).toList();

    final upcoming = prov.upcomingEcheances().map((e) {
      final cot = _cotForEcheance(e);
      final member = cot != null
          ? prov.members.cast<dynamic>().firstWhere(
              (m) => m.id == cot.membreId, orElse: () => null)
          : null;
      final days = _daysDiff(e.dateEcheance);
      return (e, days, member);
    }).where((t) => t.$3 != null).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));

    final pendingExpenses = prov.depenses.where((d) => d.statut == DepenseStatus.soumise).take(4).toList();
    final user = prov.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(s('app.name')),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: s('nav.reports'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          _LangButton(),
          _LogoutButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome
          Text(
            '${s('dashboard.welcome')}، ${user?.prenom ?? ''} 👋',
            style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          Text(
            _formatDate(DateTime.now(), lang),
            style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                label: s('dashboard.totalMembers'),
                value: activeMembers.length.toString(),
                icon: Icons.group_rounded,
                color: AppTheme.primary,
                lightColor: AppTheme.primaryLight,
              ),
              StatCard(
                label: s('dashboard.activeProjects'),
                value: activeProjects.length.toString(),
                icon: Icons.folder_open_rounded,
                color: AppTheme.info,
                lightColor: AppTheme.infoLight,
              ),
              StatCard(
                label: s('dashboard.pendingValidations'),
                value: pending.toString(),
                icon: Icons.pending_actions_rounded,
                color: AppTheme.warning,
                lightColor: AppTheme.warningLight,
              ),
              StatCard(
                label: s('dashboard.totalCollected'),
                value: '${_fmt(collected)} ${s('common.currency')}',
                icon: Icons.trending_up_rounded,
                color: AppTheme.success,
                lightColor: AppTheme.successLight,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overdue
          _SectionCard(
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.danger,
            title: s('dashboard.overdueMembers'),
            count: overdue.length,
            countColor: AppTheme.danger,
            child: overdue.isEmpty
                ? _emptyRow(s('dashboard.noOverdue'))
                : Column(
                    children: overdue.take(4).map((pair) {
                      final e = pair.$1;
                      final member = pair.$2;
                      final daysLate = _daysDiff(e.dateEcheance).abs();
                      return _OverdueRow(
                        initials: member.initials as String,
                        name: member.fullName as String,
                        daysLate: daysLate,
                        amount: e.montant,
                        currency: s('common.currency'),
                        daysLabel: s('reminders.daysOverdue'),
                        bgColor: const Color(0xFFFFF1F2),
                        textColor: AppTheme.danger,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Upcoming
          _SectionCard(
            icon: Icons.schedule_rounded,
            iconColor: AppTheme.warning,
            title: s('dashboard.upcomingDeadlines'),
            count: upcoming.length,
            countColor: AppTheme.warning,
            child: upcoming.isEmpty
                ? _emptyRow(s('dashboard.noUpcoming'))
                : Column(
                    children: upcoming.take(4).map((t) {
                      final member = t.$3;
                      return _OverdueRow(
                        initials: member.initials as String,
                        name: member.fullName as String,
                        daysLate: t.$2,
                        amount: t.$1.montant,
                        currency: s('common.currency'),
                        daysLabel: s('reminders.daysLeft'),
                        bgColor: const Color(0xFFFFFBEB),
                        textColor: AppTheme.warning,
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Pending expenses
          _SectionCard(
            icon: Icons.receipt_long_rounded,
            iconColor: AppTheme.primary,
            title: s('dashboard.recentExpenses'),
            count: pendingExpenses.length,
            countColor: AppTheme.primary,
            child: pendingExpenses.isEmpty
                ? _emptyRow(s('dashboard.noExpenses'))
                : Column(
                    children: pendingExpenses.map((d) {
                      final memberName = prov.getMemberName(d.membreId);
                      final projectName = prov.getProjectName(d.projetId);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.description, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('$memberName · $projectName', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '${_fmt(d.montant)} ${s('common.currency')}',
                              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _emptyRow(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(msg, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center),
  );

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatDate(DateTime d, String lang) {
    final months = lang == 'ar'
        ? ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر']
        : lang == 'fr'
        ? ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
        : ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final int count;
  final Color countColor;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.countColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700))),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: countColor, borderRadius: BorderRadius.circular(12)),
                  child: Text('$count', style: GoogleFonts.cairo(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OverdueRow extends StatelessWidget {
  final String initials, name, daysLabel, currency;
  final int daysLate;
  final double amount;
  final Color bgColor, textColor;

  const _OverdueRow({
    required this.initials, required this.name, required this.daysLate,
    required this.amount, required this.currency, required this.daysLabel,
    required this.bgColor, required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          MemberAvatar(initials: initials, size: 36, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('$daysLate $daysLabel', style: GoogleFonts.cairo(fontSize: 11, color: textColor)),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language_rounded, color: Colors.white),
      onSelected: prov.setLanguage,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'ar', child: Text('🇩🇿 العربية')),
        const PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
        const PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final user = prov.currentUser;
    return PopupMenuButton<String>(
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            user?.initials ?? '?',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.fullName ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(user?.telephone ?? user?.email ?? '', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          onTap: () => prov.logout(),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppTheme.danger),
              const SizedBox(width: 8),
              Text('تسجيل الخروج', style: GoogleFonts.cairo(color: AppTheme.danger, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
