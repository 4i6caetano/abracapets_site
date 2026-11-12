import 'package:abracapets/app/app_widget.dart';
import 'package:abracapets/app/di/locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await initializeDateFormatting('pt_BR');
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    await setupLocator();
  });

  testWidgets('abre na tela de login', (tester) async {
    await tester.pumpWidget(const AbracaPetsApp());
    await tester.pumpAndSettle();
    expect(find.text('Acesso à equipe'), findsOneWidget);
  });

  testWidgets('senha fraca bloqueia; senha forte cria sessão e entra',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AbracaPetsApp());
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nova.pessoa@ong.org');
    await tester.enterText(fields.at(1), 'fraca1');
    await tester.tap(find.text('Criar sessão e entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A senha precisa de'), findsOneWidget);

    await tester.enterText(fields.at(1), 'Forte1234');
    await tester.tap(find.text('Criar sessão e entrar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nova'), findsWidgets); 
    expect(find.text('Módulos de gestão'), findsOneWidget);
  });

  testWidgets('módulos abrem sem erros em tela de celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AbracaPetsApp());
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'teste@ong.org');
    await tester.enterText(fields.at(1), 'Teste1234');
    await tester.tap(find.text('Criar sessão e entrar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    for (final module in [
      'Animais',
      'Voluntários',
      'Lares',
      'Financeiro',
      'Vitrine & Blog',
      'Configurações',
    ]) {
      await tester.tap(find.text(module).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    }
    expect(find.text('Módulos de gestão'), findsOneWidget);
  });
}
