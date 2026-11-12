import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/request.dart';
import '../../../data/models/volunteer.dart';
import '../../../data/repositories/animal_repository.dart';
import '../viewmodels/volunteers_view_model.dart';
import '../widgets/request_card.dart';
import '../widgets/request_detail_sheet.dart';
import '../widgets/volunteer_card.dart';
import '../widgets/volunteer_form_sheet.dart';

class VolunteersPage extends StatefulWidget {
  const VolunteersPage({super.key});

  @override
  State<VolunteersPage> createState() => _VolunteersPageState();
}

class _VolunteersPageState extends State<VolunteersPage> {
  final _vm = VolunteersViewModel(locator());
  final _animals = locator<AnimalRepository>();

  Future<void> _addVolunteer() async {
    final v = await showAdaptiveSheet<Volunteer>(
      context,
      builder: (_) => const VolunteerFormSheet(),
    );
    if (v == null || !mounted) return;
    _vm.addVolunteer(v);
    showMessage(context, '${v.name} entrou para a equipe! 🎉',
        icon: Icons.celebration_outlined);
  }

  Future<void> _reject(AppRequest r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Recusar solicitação?',
      message: 'A solicitação de ${r.name} será marcada como recusada.',
      confirmLabel: 'Recusar',
      destructive: true,
    );
    if (ok) _vm.reject(r);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.customDate ?? now.add(const Duration(days: 7)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Verificar disponibilidade em',
    );
    if (picked != null) _vm.setCustomDate(picked);
  }

  Future<void> _pickTime() async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (_vm.customStart ?? 840) ~/ 60,
        minute: (_vm.customStart ?? 840) % 60,
      ),
      helpText: 'Horário inicial',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (start.hour + 2).clamp(0, 23),
        minute: start.minute,
      ),
      helpText: 'Horário final',
    );
    if (end == null || !mounted) return;
    final error = _vm.setCustomTime(
      start.hour * 60 + start.minute,
      end.hour * 60 + end.minute,
    );
    if (error != null) showMessage(context, error, icon: Icons.error_outline);
  }

  String _dateChipLabel(DateTime d) =>
      '${Weekday.values[d.weekday - 1].short}, ${Fmt.dayMonth(d)}';

  void _approve(AppRequest r) {
    _vm.approve(r);
    showMessage(
      context,
      r.type == RequestType.volunteering
          ? '${r.name} foi adicionado(a) à lista de voluntários'
          : 'Solicitação de ${r.name} aprovada',
      icon: Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Observer(
        builder: (_) => AppNestedScaffold(
          title: 'Voluntários',
          subtitle: '${_vm.activeVolunteers.length} ativos · '
              '${_vm.pendingTotal} solicitações pendentes',
          headerHeight: 76,
          bottomHeight: AppTabBar.height,
          bottom: AppTabBar(
            tabs: [
              const Tab(text: 'Disponíveis'),
              const Tab(text: 'Todos'),
              Tab(
                child: Badge(
                  isLabelVisible: _vm.pendingCount(RequestType.volunteering) > 0,
                  label: Text('${_vm.pendingCount(RequestType.volunteering)}'),
                  offset: const Offset(14, -6),
                  child: const Text('Solicitações'),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Novo voluntário',
            onPressed: _addVolunteer,
            child: const Icon(Icons.person_add_alt_1),
          ),
          tabViews: [
            _availableTab(context),
            _allTab(context),
            _requestsTab(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _availableTab(BuildContext context) => [
        SliverToBoxAdapter(
          child: Observer(
            builder: (_) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quem está livre?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Text('Dia', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    ChipStrip(
                      children: [
                        for (final d in Weekday.values)
                          ChoiceChip(
                            label: Text(d.short),
                            selected: _vm.customDate == null && _vm.day == d,
                            onSelected: (_) => _vm.setDay(d),
                          ),
                        if (_vm.customDate != null)
                          InputChip(
                            avatar: const Icon(Icons.event, size: 16),
                            label: Text(_dateChipLabel(_vm.customDate!)),
                            selected: true,
                            onPressed: _pickDate,
                            onDeleted: _vm.clearCustomDate,
                            deleteButtonTooltipMessage: 'Voltar para a semana atual',
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_month_outlined, size: 16),
                          label: Text(
                            _vm.customDate == null ? 'Outra data' : 'Trocar data',
                          ),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Horário',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    ChipStrip(
                      children: [
                        ChoiceChip(
                          label: const Text('Dia todo'),
                          selected: !_vm.hasCustomTime && _vm.period == null,
                          onSelected: (_) => _vm.setPeriod(null),
                        ),
                        for (final p in ShiftPeriod.values)
                          ChoiceChip(
                            avatar: Icon(p.icon, size: 16),
                            label: Text(p.label),
                            selected: !_vm.hasCustomTime && _vm.period == p,
                            onSelected: (_) => _vm.setPeriod(p),
                          ),
                        if (_vm.hasCustomTime)
                          InputChip(
                            avatar: const Icon(Icons.schedule, size: 16),
                            label: Text(_vm.customTimeLabel!),
                            selected: true,
                            onPressed: _pickTime,
                            onDeleted: _vm.clearCustomTime,
                            deleteButtonTooltipMessage: 'Remover horário',
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.more_time, size: 16),
                          label: Text(
                            _vm.hasCustomTime
                                ? 'Trocar horário'
                                : 'Horário específico',
                          ),
                          onPressed: _pickTime,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('Para quê?',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    ChipStrip(
                      children: [
                        ChoiceChip(
                          label: const Text('Qualquer tarefa'),
                          selected: _vm.skill == null,
                          onSelected: (_) => _vm.setSkill(null),
                        ),
                        for (final s in VolunteerSkill.values)
                          ChoiceChip(
                            avatar: Icon(s.icon, size: 16),
                            label: Text(s.label),
                            selected: _vm.skill == s,
                            onSelected: (_) => _vm.setSkill(s),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10),
              child: Text(
                '${_vm.availabilityLabel}'
                '${_vm.otherPeriod.isNotEmpty ? ' · ${_vm.otherPeriod.length} em outro horário' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        Observer(
          builder: (_) => _vm.available.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.event_busy,
                    title: 'Ninguém disponível neste horário',
                    message: 'Tente outro dia, período ou tarefa.',
                  ),
                )
              : _VolunteerGrid(
                  volunteers: _vm.available,
                  highlight: _vm.skill,
                  badge: const StatusBadge(
                    label: 'Livre',
                    color: AppColors.success,
                    solid: true,
                  ),
                ),
        ),
        Observer(
          builder: (_) => _vm.otherPeriod.isEmpty
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SectionTitle('Livres em outro período'),
                    ),
                    _VolunteerGrid(
                      volunteers: _vm.otherPeriod,
                      highlight: _vm.skill,
                    ),
                  ],
                ),
        ),
        Observer(
          builder: (_) => _vm.blockedOnDate.isEmpty
              ? const SliverToBoxAdapter(child: SizedBox.shrink())
              : SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: SectionTitle('Avisaram que não podem nesta data'),
                    ),
                    _VolunteerGrid(
                      volunteers: _vm.blockedOnDate,
                      highlight: _vm.skill,
                      badge: const StatusBadge(
                        label: 'Indisponível',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
        ),
      ];

  List<Widget> _allTab(BuildContext context) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10),
            child: AppSearchField(
              hint: 'Buscar por nome ou habilidade',
              onChanged: _vm.setQuery,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChipStrip(
                children: [
                  ChoiceChip(
                    label: Text('Todos (${_vm.totalVolunteers})'),
                    selected: _vm.statusFilter == null,
                    onSelected: (_) => _vm.setStatusFilter(null),
                  ),
                  for (final s in VolunteerStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _vm.statusFilter == s,
                      onSelected: (_) => _vm.setStatusFilter(s),
                    ),
                ],
              ),
            ),
          ),
        ),
        Observer(
          builder: (_) => _vm.all.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.person_search,
                    title: 'Nenhum voluntário encontrado',
                  ),
                )
              : _VolunteerGrid(volunteers: _vm.all, showStatus: true),
        ),
      ];

  List<Widget> _requestsTab(BuildContext context) => [
        SliverToBoxAdapter(
          child: Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: ChipStrip(
                children: [
                  for (final t in RequestType.values)
                    ChoiceChip(
                      avatar: Icon(t.icon, size: 16),
                      label: Text('${t.label} ${_vm.pendingCount(t)}'),
                      selected: _vm.requestType == t,
                      onSelected: (_) => _vm.setRequestType(t),
                    ),
                ],
              ),
            ),
          ),
        ),
        Observer(
          builder: (_) => _vm.requests.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nenhuma solicitação',
                  ),
                )
              : SliverAdaptiveGrid(
                  children: [
                    for (final r in _vm.requests)
                      RequestCard(
                        request: r,
                        restricted: _vm.isRestricted(r),
                        animalName: r.animalId == null
                            ? null
                            : _animals.byId(r.animalId!)?.name,
                        onApprove: () => _approve(r),
                        onReject: () => _reject(r),
                        onTap: () => showRequestDetails(
                          context,
                          r,
                          onApprove: () => _approve(r),
                          onReject: () => _reject(r),
                        ),
                        onOpenProfile: r.personId == null
                            ? null
                            : () => context.push(AppRoutes.person(r.personId!)),
                      ),
                  ],
                ),
        ),
      ];
}

class _VolunteerGrid extends StatelessWidget {
  const _VolunteerGrid({
    required this.volunteers,
    this.highlight,
    this.badge,
    this.showStatus = false,
  });

  final List<Volunteer> volunteers;
  final VolunteerSkill? highlight;
  final Widget? badge;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return SliverAdaptiveGrid(
      spacing: 10,
      children: [
        for (final v in volunteers)
          VolunteerCard(
            volunteer: v,
            highlightSkill: highlight,
            badge: showStatus
                ? StatusBadge(
                    label: v.status.label,
                    color: v.status == VolunteerStatus.active
                        ? AppColors.success
                        : AppColors.warning,
                  )
                : badge,
            onTap: () => context.push(AppRoutes.volunteer(v.id)),
          ),
      ],
    );
  }
}
