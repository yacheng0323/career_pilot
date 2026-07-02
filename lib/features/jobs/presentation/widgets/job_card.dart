import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/job.dart';
import '../providers/favorite_provider.dart';
import 'skill_chip.dart';

class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final favAsync = ref.watch(favoriteNotifierProvider);
    final isFav = favAsync.valueOrNull?.contains(job.id) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + source badge + bookmark
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _SourceBadge(source: job.source),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      isFav ? Icons.bookmark : Icons.bookmark_border,
                      color: isFav ? colors.primary : colors.onSurfaceVariant,
                    ),
                    onPressed: () => ref
                        .read(favoriteNotifierProvider.notifier)
                        .toggle(job.id),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Company
              Text(
                job.company,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              // Location + remote + salary
              Wrap(
                spacing: 8,
                children: [
                  _IconLabel(
                    icon: Icons.location_on_outlined,
                    label: job.location,
                  ),
                  if (job.isRemote)
                    _RemoteBadge(colors: colors),
                  _IconLabel(
                    icon: Icons.payments_outlined,
                    label: job.salaryRange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Skill chips (up to 4)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: job.skills
                    .take(4)
                    .map((s) => SkillChip(label: s))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 每個來源對應的顯示名稱與顏色
const _sourceConfig = {
  '104':       (label: '104人力銀行', color: Color(0xFFFF6B00)),   // 104 橘
  'yourator':  (label: 'Yourator',   color: Color(0xFF00A86B)),   // 青綠
  'remotive':  (label: 'Remotive',   color: Color(0xFF7C3AED)),   // 紫
  'arbeitnow': (label: 'Arbeitnow',  color: Color(0xFF2563EB)),   // 藍
  'linkedin':  (label: 'LinkedIn',   color: Color(0xFF0A66C2)),   // LinkedIn 藍
  'cake':      (label: 'CakeResume', color: Color(0xFFF59E0B)),   // 琥珀
};

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final cfg = _sourceConfig[source.toLowerCase()];
    final label = cfg?.label ?? source;
    final color = cfg?.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

class _RemoteBadge extends StatelessWidget {
  const _RemoteBadge({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '遠端',
        style: TextStyle(
          fontSize: 12,
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
