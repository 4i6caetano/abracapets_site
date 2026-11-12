import 'package:get_it/get_it.dart';

import '../../data/repositories/animal_repository.dart';
import '../../data/repositories/blog_repository.dart';
import '../../data/repositories/finance_repository.dart';
import '../../data/repositories/people_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../features/notifications/viewmodels/notifications_view_model.dart';
import '../app_view_model.dart';

final locator = GetIt.instance;

Future<void> setupLocator() async {
  final sessions = SessionRepository();
  await sessions.init();

  locator
    ..registerSingleton<SessionRepository>(sessions)
    ..registerLazySingleton(AnimalRepository.new)
    ..registerLazySingleton(FinanceRepository.new)
    ..registerLazySingleton(PeopleRepository.new)
    ..registerLazySingleton(BlogRepository.new)
    ..registerLazySingleton(() => AppViewModel(locator()))
    ..registerLazySingleton(
      () => NotificationsViewModel(locator(), locator(), locator()),
    );
}
