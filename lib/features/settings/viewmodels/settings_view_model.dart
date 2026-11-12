import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../../app/app_view_model.dart';

part 'settings_view_model.g.dart';

enum SettingKind { toggle, navigation, info }

class SettingItem {
  const SettingItem({
    required this.id,
    required this.section,
    required this.title,
    required this.icon,
    required this.kind,
    this.subtitle,
    this.keywords = const [],
  });

  final String id;
  final String section;
  final String title;
  final String? subtitle;
  final IconData icon;
  final SettingKind kind;
  final List<String> keywords;
}

class SettingsViewModel = SettingsViewModelBase with _$SettingsViewModel;

abstract class SettingsViewModelBase with Store {
  SettingsViewModelBase(this._app);

  final AppViewModel _app;

  static const items = [
    SettingItem(id: 'notif_requests', section: 'Notificações', title: 'Novas solicitações', subtitle: 'Adoção, voluntariado e denúncias', icon: Icons.mark_email_unread_outlined, kind: SettingKind.toggle, keywords: ['alerta', 'adoção']),
    SettingItem(id: 'notif_vaccines', section: 'Notificações', title: 'Vacinas e retornos', subtitle: 'Avisar 7 dias antes do vencimento', icon: Icons.vaccines_outlined, kind: SettingKind.toggle, keywords: ['prontuário', 'veterinário']),
    SettingItem(id: 'notif_invoice', section: 'Notificações', title: 'Gastos sem nota fiscal', icon: Icons.receipt_long_outlined, kind: SettingKind.toggle, keywords: ['financeiro', 'despesas']),
    SettingItem(id: 'notif_restricted', section: 'Notificações', title: 'Alertas da lista restrita', subtitle: 'Sempre recomendado', icon: Icons.block, kind: SettingKind.toggle, keywords: ['segurança', 'bloqueados']),
    SettingItem(id: 'dark_mode', section: 'Aparência', title: 'Tema escuro', icon: Icons.dark_mode_outlined, kind: SettingKind.toggle, keywords: ['cores', 'noite', 'tema']),
    SettingItem(id: 'compact', section: 'Aparência', title: 'Listas compactas', icon: Icons.density_medium, kind: SettingKind.toggle, keywords: ['densidade']),
    SettingItem(id: 'about', section: 'Sobre', title: 'Sobre o AbraçaPets', subtitle: 'Versão 0.3 (protótipo)', icon: Icons.info_outline, kind: SettingKind.info, keywords: ['versão']),
  ];

  @observable
  String query = '';

  final toggles = ObservableMap<String, bool>.of({
    'notif_requests': true,
    'notif_vaccines': true,
    'notif_invoice': false,
    'notif_restricted': true,
    'compact': false,
  });

  bool valueOf(String id) =>
      id == 'dark_mode' ? _app.isDark : (toggles[id] ?? false);

  @computed
  Map<String, List<SettingItem>> get sections {
    final q = query.trim().toLowerCase();
    final result = <String, List<SettingItem>>{};
    for (final item in items) {
      final match = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.section.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false) ||
          item.keywords.any((k) => k.contains(q));
      if (match) result.putIfAbsent(item.section, () => []).add(item);
    }
    return result;
  }

  @action
  void setQuery(String v) => query = v;

  @action
  void toggle(String id, bool value) {
    if (id == 'dark_mode') {
      _app.toggleTheme(value);
    } else {
      toggles[id] = value;
    }
  }

  @action
  void logout() => _app.signOut();
}
