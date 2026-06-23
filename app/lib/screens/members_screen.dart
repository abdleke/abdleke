import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('members.title'))),
      floatingActionButton: prov.canManageMembers()
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, prov, lang, null),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(s('members.add'), style: GoogleFonts.cairo()),
            )
          : null,
      body: prov.members.isEmpty
          ? EmptyState(
              icon: Icons.group_rounded,
              message: s('members.noMembers'),
              onAction: prov.canManageMembers() ? () => _showForm(context, prov, lang, null) : null,
              actionLabel: s('members.add'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final m = prov.members[i];
                return _MemberCard(
                  member: m,
                  lang: lang,
                  isCurrentUser: prov.currentUser?.id == m.id,
                  onEdit: prov.canManageMembers() ? () => _showForm(ctx, prov, lang, m) : null,
                  onDelete: (prov.canManageMembers() && prov.currentUser?.id != m.id)
                      ? () => _confirmDelete(ctx, prov, lang, m.id)
                      : null,
                );
              },
            ),
    );
  }

  void _showForm(BuildContext context, AppProvider prov, String lang, Member? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemberForm(existing: existing, lang: lang),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider prov, String lang, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('common.confirmDelete', lang), style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get('common.cancel', lang), style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () { prov.deleteMember(id); Navigator.pop(ctx); },
            child: Text(AppStrings.get('common.delete', lang), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;
  final String lang;
  final bool isCurrentUser;
  final VoidCallback? onEdit, onDelete;

  const _MemberCard({required this.member, required this.lang, required this.isCurrentUser, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    BadgeVariant bv;
    String statusLabel;
    switch (member.statut) {
      case MemberStatus.actif: bv = BadgeVariant.success; statusLabel = s('members.active'); break;
      case MemberStatus.inactif: bv = BadgeVariant.neutral; statusLabel = s('members.inactive'); break;
      case MemberStatus.suspendu: bv = BadgeVariant.danger; statusLabel = s('members.suspended'); break;
    }

    String roleLabel;
    Color roleColor;
    switch (member.role) {
      case MemberRole.admin: roleLabel = s('members.role.admin'); roleColor = AppTheme.primary; break;
      case MemberRole.tresorier: roleLabel = s('members.role.tresorier'); roleColor = AppTheme.info; break;
      case MemberRole.chefProjet: roleLabel = s('members.role.chefProjet'); roleColor = AppTheme.success; break;
      case MemberRole.membre: roleLabel = s('members.role.membre'); roleColor = AppTheme.textSecondary; break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCurrentUser ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border),
      ),
      child: Row(
        children: [
          MemberAvatar(initials: member.initials, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.fullName, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700)),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                        child: Text(s('members.you'), style: GoogleFonts.cairo(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(roleLabel, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: roleColor)),
                    ),
                    const SizedBox(width: 6),
                    StatusBadge(label: statusLabel, variant: bv),
                  ],
                ),
                if (member.email != null && member.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(member.email!, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
                if (member.telephone != null && member.telephone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(member.telephone!, style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null || onDelete != null)
            PopupMenuButton(
              iconSize: 18,
              itemBuilder: (_) => [
                if (onEdit != null) PopupMenuItem(onTap: onEdit, child: ListTile(leading: const Icon(Icons.edit_rounded, size: 18), title: Text(s('common.edit'), style: GoogleFonts.cairo()))),
                if (onDelete != null) PopupMenuItem(onTap: onDelete, child: ListTile(leading: Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger), title: Text(s('common.delete'), style: GoogleFonts.cairo(color: AppTheme.danger)))),
              ],
            ),
        ],
      ),
    );
  }
}

class _MemberForm extends StatefulWidget {
  final Member? existing;
  final String lang;
  const _MemberForm({this.existing, required this.lang});

  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  final _key = GlobalKey<FormState>();
  late String _prenom, _nom, _email, _telephone;
  MemberRole _role = MemberRole.membre;
  MemberStatus _statut = MemberStatus.actif;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _prenom = m?.prenom ?? '';
    _nom = m?.nom ?? '';
    _email = m?.email ?? '';
    _telephone = m?.telephone ?? '';
    _role = m?.role ?? MemberRole.membre;
    _statut = m?.statut ?? MemberStatus.actif;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              Text(widget.existing != null ? s('common.edit') : s('members.add'), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _field(s('members.firstName'), initial: _prenom, onSave: (v) => _prenom = v ?? '', required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(s('members.lastName'), initial: _nom, onSave: (v) => _nom = v ?? '', required: true)),
              ]),
              _field(s('members.email'), initial: _email, onSave: (v) => _email = v ?? ''),
              _field(s('members.phone'), initial: _telephone, onSave: (v) => _telephone = v ?? '', keyboardType: TextInputType.phone),
              Row(children: [
                Expanded(child: _dropdown<MemberRole>(
                  label: s('members.role'),
                  value: _role,
                  items: [
                    DropdownMenuItem(value: MemberRole.admin, child: Text(s('members.role.admin'), style: GoogleFonts.cairo())),
                    DropdownMenuItem(value: MemberRole.tresorier, child: Text(s('members.role.tresorier'), style: GoogleFonts.cairo())),
                    DropdownMenuItem(value: MemberRole.chefProjet, child: Text(s('members.role.chefProjet'), style: GoogleFonts.cairo())),
                    DropdownMenuItem(value: MemberRole.membre, child: Text(s('members.role.membre'), style: GoogleFonts.cairo())),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                )),
                const SizedBox(width: 12),
                Expanded(child: _dropdown<MemberStatus>(
                  label: s('members.status'),
                  value: _statut,
                  items: [
                    DropdownMenuItem(value: MemberStatus.actif, child: Text(s('members.active'), style: GoogleFonts.cairo())),
                    DropdownMenuItem(value: MemberStatus.inactif, child: Text(s('members.inactive'), style: GoogleFonts.cairo())),
                    DropdownMenuItem(value: MemberStatus.suspendu, child: Text(s('members.suspended'), style: GoogleFonts.cairo())),
                  ],
                  onChanged: (v) => setState(() => _statut = v!),
                )),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(s('common.cancel'), style: GoogleFonts.cairo()))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_key.currentState?.validate() != true) return;
                    _key.currentState?.save();
                    final member = Member(
                      id: widget.existing?.id ?? prov.newId(),
                      prenom: _prenom, nom: _nom,
                      email: _email.isEmpty ? null : _email,
                      telephone: _telephone.isEmpty ? null : _telephone,
                      dateAdhesion: widget.existing?.dateAdhesion ?? DateTime.now().toIso8601String().split('T')[0],
                      role: _role, statut: _statut,
                    );
                    if (widget.existing != null) prov.updateMember(member); else prov.addMember(member);
                    Navigator.pop(context);
                  },
                  child: Text(s('common.save'), style: GoogleFonts.cairo()),
                )),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, {String initial = '', bool required = false, TextInputType? keyboardType, FormFieldSetter<String>? onSave}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo()),
        style: GoogleFonts.cairo(),
        validator: required ? (v) => (v?.isEmpty == true) ? '⚠' : null : null,
        onSaved: onSave,
      ),
    );
  }

  Widget _dropdown<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo()),
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.cairo(color: AppTheme.textPrimary),
      ),
    );
  }
}
