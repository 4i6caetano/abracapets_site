import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/network_photo.dart';
import '../../../data/models/animal.dart';
import '../viewmodels/pet_edit_view_model.dart';


class PetEditPage extends StatefulWidget {
  const PetEditPage({super.key, this.petId});

  final String? petId;

  @override
  State<PetEditPage> createState() => _PetEditPageState();
}

class _PetEditPageState extends State<PetEditPage> {
  late final _vm = PetEditViewModel(
    locator(),
    widget.petId,
    author: locator<AppViewModel>().user?.firstName ?? 'Equipe',
  );
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickDate({required bool birth}) async {
    final current = birth ? _vm.birthDate : _vm.rescueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: birth ? 'Nascimento (estimado)' : 'Data do resgate',
    );
    if (picked == null) return;
    birth ? _vm.setBirthDate(picked) : _vm.setRescueDate(picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      showMessage(
        context,
        'Revise os campos destacados',
        icon: Icons.error_outline,
      );
      return;
    }
    final isNew = _vm.isNew;
    final id = await _vm.save();
    if (!mounted) return;
    showMessage(
      context,
      isNew ? 'Animal cadastrado com sucesso!' : 'Alterações salvas',
      icon: Icons.check_circle_outline,
    );
    if (isNew) {
      context.pushReplacement(AppRoutes.petDetail(id));
    } else {
      context.pop();
    }
  }

  Future<bool> _confirmDiscard() => showConfirmDialog(
    context,
    title: 'Descartar alterações?',
    message: 'As alterações feitas nesta ficha serão perdidas.',
    confirmLabel: 'Descartar',
    destructive: true,
  );

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => PopScope(
        canPop: !_vm.isDirty || _vm.isSaving,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmDiscard() && context.mounted) {
            _vm.discardChanges();
            context.pop();
          }
        },
        child: AppNestedScaffold(
          title: _vm.isNew ? 'Novo animal' : 'Edição de pet',
          subtitle: _vm.isNew ? 'Preencha a ficha do resgatado' : _vm.name,
          headerHeight: 70,
          bottomBar: _SaveBar(isSaving: _vm.isSaving, onSave: _save),
          slivers: [
            SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 840;
                    final left = _buildMainFields(context);
                    final right = _buildSideFields(context);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: left),
                          const SizedBox(width: 28),
                          Expanded(flex: 2, child: right),
                        ],
                      );
                    }
                    return Column(children: [right, left]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideFields(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Fotos'),
          FormField<int>(
            validator: (_) => _vm.validatePhotos(),
            builder: (state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 108,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _vm.photos.length; i++)
                        _PhotoThumb(
                          
                          
                          key: ValueKey(_vm.photos[i]),
                          url: _vm.photos[i],
                          isCover: i == 0,
                          onRemove: () {
                            _vm.removePhoto(i);
                            state.didChange(_vm.photos.length);
                          },
                          onMakeCover: () => _vm.makeCover(i),
                        ),
                      _AddPhotoButton(
                        onTap: () {
                          _vm.addPhoto();
                          state.didChange(_vm.photos.length);
                        },
                      ),
                    ],
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SectionTitle('Saúde rápida'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.content_cut),
                  title: const Text('Já castrado?'),
                  value: _vm.castrated,
                  onChanged: _vm.setCastrated,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.vaccines_outlined),
                  title: const Text('Já vacinado?'),
                  value: _vm.vaccinated,
                  onChanged: _vm.setVaccinated,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.public),
                  title: const Text('Exibir na vitrine do site'),
                  subtitle: _vm.canShowOnShowcase
                      ? null
                      : const Text('Animais adotados não aparecem na vitrine'),
                  value: _vm.showOnShowcase,
                  onChanged: _vm.canShowOnShowcase
                      ? _vm.setShowOnShowcase
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFields(BuildContext context) {
    final gap = const SizedBox(height: 16);
    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Identificação'),
          TextFormField(
            initialValue: _vm.name,
            onChanged: _vm.setName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome do pet'),
            validator: Validators.minLength(2, label: 'Nome'),
          ),
          gap,
          _ResponsiveRow(
            children: [
              DropdownButtonFormField<Species>(
                initialValue: _vm.species,
                decoration: const InputDecoration(labelText: 'Espécie'),
                items: [
                  for (final s in Species.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => _vm.setSpecies(v ?? _vm.species),
              ),
              DropdownButtonFormField<AnimalStatus>(
                initialValue: _vm.status,
                decoration: const InputDecoration(
                  labelText: 'Status do animal',
                ),
                items: [
                  for (final s in AnimalStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => _vm.setStatus(v ?? _vm.status),
              ),
            ],
          ),
          gap,
          TextFormField(
            initialValue: _vm.breed,
            onChanged: _vm.setBreed,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Raça',
              hintText: 'Ex.: Vira-lata, Siamês...',
            ),
            validator: Validators.required('Informe a raça (ou SRD)'),
          ),
          gap,
          SegmentedButton<Sex>(
            segments: [
              for (final s in Sex.values)
                ButtonSegment(
                  value: s,
                  label: Text(s.label),
                  icon: Icon(s == Sex.male ? Icons.male : Icons.female),
                ),
            ],
            selected: {_vm.sex},
            onSelectionChanged: (v) => _vm.setSex(v.first),
          ),
          const SectionTitle('Datas importantes'),
          _ResponsiveRow(
            children: [
              FormField<DateTime>(
                validator: (_) => _vm.validateBirthDate(),
                builder: (state) => DateField(
                  label: 'Nascimento (estimado)',
                  value: _vm.birthDate,
                  error: state.errorText,
                  onTap: () async {
                    await _pickDate(birth: true);
                    state.didChange(_vm.birthDate);
                  },
                ),
              ),
              FormField<DateTime>(
                validator: (_) => _vm.validateRescueDate(),
                builder: (state) => DateField(
                  label: 'Data do resgate',
                  value: _vm.rescueDate,
                  error: state.errorText,
                  onTap: () async {
                    await _pickDate(birth: false);
                    state.didChange(_vm.rescueDate);
                  },
                ),
              ),
            ],
          ),
          const SectionTitle('História e personalidade'),
          TextFormField(
            initialValue: _vm.description,
            onChanged: _vm.setDescription,
            maxLines: 4,
            maxLength: PetEditViewModelBase.descriptionMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Jeitinho dele: sociável, calmo, brincalhão...',
              alignLabelWithHint: true,
            ),
            validator: Validators.compose([
              Validators.minLength(20, label: 'Descrição'),
              Validators.maxLength(PetEditViewModelBase.descriptionMax),
            ]),
          ),
          gap,
          TextFormField(
            initialValue: _vm.rescueStory,
            onChanged: _vm.setRescueStory,
            minLines: 5,
            maxLines: 8,
            maxLength: PetEditViewModelBase.storyMax,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'História do resgate',
              alignLabelWithHint: true,
            ),
            validator: Validators.minLength(20, label: 'História'),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (context.screenWidth < 420) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    super.key,
    required this.url,
    required this.isCover,
    required this.onRemove,
    required this.onMakeCover,
  });

  final String url;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback onMakeCover;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        width: 108,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: isCover ? null : onMakeCover,
              child: NetworkPhoto(
                url: url,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            if (isCover)
              const Positioned(
                left: 6,
                bottom: 6,
                child: StatusBadge(
                  label: 'Capa',
                  color: AppColors.primary,
                  solid: true,
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: 'Remover foto',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline, width: 1.2),
          color: scheme.surfaceContainerLowest,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              'Adicionar\nimagem',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}


class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(isSaving ? 'Salvando...' : 'SALVAR'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
