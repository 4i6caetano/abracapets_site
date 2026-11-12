import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../../../data/models/finance.dart';
import '../../../data/models/medical_record.dart';
import '../../../data/models/request.dart';
import '../../finance/widgets/finance_detail_sheets.dart';
import '../../volunteers/viewmodels/volunteers_view_model.dart';
import '../../volunteers/widgets/request_detail_sheet.dart';
import '../viewmodels/notifications_view_model.dart';



Future<void> showNotifications(BuildContext context) async {
  final vm = locator<NotificationsViewModel>();
  final chosen = await showAdaptiveSheet<AppNotification>(
    context,
    builder: (_) => _NotificationsSheet(vm: vm),
  );
  if (chosen == null || !context.mounted) return;
  vm.markRead(chosen);

  switch (chosen.payload) {
    case final AppRequest r:
      final requests = VolunteersViewModel(locator());
      await showRequestDetails(
        context,
        r,
        onApprove: () {
          requests.approve(r);
          showMessage(context, 'Solicitação de ${r.name} aprovada',
              icon: Icons.check_circle_outline);
        },
        onReject: () {
          requests.reject(r);
          showMessage(context, 'Solicitação de ${r.name} recusada');
        },
      );
    case final MedicalRecord m:
      context.push(AppRoutes.petDetail(m.animalId));
    case final Expense e:
      await showExpenseDetails(context, e);
    case final Donation d:
      await showDonationDetails(context, d);
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.vm});

  final NotificationsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Observer(
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: 'Notificações',
            subtitle: vm.unreadCount == 0
                ? 'Tudo em dia'
                : '${vm.unreadCount} não lidas · toque para explorar',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ChipStrip(
              children: [
                ChoiceChip(
                  label: Text('Todas (${vm.countFor(null)})'),
                  selected: vm.filter == null,
                  onSelected: (_) => vm.setFilter(null),
                ),
                for (final c in NotificationCategory.values)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 16),
                    label: Text('${c.label} (${vm.countFor(c)})'),
                    selected: vm.filter == c,
                    onSelected: (_) => vm.setFilter(c),
                  ),
              ],
            ),
          ),
          Flexible(
            child: vm.visible.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Nenhuma notificação aqui',
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    itemCount: vm.visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final n = vm.visible[i];
                      final read = vm.isRead(n);
                      return Card(
                        color: read
                            ? null
                            : scheme.primaryContainer.withValues(alpha: 0.35),
                        child: ListTile(
                          onTap: () => Navigator.pop(context, n),
                          leading: CircleAvatar(
                            backgroundColor: n.color.withValues(alpha: 0.14),
                            child: Icon(n.icon, color: n.color, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  read ? FontWeight.w500 : FontWeight.w800,
                            ),
                          ),
                          subtitle: Text(
                            '${n.subtitle}\n${Fmt.relative(n.date)}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!read)
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: vm.unreadCount == 0 ? null : vm.markAllRead,
                    child: const Text('Marcar todas como lidas'),
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
