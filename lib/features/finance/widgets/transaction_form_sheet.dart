import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../app/di/locator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/input_masks.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/finance.dart';
import '../viewmodels/transaction_form_view_model.dart';


class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({super.key, required this.isExpense});

  final bool isExpense;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final _vm = TransactionFormViewModel(
    locator(),
    locator(),
    isExpense: widget.isExpense,
  );
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) _vm.setDate(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _vm.save();
    if (!mounted) return;
    Navigator.pop(context, true);
    showMessage(
      context,
      widget.isExpense
          ? 'Despesa de ${Fmt.currency(_vm.parsedAmount)} registrada'
          : 'Doação de ${Fmt.currency(_vm.parsedAmount)} registrada 💜',
      icon: Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Observer(
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: widget.isExpense ? 'Nova despesa' : 'Nova doação',
            subtitle: widget.isExpense
                ? 'Saída do caixa da ONG'
                : 'Entrada no caixa da ONG',
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
                      autofocus: true,
                      onChanged: _vm.setAmount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [moneyInputFormatter],
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        prefixText: 'R\$ ',
                        hintText: '0,00',
                      ),
                      validator: Validators.money,
                    ),
                    gap,
                    if (widget.isExpense) ..._expenseFields(gap)
                    else ..._donationFields(gap),
                    gap,
                    FormField<DateTime>(
                      validator: (_) => _vm.validateDate(),
                      builder: (state) => DateField(
                        label: 'Data',
                        value: _vm.date,
                        error: state.errorText,
                        onTap: () async {
                          await _pickDate();
                          state.didChange(_vm.date);
                        },
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
              onPressed: _vm.isSaving ? null : _save,
              child: _vm.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isExpense
                      ? 'Registrar despesa'
                      : 'Registrar doação'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _expenseFields(Widget gap) => [
        TextFormField(
          onChanged: _vm.setDescription,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'O que foi comprado?',
            hintText: 'Ex.: Ração 15kg, vacina V10...',
          ),
          validator: Validators.minLength(3, label: 'Descrição'),
        ),
        gap,
        DropdownButtonFormField<ExpenseCategory>(
          initialValue: _vm.category,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: [
            for (final c in ExpenseCategory.values)
              DropdownMenuItem(
                value: c,
                child: Row(
                  children: [
                    Icon(c.icon, size: 18, color: c.color),
                    const SizedBox(width: 8),
                    Text(c.label),
                  ],
                ),
              ),
          ],
          onChanged: (v) => _vm.setCategory(v ?? _vm.category),
        ),
        gap,
        DropdownButtonFormField<PaymentMethod>(
          initialValue: _vm.paymentMethod,
          decoration: const InputDecoration(labelText: 'Forma de pagamento'),
          items: [
            for (final p in PaymentMethod.values)
              DropdownMenuItem(value: p, child: Text(p.label)),
          ],
          onChanged: (v) => _vm.setPaymentMethod(v ?? _vm.paymentMethod),
        ),
        if (_vm.paymentMethod == PaymentMethod.creditCard) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Foi parcelado?'),
            value: _vm.installment,
            onChanged: _vm.setInstallment,
          ),
          if (_vm.installment)
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _vm.installments.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 10,
                    label: '${_vm.installments}x',
                    onChanged: (v) => _vm.setInstallments(v.round()),
                  ),
                ),
                Text(
                  '${_vm.installments}x de ${Fmt.currency(_vm.installmentValue)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ],
        gap,
        DropdownButtonFormField<String?>(
          initialValue: _vm.animalId,
          decoration: const InputDecoration(
            labelText: 'Gasto de um pet específico?',
            helperText: 'Deixe em "Despesa geral" se for para todos',
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Despesa geral da ONG')),
            for (final a in _vm.animals)
              DropdownMenuItem(value: a.id, child: Text(a.name)),
          ],
          onChanged: _vm.setAnimal,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.receipt_long_outlined),
          title: const Text('Nota fiscal / recibo anexado'),
          subtitle: _vm.hasInvoice
              ? const Text('nota_fiscal.jpg')
              : const Text('Gastos sem nota geram pendência'),
          value: _vm.hasInvoice,
          onChanged: _vm.setHasInvoice,
        ),
      ];

  List<Widget> _donationFields(Widget gap) => [
        Text('Meio', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in DonationMethod.values)
              ChoiceChip(
                avatar: Icon(m.icon, size: 18),
                label: Text(m.label),
                selected: _vm.donationMethod == m,
                onSelected: (_) => _vm.setDonationMethod(m),
              ),
          ],
        ),
        gap,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Doação anônima'),
          value: _vm.anonymous,
          onChanged: _vm.setAnonymous,
        ),
        if (!_vm.anonymous)
          TextFormField(
            onChanged: _vm.setDonorName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome do doador'),
            validator: _vm.validateDonor,
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.image_outlined),
          title: const Text('Comprovante anexado'),
          value: _vm.hasReceipt,
          onChanged: _vm.setHasReceipt,
        ),
      ];
}
