import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/cotisation.dart';
import '../models/echeance.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/empty_state.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k, [Map<String, String>? a]) => AppStrings.get(k, lang, a);

    final now = DateTime.now();

    Cotisation? _cotForEcheance(Echeance e) =>
        prov.cotisations.cast<Cotisation?>().firstWhere(
            (c) => c?.id == e.cotisationId, orElse: () => null);

    final overdueItems = prov.overdueEcheances.map((e) {
      final cot = _cotForEcheance(e);
      final member = cot != null
          ? prov.members.cast<dynamic>().firstWhere(
              (m) => m.id == cot.membreId, orElse: () => null)
          : null;
      final daysLate = now.difference(DateTime.tryParse(e.dateEcheance) ?? now).inDays.abs();
      return (e, member, daysLate);
    }).where((t) => t.$2 != null).toList()
      ..sort((a, b) => b.$3.compareTo(a.$3));

    final upcomingItems = prov.upcomingEcheances().map((e) {
      final cot = _cotForEcheance(e);
      final member = cot != null
          ? prov.members.cast<dynamic>().firstWhere(
              (m) => m.id == cot.membreId, orElse: () => null)
          : null;
      final daysLeft = (DateTime.tryParse(e.dateEcheance) ?? now).difference(now).inDays;
      return (e, member, daysLeft);
    }).where((t) => t.$2 != null).toList()
      ..sort((a, b) => a.$3.compareTo(b.$3));

    return Scaffold(
      appBar: AppBar(title: Text(s('reminders.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s('reminders.summary'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        s('reminders.summaryDetail', {'overdue': '${overdueItems.length}', 'upcoming': '${upcomingItems.length}'}),
                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overdue section
          _sectionHeader(Icons.warning_amber_rounded, s('reminders.overdueTitle'), AppTheme.danger, overdueItems.length),
          const SizedBox(height: 8),
          if (overdueItems.isEmpty)
            EmptyState(icon: Icons.check_circle_outline_rounded, message: s('dashboard.noOverdue'))
          else
            ...overdueItems.map((t) => _ReminderCard(
              member: t.$2,
              amount: t.$1.montant,
              lang: lang,
              days: t.$3,
              isOverdue: true,
              currency: prov.currency,
            )),

          const SizedBox(height: 20),

          // Upcoming section
          _sectionHeader(Icons.schedule_rounded, s('reminders.upcomingTitle'), AppTheme.warning, upcomingItems.length),
          const SizedBox(height: 8),
          if (upcomingItems.isEmpty)
            EmptyState(icon: Icons.event_available_rounded, message: s('dashboard.noUpcoming'))
          else
            ...upcomingItems.map((t) => _ReminderCard(
              member: t.$2,
              amount: t.$1.montant,
              lang: lang,
              days: t.$3,
              isOverdue: false,
              currency: prov.currency,
            )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: GoogleFonts.cairo(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final dynamic member;
  final double amount;
  final String lang, currency;
  final int days;
  final bool isOverdue;

  const _ReminderCard({
    required this.member,
    required this.amount,
    required this.lang,
    required this.days,
    required this.isOverdue,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k, [Map<String, String>? a]) => AppStrings.get(k, lang, a);
    final color = isOverdue ? AppTheme.danger : AppTheme.warning;
    final bgColor = isOverdue ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB);
    final daysLabel = isOverdue ? s('reminders.daysOverdue') : s('reminders.daysLeft');
    final hasPhone = member.telephone != null && (member.telephone as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MemberAvatar(initials: member.initials as String, size: 40, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.fullName as String, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('$days $daysLabel', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                        ),
                        const SizedBox(width: 8),
                        Text('${amount.toStringAsFixed(0)} $currency', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasPhone) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendWhatsApp(context, member.telephone as String, member.fullName as String, amount, lang, s),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.message_rounded, size: 16),
                    label: Text(s('reminders.whatsapp'), style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _call(context, member.telephone as String),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.info,
                      side: BorderSide(color: AppTheme.info),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text(s('reminders.call'), style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp(
    BuildContext context,
    String phone,
    String name,
    double amount,
    String lang,
    Function s,
  ) async {
    final message = s('reminders.whatsappMessage', {'name': name, 'amount': amount.toStringAsFixed(0)});
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(message as String)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s('reminders.whatsappUnavailable') as String, style: GoogleFonts.cairo())),
      );
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
