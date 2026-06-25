import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/cotisation.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lang = prov.language;
    final s = (String k) => AppStrings.get(k, lang);

    final visible = prov.visibleCotisations;
    final global = visible.where((c) => c.type == CotisationType.normale).toList();
    final dedicated = visible.where((c) => c.type == CotisationType.dediee).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s('cotisations.title')),
        bottom: TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.cairo(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: '${s('cotisations.tab.global')} (${global.length})'),
            Tab(text: '${s('cotisations.tab.projects')} (${dedicated.length})'),
          ],
        ),
        actions: [
          if (prov.canAddCotisation())
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: s('cotisations.add'),
              onPressed: () => _showForm(context, prov, lang, null),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _CotisationList(cotisations: global, prov: prov, lang: lang, canValidate: prov.canValidateCotisation()),
          _CotisationList(cotisations: dedicated, prov: prov, lang: lang, canValidate: prov.canValidateCotisation(), showProject: true),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, AppProvider prov, String lang, Cotisation? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CotisationForm(existing: existing, lang: lang),
    );
  }
}

class _CotisationList extends StatelessWidget {
  final List<Cotisation> cotisations;
  final AppProvider prov;
  final String lang;
  final bool canValidate;
  final bool showProject;

  const _CotisationList({
    required this.cotisations,
    required this.prov,
    required this.lang,
    this.canValidate = false,
    this.showProject = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);

    if (cotisations.isEmpty) {
      return EmptyState(icon: Icons.credit_card_rounded, message: s('cotisations.noCotisations'));
    }

    final total = cotisations.fold(0.0, (sum, c) => sum + c.montant);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cotisations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == cotisations.length) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s('common.total'), style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                Text('${total.toStringAsFixed(0)} ${s('common.currency')}', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 16)),
              ],
            ),
          );
        }

        final c = cotisations[i];
        final memberName = prov.getMemberName(c.membreId);

        BadgeVariant bv;
        String statusLabel;
        switch (c.statut) {
          case CotisationStatus.validee: bv = BadgeVariant.success; statusLabel = s('cotisations.validated'); break;
          case CotisationStatus.enRetard: bv = BadgeVariant.danger; statusLabel = s('cotisations.overdue'); break;
          default: bv = BadgeVariant.warning; statusLabel = s('cotisations.pending');
        }

        String freqLabel;
        switch (c.frequence) {
          case CotisationFrequence.mensuelle: freqLabel = s('cotisations.freq.monthly'); break;
          case CotisationFrequence.trimestrielle: freqLabel = s('cotisations.freq.quarterly'); break;
          case CotisationFrequence.unique: freqLabel = s('cotisations.freq.unique'); break;
          default: freqLabel = s('cotisations.freq.annual');
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(memberName, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700))),
                  StatusBadge(label: statusLabel, variant: bv),
                ],
              ),
              if (showProject && c.projetId != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.folder_outlined, size: 12, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(prov.getProjectName(c.projetId!), style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ]),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${s('cotisations.year')}: ${c.annee}', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(Icons.repeat_rounded, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(freqLabel, style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text('${c.montant.toStringAsFixed(0)} ${s('common.currency')}', style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${s('cotisations.dueDate')}: ${c.dateEcheance}', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary)),
                  if (c.datePaiement != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.check_circle_outline_rounded, size: 12, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text('${s('cotisations.paidOn')}: ${c.datePaiement}', style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.success)),
                  ],
                ],
              ),
              if (canValidate && c.statut == CotisationStatus.enAttente) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () => context.read<AppProvider>().markCotisationOverdue(c.id),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: BorderSide(color: AppTheme.danger)),
                      icon: const Icon(Icons.warning_amber_rounded, size: 16),
                      label: Text(s('cotisations.markOverdue'), style: GoogleFonts.cairo(fontSize: 12)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () => context.read<AppProvider>().validateCotisation(c.id),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(s('cotisations.validate'), style: GoogleFonts.cairo(fontSize: 12)),
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
}

class _CotisationForm extends StatefulWidget {
  final Cotisation? existing;
  final String lang;
  const _CotisationForm({this.existing, required this.lang});

  @override
  State<_CotisationForm> createState() => _CotisationFormState();
}

class _CotisationFormState extends State<_CotisationForm> {
  final _key = GlobalKey<FormState>();
  late String _membreId, _dateEcheance;
  double _montant = 0;
  int _annee = DateTime.now().year;
  CotisationFrequence _frequence = CotisationFrequence.annuelle;
  CotisationType _type = CotisationType.normale;
  String? _projetId;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _membreId = c?.membreId ?? '';
    _dateEcheance = c?.dateEcheance ?? DateTime.now().toIso8601String().split('T')[0];
    _montant = c?.montant ?? 0;
    _annee = c?.annee ?? DateTime.now().year;
    _frequence = c?.frequence ?? CotisationFrequence.annuelle;
    _type = c?.type ?? CotisationType.normale;
    _projetId = c?.projetId;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);
    final allMembers = prov.members;
    final ponctuelProjects = prov.projects.where((p) => p.type == ProjectType.ponctuel && p.statut == ProjectStatus.actif).toList();

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
              Text(s('cotisations.add'), style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _membreId.isNotEmpty ? _membreId : null,
                decoration: InputDecoration(labelText: s('cotisations.member'), labelStyle: GoogleFonts.cairo()),
                items: allMembers.map((m) => DropdownMenuItem(value: m.id, child: Text(m.fullName, style: GoogleFonts.cairo()))).toList(),
                onChanged: (v) => setState(() => _membreId = v ?? ''),
                validator: (v) => (v == null || v.isEmpty) ? '⚠' : null,
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CotisationType>(
                value: _type,
                decoration: InputDecoration(labelText: s('cotisations.type'), labelStyle: GoogleFonts.cairo()),
                items: [
                  DropdownMenuItem(value: CotisationType.normale, child: Text(s('cotisations.normal'), style: GoogleFonts.cairo())),
                  DropdownMenuItem(value: CotisationType.dediee, child: Text(s('cotisations.dedicated'), style: GoogleFonts.cairo())),
                ],
                onChanged: (v) => setState(() { _type = v!; if (_type == CotisationType.normale) _projetId = null; }),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
              ),
              if (_type == CotisationType.dediee) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _projetId,
                  decoration: InputDecoration(labelText: s('cotisations.project'), labelStyle: GoogleFonts.cairo()),
                  items: ponctuelProjects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom, style: GoogleFonts.cairo()))).toList(),
                  onChanged: (v) => setState(() => _projetId = v),
                  validator: (v) => (v == null || v.isEmpty) ? '⚠' : null,
                  style: GoogleFonts.cairo(color: AppTheme.textPrimary),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(
                  initialValue: _montant > 0 ? _montant.toStringAsFixed(0) : '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: s('cotisations.amount'), labelStyle: GoogleFonts.cairo()),
                  style: GoogleFonts.cairo(),
                  validator: (v) => (double.tryParse(v ?? '') == null) ? '⚠' : null,
                  onSaved: (v) => _montant = double.tryParse(v ?? '0') ?? 0,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  initialValue: _annee.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: s('cotisations.year'), labelStyle: GoogleFonts.cairo()),
                  style: GoogleFonts.cairo(),
                  onSaved: (v) => _annee = int.tryParse(v ?? '') ?? DateTime.now().year,
                )),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<CotisationFrequence>(
                value: _frequence,
                decoration: InputDecoration(labelText: s('cotisations.frequency'), labelStyle: GoogleFonts.cairo()),
                items: [
                  DropdownMenuItem(value: CotisationFrequence.mensuelle, child: Text(s('cotisations.freq.monthly'), style: GoogleFonts.cairo())),
                  DropdownMenuItem(value: CotisationFrequence.trimestrielle, child: Text(s('cotisations.freq.quarterly'), style: GoogleFonts.cairo())),
                  DropdownMenuItem(value: CotisationFrequence.annuelle, child: Text(s('cotisations.freq.annual'), style: GoogleFonts.cairo())),
                  DropdownMenuItem(value: CotisationFrequence.unique, child: Text(s('cotisations.freq.unique'), style: GoogleFonts.cairo())),
                ],
                onChanged: (v) => setState(() => _frequence = v!),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _dateEcheance,
                decoration: InputDecoration(labelText: s('cotisations.dueDate'), labelStyle: GoogleFonts.cairo()),
                style: GoogleFonts.cairo(),
                onSaved: (v) => _dateEcheance = v ?? '',
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(s('common.cancel'), style: GoogleFonts.cairo()))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_key.currentState?.validate() != true) return;
                    _key.currentState?.save();
                    prov.addCotisation(Cotisation(
                      id: widget.existing?.id ?? prov.newId(),
                      membreId: _membreId,
                      montant: _montant,
                      annee: _annee,
                      frequence: _frequence,
                      statut: CotisationStatus.enAttente,
                      dateDeclaration: DateTime.now().toIso8601String().split('T')[0],
                      dateEcheance: _dateEcheance,
                      type: _type,
                      projetId: _type == CotisationType.dediee ? _projetId : null,
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
}
