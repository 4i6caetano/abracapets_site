import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/detail_sheet.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/medical_record.dart';
import '../viewmodels/pet_detail_view_model.dart';


class MedicalRecordSheet extends StatefulWidget {
  const MedicalRecordSheet({super.key, required this.vm});

  final PetDetailViewModel vm;

  @override
  State<MedicalRecordSheet> createState() => _MedicalRecordSheetState();
}

class _MedicalRecordSheetState extends State<MedicalRecordSheet> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _adding
          ? _RecordForm(
              key: const ValueKey('form'),
              vm: widget.vm,
              onDone: () => setState(() => _adding = false),
            )
          : _RecordList(
              key: const ValueKey('list'),
              vm: widget.vm,
              onAdd: () => setState(() => _adding = true),
            ),
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList({super.key, required this.vm, required this.onAdd});

  final PetDetailViewModel vm;
  final VoidCallback onAdd;

  static const _filterLabels = {
    RecordFilter.all: 'Todos',
    RecordFilter.vaccines: 'Vacinas',
    RecordFilter.exams: 'Exames',
    RecordFilter.treatments: 'Tratamentos',
  };

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: 'Prontuário médico', subtitle: vm.pet?.name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ChipStrip(
              children: [
                for (final f in RecordFilter.values)
                  ChoiceChip(
                    label: Text(_filterLabels[f]!),
                    selected: vm.recordFilter == f,
                    onSelected: (_) => vm.setRecordFilter(f),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: vm.records.isEmpty
                ? const EmptyState(
                    icon: Icons.medical_information_outlined,
                    title: 'Nenhum registro nesta categoria',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    itemCount: vm.records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _RecordTile(record: vm.records[i]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar registro'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final MedicalRecord record;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final due = record.nextDate;
    final dueSoon =
        (due != null && due.isAfter(now) && due.difference(now).inDays <= 7) ||
        (record.isScheduled && record.date.difference(now).inDays <= 7);

    final String subtitle;
    if (record.isScheduled) {
      subtitle = 'Agendado para ${Fmt.date(record.date)}';
    } else {
      subtitle =
          'Realizado em ${Fmt.date(record.date)}'
          '${due != null ? ' · próximo: ${Fmt.date(due)}' : ''}';
    }

    Widget? trailing;
    if (dueSoon) {
      trailing = const StatusBadge(
        label: 'Vence esta semana',
        color: AppColors.danger,
      );
    } else if (record.isScheduled) {
      trailing = const StatusBadge(label: 'Em breve', color: AppColors.info);
    } else if (record.attachmentName != null) {
      trailing = ActionChip(
        avatar: const Icon(Icons.picture_as_pdf_outlined, size: 16),
        label: const Text('Laudo'),
        onPressed: () => showMessage(
          context,
          'Abrindo ${record.attachmentName} (simulação)',
          icon: Icons.attach_file,
        ),
      );
    }

    return Card(
      child: ListTile(
        onTap: () => showAdaptiveSheet<void>(
          context,
          builder: (sheet) => DetailSheet(
            title: record.title,
            subtitle: record.type.label,
            icon: record.type.icon,
            color: record.isScheduled ? AppColors.info : AppColors.success,
            badge: trailing is StatusBadge ? trailing : null,
            note: record.notes,
            rows: [
              DetailRow(
                Icons.event_outlined,
                record.isScheduled ? 'Agendado para' : 'Realizado em',
                Fmt.date(record.date),
              ),
              if (record.nextDate != null)
                DetailRow(
                  Icons.event_repeat,
                  'Próximo reforço / retorno',
                  Fmt.date(record.nextDate!),
                ),
              DetailRow(
                Icons.attach_file,
                'Laudo anexado',
                record.attachmentName ?? 'Nenhum',
              ),
            ],
            actions: [
              if (record.attachmentName != null)
                OutlinedButton.icon(
                  onPressed: () => showMessage(
                    sheet,
                    'Abrindo ${record.attachmentName} (simulação)',
                    icon: Icons.attach_file,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Ver laudo'),
                ),
            ],
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: record.isScheduled
              ? scheme.secondaryContainer
              : const Color(0xFF1E9E6A).withValues(alpha: 0.12),
          child: Icon(
            record.isScheduled ? record.type.icon : Icons.check,
            color: record.isScheduled
                ? scheme.onSecondaryContainer
                : const Color(0xFF1E9E6A),
          ),
        ),
        title: Text(
          record.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          record.notes == null ? subtitle : '$subtitle\n${record.notes}',
        ),
        isThreeLine: record.notes != null,
        trailing: trailing,
      ),
    );
  }
}

class _RecordForm extends StatefulWidget {
  const _RecordForm({super.key, required this.vm, required this.onDone});

  final PetDetailViewModel vm;
  final VoidCallback onDone;

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  MedicalRecordType _type = MedicalRecordType.vaccine;
  DateTime? _date = DateTime.now();
  DateTime? _nextDate;
  bool _attachment = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool next}) async {
    final initial = next
        ? (_nextDate ?? DateTime.now().add(const Duration(days: 365)))
        : (_date ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => next ? _nextDate = picked : _date = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.vm.addRecord(
      type: _type,
      title: _title.text.trim(),
      date: _date!,
      nextDate: _nextDate,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      withAttachment: _attachment,
    );
    showMessage(
      context,
      'Registro adicionado ao prontuário',
      icon: Icons.check_circle_outline,
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(title: 'Novo registro médico'),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  DropdownButtonFormField<MedicalRecordType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: [
                      for (final t in MedicalRecordType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t.icon, size: 18),
                              const SizedBox(width: 8),
                              Text(t.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Ex.: Vacina V4 (reforço)',
                    ),
                    validator: Validators.minLength(3, label: 'Descrição'),
                  ),
                  const SizedBox(height: 14),
                  FormField<DateTime>(
                    initialValue: _date,
                    validator: (_) => _date == null ? 'Informe a data' : null,
                    builder: (state) => DateField(
                      label: 'Data do procedimento',
                      value: _date,
                      error: state.errorText,
                      onTap: () async {
                        await _pick(next: false);
                        state.didChange(_date);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  FormField<DateTime>(
                    validator: (_) =>
                        (_nextDate != null &&
                            _date != null &&
                            !_nextDate!.isAfter(_date!))
                        ? 'O retorno deve ser após a data do procedimento'
                        : null,
                    builder: (state) => DateField(
                      label: 'Próximo reforço / retorno (opcional)',
                      value: _nextDate,
                      error: state.errorText,
                      onClear: _nextDate == null
                          ? null
                          : () {
                              setState(() => _nextDate = null);
                              state.didChange(null);
                            },
                      onTap: () async {
                        await _pick(next: true);
                        state.didChange(_nextDate);
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Observações',
                      alignLabelWithHint: true,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.attach_file),
                    title: const Text('Anexar laudo (foto ou PDF)'),
                    value: _attachment,
                    onChanged: (v) => setState(() => _attachment = v),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onDone,
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
