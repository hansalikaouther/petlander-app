import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/animals/screens/add_animal_screen.dart';
import '../../features/animals/screens/animal_detail_screen.dart';
import '../../features/animals/screens/animals_list_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/verify_otp_screen.dart';
import '../../features/consultations/screens/add_consultation_screen.dart';
import '../../features/consultations/screens/consultation_detail_screen.dart';
import '../../features/consultations/screens/consultations_screen.dart';
import '../../features/allergies/screens/allergies_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/dashboard/widgets/main_shell.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/maladies/screens/maladies_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/vet_assistant/screens/vet_assistant_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/screens/standard_reminders_screen.dart';
import '../../features/operations/screens/operations_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/vaccinations/screens/add_vaccination_screen.dart';
import '../../features/vaccinations/screens/recommended_vaccines_screen.dart';
import '../../features/vaccinations/screens/vaccinations_screen.dart';
import '../../features/veterinarians/screens/add_vet_screen.dart';
import '../../features/veterinarians/screens/vets_list_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyOtp = '/verify-otp';
  static const dashboard = '/dashboard';
  static const animals = '/animals';
  static const animalsAdd = '/animals/add';
  static String animalDetail(String id) => '/animals/$id';
  static const vets = '/vets';
  static const vetsAdd = '/vets/add';
  static const appointments = '/appointments';
  static const appointmentsAdd = '/appointments/add';
  static const notifications = '/notifications';
  static const standardReminders = '/reminders/standard';
  static const profile = '/profile';
  static const search = '/search';
  static const about = '/about';
  static const vetAssistant = '/assistant';
  static const changePassword = '/change-password';
  static const resetPassword = '/reset-password';
}

class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootKey = GlobalKey<NavigatorState>();
final _shellDashboardKey = GlobalKey<NavigatorState>();
final _shellAnimalsKey = GlobalKey<NavigatorState>();
final _shellAppointmentsKey = GlobalKey<NavigatorState>();
final _shellProfileKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final loggedIn = authRepo.currentAuthUser != null;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.verifyOtp;
      final isSplash = loc == AppRoutes.splash;
      final isReset = loc == AppRoutes.resetPassword;

      // Lien de réinitialisation cliqué → priorité absolue.
      // On vérifie le JWT (isRecoverySession) ET l'événement stream (lastEvent)
      // car l'événement peut être émis avant que le router ne s'abonne.
      final isRecovery = authRepo.isRecoverySession ||
          authRepo.lastEvent == AuthChangeEvent.passwordRecovery;
      if (isRecovery && !isReset) return AppRoutes.resetPassword;

      if (isSplash) return null;
      if (!loggedIn && !isAuthRoute && !isReset) return AppRoutes.login;
      if (loggedIn && isAuthRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // Routes hors-shell (auth + splash)
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (_, st) => VerifyOtpScreen(
          email: (st.extra as Map<String, dynamic>?)?['email'] as String? ?? '',
        ),
      ),

      // === Shell avec bottom navigation ===
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          // Branche 0 : Dashboard
          StatefulShellBranch(
            navigatorKey: _shellDashboardKey,
            routes: [
              GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const DashboardScreen()),
            ],
          ),
          // Branche 1 : Animaux + sous-écrans médicaux
          StatefulShellBranch(
            navigatorKey: _shellAnimalsKey,
            routes: [
              GoRoute(
                path: AppRoutes.animals,
                builder: (_, _) => const AnimalsListScreen(),
                routes: [
                  GoRoute(path: 'add', builder: (_, _) => const AddAnimalScreen()),
                  GoRoute(
                    path: ':id',
                    builder: (_, st) => AnimalDetailScreen(animalId: st.pathParameters['id']!),
                    routes: [
                      // Vaccinations
                      GoRoute(
                        path: 'vaccinations',
                        builder: (_, st) => VaccinationsScreen(
                            animalId: st.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            path: 'add',
                            builder: (_, st) => AddVaccinationScreen(
                                animalId: st.pathParameters['id']!),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'vaccines/recommended',
                        builder: (_, st) => RecommendedVaccinesScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                      // Consultations
                      GoRoute(
                        path: 'consultations',
                        builder: (_, st) => ConsultationsScreen(
                            animalId: st.pathParameters['id']!),
                        routes: [
                          GoRoute(
                            path: 'add',
                            builder: (_, st) => AddConsultationScreen(
                                animalId: st.pathParameters['id']!),
                          ),
                          GoRoute(
                            path: ':consultationId',
                            builder: (_, st) => ConsultationDetailScreen(
                              animalId: st.pathParameters['id']!,
                              consultationId: st.pathParameters['consultationId']!,
                            ),
                          ),
                        ],
                      ),
                      // Opérations
                      GoRoute(
                        path: 'operations',
                        builder: (_, st) => OperationsScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                      // Croissance
                      GoRoute(
                        path: 'growth',
                        builder: (_, st) => GrowthScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                      // Documents
                      GoRoute(
                        path: 'documents',
                        builder: (_, st) => DocumentsScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                      // Allergies
                      GoRoute(
                        path: 'allergies',
                        builder: (_, st) => AllergiesScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                      // Maladies chroniques
                      GoRoute(
                        path: 'maladies',
                        builder: (_, st) => MaladiesScreen(
                            animalId: st.pathParameters['id']!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // Branche 2 : Rendez-vous
          StatefulShellBranch(
            navigatorKey: _shellAppointmentsKey,
            routes: [
              GoRoute(
                path: AppRoutes.appointments,
                builder: (_, _) => const AppointmentsScreen(),
                routes: [
                  GoRoute(path: 'add', builder: (_, _) => const AddAppointmentScreen()),
                ],
              ),
            ],
          ),
          // Branche 3 : Profil
          StatefulShellBranch(
            navigatorKey: _shellProfileKey,
            routes: [
              GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // Routes hors-shell (push sur le navigator root)
      GoRoute(path: AppRoutes.vets, builder: (_, _) => const VetsListScreen()),
      GoRoute(path: AppRoutes.vetsAdd, builder: (_, _) => const AddVetScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.standardReminders, builder: (_, _) => const StandardRemindersScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(path: AppRoutes.about, builder: (_, _) => const AboutScreen()),
      GoRoute(path: AppRoutes.vetAssistant, builder: (_, _) => const VetAssistantScreen()),
      GoRoute(path: AppRoutes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: AppRoutes.resetPassword, builder: (_, _) => const ResetPasswordScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.uri}')),
    ),
  );
});
