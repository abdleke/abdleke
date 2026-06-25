import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import 'members_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);
    final user = prov.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(s('profile.title')),
        actions: [
          TextButton.icon(
            onPressed: () => _confirmLogout(context, prov, lang),
            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
            label: Text(s('auth.logout'), style: GoogleFonts.cairo(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileHeader(user: user, lang: lang),
          const SizedBox(height: 24),
          _InfoSection(user: user, lang: lang),
          const SizedBox(height: 16),
          _LanguageSection(prov: prov, lang: lang),
          const SizedBox(height: 16),
          _PasswordSection(user: user, lang: lang),
          if (prov.canManageMembers()) ...[
            const SizedBox(height: 16),
            _AdminSection(prov: prov, lang: lang),
          ],
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider prov, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('auth.logout', lang), style: GoogleFonts.cairo()),
        content: Text(AppStrings.get('common.confirm', lang), style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('common.cancel', lang), style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); prov.logout(); },
            child: Text(AppStrings.get('auth.logout', lang), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Member user;
  final String lang;
  const _ProfileHeader({required this.user, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    return Center(
      child: Column(
        children: [
          MemberAvatar(name: user.fullName, size: 72),
          const SizedBox(height: 12),
          Text(user.fullName, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Text(
              s('members.role.${user.role.name}'),
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Member user;
  final String lang;
  const _InfoSection({required this.user, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    return _Card(
      children: [
        _InfoRow(icon: Icons.phone_rounded, label: s('members.phone'), value: user.telephone ?? '—'),
        if (user.email != null && user.email!.isNotEmpty)
          _InfoRow(icon: Icons.email_outlined, label: s('members.email'), value: user.email!),
        _InfoRow(icon: Icons.calendar_today_outlined, label: s('members.joinDate'), value: user.dateAdhesion),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  final AppProvider prov;
  final String lang;
  const _LanguageSection({required this.prov, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    return _Card(
      children: [
        Row(
          children: [
            Icon(Icons.language_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(s('common.language'), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600))),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('ع')),
                ButtonSegment(value: 'fr', label: Text('Fr')),
                ButtonSegment(value: 'en', label: Text('En')),
              ],
              selected: {lang},
              onSelectionChanged: (s) => prov.setLanguage(s.first),
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(GoogleFonts.cairo(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordSection extends StatefulWidget {
  final Member user;
  final String lang;
  const _PasswordSection({required this.user, required this.lang});

  @override
  State<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends State<_PasswordSection> {
  bool _expanded = false;
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final prov = context.read<AppProvider>();
    final s = (String k) => AppStrings.get(k, widget.lang);
    setState(() { _error = null; _success = false; });

    if (_currentCtrl.text != widget.user.motDePasse) {
      setState(() => _error = s('profile.wrongCurrentPassword'));
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = s('profile.passwordMismatch'));
      return;
    }
    if (_newCtrl.text.isEmpty) return;

    prov.updateMember(widget.user.copyWith(motDePasse: _newCtrl.text));
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    setState(() { _success = true; _expanded = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, widget.lang);

    return _Card(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(s('profile.editPassword'), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600))),
              if (_success) Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.success),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          _pwField(s('profile.currentPassword'), _currentCtrl),
          _pwField(s('profile.newPassword'), _newCtrl),
          _pwField(s('profile.confirmPassword'), _confirmCtrl),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: GoogleFonts.cairo(color: AppTheme.danger, fontSize: 12)),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _submit(context),
            child: Text(s('common.save'), style: GoogleFonts.cairo()),
          ),
        ],
      ],
    );
  }

  Widget _pwField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo(), isDense: true),
        style: GoogleFonts.cairo(),
      ),
    );
  }
}

class _AdminSection extends StatelessWidget {
  final AppProvider prov;
  final String lang;
  const _AdminSection({required this.prov, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    return _Card(
      children: [
        Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppTheme.primary),
            const SizedBox(width: 10),
            Text(s('profile.admin'), style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: prov.isOnlineMode ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          label: prov.isOnlineMode ? s('profile.onlineMode') : s('profile.offlineMode'),
          value: '',
          iconColor: prov.isOnlineMode ? AppTheme.success : AppTheme.warning,
        ),
        _InfoRow(icon: Icons.group_rounded, label: s('profile.membersCount'), value: prov.members.length.toString()),
        _InfoRow(icon: Icons.folder_rounded, label: s('profile.projectsCount'), value: prov.projects.length.toString()),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersScreen())),
          icon: const Icon(Icons.manage_accounts_rounded, size: 18),
          label: Text(s('members.title'), style: GoogleFonts.cairo()),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary))),
          if (value.isNotEmpty)
            Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
