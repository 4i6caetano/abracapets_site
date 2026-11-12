import 'package:flutter/material.dart';

import '../../../core/utils/input_masks.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/volunteer.dart';
import 'availability_grid.dart';


class VolunteerFormSheet extends StatefulWidget {
  const VolunteerFormSheet({super.key, this.initial});

  
  final Volunteer? initial;

  @override
  State<VolunteerFormSheet> createState() => _VolunteerFormSheetState();
}

class _VolunteerFormSheetState extends State<VolunteerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _phone = TextEditingController(text: widget.initial?.whatsapp);
  late final _instagram =
      TextEditingController(text: widget.initial?.instagram);
  late final _skills = <VolunteerSkill>{...?widget.initial?.skills};
  late final _availability = <Weekday, Set<ShiftPeriod>>{
    for (final e in (widget.initial?.availability ?? const {}).entries)
      e.key: {...e.value},
  };

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _instagram.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final availability = {
      for (final e in _availability.entries)
        if (e.value.isNotEmpty) e.key: Set.of(e.value),
    };
    final instagram =
        _instagram.text.trim().isEmpty ? null : _instagram.text.trim();
    final initial = widget.initial;
    if (initial != null) {
      Navigator.pop(
        context,
        initial.copyWith(
          name: _name.text.trim(),
          whatsapp: _phone.text,
          instagram: instagram,
          skills: Set.of(_skills),
          availability: availability,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      Volunteer(
        id: 'v${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        whatsapp: _phone.text,
        instagram: instagram,
        birthDate: DateTime(1995),
        skills: Set.of(_skills),
        availability: availability,
        since: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: widget.initial == null ? 'Novo voluntário' : 'Editar voluntário',
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: Validators.minLength(3, label: 'Nome'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [MaskInputFormatter.phone()],
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp',
                      hintText: '(17) 99999-9999',
                      prefixIcon: Icon(Icons.chat_outlined),
                    ),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _instagram,
                    decoration: const InputDecoration(
                      labelText: 'Instagram (opcional)',
                      hintText: '@usuario',
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return RegExp(r'^@[\w\.]{2,30}$').hasMatch(t)
                          ? null
                          : 'Use o formato @usuario';
                    },
                  ),
                  const SizedBox(height: 18),
                  FormField<Set<VolunteerSkill>>(
                    validator: (_) =>
                        _skills.isEmpty ? 'Selecione ao menos uma habilidade' : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('O que a pessoa pode fazer?',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in VolunteerSkill.values)
                              FilterChip(
                                avatar: Icon(s.icon, size: 18),
                                label: Text(s.label),
                                selected: _skills.contains(s),
                                onSelected: (sel) {
                                  setState(() =>
                                      sel ? _skills.add(s) : _skills.remove(s));
                                  state.didChange(_skills);
                                },
                              ),
                          ],
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(state.errorText!,
                                style: TextStyle(color: error, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FormField<int>(
                    validator: (_) => _availability.values.every((s) => s.isEmpty)
                        ? 'Marque ao menos um horário livre'
                        : null,
                    builder: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dias e períodos livres',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        AvailabilityGrid(
                          availability: _availability,
                          onToggle: (d, p) {
                            setState(() {
                              final set = _availability.putIfAbsent(d, () => {});
                              set.contains(p) ? set.remove(p) : set.add(p);
                            });
                            state.didChange(0);
                          },
                        ),
                        if (state.hasError)
                          Text(state.errorText!,
                              style: TextStyle(color: error, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: FilledButton(
            onPressed: _submit,
            child: Text(
              widget.initial == null ? 'Cadastrar voluntário' : 'Salvar alterações',
            ),
          ),
        ),
      ],
    );
  }
}
