import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/finance.dart';
import '../../../data/models/medical_record.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'notifications_view_model.g.dart';

enum NotificationCategory {
  requests('Solicitações', Icons.mark_email_unread_outlined),
  health('Saúde', Icons.vaccines_outlined),
  finance('Financeiro', Icons.account_balance_wallet_outlined);

  const NotificationCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}



class AppNotification {
  const AppNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.date,
    required this.payload,
    this.urgent = false,
  });

  final String id;
  final NotificationCategory category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime date;
  final Object payload;
  final bool urgent;
}

class NotificationsViewModel = NotificationsViewModelBase
    with _$NotificationsViewModel;

abstract class NotificationsViewModelBase with Store {
  NotificationsViewModelBase(this._animals, this._finance, this._people);

  final AnimalRepository _animals;
  final FinanceRepository _finance;
  final PeopleRepository _people;

  final readIds = ObservableSet<String>();

  @observable
  NotificationCategory? filter;

  @computed
  List<AppNotification> get all {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = <AppNotification>[];

    
    for (final r in _people.requests) {
      if (r.status != RequestStatus.pending) continue;
      final person = r.personId == null ? null : _people.personById(r.personId!);
      final restricted = person?.isRestricted ?? false;
      final animal = r.animalId == null ? null : _animals.byId(r.animalId!);
      list.add(AppNotification(
        id: 'req-${r.id}',
        category: NotificationCategory.requests,
        title: restricted
            ? 'Pedido de pessoa da lista restrita'
            : switch (r.type) {
                RequestType.adoption => 'Novo pedido de adoção',
                RequestType.volunteering => 'Nova solicitação de voluntariado',
                RequestType.report => 'Nova denúncia recebida',
              },
        subtitle: animal == null ? '${r.name} · ${r.summary}' : '${r.name} quer adotar ${animal.name}',
        icon: restricted ? Icons.warning_amber_rounded : r.type.icon,
        color: restricted
            ? AppColors.danger
            : r.type == RequestType.report
                ? AppColors.warning
                : AppColors.info,
        date: r.date,
        payload: r,
        urgent: restricted || r.type == RequestType.report,
      ));
    }

    
    for (final m in _animals.medicalRecords) {
      final due = m.nextDate ?? (m.isScheduled ? m.date : null);
      if (due == null) continue;
      final days = DateTime(due.year, due.month, due.day).difference(today).inDays;
      if (days < 0 || days > 7) continue;
      final pet = _animals.byId(m.animalId)?.name ?? '—';
      list.add(AppNotification(
        id: 'med-${m.id}',
        category: NotificationCategory.health,
        title: m.type == MedicalRecordType.vaccine
            ? 'Vacina de $pet vence ${days == 0 ? 'hoje' : 'em $days dias'}'
            : '${m.title} de $pet ${days == 0 ? 'é hoje' : 'em $days dias'}',
        subtitle: '${m.title} · ${Fmt.date(due)}',
        icon: m.type.icon,
        color: days <= 2 ? AppColors.danger : AppColors.warning,
        date: today,
        payload: m,
        urgent: days <= 2,
      ));
    }

    
    for (final e in _finance.expenses) {
      if (e.hasInvoice || e.date.month != now.month || e.date.year != now.year) {
        continue;
      }
      list.add(AppNotification(
        id: 'inv-${e.id}',
        category: NotificationCategory.finance,
        title: 'Gasto sem nota fiscal',
        subtitle: '${e.description} · ${Fmt.currency(e.amount)}',
        icon: Icons.receipt_long_outlined,
        color: AppColors.danger,
        date: e.date,
        payload: e,
      ));
    }

    
    for (final d in _finance.donations) {
      if (today.difference(d.date).inDays > 7 || d.date.isAfter(now)) continue;
      list.add(AppNotification(
        id: 'don-${d.id}',
        category: NotificationCategory.finance,
        title: 'Doação recebida: ${Fmt.currency(d.amount)}',
        subtitle: '${d.displayName} · ${d.method.label}',
        icon: Icons.volunteer_activism_outlined,
        color: AppColors.success,
        date: d.date,
        payload: d,
      ));
    }

    list.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  @computed
  List<AppNotification> get visible =>
      filter == null ? all : all.where((n) => n.category == filter).toList();

  @computed
  int get unreadCount => all.where((n) => !readIds.contains(n.id)).length;

  int countFor(NotificationCategory? c) =>
      c == null ? all.length : all.where((n) => n.category == c).length;

  bool isRead(AppNotification n) => readIds.contains(n.id);

  @action
  void setFilter(NotificationCategory? value) => filter = value;

  @action
  void markRead(AppNotification n) => readIds.add(n.id);

  @action
  void markAllRead() => readIds.addAll(all.map((n) => n.id));
}
