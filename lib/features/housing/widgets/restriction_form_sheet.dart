import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/input_masks.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/dialogs.dart';

typedef RestrictionData = ({String name, String cpf, String reason});



class RestrictionFormSheet extends StatefulWidget {
  const RestrictionFormSheet({super.key, this.initialName, this.initialCpf});

  final String? initialName;
  final String? initialCpf;

  @override
  State<RestrictionFormSheet> createState() => _RestrictionFormSheetState();
}

class _RestrictionFormSheetState extends State<RestrictionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _cpf = TextEditingController(text: widget.initialCpf);
  final _reason = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _name.dispose();
    _cpf.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Incluir na lista restrita?',
      message:
          '${_name.text.trim()} será sinalizada e nenhuma voluntária poderá doar '
          'animais para essa pessoa. Pedidos dela gerarão alerta automático.',
      confirmLabel: 'Incluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    Navigator.pop<RestrictionData>(
      context,
      (name: _name.text.trim(), cpf: _cpf.text, reason: _reason.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = widget.initialCpf != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetHeader(
          title: 'Incluir na lista restrita',
          subtitle: 'Alerta de proteção interno',
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
                    readOnly: readOnly,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: Validators.minLength(5, label: 'Nome'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cpf,
                    readOnly: readOnly,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MaskInputFormatter.cpf()],
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      hintText: '000.000.000-00',
                    ),
                    validator: Validators.cpf,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _reason,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Motivo (obrigatório)',
                      hintText: 'Ex.: devolução fútil, negligência, maus-tratos...',
                      alignLabelWithHint: true,
                    ),
                    validator: Validators.minLength(15, label: 'Motivo'),
                  ),
                  FormField<bool>(
                    validator: (_) => _confirmed
                        ? null
                        : 'Confirme que o motivo foi verificado',
                    builder: (state) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Confirmo que as informações foram verificadas pela equipe',
                      ),
                      subtitle: state.hasError
                          ? Text(
                              state.errorText!,
                              style: const TextStyle(color: AppColors.danger),
                            )
                          : null,
                      value: _confirmed,
                      onChanged: (v) {
                        setState(() => _confirmed = v ?? false);
                        state.didChange(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _submit,
            icon: const Icon(Icons.block),
            label: const Text('Incluir na lista'),
          ),
        ),
      ],
    );
  }
}
