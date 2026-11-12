import 'package:flutter/material.dart';

import '../../../core/widgets/dialogs.dart';
import '../../../data/models/animal.dart';
import '../viewmodels/pets_view_model.dart';


class PetFilterSheet extends StatefulWidget {
  const PetFilterSheet({super.key, required this.vm});

  final PetsViewModel vm;

  @override
  State<PetFilterSheet> createState() => _PetFilterSheetState();
}

class _PetFilterSheetState extends State<PetFilterSheet> {
  late Species? _species = widget.vm.species;
  late Sex? _sex = widget.vm.sex;
  late bool _castrated = widget.vm.onlyCastrated;
  late bool _vaccinated = widget.vm.onlyVaccinated;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Filtrar animais'),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Espécie', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<Species?>(
                  segments: [
                    const ButtonSegment(value: null, label: Text('Todas')),
                    for (final s in Species.values)
                      ButtonSegment(
                        value: s,
                        label: Text(s.label),
                        icon: Icon(s.icon),
                      ),
                  ],
                  selected: {_species},
                  onSelectionChanged: (v) => setState(() => _species = v.first),
                ),
                const SizedBox(height: 20),
                Text('Sexo', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<Sex?>(
                  segments: [
                    const ButtonSegment(value: null, label: Text('Ambos')),
                    for (final s in Sex.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: {_sex},
                  onSelectionChanged: (v) => setState(() => _sex = v.first),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apenas castrados'),
                  secondary: const Icon(Icons.content_cut),
                  value: _castrated,
                  onChanged: (v) => setState(() => _castrated = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Apenas vacinados'),
                  secondary: const Icon(Icons.vaccines_outlined),
                  value: _vaccinated,
                  onChanged: (v) => setState(() => _vaccinated = v),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _species = null;
                    _sex = null;
                    _castrated = false;
                    _vaccinated = false;
                  }),
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.vm.applyFilters(
                      species: _species,
                      sex: _sex,
                      castrated: _castrated,
                      vaccinated: _vaccinated,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
