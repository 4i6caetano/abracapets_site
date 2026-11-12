import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/feature_tile.dart';
import '../../notifications/viewmodels/notifications_view_model.dart';
import '../../notifications/widgets/notifications_sheet.dart';
import '../viewmodels/dashboard_view_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _appVm = locator<AppViewModel>();
  final _vm = DashboardViewModel(locator(), locator(), locator());
  final _notifications = locator<NotificationsViewModel>();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: '$_greeting, ${_appVm.user?.firstName ?? ''}',
        subtitle: 'O que vamos cuidar hoje?',
        showBack: false,
        headerHeight: 150,
        headerContent: _HeaderSummary(vm: _vm),
        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () => showNotifications(context),
            icon: Badge(
              isLabelVisible: _notifications.unreadCount > 0,
              label: Text('${_notifications.unreadCount}'),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.notifications_none),
            ),
          ),
          IconButton(
            tooltip: 'Meu perfil',
            onPressed: () => context.go(AppRoutes.profile),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                (_appVm.user?.firstName ?? '?')[0],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
        bottomHeight: 48,
        bottom: AppSearchField(
          hint: 'Pesquisar funcionalidades...',
          onChanged: _vm.setQuery,
        ),
        slivers: [
          const SliverToBoxAdapter(child: SectionTitle('Módulos de gestão')),
          if (_vm.filteredModules.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Nenhuma funcionalidade encontrada',
                message: 'Tente buscar por "despesas", "vacina" ou "lares".',
              ),
            )
          else
            SliverGrid.builder(
              gridDelegate: FeatureTile.gridDelegate(),
              itemCount: _vm.filteredModules.length,
              itemBuilder: (context, i) {
                final m = _vm.filteredModules[i];
                return FeatureTile(
                  icon: m.icon,
                  label: m.label,
                  caption: m.caption,
                  badge: m.badge,
                  color: m.color,
                  onTap: () => context.go(m.route),
                );
              },
            ),
          const SliverToBoxAdapter(child: SectionTitle('Pendências de hoje')),
          SliverList.separated(
            itemCount: _vm.pendencies.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = _vm.pendencies[i];
              return NavCard(
                icon: p.icon,
                color: p.color,
                title: p.title,
                subtitle: p.subtitle,
                onTap: () => context.go(p.route),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.vm});

  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    Widget pill(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill(Icons.pets, vm.modules.first.caption),
        pill(Icons.notifications_active_outlined,
            '${vm.pendencies.length} pendências'),
      ],
    );
  }
}
