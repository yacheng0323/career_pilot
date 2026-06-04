import 'package:go_router/go_router.dart';

import '../features/jobs/presentation/screens/job_detail_screen.dart';
import '../features/jobs/presentation/screens/job_list_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const JobListScreen(),
    ),
    GoRoute(
      path: '/jobs/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return JobDetailScreen(jobId: id);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
