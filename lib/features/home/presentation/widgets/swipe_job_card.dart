import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/domain/job.dart';
import '../../../jobs/presentation/widgets/skill_chip.dart';

class SwipeJobCard extends StatelessWidget {
  const SwipeJobCard({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SourceChip(source: job.source),
                  const SizedBox(height: 12),
                  Text(
                    job.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job.company,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12, runSpacing: 8,
                      children: [
                        _MetaChip(icon: Icons.location_on_outlined, label: job.location),
                        _MetaChip(
                          icon: Icons.payments_outlined,
                          label: job.salaryRange.isEmpty ? '薪資面議' : job.salaryRange,
                        ),
                        if (job.isRemote)
                          _MetaChip(icon: Icons.wifi_outlined, label: '遠端', highlighted: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (job.skills.isNotEmpty) ...[
                      Text('所需技能',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: job.skills.take(6).map((s) => SkillChip(label: s)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: Text(
                        job.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant, height: 1.5),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    Center(
                      child: Text('點擊查看完整職缺',
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.6))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _sourceConfig = {
  '104':       (label: '104人力銀行', color: Color(0xFFFF6B00)),
  'yourator':  (label: 'Yourator',   color: Color(0xFF00A86B)),
  'remotive':  (label: 'Remotive',   color: Color(0xFF7C3AED)),
  'arbeitnow': (label: 'Arbeitnow',  color: Color(0xFF2563EB)),
};

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;
  @override
  Widget build(BuildContext context) {
    final cfg = _sourceConfig[source.toLowerCase()];
    final label = cfg?.label ?? source;
    final color = cfg?.color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.highlighted = false});
  final IconData icon;
  final String label;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = highlighted ? colors.tertiary : colors.onSurfaceVariant;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color, fontWeight: highlighted ? FontWeight.w600 : null)),
    ]);
  }
}
