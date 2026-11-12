import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/detail_sheet.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/finance.dart';
import '../../../data/repositories/animal_repository.dart';



Future<void> showExpenseDetails(BuildContext context, Expense e) {
  final animal =
      e.animalId == null ? null : locator<AnimalRepository>().byId(e.animalId!);
  return showAdaptiveSheet<void>(
    context,
    builder: (sheet) => DetailSheet(
      title: e.description,
      subtitle: 'Despesa · ${Fmt.date(e.date)}',
      icon: e.category.icon,
      color: e.category.color,
      highlight: '− ${Fmt.currency(e.amount)}',
      badge: StatusBadge(
        label: e.hasInvoice ? 'Nota anexada' : 'Falta nota',
        color: e.hasInvoice ? AppColors.success : AppColors.danger,
        icon: e.hasInvoice ? Icons.verified_outlined : Icons.warning_amber,
      ),
      rows: [
        DetailRow(Icons.category_outlined, 'Categoria', e.category.label),
        DetailRow(
          Icons.payments_outlined,
          'Forma de pagamento',
          e.installments > 1
              ? '${e.paymentMethod.label} · ${e.installments}x de '
                  '${Fmt.currency(e.amount / e.installments)}'
              : e.paymentMethod.label,
        ),
        DetailRow(Icons.event_outlined, 'Data', Fmt.date(e.date)),
        DetailRow(
          Icons.pets_outlined,
          'Vinculada a',
          animal?.name ?? 'Despesa geral da ONG',
          onTap: animal == null
              ? null
              : () {
                  Navigator.pop(sheet);
                  context.push(AppRoutes.petDetail(animal.id));
                },
        ),
      ],
      actions: [
        if (e.hasInvoice)
          OutlinedButton.icon(
            onPressed: () => showMessage(
              sheet,
              'Abrindo nota fiscal (simulação)',
              icon: Icons.receipt_long,
            ),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Ver nota fiscal'),
          )
        else
          FilledButton.icon(
            onPressed: () => showMessage(
              sheet,
              'Anexar nota fiscal (simulação)',
              icon: Icons.attach_file,
            ),
            icon: const Icon(Icons.attach_file),
            label: const Text('Anexar nota'),
          ),
      ],
    ),
  );
}

Future<void> showDonationDetails(BuildContext context, Donation d) {
  return showAdaptiveSheet<void>(
    context,
    builder: (sheet) => DetailSheet(
      title: d.campaign != null ? 'Campanha: ${d.campaign}' : d.displayName,
      subtitle: 'Doação · ${Fmt.date(d.date)}',
      icon: d.method.icon,
      color: AppColors.success,
      highlight: '+ ${Fmt.currency(d.amount)}',
      highlightColor: AppColors.success,
      badge: StatusBadge(
        label: d.hasReceipt ? 'Com comprovante' : 'Sem comprovante',
        color: d.hasReceipt ? AppColors.success : AppColors.warning,
      ),
      rows: [
        DetailRow(Icons.person_outline, 'Doador', d.displayName),
        DetailRow(d.method.icon, 'Meio', d.method.label),
        if (d.campaign != null)
          DetailRow(Icons.campaign_outlined, 'Campanha', d.campaign!),
        DetailRow(Icons.event_outlined, 'Data', Fmt.date(d.date)),
      ],
      actions: [
        if (d.hasReceipt)
          OutlinedButton.icon(
            onPressed: () => showMessage(
              sheet,
              'Abrindo comprovante (simulação)',
              icon: Icons.image_outlined,
            ),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Ver comprovante'),
          ),
        if (d.donorName != null)
          FilledButton.icon(
            onPressed: () => showMessage(
              sheet,
              'Mensagem de agradecimento enviada para ${d.donorName} (simulação)',
              icon: Icons.favorite,
            ),
            icon: const Icon(Icons.favorite_outline),
            label: const Text('Agradecer'),
          ),
      ],
    ),
  );
}

Future<void> showFinanceEntryDetails(BuildContext context, FinanceEntry e) =>
    e.isIncome
        ? showDonationDetails(context, e.donation!)
        : showExpenseDetails(context, e.expense!);
