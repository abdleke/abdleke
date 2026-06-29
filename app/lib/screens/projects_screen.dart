import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_bar.dart';
import '../widgets/empty_state.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    return Scaffold(
      appBar: AppBar(title: Text(s('projects.title'))),
      floatingActionButton: prov.canManageProjects()
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, prov, lang, null),
              icon: const Icon(Icons.add_rounded),
              label: Text(s('projects.add'), style: GoogleFonts.cairo()),
            )
          : null,
      body: prov.visibleProjects.isEmpty
          ? EmptyState(
              icon: Icons.folder_open_rounded,
              message: s('projects.noProjects'),
              onAction: prov.canManageProjects() ? () => _showForm(context, prov, lang, null) : null,
              actionLabel: s('projects.add'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.visibleProjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final p = prov.visibleProjects[i];
                final spent = prov.getProjectSpent(p.id);
                final manager = prov.members.cast<dynamic>().firstWhere(
                  (m) => m.id == p.responsableId, orElse: () => null);
                final pendingCount = prov.visibleDepenses.where((d) => d.projetId == p.id && d.statut.name == 'soumise').length;

                return _ProjectCard(
                  project: p,
                  spent: spent,
                  managerName: manager?.fullName ?? '—',
                  pendingCount: pendingCount,
                  currency: prov.currency,
                  lang: lang,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: p.id))),
                  onEdit: prov.canManageProjects() ? () => _showForm(ctx, prov, lang, p) : null,
                  onDelete: prov.canManageProjects() ? () => _confirmDelete(ctx, prov, lang, p.id) : null,
                );
              },
            ),
    );
  }

  void _showForm(BuildContext context, AppProvider prov, String lang, Project? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProjectForm(existing: existing, lang: lang),
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
            onPressed: () { prov.deleteProject(id); Navigator.pop(ctx); },
            child: Text(AppStrings.get('common.delete', lang), style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final double spent;
  final String managerName, currency, lang;
  final int pendingCount;
  final VoidCallback onTap;
  final VoidCallback? onEdit, onDelete;

  const _ProjectCard({
    required this.project, required this.spent, required this.managerName,
    required this.pendingCount, required this.currency, required this.lang,
    required this.onTap, this.onEdit, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final isOverdue = spent > project.budget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOverdue ? AppTheme.danger.withValues(alpha: 0.3) : AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: project.type == ProjectType.ponctuel ? AppTheme.primaryLight : AppTheme.successLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.type == ProjectType.ponctuel ? s('projects.ponctuel') : s('projects.normale'),
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: project.type == ProjectType.ponctuel ? AppTheme.primary : AppTheme.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _statusChip(project.statut, lang),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(project.nom, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
                      if (project.description.isNotEmpty)
                        Text(project.description, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
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
            const SizedBox(height: 12),
            BudgetBar(spent: spent, budget: project.budget, currency: currency),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(child: Text(managerName, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary))),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.warningLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '$pendingCount ${s('expenses.submitted')}',
                      style: GoogleFonts.cairo(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ProjectStatus s, String lang) {
    Color c; String label;
    switch (s) {
      case ProjectStatus.actif: c = AppTheme.success; label = AppStrings.get('projects.active', lang); break;
      case ProjectStatus.termine: c = AppTheme.info; label = AppStrings.get('projects.completed', lang); break;
      case ProjectStatus.suspendu: c = AppTheme.textSecondary; label = AppStrings.get('projects.suspended', lang); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

class _ProjectForm extends StatefulWidget {
  final Project? existing;
  final String lang;
  const _ProjectForm({this.existing, required this.lang});

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late String _nom, _description, _dateDebut, _responsableId;
  String? _dateFin;
  double _budget = 0;
  double? _cotisationDediee;
  ProjectType _type = ProjectType.normale;
  ProjectStatus _statut = ProjectStatus.actif;
  String? _exerciceId;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    final prov = context.read<AppProvider>();
    _nom = p?.nom ?? '';
    _description = p?.description ?? '';
    _dateDebut = p?.dateDebut ?? DateTime.now().toIso8601String().split('T')[0];
    _dateFin = p?.dateFin;
    _budget = p?.budget ?? 0;
    _cotisationDediee = p?.cotisationDediee;
    _type = p?.type ?? ProjectType.normale;
    _statut = p?.statut ?? ProjectStatus.actif;
    _responsableId = p?.responsableId ?? '';
    _exerciceId = p?.exerciceId ?? prov.activeExercice?.id;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);
    final activeMembers = prov.members.where((m) => m.statut.name == 'actif').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scroll) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(widget.existing != null ? s('common.edit') : s('projects.add'),
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(s('projects.name'), initial: _nom, onSave: (v) => _nom = v ?? ''),
                      _field(s('projects.description'), initial: _description, onSave: (v) => _description = v ?? '', maxLines: 2),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _dropdown<ProjectType>(
                          label: s('projects.type'),
                          value: _type,
                          items: [
                            DropdownMenuItem(value: ProjectType.normale, child: Text(s('projects.normale'), style: GoogleFonts.cairo())),
                            DropdownMenuItem(value: ProjectType.ponctuel, child: Text(s('projects.ponctuel'), style: GoogleFonts.cairo())),
                          ],
                          onChanged: (v) => setState(() {
                            _type = v!;
                            if (_type == ProjectType.normale) {
                              _exerciceId = context.read<AppProvider>().activeExercice?.id;
                            } else {
                              _exerciceId = null;
                            }
                          }),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _dropdown<ProjectStatus>(
                          label: s('projects.status'),
                          value: _statut,
                          items: [
                            DropdownMenuItem(value: ProjectStatus.actif, child: Text(s('projects.active'), style: GoogleFonts.cairo())),
                            DropdownMenuItem(value: ProjectStatus.termine, child: Text(s('projects.completed'), style: GoogleFonts.cairo())),
                            DropdownMenuItem(value: ProjectStatus.suspendu, child: Text(s('projects.suspended'), style: GoogleFonts.cairo())),
                          ],
                          onChanged: (v) => setState(() => _statut = v!),
                        )),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field(s('projects.budget'), initial: _budget > 0 ? _budget.toStringAsFixed(0) : '', keyboardType: TextInputType.number, onSave: (v) => _budget = double.tryParse(v ?? '0') ?? 0)),
                        if (_type == ProjectType.ponctuel) ...[
                          const SizedBox(width: 12),
                          Expanded(child: _field(s('projects.dedicatedFee'), initial: _cotisationDediee?.toStringAsFixed(0) ?? '', keyboardType: TextInputType.number, onSave: (v) => _cotisationDediee = double.tryParse(v ?? ''))),
                        ],
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _field(s('projects.startDate'), initial: _dateDebut, onSave: (v) => _dateDebut = v ?? '')),
                        const SizedBox(width: 12),
                        Expanded(child: _field(s('projects.endDate'), initial: _dateFin ?? '', onSave: (v) => _dateFin = v?.isEmpty == true ? null : v)),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _responsableId.isNotEmpty ? _responsableId : null,
                        decoration: InputDecoration(labelText: s('projects.manager'), labelStyle: GoogleFonts.cairo()),
                        items: activeMembers.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName, style: GoogleFonts.cairo()))).toList(),
                        onChanged: (v) => _responsableId = v ?? '',
                        validator: (v) => (v == null || v.isEmpty) ? '⚠' : null,
                        style: GoogleFonts.cairo(),
                      ),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: Text(s('common.cancel'), style: GoogleFonts.cairo()))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() != true) return;
                            _formKey.currentState?.save();
                            final project = Project(
                              id: widget.existing?.id ?? prov.newId(),
                              nom: _nom, description: _description,
                              type: _type, budget: _budget,
                              dateDebut: _dateDebut, dateFin: _dateFin,
                              statut: _statut, responsableId: _responsableId,
                              cotisationDediee: _type == ProjectType.ponctuel ? _cotisationDediee : null,
                              exerciceId: _type == ProjectType.normale ? _exerciceId : null,
                            );
                            if (widget.existing != null) prov.updateProject(project); else prov.addProject(project);
                            Navigator.pop(ctx);
                          },
                          child: Text(s('common.save'), style: GoogleFonts.cairo()),
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, {String initial = '', int maxLines = 1, TextInputType? keyboardType, FormFieldSetter<String>? onSave}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initial,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo()),
        style: GoogleFonts.cairo(),
        onSaved: onSave,
      ),
    );
  }

  Widget _dropdown<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.cairo()),
      items: items,
      onChanged: onChanged,
      style: GoogleFonts.cairo(color: AppTheme.textPrimary),
    );
  }
}
