import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_view_model.dart';
import '../../app/di/locator.dart';
import '../../app/router/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'common_widgets.dart';



class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _destinations = [
    (
      AppRoutes.dashboard,
      Icons.space_dashboard_outlined,
      Icons.space_dashboard,
      'Início',
    ),
    (AppRoutes.pets, Icons.pets_outlined, Icons.pets, 'Animais'),
    (
      AppRoutes.finance,
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Financeiro',
    ),
    (AppRoutes.volunteers, Icons.groups_outlined, Icons.groups, 'Voluntários'),
    (AppRoutes.housing, Icons.home_work_outlined, Icons.home_work, 'Lares'),
    (
      AppRoutes.showcase,
      Icons.storefront_outlined,
      Icons.storefront,
      'Vitrine & Blog',
    ),
    (
      AppRoutes.settings,
      Icons.settings_outlined,
      Icons.settings,
      'Configurações',
    ),
  ];

  int get _selectedIndex {
    for (var i = _destinations.length - 1; i > 0; i--) {
      if (location.startsWith(_destinations[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = context.screenWidth;
    if (width < Breakpoints.desktop) return child;

    final extended = width >= Breakpoints.wide;
    final scheme = Theme.of(context).colorScheme;
    final appVm = locator<AppViewModel>();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 232,
            selectedIndex: _selectedIndex,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            onDestinationSelected: (i) => context.go(_destinations[i].$1),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.pets, color: Colors.white),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    Text(
                      'AbraçaPets',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Observer(
                    builder: (_) => InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => context.go(AppRoutes.profile),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InitialsAvatar(
                              name: appVm.user?.name ?? '?',
                              radius: 20,
                            ),
                            if (extended) ...[
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appVm.user?.name ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    appVm.user?.role ?? '',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.$2),
                  selectedIcon: Icon(d.$3),
                  label: Text(d.$4),
                ),
            ],
          ),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(child: child),
        ],
      ),
    );
  }
}
