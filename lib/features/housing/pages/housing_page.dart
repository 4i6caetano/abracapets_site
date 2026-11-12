import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/home.dart';
import '../../../data/models/person.dart';
import '../viewmodels/housing_view_model.dart';
import '../widgets/restriction_form_sheet.dart';


class HousingPage extends StatefulWidget {
  const HousingPage({super.key});

  @override
  State<HousingPage> createState() => _HousingPageState();
}

class _HousingPageState extends State<HousingPage> {
  final _vm = HousingViewModel(locator(), locator());

  Future<void> _addRestriction() async {
    final data = await showAdaptiveSheet<RestrictionData>(
      context,
      builder: (_) => const RestrictionFormSheet(),
    );
    if (data == null || !mounted) return;
    _vm.addRestriction(
      name: data.name,
      cpf: data.cpf,
      reason: data.reason,
      addedBy: locator<AppViewModel>().user?.firstName ?? 'Equipe',
    );
    showMessage(context, '${data.name} incluída na lista restrita',
        icon: Icons.block);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Observer(
        builder: (_) => AppNestedScaffold(
          title: 'Lares',
          subtitle: '${_vm.totalTemporary} lares temporários · '
              '${_vm.freeVacancies} vagas livres',
          headerHeight: 76,
          bottomHeight: AppTabBar.height,
          bottom: const AppTabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Temporários'),
              Tab(text: 'Definitivos'),
              Tab(text: 'Adotantes'),
              Tab(text: 'Restritos'),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Cadastrar lar',
            onPressed: () => showMessage(
              context,
              'Cadastro de lar com vistoria (próxima etapa do protótipo)',
              icon: Icons.home_outlined,
            ),
            child: const Icon(Icons.add_home_outlined),
          ),
          tabViews: [
            _temporaryTab(),
            _definitiveTab(),
            _adoptersTab(),
            _restrictedTab(),
          ],
        ),
      ),
    );
  }

  List<Widget> _temporaryTab() => [
        SliverToBoxAdapter(
          child: Observer(
            builder: (_) => Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: ChipStrip(
                children: [
                  for (final (f, label) in const [
                    (TempHomeFilter.all, 'Todos'),
                    (TempHomeFilter.withVacancy, 'Com vaga'),
                    (TempHomeFilter.dogs, 'Aceita cães'),
                    (TempHomeFilter.cats, 'Aceita gatos'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _vm.tempFilter == f,
                      onSelected: (_) => _vm.setTempFilter(f),
                    ),
                ],
              ),
            ),
          ),
        ),
        Observer(
          builder: (_) => _vm.temporaryHomes.isEmpty
              ? const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.house_outlined,
                    title: 'Nenhum lar com esse filtro',
                  ),
                )
              : SliverAdaptiveGrid(
                  children: [
                    for (final h in _vm.temporaryHomes) _HomeCard(home: h, vm: _vm),
                  ],
                ),
        ),
      ];

  List<Widget> _definitiveTab() => [
        Observer(
          builder: (_) => SliverAdaptiveGrid(
            children: [
              for (final h in _vm.definitiveHomes) _HomeCard(home: h, vm: _vm),
            ],
          ),
        ),
      ];

  List<Widget> _adoptersTab() => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: AppSearchField(
              hint: 'Buscar adotante por nome ou e-mail',
              onChanged: _vm.setAdopterQuery,
            ),
          ),
        ),
        Observer(
          builder: (_) => SliverAdaptiveGrid(
            spacing: 8,
            children: [
              for (final p in _vm.adopters)
                Card(
                  child: ListTile(
                    onTap: () => context.push(AppRoutes.person(p.id)),
                    leading: InitialsAvatar(name: p.fullName),
                    title: Text(
                      p.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${p.phone} · ${_vm.adoptionsCount(p)} adoções',
                    ),
                    trailing: p.hasDocumentPhoto
                        ? const Tooltip(
                            message: 'Documento arquivado',
                            child: Icon(Icons.verified_user_outlined,
                                color: AppColors.success),
                          )
                        : const Tooltip(
                            message: 'Sem documento',
                            child: Icon(Icons.gpp_maybe_outlined,
                                color: AppColors.warning),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ];

  List<Widget> _restrictedTab() => [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.danger),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pedidos de pessoas desta lista geram alerta automático em '
                    'Solicitações. Dados estritamente confidenciais.',
                  ),
                ),
              ],
            ),
          ),
        ),
        Observer(
          builder: (_) => SliverAdaptiveGrid(
            children: [
              for (final p in _vm.restricted) _RestrictedCard(person: p),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _addRestriction,
                  icon: const Icon(Icons.add),
                  label: const Text('Incluir pessoa na lista'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Motivo obrigatório e confirmação antes de salvar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ];
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.home, required this.vm});

  final Home home;
  final HousingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final animals = vm.hostedAnimals(home);
    final title = vm.homeTitle(home);
    final responsible = vm.responsible(home);

    final acceptsList = [
      if (home.acceptsDogs) 'cães',
      if (home.acceptsCats) 'gatos',
    ];
    final accepts =
        acceptsList.isEmpty ? 'Sem preferência' : acceptsList.join(' e ');

    Widget badge;
    if (!home.isTemporary) {
      badge = const StatusBadge(label: 'Definitivo', color: AppColors.accentDark);
    } else if (home.isFull) {
      badge = StatusBadge(label: 'Lotado', color: scheme.outline);
    } else {
      badge = StatusBadge(
        label: '${home.freeVacancies} ${home.freeVacancies == 1 ? 'vaga' : 'vagas'}',
        color: AppColors.success,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.home(home.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: title, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          home.isTemporary
                              ? '${accepts[0].toUpperCase()}${accepts.substring(1)} · capacidade ${home.vacancies}'
                              : '${home.propertyType.label} · ${home.city}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  badge,
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusBadge(
                    icon: home.propertyType.icon,
                    label: '${home.propertyType.label} · ${home.sizeM2} m²',
                    color: scheme.primary,
                  ),
                  StatusBadge(
                    icon: home.hasProtectionNet
                        ? Icons.shield_outlined
                        : Icons.warning_amber,
                    label: home.hasProtectionNet ? 'Com tela' : 'Sem tela',
                    color: home.hasProtectionNet
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  if (home.familyPetsCount > 0)
                    StatusBadge(
                      icon: Icons.pets,
                      label: '${home.familyPetsCount} pets da família',
                      color: AppColors.info,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      animals.isEmpty
                          ? 'Nenhum animal agora'
                          : 'Com ${home.isTemporary ? 'ela' : 'a família'}: '
                              '${animals.map((a) => a.name).join(', ')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (responsible != null)
                    TextButton.icon(
                      onPressed: () => showMessage(
                        context,
                        'Abrindo WhatsApp ${responsible.phone}',
                        icon: Icons.chat,
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestrictedCard extends StatelessWidget {
  const _RestrictedCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final r = person.restriction!;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.person(person.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: person.fullName, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Incluída em ${Fmt.date(r.date)} por ${r.addedBy}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const StatusBadge(
                    label: 'RESTRITA',
                    color: AppColors.danger,
                    solid: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Motivo: ${r.reason}'),
            ],
          ),
        ),
      ),
    );
  }
}
