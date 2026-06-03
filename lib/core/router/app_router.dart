import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/tracker/presentation/pages/all_tracker_page.dart';
import '../../features/tracker/presentation/pages/symptom_tracker_page.dart';
import '../../features/tracker/presentation/pages/mood_tracker_page.dart';
import '../../features/tracker/presentation/pages/sleep_tracker_page.dart';
import '../../features/tracker/presentation/pages/vitals_tracker_page.dart';
import '../../features/tracker/presentation/pages/nutrition_tracker_page.dart';
import '../../features/reports/presentation/pages/weekly_report_page.dart';
import '../../features/consultation/presentation/pages/consultation_page.dart';
import '../../features/consultation/presentation/pages/doctor_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/manage_profile_page.dart';
import '../../features/profile/presentation/pages/account_management_page.dart';
import '../../features/profile/presentation/pages/change_email_page.dart';
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/debug/presentation/pages/database_inspector_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/tracker',
        builder: (context, state) => const AllTrackerPage(),
      ),
      GoRoute(
        path: '/symptom',
        builder: (context, state) => const SymptomTrackerPage(),
      ),
      GoRoute(
        path: '/mood',
        builder: (context, state) => const MoodTrackerPage(),
      ),
      GoRoute(
        path: '/sleep',
        builder: (context, state) => const SleepTrackerPage(),
      ),
      GoRoute(
        path: '/vitals',
        builder: (context, state) => const VitalsTrackerPage(),
      ),
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const NutritionTrackerPage(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const WeeklyReportPage(),
      ),
      GoRoute(
        path: '/consult',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'];
          return ConsultationPage(initialCategory: category);
        },
      ),
      GoRoute(
        path: '/doctor_profile',
        builder: (context, state) {
          final name = state.uri.queryParameters['name'] ?? 'Dr. Sarah Wijaya';
          final spec =
              state.uri.queryParameters['spec'] ?? 'Spesialis Gizi Klinik';
          final exp = state.uri.queryParameters['exp'] ?? '8 Thn';
          final img =
              state.uri.queryParameters['img'] ??
              'https://images.unsplash.com/photo-1559839734-2b71f1536783?q=80&w=200';
          final phone = state.uri.queryParameters['phone'] ?? '6285176914026';
          return DoctorProfilePage(
            name: name,
            spec: spec,
            exp: exp,
            img: img,
            phone: phone,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/manage_profile',
        builder: (context, state) => const ManageProfilePage(),
      ),
      GoRoute(
        path: '/account_management',
        builder: (context, state) => const AccountManagementPage(),
      ),
      GoRoute(
        path: '/change_email',
        builder: (context, state) => const ChangeEmailPage(),
      ),
      GoRoute(
        path: '/change_password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/debug_db',
        builder: (context, state) => const DatabaseInspectorPage(),
      ),
    ],
  );
}
