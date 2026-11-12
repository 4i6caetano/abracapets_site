import 'package:go_router/go_router.dart';

import '../../core/widgets/adaptive_shell.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/finance/pages/donations_page.dart';
import '../../features/finance/pages/finance_page.dart';
import '../../features/housing/pages/home_profile_page.dart';
import '../../features/housing/pages/housing_page.dart';
import '../../features/housing/pages/person_profile_page.dart';
import '../../features/pets/pages/pet_detail_page.dart';
import '../../features/pets/pages/pet_edit_page.dart';
import '../../features/pets/pages/pets_page.dart';
import '../../features/profile/pages/user_profile_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/showcase/pages/post_editor_page.dart';
import '../../features/showcase/pages/showcase_page.dart';
import '../../features/volunteers/pages/volunteer_profile_page.dart';
import '../../features/volunteers/pages/volunteers_page.dart';
import '../app_view_model.dart';
import '../di/locator.dart';
import 'app_routes.dart';

GoRouter createRouter() {
  final appVm = locator<AppViewModel>();

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppRoutes.login;
      if (!appVm.isLoggedIn && !loggingIn) return AppRoutes.login;
      if (appVm.isLoggedIn && loggingIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
            routes: [
              GoRoute(
                path: 'pets',
                builder: (context, state) => const PetsPage(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PetEditPage(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        PetDetailPage(petId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) =>
                            PetEditPage(petId: state.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'finance',
                builder: (context, state) => const FinancePage(),
                routes: [
                  GoRoute(
                    path: 'donations',
                    builder: (context, state) => const DonationsPage(),
                  ),
                ],
              ),
              GoRoute(
                path: 'volunteers',
                builder: (context, state) => const VolunteersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => VolunteerProfilePage(
                      volunteerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'housing',
                builder: (context, state) => const HousingPage(),
                routes: [
                  GoRoute(
                    path: 'home/:id',
                    builder: (context, state) =>
                        HomeProfilePage(homeId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'person/:id',
                    builder: (context, state) => PersonProfilePage(
                      personId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'showcase',
                builder: (context, state) => const ShowcasePage(),
                routes: [
                  GoRoute(
                    path: 'post/new',
                    builder: (context, state) => const PostEditorPage(),
                  ),
                  GoRoute(
                    path: 'post/:id',
                    builder: (context, state) =>
                        PostEditorPage(postId: state.pathParameters['id']),
                  ),
                ],
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const UserProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
