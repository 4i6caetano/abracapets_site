import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../data/repositories/animal_repository.dart';
import '../pages/report_preview_page.dart';
import '../services/report_pdf_service.dart';
import '../viewmodels/finance_view_model.dart';


class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.vm});

  final FinanceViewModel vm;

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  bool _exporting = false;
  bool _includeDonors = false;

  Future<void> _generatePdf() async {
    setState(() => _exporting = true);
    final vm = widget.vm;
    final animals = locator<AnimalRepository>();
    const service = ReportPdfService();
    final bytes = await service.build(
      month: vm.selectedMonth,
      donations: vm.monthDonations,
      expenses: vm.monthExpenses,
      categoryTotals: vm.categoryTotals,
      includeDonorNames: _includeDonors,
      animalName: (id) => animals.byId(id)?.name ?? '—',
      generatedBy: locator<AppViewModel>().user?.name ?? 'Equipe',
    );
    if (!mounted) return;
    setState(() => _exporting = false);
    final navigator = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ReportPreviewPage(
          bytes: bytes,
          fileName: service.fileName(vm.selectedMonth),
          title: 'Relatório · ${Fmt.monthYear(vm.selectedMonth)}',
        ),
      ),
    );
  }

  Future<void> _exportSheet() async {
    setState(() => _exporting = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _exporting = false);
    showMessage(context, 'Exportação para planilha (simulação)',
        icon: Icons.table_chart_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final scheme = Theme.of(context).colorScheme;
    final categories = vm.categoryTotals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Widget line(String label, String value, {Color? color, bool bold = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: 'Relatório mensal',
          subtitle: Fmt.monthYear(vm.selectedMonth),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        line('Entradas (${vm.monthDonations.length} doações)',
                            Fmt.currency(vm.totalIncome),
                            color: AppColors.success),
                        line('Saídas (${vm.monthExpenses.length} despesas)',
                            Fmt.currency(vm.totalExpense),
                            color: AppColors.danger),
                        const Divider(),
                        line('Saldo do mês', Fmt.currency(vm.balance),
                            bold: true,
                            color: vm.balance >= 0
                                ? AppColors.success
                                : AppColors.danger),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Despesas por categoria',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final c in categories) ...[
                  Row(
                    children: [
                      Icon(c.key.icon, size: 18, color: c.key.color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.key.label)),
                      Text(Fmt.currency(c.value)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 10),
                    child: LinearProgressIndicator(
                      value: vm.totalExpense == 0 ? 0 : c.value / vm.totalExpense,
                      color: c.key.color,
                      backgroundColor: scheme.surfaceContainerHighest,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
                if (vm.expensesWithoutInvoice > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${vm.expensesWithoutInvoice} despesas sem nota fiscal '
                            'serão sinalizadas no relatório.',
                          ),
                        ),
                      ],
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Incluir nomes dos doadores'),
                  subtitle: const Text('Desligado: relatório público anônimo'),
                  value: _includeDonors,
                  onChanged: (v) => setState(() => _includeDonors = v),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: _exporting
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportSheet,
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Planilha'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _generatePdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Gerar PDF'),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
