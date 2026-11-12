import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_view_model.dart';
import '../../../app/di/locator.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_nested_scaffold.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/dialogs.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _appVm = locator<AppViewModel>();
  late final _vm = SettingsViewModel(_appVm);

  Future<void> _logout() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Sair do sistema?',
      message: 'Você precisará entrar novamente com e-mail e senha.',
      confirmLabel: 'Sair',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _vm.logout();
    context.go(AppRoutes.login);
  }

  void _openItem(SettingItem item) {
    switch (item.id) {
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: 'AbraçaPets',
          applicationVersion: '0.3 (protótipo)',
          applicationIcon: const Icon(Icons.pets, color: AppColors.primary, size: 40),
          children: const [
            Text('Gestão interna de resgate de animais: fichas, prontuários, '
                'lares, voluntários e finanças com transparência.'),
          ],
        );
      default:
        showMessage(context, '${item.title}: disponível na próxima versão',
            icon: Icons.construction);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => AppNestedScaffold(
        title: 'Configurações',
        subtitle: 'Preferências do app e da conta',
        headerHeight: 76,
        bottomHeight: 48,
        bottom: AppSearchField(
          hint: 'Pesquisar configurações...',
          onChanged: _vm.setQuery,
        ),
        maxContentWidth: 820,
        slivers: [
          if (_vm.query.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    onTap: () => context.go(AppRoutes.profile),
                    leading: InitialsAvatar(name: _appVm.user?.name ?? '?', radius: 26),
                    title: Text(
                      _appVm.user?.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text('Perfil de acesso: ${_appVm.user?.role ?? ''}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          if (_vm.sections.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Nenhuma configuração encontrada',
                message: 'Tente "tema", "notificações" ou "vacina".',
              ),
            ),
          for (final entry in _vm.sections.entries) ...[
            SliverToBoxAdapter(child: SectionTitle(entry.key)),
            SliverToBoxAdapter(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < entry.value.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 56),
                      _tile(entry.value[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair do sistema'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'AbraçaPets · versão 0.3 (protótipo)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(SettingItem item) {
    final subtitle = item.subtitle == null ? null : Text(item.subtitle!);
    if (item.kind == SettingKind.toggle) {
      return Observer(
        builder: (_) => SwitchListTile(
          secondary: Icon(item.icon),
          title: Text(item.title),
          subtitle: subtitle,
          value: _vm.valueOf(item.id),
          onChanged: (v) => _vm.toggle(item.id, v),
        ),
      );
    }
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _openItem(item),
    );
  }
}
