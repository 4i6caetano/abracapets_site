import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../core/widgets/feature_tile.dart';
import '../../../data/models/finance.dart';
import '../../../data/repositories/animal_repository.dart';
import '../viewmodels/finance_view_model.dart';
import '../widgets/expenses_chart.dart';
import '../widgets/finance_detail_sheets.dart';
import '../widgets/month_picker_dialog.dart';
import '../widgets/report_sheet.dart';
import '../widgets/transaction_form_sheet.dart';


class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _vm = FinanceViewModel(locator());
  bool _searching = false;

  void _newTransaction({required bool expense}) => showAdaptiveSheet<bool>(
        context,
        builder: (_) => TransactionFormSheet(isExpense: expense),
      );

  Future<void> _pickMonth() async {
    final picked = await showMonthPicker(context, _vm.selectedMonth);
    if (picked != null) _vm.setMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: 'Controle financeiro',
        headerHeight: 185,
        showExpandedTitle: false,
        headerContent: _MonthSummary(vm: _vm, onPickMonth: _pickMonth),
        actions: [
          IconButton(
            tooltip: 'Buscar lançamentos',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _vm.setQuery('');
            }),
            icon: Icon(_searching ? Icons.search_off : Icons.search),
          ),
          IconButton(
            tooltip: 'Gerar relatório',
            onPressed: () => showAdaptiveSheet<void>(
              context,
              builder: (_) => ReportSheet(vm: _vm),
            ),
            icon: const Icon(Icons.ios_share),
          ),
        ],
        floatingActionButton: FloatingActionButton(
          tooltip: 'Nova despesa',
          onPressed: () => _newTransaction(expense: true),
          child: const Icon(Icons.add),
        ),
        slivers: [
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 132,
            ),
            delegate: SliverChildListDelegate([
              FeatureTile(
                icon: Icons.remove_circle_outline,
                label: 'Nova despesa',
                caption: 'Ração, vet, aluguel...',
                color: AppColors.accent,
                onTap: () => _newTransaction(expense: true),
              ),
              FeatureTile(
                icon: Icons.volunteer_activism_outlined,
                label: 'Nova doação',
                caption: 'Pix, dinheiro, campanha',
                color: AppColors.success,
                onTap: () => _newTransaction(expense: false),
              ),
              FeatureTile(
                icon: Icons.summarize_outlined,
                label: 'Gerar relatório',
                caption: 'PDF ou planilha',
                color: AppColors.info,
                onTap: () => showAdaptiveSheet<void>(
                  context,
                  builder: (_) => ReportSheet(vm: _vm),
                ),
              ),
              FeatureTile(
                icon: Icons.receipt_long_outlined,
                label: 'Registro de doações',
                caption: 'Histórico completo',
                color: AppColors.primary,
                badge: '${_vm.monthDonations.length}',
                onTap: () => context.push(AppRoutes.donations),
              ),
            ]),
          ),
          if (_vm.expensesWithoutInvoice > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: NavCard(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  title:
                      '${_vm.expensesWithoutInvoice} gastos sem nota fiscal',
                  subtitle: 'Anexe os comprovantes para manter a transparência',
                  onTap: () => _vm.setFilter(EntryFilter.expense),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chart = _ChartCard(vm: _vm);
                final latest = _LatestExpensesCard(vm: _vm);
                if (constraints.maxWidth >= 840) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: chart),
                        const SizedBox(width: 16),
                        Expanded(child: latest),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    chart,
                    const SizedBox(height: 16),
                    latest,
                  ],
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SectionTitle('Lançamentos do mês')),
          if (_searching)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSearchField(
                  hint: 'Buscar lançamento...',
                  onChanged: _vm.setQuery,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<EntryFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: EntryFilter.all, label: Text('Todos')),
                  ButtonSegment(
                    value: EntryFilter.income,
                    label: Text('Entradas'),
                    icon: Icon(Icons.south_west, size: 16),
                  ),
                  ButtonSegment(
                    value: EntryFilter.expense,
                    label: Text('Saídas'),
                    icon: Icon(Icons.north_east, size: 16),
                  ),
                ],
                selected: {_vm.filter},
                onSelectionChanged: (s) => _vm.setFilter(s.first),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_vm.entries.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.receipt_outlined,
                title: 'Nenhum lançamento',
                message: 'Não há movimentações para este filtro e mês.',
              ),
            )
          else
            SliverList.builder(
              itemCount: _vm.entries.length,
              itemBuilder: (context, i) => _EntryTile(entry: _vm.entries[i]),
            ),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.vm, required this.onPickMonth});

  final FinanceViewModel vm;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget column(String label, String value) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );

    return Observer(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mês anterior',
                color: Colors.white,
                onPressed: vm.previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  onTap: onPickMonth,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            Fmt.monthYear(vm.selectedMonth),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Próximo mês',
                color: Colors.white,
                disabledColor: Colors.white38,
                onPressed: vm.canGoNext ? vm.nextMonth : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo do mês',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          Text(
            Fmt.currency(vm.balance),
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              column('Entradas', '+ ${Fmt.currency(vm.totalIncome)}'),
              column('Saídas', '− ${Fmt.currency(vm.totalExpense)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.vm});

  final FinanceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final variation = vm.expenseVariation;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Gastos do mês por categoria',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (variation != null)
                  StatusBadge(
                    icon: variation > 0 ? Icons.trending_up : Icons.trending_down,
                    label: '${(variation.abs() * 100).round()}% vs mês anterior',
                    color: variation > 0 ? AppColors.danger : AppColors.success,
                  ),
              ],
            ),
            Text(
              'Total: ${Fmt.currency(vm.totalExpense)}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ExpensesChart(totals: vm.categoryTotals),
          ],
        ),
      ),
    );
  }
}

class _LatestExpensesCard extends StatelessWidget {
  const _LatestExpensesCard({required this.vm});

  final FinanceViewModel vm;

  @override
  Widget build(BuildContext context) {
    final animals = locator<AnimalRepository>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey<String>('latest-expenses'),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.history),
        title: const Text(
          'Últimos gastos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${vm.monthExpenses.length} despesas no mês'),
        children: [
          if (vm.latestExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum gasto neste mês.'),
            ),
          for (final e in vm.latestExpenses)
            ListTile(
              onTap: () => showExpenseDetails(context, e),
              leading: CircleAvatar(
                backgroundColor: e.category.color.withValues(alpha: 0.12),
                child: Icon(e.category.icon, color: e.category.color, size: 20),
              ),
              title: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${Fmt.relative(e.date)} · '
                '${e.animalId == null ? 'geral' : animals.byId(e.animalId!)?.name ?? '—'}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '− ${Fmt.currency(e.amount)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (!e.hasInvoice)
                    const Text(
                      'SEM NOTA',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final FinanceEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missingDoc = entry.isIncome
        ? !(entry.donation?.hasReceipt ?? true)
        : !(entry.expense?.hasInvoice ?? true);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          onTap: () => showFinanceEntryDetails(context, entry),
          leading: CircleAvatar(
            backgroundColor: entry.color.withValues(alpha: 0.12),
            child: Icon(entry.icon, color: entry.color, size: 20),
          ),
          title: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${Fmt.relative(entry.date)}'
            '${missingDoc ? (entry.isIncome ? ' · sem comprovante' : ' · falta nota') : ''}',
          ),
          trailing: Text(
            Fmt.signedCurrency(entry.amount, income: entry.isIncome),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: entry.isIncome ? AppColors.success : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
