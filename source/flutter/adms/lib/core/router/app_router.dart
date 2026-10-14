import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../../features/auth/screens/screens.dart';
import '../../features/super_admin/screens/screens.dart';
import '../../features/municipal_admin/screens/municipal_admin_dashboard.dart';
import '../../features/driver/screens/driver_dashboard.dart';
import '../../features/citizen/screens/citizen_dashboard.dart';
import '../../features/citizen/screens/citizen_login_screen.dart';
import '../../features/citizen/screens/incident_tracking_screen.dart';

import '../../features/shared/screens/not_found_screen.dart';

/// App route paths
class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String citizenLogin = '/citizen/login';
  static const String staffLogin = '/staff-login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String pendingApproval = '/pending-approval';

  // Role-based home routes
  static const String superAdminHome = '/super-admin';
  static const String municipalAdminHome = '/municipal-admin';
  static const String driverHome = '/driver';

  // Citizen sub-routes
  static const String citizenHome = '/citizen';
  static const String citizenIncidentTracking = '/citizen/track';

  // Super Admin management sub-routes
  static const String municipalityManagement = '/super-admin/municipalities';
  static const String userManagement = '/super-admin/users';
  static const String systemSettings = '/super-admin/settings';
  static const String reports = '/super-admin/reports';

  /// Get home route for a given role
  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return superAdminHome;
      case UserRole.municipalAdmin:
        return municipalAdminHome;
      case UserRole.driver:
        return driverHome;
      case UserRole.citizen:
        return citizenHome;
    }
  }

  /// Role required to view [location], or null when the location is not
  /// role-scoped (auth pages, welcome).
  ///
  /// Auth routes inside a role prefix (e.g. `/citizen/login`) are explicitly
  /// excluded — they must stay reachable regardless of who is signed in.
  static UserRole? roleForLocation(String location) {
    if (location == citizenLogin) return null;
    if (location == welcome ||
        location == login ||
        location == staffLogin ||
        location == register ||
        location == forgotPassword ||
        location == verifyEmail ||
        location == pendingApproval) {
      return null;
    }
    if (location == superAdminHome || location.startsWith('/super-admin/')) {
      return UserRole.superAdmin;
    }
    if (location == municipalAdminHome ||
        location.startsWith('/municipal-admin/')) {
      return UserRole.municipalAdmin;
    }
    if (location == driverHome || location.startsWith('/driver/')) {
      return UserRole.driver;
    }
    if (location == citizenHome || location.startsWith('/citizen/')) {
      return UserRole.citizen;
    }
    return null;
  }
}

/// Router provider using Riverpod
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Web only: make the browser URL reflect imperative navigations such as
  // `context.push(...)`. go_router defaults this to `false`, which leaves the
  // address bar pointing at the previous location after an in-app push — so a
  // refresh or a shared link would drop the user back on the welcome screen
  // instead of the screen they were on. Setting it to `true` makes the URL a
  // faithful representation of the current route on web; it has no effect on
  // the in-app navigation stack or on mobile/desktop builds.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const NotFoundScreen(),
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) {
      final isPendingApproval = authState is AuthPendingApproval;
      final isNotVerified = authState is AuthNotVerified;

      final isAuthRoute =
          state.matchedLocation == AppRoutes.welcome ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.citizenLogin ||
          state.matchedLocation == AppRoutes.staffLogin ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      // Handle pending approval
      if (isPendingApproval) {
        if (state.matchedLocation != AppRoutes.pendingApproval) {
          return AppRoutes.pendingApproval;
        }
        return null;
      }

      // Handle email not verified
      if (isNotVerified) {
        if (state.matchedLocation != AppRoutes.verifyEmail) {
          return AppRoutes.verifyEmail;
        }
        return null;
      }

      // Redirect authenticated users away from auth pages
      if (authState is AuthAuthenticated && isAuthRoute) {
        return AppRoutes.getHomeRoute(authState.user.role);
      }

      // Redirect unauthenticated users to welcome
      if (authState is AuthUnauthenticated &&
          !isAuthRoute &&
          state.matchedLocation != AppRoutes.pendingApproval &&
          state.matchedLocation != AppRoutes.verifyEmail) {
        return AppRoutes.welcome;
      }

      // Guard role-scoped routes. Role roots and their sub-paths are only
      // reachable by the owning role (superAdmin: /super-admin*,
      // municipalAdmin: /municipal-admin*, driver: /driver*, citizen:
      // /citizen*). Anyone else is bounced to their own home. RTDB rules are
      // the authoritative data boundary; this keeps the UI from rendering
      // screens whose queries would all be permission-denied.
      if (authState is AuthAuthenticated) {
        final requiredRole = AppRoutes.roleForLocation(state.matchedLocation);
        if (requiredRole != null && authState.user.role != requiredRole) {
          return AppRoutes.getHomeRoute(authState.user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final role = roleParam != null
              ? UserRole.values.firstWhere(
                  (r) => r.name == roleParam,
                  orElse: () => UserRole.citizen,
                )
              : UserRole.citizen;
          return LoginScreen(role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final role = roleParam != null
              ? UserRole.values.firstWhere(
                  (r) => r.name == roleParam,
                  orElse: () => UserRole.citizen,
                )
              : UserRole.citizen;
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        name: 'pendingApproval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffLogin,
        name: 'staffLogin',
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminHome,
        name: 'superAdminHome',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.municipalityManagement,
        name: 'municipalityManagement',
        builder: (context, state) => const MunicipalityManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'userManagement',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.systemSettings,
        name: 'systemSettings',
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.municipalAdminHome,
        name: 'municipalAdminHome',
        builder: (context, state) => const MunicipalAdminDashboard(),
      ),
      GoRoute(
        path: AppRoutes.driverHome,
        name: 'driverHome',
        builder: (context, state) => const DriverDashboard(),
      ),
      GoRoute(
        path: AppRoutes.citizenHome,
        name: 'citizenHome',
        builder: (context, state) => const CitizenDashboard(),
      ),
      GoRoute(
        path: AppRoutes.citizenLogin,
        name: 'citizenLogin',
        builder: (context, state) => const CitizenLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.citizenIncidentTracking,
        name: 'citizenIncidentTracking',
        builder: (context, state) {
          final municipalityId =
              state.uri.queryParameters['municipalityId'] ?? '';
          final incidentId = state.uri.queryParameters['incidentId'] ?? '';
          return IncidentTrackingScreen(
            municipalityId: municipalityId,
            incidentId: incidentId,
          );
        },
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
