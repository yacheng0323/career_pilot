import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/domain/job.dart';
import '../../../jobs/presentation/providers/apply_status_provider.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';
import '../../domain/job_memo.dart';
import '../providers/job_memo_provider.dart';
import '../widgets/memo_card.dart' show formatInterviewAt;

Color urgencyColor(InterviewUrgency urgency) => switch (urgency) {
      InterviewUrgency.past => const Color(0xFF9CA3AF),
      InterviewUrgency.imminent => const Color(0xFFEF4444),
      InterviewUrgency.soon => const Color(0xFFF97316),
      InterviewUrgency.scheduled => const Color(0xFF3B82F6),
    };

const _columns = [
  (status: ApplyStatus.wantToApply, label: '想投',  color: Color(0xFF3B82F6)),
  (status: ApplyStatus.applied,     label: '已投',  color: Color(0xFFF59E0B)),
  (status: ApplyStatus.interview,   label: '面試',  color: Color(0xFF8B5CF6)),
  (status: ApplyStatus.rejected,    label: '結果',  color: Color(0xFF6B7280)),
];

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider());

    return Scaffold(
      appBar: AppBar(title: const Text('求職追蹤'), elevation: 0),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (jobs) {
          final tracked = jobs.where((j) {
            final s = ref.read(applyStatusNotifierProvider(j.id)).valueOrNull;
            return s != null && s != ApplyStatus.none;
          }).toList();

          if (tracked.isEmpty) return const _EmptyTracker();

          return Column(
            children: [
              _UpcomingBanner(jobs: tracked),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  children: _columns.map((col) {
                    final colJobs = tracked.where((j) {
                      final s =
                          ref.read(applyStatusNotifierProvider(j.id)).valueOrNull;
                      return s == col.status;
                    }).toList();
                    return _KanbanColumn(
                      label: col.label,
                      color: col.color,
                      status: col.status,
                      jobs: colJobs,
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({
    required this.label, required this.color,
    required this.status, required this.jobs,
  });
  final String label;
  final Color color;
  final ApplyStatus status;
  final List<Job> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Job>(
      onAcceptWithDetails: (details) {
        ref.read(applyStatusNotifierProvider(details.data.id).notifier)
            .setStatus(status);
      },
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(label,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${jobs.length}',
                          style: TextStyle(
                            fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _KanbanCard(job: jobs[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Job>(
      data: job,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 200, child: _CardContent(job: job)),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _CardContent(job: job)),
      child: GestureDetector(
        onTap: () => context.push('/jobs/${job.id}'),
        child: _CardContent(job: job),
      ),
    );
  }
}

class _CardContent extends ConsumerWidget {
  const _CardContent({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final memo = ref.watch(jobMemoNotifierProvider(job.id)).valueOrNull;
    final interviewAt = memo?.interviewAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(job.company,
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 12, color: colors.onSurfaceVariant),
              const SizedBox(width: 2),
              Expanded(
                child: Text(job.location,
                    style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            if (interviewAt != null) ...[
              const SizedBox(height: 6),
              _InterviewChip(interviewAt: interviewAt),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterviewChip extends StatelessWidget {
  const _InterviewChip({required this.interviewAt});
  final DateTime interviewAt;

  @override
  Widget build(BuildContext context) {
    final color = urgencyColor(interviewUrgency(interviewAt, DateTime.now()));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '面試 ${formatInterviewAt(interviewAt)}',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 未來 7 天內有面試的職缺提醒。
class _UpcomingBanner extends ConsumerWidget {
  const _UpcomingBanner({required this.jobs});
  final List<Job> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final upcoming = <({Job job, DateTime at})>[];
    for (final job in jobs) {
      final at =
          ref.watch(jobMemoNotifierProvider(job.id)).valueOrNull?.interviewAt;
      if (at == null) continue;
      final urgency = interviewUrgency(at, now);
      if (urgency == InterviewUrgency.imminent ||
          urgency == InterviewUrgency.soon) {
        upcoming.add((job: job, at: at));
      }
    }
    if (upcoming.isEmpty) return const SizedBox.shrink();
    upcoming.sort((a, b) => a.at.compareTo(b.at));

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 16, color: colors.onTertiaryContainer),
              const SizedBox(width: 6),
              Text('即將面試',
                  style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onTertiaryContainer)),
            ],
          ),
          const SizedBox(height: 6),
          ...upcoming.map((e) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${formatInterviewAt(e.at)}　${e.job.title}｜${e.job.company}',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colors.onTertiaryContainer),
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyTracker extends StatelessWidget {
  const _EmptyTracker();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 72,
                color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('還沒有追蹤中的職缺',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('在職缺詳情頁設定應徵狀態\n職缺就會出現在這裡',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
