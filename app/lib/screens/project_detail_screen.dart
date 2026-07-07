import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/project.dart';
import '../models/depense.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_bar.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);
    final project = prov.projects.cast<dynamic>().firstWhere((p) => p.id == projectId, orElse: () => null);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s('common.back'))),
        body: EmptyState(icon: Icons.folder_off_rounded, message: s('common.noData')),
      );
    }

    final spent = prov.getProjectSpent(projectId);
    final committed = prov.getProjectCommitted(projectId);
    final collected = prov.getProjectCollected(projectId);
    final depenses = prov.visibleDepenses.where((d) => d.projetId == projectId).toList();
    final manager = prov.members.cast<dynamic>().firstWhere((m) => m.id == project.responsableId, orElse: () => null);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.nom, style: GoogleFonts.cairo(fontSize: 16)),
          bottom: TabBar(
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.cairo(),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: s('common.details')),
              Tab(text: s('expenses.title')),
              Tab(text: '${s('expenses.submitted')} (${depenses.where((d) => d.statut == DepenseStatus.soumise).length})'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: s('expenses.add'),
              onPressed: () => _showExpenseForm(context, prov, lang, null),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Info tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoCard(
                    project: project,
                    spent: spent,
                    committed: committed,
                    collected: collected,
                    manager: manager,
                    currency: prov.currency,
                    lang: lang,
                  ),
                ],
              ),
            ),
            // All expenses tab
            _ExpensesList(depenses: depenses, prov: prov, lang: lang, filter: null),
            // Pending tab
            _ExpensesList(
              depenses: depenses.where((d) => d.statut == DepenseStatus.soumise).toList(),
              prov: prov, lang: lang, filter: DepenseStatus.soumise,
              canValidate: prov.canValidateExpense(projectId),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseForm(BuildContext context, AppProvider prov, String lang, Depense? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseForm(projectId: projectId, existing: existing, lang: lang),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final dynamic project;
  final double spent;
  final double committed;
  final double collected;
  final dynamic manager;
  final String currency, lang;

  const _InfoCard({required this.project, required this.spent, required this.committed, required this.collected, required this.manager, required this.currency, required this.lang});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final isPonctuel = project.type == ProjectType.ponctuel;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.description?.isNotEmpty == true)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(project.description, style: GoogleFonts.cairo(fontSize: 14, color: AppTheme.textSecondary))),
          _row(s('projects.manager'), manager?.fullName ?? '—'),
          _row(s('projects.startDate'), project.dateDebut),
          if (project.dateFin != null) _row(s('projects.endDate'), project.dateFin),
          _row(s('projects.type'), isPonctuel ? s('projects.ponctuel') : s('projects.normale')),
          const SizedBox(height: 16),
          Text(s('projects.budgetUsage'), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          BudgetBar(spent: spent, budget: project.budget, currency: currency),
          if (isPonctuel && committed > 0) ...[
            const SizedBox(height: 16),
            Text(s('projects.fundraising'), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${s('projects.committed')}: ${committed.toStringAsFixed(0)} $currency',
              style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            BudgetBar(spent: collected, budget: committed, currency: currency),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _ExpensesList extends StatelessWidget {
  final List<Depense> depenses;
  final AppProvider prov;
  final String lang;
  final DepenseStatus? filter;
  final bool canValidate;

  const _ExpensesList({required this.depenses, required this.prov, required this.lang, required this.filter, this.canValidate = false});

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);

    if (depenses.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_rounded, message: s('expenses.noExpenses'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: depenses.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == depenses.length) {
          final total = depenses.fold(0.0, (sum, d) => sum + d.montant);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s('common.total'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                Text('${total.toStringAsFixed(0)} ${prov.currency}', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16)),
              ],
            ),
          );
        }

        final d = depenses[i];
        final memberName = prov.getMemberName(d.membreId);
        BadgeVariant bv;
        switch (d.statut) {
          case DepenseStatus.approuvee: bv = BadgeVariant.success; break;
          case DepenseStatus.rejetee: bv = BadgeVariant.danger; break;
          default: bv = BadgeVariant.warning;
        }
        final label = d.statut == DepenseStatus.approuvee ? s('expenses.approved') : d.statut == DepenseStatus.rejetee ? s('expenses.rejected') : s('expenses.submitted');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(d.description, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600))),
                  StatusBadge(label: label, variant: bv),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(memberName, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(Icons.category_outlined, size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(s('expenses.cat.${d.categorie.name}'), style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text('${d.montant.toStringAsFixed(0)} ${prov.currency}', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
              if (d.commentaire != null && d.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(d.commentaire!, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
              ],
              if (canValidate && d.statut == DepenseStatus.soumise) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => _reject(ctx, d),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: BorderSide(color: AppTheme.danger)),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(s('expenses.reject'), style: GoogleFonts.cairo(fontSize: 12)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => _confirmApprove(ctx, d),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(s('expenses.approve'), style: GoogleFonts.cairo(fontSize: 12)),
                    )),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmApprove(BuildContext context, Depense d) {
    final s = (String k) => AppStrings.get(k, lang);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('expenses.approve'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text('${d.description}\n${d.montant.toStringAsFixed(0)} ${context.read<AppProvider>().currency}',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s('common.cancel'), style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () { context.read<AppProvider>().approveDepense(d.id); Navigator.pop(ctx); },
            child: Text(s('expenses.approve'), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, Depense d) {
    final s = (String k) => AppStrings.get(k, lang);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('expenses.rejectionReason'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintStyle: GoogleFonts.cairo()),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s('common.cancel'), style: GoogleFonts.cairo())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              context.read<AppProvider>().rejectDepense(d.id, controller.text);
              Navigator.pop(ctx);
            },
            child: Text(s('expenses.reject'), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  final String projectId, lang;
  final Depense? existing;
  const _ExpenseForm({required this.projectId, required this.lang, this.existing});

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _key = GlobalKey<FormState>();
  late String _desc, _date, _membreId;
  double _montant = 0;
  DepenseCategorie _cat = DepenseCategorie.materiel;
  bool _isAvance = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _desc = e?.description ?? '';
    _date = e?.date ?? DateTime.now().toIso8601String().split('T')[0];
    _montant = e?.montant ?? 0;
    _cat = e?.categorie ?? DepenseCategorie.materiel;
    _isAvance = e?.isAvance ?? false;
    final prov = context.read<AppProvider>();
    final user = prov.currentUser;
    if (e != null) {
      _membreId = e.membreId;
    } else if (user?.role == MemberRole.membre) {
      _membreId = user!.id;
    } else {
      _membreId = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);
    final activeMembers = prov.members.where((m) => m.statut.name == 'actif').toList();
    final cats = DepenseCategorie.values;
    final currentUser = prov.currentUser;
    final isMembre = currentUser?.role == MemberRole.membre;

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
              Text(s('expenses.add'), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextFormField(initialValue: _desc, decoration: InputDecoration(labelText: s('expenses.description'), labelStyle: GoogleFonts.cairo()), style: GoogleFonts.cairo(), validator: (v) => v?.isEmpty == true ? '⚠' : null, onSaved: (v) => _desc = v ?? ''),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(initialValue: _montant > 0 ? _montant.toStringAsFixed(0) : '', keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s('expenses.amount'), labelStyle: GoogleFonts.cairo()), style: GoogleFonts.cairo(), validator: (v) => (double.tryParse(v ?? '') == null) ? '⚠' : null, onSaved: (v) => _montant = double.tryParse(v ?? '0') ?? 0)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(initialValue: _date, decoration: InputDecoration(labelText: s('expenses.date'), labelStyle: GoogleFonts.cairo()), style: GoogleFonts.cairo(), onSaved: (v) => _date = v ?? '')),
              ]),
              const SizedBox(height: 12),
              if (isMembre)
                InputDecorator(
                  decoration: InputDecoration(labelText: s('expenses.submittedBy'), labelStyle: GoogleFonts.cairo()),
                  child: Text(currentUser!.fullName, style: GoogleFonts.cairo(color: AppTheme.textPrimary)),
                )
              else
                DropdownButtonFormField<String>(
                  value: _membreId.isNotEmpty ? _membreId : null,
                  decoration: InputDecoration(labelText: s('expenses.submittedBy'), labelStyle: GoogleFonts.cairo()),
                  items: activeMembers.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName, style: GoogleFonts.cairo()))).toList(),
                  onChanged: (v) => _membreId = v ?? '',
                  validator: (v) => (v == null || v.isEmpty) ? '⚠' : null,
                  style: GoogleFonts.cairo(color: AppTheme.textPrimary),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DepenseCategorie>(
                value: _cat,
                decoration: InputDecoration(labelText: s('expenses.category'), labelStyle: GoogleFonts.cairo()),
                items: cats.map((c) => DropdownMenuItem(value: c, child: Text(s('expenses.cat.${c.name}'), style: GoogleFonts.cairo()))).toList(),
                onChanged: (v) => setState(() => _cat = v!),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              // Source de financement
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s('expenses.source'), style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _sourceBtn(
                            label: s('expenses.fondAssociation'),
                            icon: Icons.account_balance_rounded,
                            selected: !_isAvance,
                            onTap: () => setState(() => _isAvance = false),
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _sourceBtn(
                            label: s('expenses.avanceMembre'),
                            icon: Icons.person_pin_circle_rounded,
                            selected: _isAvance,
                            onTap: () => setState(() => _isAvance = true),
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    if (_isAvance)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 13, color: AppTheme.warning),
                            const SizedBox(width: 4),
                            Expanded(child: Text(s('expenses.avanceHint'),
                                style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.warning))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(s('common.cancel'), style: GoogleFonts.cairo()))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_key.currentState?.validate() != true) return;
                    _key.currentState?.save();
                    prov.addDepense(Depense(
                      id: prov.newId(), projetId: widget.projectId,
                      membreId: _membreId, description: _desc,
                      montant: _montant, date: _date,
                      categorie: _cat, statut: DepenseStatus.soumise,
                      isAvance: _isAvance,
                    ));
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

  Widget _sourceBtn({required String label, required IconData icon, required bool selected, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppTheme.border, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 22),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? color : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
