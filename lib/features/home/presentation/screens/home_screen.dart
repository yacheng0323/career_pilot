import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jobs/presentation/providers/job_list_provider.dart';
import '../../../jobs/presentation/widgets/job_card.dart';
import '../../../jobs/presentation/widgets/job_card_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider());
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Pilot'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '今日推薦職缺',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, _) => const JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) => ListView.builder(
                itemCount: jobs.take(10).length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (_, i) => JobCard(job: jobs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
