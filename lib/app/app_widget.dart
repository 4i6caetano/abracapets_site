import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../core/theme/app_theme.dart';
import 'app_view_model.dart';
import 'di/locator.dart';
import 'router/app_router.dart';

class AbracaPetsApp extends StatefulWidget {
  const AbracaPetsApp({super.key});

  @override
  State<AbracaPetsApp> createState() => _AbracaPetsAppState();
}

class _AbracaPetsAppState extends State<AbracaPetsApp> {
  final _router = createRouter();
  final _appVm = locator<AppViewModel>();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => MaterialApp.router(
        title: 'AbraçaPets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _appVm.themeMode,
        routerConfig: _router,
        scrollBehavior: const AppScrollBehavior(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}



class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}
