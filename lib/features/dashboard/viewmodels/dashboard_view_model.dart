import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/animal.dart';
import '../../../data/models/request.dart';
import '../../../data/repositories/animal_repository.dart';
import '../../../data/repositories/finance_repository.dart';
import '../../../data/repositories/people_repository.dart';

part 'dashboard_view_model.g.dart';

class DashboardModule {
  const DashboardModule({
    required this.label,
    required this.caption,
    required this.icon,
    required this.route,
    required this.color,
    this.badge,
    this.keywords = const [],
  });

  final String label;
  final String caption;
  final IconData icon;
  final String route;
  final Color color;
  final String? badge;
  final List<String> keywords;
}

class Pendency {
  const Pendency({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(this._animals, this._finance, this._people);

  final AnimalRepository _animals;
  final FinanceRepository _finance;
  final PeopleRepository _people;

  @observable
  String query = '';

  @action
  void setQuery(String value) => query = value;

  @computed
  int get pendingRequests =>
      _people.requests.where((r) => r.status == RequestStatus.pending).length;

  @computed
  List<DashboardModule> get modules => [
        DashboardModule(
          label: 'Animais',
          caption: '${_animals.animals.length} cadastrados',
          icon: Icons.pets,
          route: AppRoutes.pets,
          color: AppColors.primary,
          badge: '${_animals.animals.where((a) => a.status == AnimalStatus.available).length}',
          keywords: ['pets', 'gato', 'cão', 'ficha', 'prontuário', 'vacina'],
        ),
        DashboardModule(
          label: 'Voluntários',
          caption: '${_people.volunteers.length} na equipe',
          icon: Icons.groups_outlined,
          route: AppRoutes.volunteers,
          color: AppColors.info,
          badge: pendingRequests > 0 ? '$pendingRequests' : null,
          keywords: ['equipe', 'solicitações', 'transporte', 'feira'],
        ),
        DashboardModule(
          label: 'Lares',
          caption: 'Temporários e definitivos',
          icon: Icons.home_work_outlined,
          route: AppRoutes.housing,
          color: const Color(0xFF16A394),
          keywords: ['lar temporário', 'adoção', 'adotantes', 'restritos'],
        ),
        DashboardModule(
          label: 'Financeiro',
          caption: 'Despesas e doações',
          icon: Icons.account_balance_wallet_outlined,
          route: AppRoutes.finance,
          color: AppColors.accent,
          badge: 'R\$',
          keywords: ['despesas', 'doações', 'relatório', 'gastos', 'pix'],
        ),
        DashboardModule(
          label: 'Vitrine & Blog',
          caption: 'Site e comunicados',
          icon: Icons.campaign_outlined,
          route: AppRoutes.showcase,
          color: const Color(0xFFE2478B),
          keywords: ['site', 'posts', 'avisos', 'mensagens'],
        ),
        DashboardModule(
          label: 'Configurações',
          caption: 'Preferências do app',
          icon: Icons.settings_outlined,
          route: AppRoutes.settings,
          color: const Color(0xFF4A4458),
          keywords: ['notificações', 'tema', 'senha', 'sair'],
        ),
      ];

  @computed
  List<DashboardModule> get filteredModules {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return modules;
    return modules
        .where(
          (m) =>
              m.label.toLowerCase().contains(q) ||
              m.caption.toLowerCase().contains(q) ||
              m.keywords.any((k) => k.contains(q)),
        )
        .toList();
  }

  @computed
  List<Pendency> get pendencies {
    final now = DateTime.now();
    final weekAhead = now.add(const Duration(days: 7));
    final list = <Pendency>[];

    final dueRecords = _animals.medicalRecords.where((r) {
      final due = r.nextDate ?? (r.isScheduled ? r.date : null);
      return due != null && !due.isBefore(DateTime(now.year, now.month, now.day)) && due.isBefore(weekAhead);
    }).toList();
    if (dueRecords.isNotEmpty) {
      final names = dueRecords
          .map((r) => _animals.byId(r.animalId)?.name)
          .whereType<String>()
          .toSet()
          .join(', ');
      list.add(Pendency(
        title: '${dueRecords.length} procedimentos vencem esta semana',
        subtitle: names,
        icon: Icons.vaccines_outlined,
        color: AppColors.warning,
        route: AppRoutes.pets,
      ));
    }

    final noInvoice = _finance.expenses
        .where((e) =>
            !e.hasInvoice && e.date.month == now.month && e.date.year == now.year)
        .toList();
    if (noInvoice.isNotEmpty) {
      list.add(Pendency(
        title:
            '${noInvoice.length} ${noInvoice.length == 1 ? 'gasto' : 'gastos'} sem nota fiscal',
        subtitle: noInvoice.map((e) => e.description).join(' · '),
        icon: Icons.receipt_long_outlined,
        color: AppColors.danger,
        route: AppRoutes.finance,
      ));
    }

    if (pendingRequests > 0) {
      list.add(Pendency(
        title: '$pendingRequests solicitações aguardando análise',
        subtitle: 'Adoção, voluntariado e denúncias',
        icon: Icons.mark_email_unread_outlined,
        color: AppColors.info,
        route: AppRoutes.volunteers,
      ));
    }
    return list;
  }
}
