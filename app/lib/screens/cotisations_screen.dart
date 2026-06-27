import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../l10n/strings.dart';
import '../models/cotisation.dart';
import '../models/echeance.dart';
import '../models/member.dart';
import '../models/project.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state.dart';

class CotisationsScreen extends StatefulWidget {
  const CotisationsScreen({super.key});

  @override
  State<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends State<CotisationsScreen>
    with SingleTickerProviderStateMixin {
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
    final exercice = prov.activeExercice;

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
              onPressed: () => _showForm(context, lang),
            ),
        ],
      ),
      body: Column(
        children: [
          if (exercice != null)
            _ExerciceHeader(prov: prov, exerciceId: exercice.id,
                libelle: exercice.libelle, periode: exercice.periode, lang: lang),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CotisationList(
                  cotisations: global, prov: prov, lang: lang,
                  canValidate: prov.canValidateCotisation()),
                _CotisationList(
                  cotisations: dedicated, prov: prov, lang: lang,
                  canValidate: prov.canValidateCotisation(), showProject: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CotisationForm(lang: lang),
    );
  }
}

class _ExerciceHeader extends StatelessWidget {
  final AppProvider prov;
  final String exerciceId, libelle, periode, lang;

  const _ExerciceHeader({
    required this.prov,
    required this.exerciceId,
    required this.libelle,
    required this.periode,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final budget = prov.budgetExercice(exerciceId);
    final collecte = prov.collecteExercice(exerciceId);
    final pct = budget > 0 ? (collecte / budget).clamp(0.0, 1.0) : 0.0;
    final currency = prov.currency;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(libelle,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              Text(periode,
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(s('exercice.budget'),
                  '${budget.toStringAsFixed(0)} $currency'),
              _stat(s('exercice.collected'),
                  '${collecte.toStringAsFixed(0)} $currency'),
              _stat('${(pct * 100).toStringAsFixed(0)}%',
                  s('cotisations.totalCollected')),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.cairo(color: Colors.white70, fontSize: 10)),
          Text(value,
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      );
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
      return EmptyState(
          icon: Icons.credit_card_rounded,
          message: s('cotisations.noCotisations'));
    }

    final total = cotisations.fold(0.0, (sum, c) => sum + c.montantTotal);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: cotisations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        if (i == cotisations.length) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s('common.total'),
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary)),
                Text('${total.toStringAsFixed(0)} ${prov.currency}',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        fontSize: 16)),
              ],
            ),
          );
        }
        return _CotisationCard(
          cotisation: cotisations[i],
          prov: prov,
          lang: lang,
          canValidate: canValidate,
          showProject: showProject,
        );
      },
    );
  }
}

class _CotisationCard extends StatefulWidget {
  final Cotisation cotisation;
  final AppProvider prov;
  final String lang;
  final bool canValidate;
  final bool showProject;

  const _CotisationCard({
    required this.cotisation,
    required this.prov,
    required this.lang,
    this.canValidate = false,
    this.showProject = false,
  });

  @override
  State<_CotisationCard> createState() => _CotisationCardState();
}

class _CotisationCardState extends State<_CotisationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cotisation;
    final prov = widget.prov;
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);
    final memberName = prov.getMemberName(c.membreId);
    final echeances = prov.echeancesFor(c.id);

    final validatedCount =
        echeances.where((e) => e.statut == EcheanceStatus.validee).length;
    final overdueCount =
        echeances.where((e) => e.statut == EcheanceStatus.enRetard).length;

    BadgeVariant cardBv;
    String cardStatus;
    if (echeances.isEmpty) {
      cardBv = BadgeVariant.warning;
      cardStatus = s('echeance.pending');
    } else if (overdueCount > 0) {
      cardBv = BadgeVariant.danger;
      cardStatus = s('echeance.overdue');
    } else if (validatedCount == echeances.length) {
      cardBv = BadgeVariant.success;
      cardStatus = s('echeance.validated');
    } else {
      cardBv = BadgeVariant.warning;
      cardStatus = s('echeance.pending');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(_expanded ? 0 : 12),
              bottomRight: Radius.circular(_expanded ? 0 : 12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(memberName,
                              style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700))),
                      StatusBadge(label: cardStatus, variant: cardBv),
                      const SizedBox(width: 6),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  if (widget.showProject && c.projetId != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.folder_outlined,
                          size: 12, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(prov.getProjectName(c.projetId!),
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(c.dateDebut,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                      const Spacer(),
                      Text(
                          '${c.montantTotal.toStringAsFixed(0)} ${prov.currency}',
                          style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.payments_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                        '$validatedCount/${echeances.length} ${s('cotisations.echeances')}',
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ]),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: echeances
                    .map((e) => _EcheanceRow(
                          echeance: e,
                          lang: lang,
                          canValidate: widget.canValidate,
                          currency: prov.currency,
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EcheanceRow extends StatelessWidget {
  final Echeance echeance;
  final String lang, currency;
  final bool canValidate;

  const _EcheanceRow({
    required this.echeance,
    required this.lang,
    required this.currency,
    this.canValidate = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = (String k) => AppStrings.get(k, lang);
    final e = echeance;

    BadgeVariant bv;
    String label;
    switch (e.statut) {
      case EcheanceStatus.validee:
        bv = BadgeVariant.success;
        label = s('echeance.validated');
        break;
      case EcheanceStatus.enRetard:
        bv = BadgeVariant.danger;
        label = s('echeance.overdue');
        break;
      default:
        bv = BadgeVariant.warning;
        label = s('echeance.pending');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(6)),
                child: Center(
                    child: Text('${e.numero}',
                        style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.dateEcheance,
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    if (e.datePaiement != null)
                      Text(
                          '${s('echeance.paidOn')}: ${e.datePaiement}',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: AppTheme.success)),
                  ],
                ),
              ),
              Text('${e.montant.toStringAsFixed(0)} $currency',
                  style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              const SizedBox(width: 8),
              StatusBadge(label: label, variant: bv),
            ],
          ),
          if (canValidate && e.statut != EcheanceStatus.validee) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (e.statut == EcheanceStatus.enAttente)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.read<AppProvider>().markEcheanceOverdue(e.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: BorderSide(color: AppTheme.danger),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(0, 32),
                      ),
                      icon: const Icon(Icons.warning_amber_rounded, size: 14),
                      label: Text(s('echeance.markOverdue'),
                          style: GoogleFonts.cairo(fontSize: 11)),
                    ),
                  ),
                if (e.statut == EcheanceStatus.enAttente)
                  const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.read<AppProvider>().validateEcheance(e.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 32),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: Text(s('echeance.validate'),
                        style: GoogleFonts.cairo(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CotisationForm extends StatefulWidget {
  final String lang;
  const _CotisationForm({required this.lang});

  @override
  State<_CotisationForm> createState() => _CotisationFormState();
}

class _CotisationFormState extends State<_CotisationForm> {
  final _key = GlobalKey<FormState>();
  String _membreId = '';
  double _montantTotal = 0;
  int _nombreEcheances = 1;
  String _dateDebut = '';
  CotisationType _type = CotisationType.normale;
  String? _projetId;

  @override
  void initState() {
    super.initState();
    final prov = context.read<AppProvider>();
    _dateDebut =
        prov.activeExercice?.dateDebut ??
        DateTime.now().toIso8601String().split('T')[0];
    final user = prov.currentUser;
    if (user != null && user.role == MemberRole.membre) {
      _membreId = user.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final lang = widget.lang;
    final s = (String k) => AppStrings.get(k, lang);
    final activeMembers =
        prov.members.where((m) => m.statut.name == 'actif').toList();
    final ponctuelProjects = prov.projects
        .where((p) =>
            p.type == ProjectType.ponctuel &&
            p.statut == ProjectStatus.actif)
        .toList();
    final currentUser = prov.currentUser;
    final isMembre = currentUser?.role == MemberRole.membre;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2))),
              Text(s('cotisations.add'),
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (isMembre)
                InputDecorator(
                  decoration: InputDecoration(
                      labelText: s('cotisations.member'),
                      labelStyle: GoogleFonts.cairo()),
                  child: Text(currentUser!.fullName,
                      style: GoogleFonts.cairo(color: AppTheme.textPrimary)),
                )
              else
                DropdownButtonFormField<String>(
                  value: _membreId.isNotEmpty ? _membreId : null,
                  decoration: InputDecoration(
                      labelText: s('cotisations.member'),
                      labelStyle: GoogleFonts.cairo()),
                  items: activeMembers
                      .map((m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.fullName, style: GoogleFonts.cairo())))
                      .toList(),
                  onChanged: (v) => setState(() => _membreId = v ?? ''),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '⚠' : null,
                  style: GoogleFonts.cairo(color: AppTheme.textPrimary),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CotisationType>(
                value: _type,
                decoration: InputDecoration(
                    labelText: s('cotisations.type'),
                    labelStyle: GoogleFonts.cairo()),
                items: [
                  DropdownMenuItem(
                      value: CotisationType.normale,
                      child: Text(s('cotisations.normal'),
                          style: GoogleFonts.cairo())),
                  DropdownMenuItem(
                      value: CotisationType.dediee,
                      child: Text(s('cotisations.dedicated'),
                          style: GoogleFonts.cairo())),
                ],
                onChanged: (v) => setState(() {
                  _type = v!;
                  if (_type == CotisationType.normale) {
                    _projetId = null;
                    _dateDebut = prov.activeExercice?.dateDebut ?? _dateDebut;
                  }
                }),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
              ),
              if (_type == CotisationType.dediee) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _projetId,
                  decoration: InputDecoration(
                      labelText: s('cotisations.project'),
                      labelStyle: GoogleFonts.cairo()),
                  items: ponctuelProjects
                      .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.nom, style: GoogleFonts.cairo())))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _projetId = v;
                      if (v != null) {
                        final proj = prov.projects
                            .cast<dynamic>()
                            .firstWhere((p) => p.id == v,
                                orElse: () => null);
                        if (proj != null) _dateDebut = proj.dateDebut as String;
                      }
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '⚠' : null,
                  style: GoogleFonts.cairo(color: AppTheme.textPrimary),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _montantTotal > 0
                        ? _montantTotal.toStringAsFixed(0)
                        : '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: s('cotisations.totalAmount'),
                        labelStyle: GoogleFonts.cairo()),
                    style: GoogleFonts.cairo(),
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? '⚠' : null,
                    onSaved: (v) =>
                        _montantTotal = double.tryParse(v ?? '0') ?? 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _nombreEcheances.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: s('cotisations.installments'),
                        labelStyle: GoogleFonts.cairo()),
                    style: GoogleFonts.cairo(),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 1 || n > 12) ? '1-12' : null;
                    },
                    onSaved: (v) =>
                        _nombreEcheances = int.tryParse(v ?? '1') ?? 1,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _dateDebut,
                decoration: InputDecoration(
                    labelText: s('cotisations.startDate'),
                    labelStyle: GoogleFonts.cairo()),
                style: GoogleFonts.cairo(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '⚠' : null,
                onSaved: (v) => _dateDebut = v ?? '',
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s('common.cancel'),
                            style: GoogleFonts.cairo()))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_key.currentState?.validate() != true) return;
                      _key.currentState?.save();
                      final exercice = prov.activeExercice;
                      prov.addCotisation(Cotisation(
                        id: prov.newId(),
                        membreId: _membreId,
                        exerciceId: exercice?.id ?? '',
                        annee: exercice?.annee ?? DateTime.now().year,
                        montantTotal: _montantTotal,
                        nombreEcheances: _nombreEcheances,
                        dateDebut: _dateDebut,
                        type: _type,
                        projetId:
                            _type == CotisationType.dediee ? _projetId : null,
                      ));
                      Navigator.pop(context);
                    },
                    child: Text(s('common.save'),
                        style: GoogleFonts.cairo()),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
