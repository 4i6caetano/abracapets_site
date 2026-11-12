
abstract final class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';

  static const pets = '/pets';
  static const petNew = '/pets/new';
  static String petDetail(String id) => '/pets/$id';
  static String petEdit(String id) => '/pets/$id/edit';

  static const finance = '/finance';
  static const donations = '/finance/donations';

  static const volunteers = '/volunteers';
  static String volunteer(String id) => '/volunteers/$id';

  static const housing = '/housing';
  static String home(String id) => '/housing/home/$id';
  static String person(String id) => '/housing/person/$id';

  static const showcase = '/showcase';
  static const postNew = '/showcase/post/new';
  static String postEdit(String id) => '/showcase/post/$id';

  static const settings = '/settings';
  static const profile = '/profile';
}
