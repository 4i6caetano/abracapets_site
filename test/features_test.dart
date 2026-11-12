import 'package:abracapets/app/di/locator.dart';
import 'package:abracapets/core/widgets/detail_sheet.dart';
import 'package:abracapets/data/mock/mock_data.dart';
import 'package:abracapets/data/models/finance.dart';
import 'package:abracapets/data/models/request.dart';
import 'package:abracapets/data/repositories/animal_repository.dart';
import 'package:abracapets/data/repositories/finance_repository.dart';
import 'package:abracapets/features/finance/pages/finance_page.dart';
import 'package:abracapets/features/finance/services/report_pdf_service.dart';
import 'package:abracapets/features/notifications/viewmodels/notifications_view_model.dart';
import 'package:abracapets/features/pets/pages/pet_edit_page.dart';
import 'package:abracapets/features/showcase/pages/showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() async {
    await initializeDateFormatting('pt_BR');
    SharedPreferences.setMockInitialValues({});
    await locator.reset();
    await setupLocator();
  });

  testWidgets('remover foto apaga a miniatura clicada, não a última',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const PetEditPage(petId: 'a1')));
    await tester.pumpAndSettle();

    
    expect(find.byKey(ValueKey(catPhoto(2))), findsWidgets);
    await tester.tap(find.byTooltip('Remover foto').at(1));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey(catPhoto(2))), findsNothing);
    expect(find.byKey(ValueKey(catPhoto(1))), findsWidgets);
    expect(find.byKey(ValueKey(catPhoto(3))), findsWidgets);
  });

  testWidgets('blog em feed de coluna única sem overflow', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const ShowcasePage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blog'));
    await tester.pumpAndSettle();
    
    expect(find.text('Feira de adoção no Shopping – sábado!'), findsWidgets);
    final last = find.text('Por que castrar seu pet?');
    for (var i = 0; i < 12 && last.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(TabBarView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(last, findsWidgets);
  });

  testWidgets('tocar em um lançamento abre o sheet de detalhes',
      (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(const FinancePage()));
    await tester.pumpAndSettle();

    final entry = find.text('Doação Pix – João S.');
    await tester.scrollUntilVisible(entry, 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(DetailSheet), findsOneWidget);
    expect(find.text('Doador'), findsOneWidget);
  });

  test('notificações agrupam solicitações, saúde e financeiro', () {
    final vm = NotificationsViewModel(locator(), locator(), locator());
    expect(vm.all.whereType<AppNotification>(), isNotEmpty);
    expect(vm.all.any((n) => n.payload is AppRequest), isTrue);
    expect(vm.all.any((n) => n.payload is Expense), isTrue);
    expect(vm.unreadCount, vm.all.length);
    vm.markRead(vm.all.first);
    expect(vm.unreadCount, vm.all.length - 1);
    vm.markAllRead();
    expect(vm.unreadCount, 0);
  });

  test('relatório gera um PDF válido', () async {
    final finance = locator<FinanceRepository>();
    final animals = locator<AnimalRepository>();
    final month = DateTime(2026, 11);
    final bytes = await const ReportPdfService().build(
      month: month,
      donations: finance.donations
          .where((d) => d.date.month == 11 && d.date.year == 2026)
          .toList(),
      expenses: finance.expenses
          .where((e) => e.date.month == 11 && e.date.year == 2026)
          .toList(),
      categoryTotals: {
        for (final c in ExpenseCategory.values)
          c: finance.expenses
              .where((e) =>
                  e.category == c && e.date.month == 11 && e.date.year == 2026)
              .fold(0.0, (s, e) => s + e.amount),
      },
      includeDonorNames: true,
      animalName: (id) => animals.byId(id)?.name ?? '—',
      generatedBy: 'Teste',
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
