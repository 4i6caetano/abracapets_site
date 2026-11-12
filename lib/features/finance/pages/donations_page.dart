import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../app/di/locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/finance.dart';
import '../viewmodels/donations_view_model.dart';
import '../widgets/finance_detail_sheets.dart';
import '../widgets/transaction_form_sheet.dart';


class DonationsPage extends StatefulWidget {
  const DonationsPage({super.key});

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  final _vm = DonationsViewModel(locator());

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: 'Registro de doações',
        headerHeight: 110,
        headerContent: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total filtrado',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                  Text(
                    Fmt.currency(_vm.total),
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_vm.donations.length} doações',
                    style: const TextStyle(color: Colors.white)),
                Text('${_vm.donorsCount} doadores identificados',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
        bottomHeight: 48,
        bottom: AppSearchField(
          hint: 'Buscar doador ou campanha',
          onChanged: _vm.setQuery,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showAdaptiveSheet<bool>(
            context,
            builder: (_) => const TransactionFormSheet(isExpense: false),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova doação'),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ChipStrip(
                children: [
                  ChoiceChip(
                    label: const Text('Todos os meios'),
                    selected: _vm.method == null,
                    onSelected: (_) => _vm.setMethod(null),
                  ),
                  for (final m in DonationMethod.values)
                    ChoiceChip(
                      avatar: Icon(m.icon, size: 16),
                      label: Text(m.label),
                      selected: _vm.method == m,
                      onSelected: (_) => _vm.setMethod(m),
                    ),
                  FilterChip(
                    label: const Text('Sem comprovante'),
                    selected: _vm.onlyWithoutReceipt,
                    onSelected: _vm.setOnlyWithoutReceipt,
                  ),
                ],
              ),
            ),
          ),
          if (_vm.donations.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.volunteer_activism_outlined,
                title: 'Nenhuma doação encontrada',
              ),
            )
          else
            SliverList.builder(
              itemCount: _vm.donations.length,
              itemBuilder: (context, i) {
                final d = _vm.donations[i];
                final showHeader = i == 0 ||
                    _vm.donations[i - 1].date.month != d.date.month ||
                    _vm.donations[i - 1].date.year != d.date.year;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      SectionTitle(Fmt.monthYear(d.date)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          onTap: () => showDonationDetails(context, d),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.success.withValues(alpha: 0.12),
                            child: Icon(d.method.icon, color: AppColors.success),
                          ),
                          title: Text(
                            d.campaign != null
                                ? 'Campanha: ${d.campaign}'
                                : d.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${d.method.label} · ${Fmt.date(d.date)}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+ ${Fmt.currency(d.amount)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Icon(
                                d.hasReceipt
                                    ? Icons.verified_outlined
                                    : Icons.help_outline,
                                size: 16,
                                color: d.hasReceipt
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
