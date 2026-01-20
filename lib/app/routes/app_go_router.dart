import 'package:go_router/go_router.dart';
import 'package:realtime_location_tracking/app/routes/app_routes.dart';
import 'package:realtime_location_tracking/features/admin/AdminLiveLocationListScreen.dart';
import 'package:realtime_location_tracking/features/auth/login.dart';
import 'package:realtime_location_tracking/features/splash/splash_screen.dart';
import 'package:realtime_location_tracking/features/home/home_screen.dart';
import 'package:realtime_location_tracking/features/profile/profile_screen.dart';
import 'package:realtime_location_tracking/features/reports/submitted_reports_screen.dart';
import 'package:realtime_location_tracking/features/home/admin_home_screen.dart';
import 'package:realtime_location_tracking/features/admin/user_list_screen.dart';
import 'package:realtime_location_tracking/features/reports/admin_reports_screen.dart';
import 'package:realtime_location_tracking/features/admin/location_history_screen.dart';

class AppGoRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.submitted,
        name: AppRouteNames.submitted,
        builder: (context, state) => const SubmittedReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        name: AppRouteNames.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.adminUsers,
            name: AppRouteNames.adminUsers,
            builder: (context, state) => const UserListScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminReports,
            name: AppRouteNames.adminReports,
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.locationHistory,
            name: AppRouteNames.locationHistory,
            builder: (context, state) => const LocationHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminLiveLocation,
            name: AppRouteNames.adminLiveLocation,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return AdminLiveLocationListScreen(
                userAuthUid: extra['userAuthUid'] as String,
                userName: extra['userName'] as String,
              );
            },
          ),
        ],
      ),
    ],
  );
}
