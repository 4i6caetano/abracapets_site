import 'package:abracapets/core/utils/validators.dart';
import 'package:abracapets/data/models/volunteer.dart';
import 'package:abracapets/data/repositories/people_repository.dart';
import 'package:abracapets/data/repositories/session_repository.dart';
import 'package:abracapets/features/volunteers/viewmodels/volunteers_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Regra de senha', () {
    test('exige 8+ caracteres, maiúscula, minúscula e número', () {
      expect(Validators.password('abc123'), isNotNull);
      expect(Validators.password('abcdefgh1'), isNotNull); 
      expect(Validators.password('ABCDEFGH1'), isNotNull); 
      expect(Validators.password('Abcdefghi'), isNotNull); 
      expect(Validators.password('Abcdefg1'), isNull);
    });
  });

  group('Sessões', () {
    late SessionRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = SessionRepository();
      await repo.init();
    });

    test('qualquer e-mail novo cria uma sessão', () async {
      final user = await repo.signIn('ana.paula@ong.org', 'Senha123');
      expect(user.name, 'Ana Paula');
      expect(repo.restore()?.email, 'ana.paula@ong.org');
      expect(repo.accounts, hasLength(1));
    });

    test('e-mail existente exige a mesma senha', () async {
      await repo.signIn('bia@ong.org', 'Senha123');
      await repo.signOut();
      expect(repo.restore(), isNull);
      expect(
        () => repo.signIn('bia@ong.org', 'Outra456'),
        throwsA(isA<AuthException>()),
      );
      final again = await repo.signIn('BIA@ong.org', 'Senha123');
      expect(again.email, 'bia@ong.org');
    });

    test('sessão sobrevive a reabrir o app', () async {
      await repo.signIn('carla@ong.org', 'Senha123');
      final reopened = SessionRepository();
      await reopened.init();
      expect(reopened.restore()?.email, 'carla@ong.org');
    });
  });

  group('Quem está livre?', () {
    late VolunteersViewModel vm;

    setUp(() => vm = VolunteersViewModel(PeopleRepository()));

    test('horário específico mapeia para os turnos cobertos', () {
      expect(
        VolunteersViewModelBase.periodsForRange(14 * 60, 16 * 60),
        {ShiftPeriod.afternoon},
      );
      expect(
        VolunteersViewModelBase.periodsForRange(11 * 60, 13 * 60),
        {ShiftPeriod.morning, ShiftPeriod.afternoon},
      );
    });

    test('horário inválido é recusado', () {
      expect(vm.setCustomTime(16 * 60, 14 * 60), isNotNull);
      expect(vm.hasCustomTime, isFalse);
    });

    test('data fora da semana respeita indisponibilidades', () {
      
      
      vm.setPeriod(ShiftPeriod.morning);
      vm.setCustomDate(DateTime(2026, 11, 21));
      expect(vm.effectiveDay, Weekday.sat);
      expect(vm.available.map((v) => v.name), isNot(contains('Carla Mendes')));
      expect(vm.blockedOnDate.map((v) => v.name), contains('Carla Mendes'));

      
      vm.setCustomDate(DateTime(2026, 11, 28));
      expect(vm.available.map((v) => v.name), contains('Carla Mendes'));
    });
  });
}

