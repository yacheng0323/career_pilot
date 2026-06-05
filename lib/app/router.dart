import 'package:go_router/go_router.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/jobs/presentation/screens/explore_screen.dart';
import '../features/jobs/presentation/screens/job_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/tracker/presentation/screens/tracker_screen.dart';
import 'shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // Full-screen（不顯示 BottomNavBar）
    GoRoute(
      path: '/jobs/:id',
      builder: (context, state) =>
          JobDetailScreen(jobId: state.pathParameters['id']!),
    ),
    // Shell（顯示 BottomNavBar）
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/explore', builder: (_, _) => const ExploreScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/tracker', builder: (_, _) => const TrackerScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
);
