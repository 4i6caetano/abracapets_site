import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/animal.dart';
import '../viewmodels/pets_view_model.dart';
import '../widgets/pet_card.dart';
import '../widgets/pet_filter_sheet.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  final _vm = PetsViewModel(locator());

  void _openFilters() =>
      showAdaptiveSheet<void>(context, builder: (_) => PetFilterSheet(vm: _vm));

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: 'Animais',
        subtitle: '${_vm.total} focinhos cadastrados na ONG',
        headerHeight: 76,
        actions: [
          IconButton(
            tooltip: 'Cadastrar animal',
            onPressed: () => context.push(AppRoutes.petNew),
            icon: const Icon(Icons.add),
          ),
        ],
        bottomHeight: 48,
        bottom: AppSearchField(
          hint: 'Pesquisar por nome ou raça',
          initialValue: _vm.query,
          onChanged: _vm.setQuery,
          onFilterTap: _openFilters,
          filterCount: _vm.activeFilterCount,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.petNew),
          icon: const Icon(Icons.add),
          label: const Text('Novo animal'),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: ChipStrip(
                children: [
                  for (final s in <AnimalStatus?>[null, ...AnimalStatus.values])
                    ChoiceChip(
                      label: Text(
                        '${s?.label ?? 'Todos'} (${_vm.countFor(s)})',
                      ),
                      selected: _vm.status == s,
                      onSelected: (_) => _vm.setStatus(s),
                    ),
                ],
              ),
            ),
          ),
          if (_vm.activeFilterCount > 0)
            SliverToBoxAdapter(child: _ActiveFilters(vm: _vm)),
          if (_vm.pets.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.pets,
                title: 'Nenhum animal encontrado',
                message: 'Ajuste a busca ou os filtros aplicados.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisExtent: 250,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: _vm.pets.length,
                itemBuilder: (context, i) {
                  final pet = _vm.pets[i];
                  return PetCard(
                    animal: pet,
                    onTap: () => context.push(AppRoutes.petDetail(pet.id)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.vm});

  final PetsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Row(
        children: [
          Text(
            'Filtros:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChipStrip(
              children: [
                if (vm.species != null)
                  InputChip(
                    label: Text(vm.species!.label),
                    onDeleted: vm.clearSpecies,
                  ),
                if (vm.sex != null)
                  InputChip(label: Text(vm.sex!.label), onDeleted: vm.clearSex),
                if (vm.onlyCastrated)
                  InputChip(
                    label: const Text('Castrado'),
                    onDeleted: vm.clearCastrated,
                  ),
                if (vm.onlyVaccinated)
                  InputChip(
                    label: const Text('Vacinado'),
                    onDeleted: vm.clearVaccinated,
                  ),
              ],
            ),
          ),
          TextButton(onPressed: vm.clearFilters, child: const Text('Limpar')),
        ],
      ),
    );
  }
}
