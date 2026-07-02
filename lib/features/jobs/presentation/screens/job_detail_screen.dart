import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ai/ai_service.dart';
import '../providers/apply_status_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/job_list_provider.dart';
import '../widgets/skill_chip.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../tracker/presentation/widgets/memo_card.dart';

// ---------------------------------------------------------------------------
// AI analysis provider (family per jobId)
// ---------------------------------------------------------------------------
final _aiServiceProvider = Provider<AiService>(
  (ref) => AiService(apiKey: const String.fromEnvironment('CLAUDE_API_KEY')),
);

final _aiAnalysisProvider = FutureProvider.family<AiJobAnalysis, String>(
  (ref, jobId) async {
    final jobs = await ref.watch(jobListProvider().future);
    final job = jobs.firstWhere((j) => j.id == jobId);
    final profile = await ref.watch(userProfileNotifierProvider.future);
    final service = ref.read(_aiServiceProvider);

    // Cache key: jobId + user skills fingerprint
    final cacheKey = 'ai_cache_${jobId}_${profile.skills.join(',')}';
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        // dart:convert already imported at top
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return AiJobAnalysis(
          summaryBullets: (map['bullets'] as List).cast<String>(),
          matchScore: map['score'] as int,
          matchReason: map['reason'] as String,
        );
      } catch (_) { /* cache corrupt, re-analyze */ }
    }

    final result = await service.analyze(
      jobTitle: job.title,
      company: job.company,
      description: job.description,
      jobSkills: job.skills,
      userSkills: profile.skills,
    );

    // Store to cache
    // dart:convert already imported at top
    await prefs.setString(cacheKey, jsonEncode({
      'bullets': result.summaryBullets,
      'score': result.matchScore,
      'reason': result.matchReason,
    }));

    return result;
  },
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class JobDetailScreen extends ConsumerWidget {
  const JobDetailScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider());
    final favAsync = ref.watch(favoriteNotifierProvider);
    final isFav = favAsync.valueOrNull?.contains(jobId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('職缺詳情'),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () =>
                ref.read(favoriteNotifierProvider.notifier).toggle(jobId),
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (jobs) {
          final job = jobs.where((j) => j.id == jobId).firstOrNull;
          if (job == null) {
            return const Center(child: Text('找不到此職缺'));
          }

          final colors = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  job.title,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                // Company
                Text(
                  job.company,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                // Meta
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _MetaItem(icon: Icons.location_on_outlined, label: job.location),
                    _MetaItem(icon: Icons.payments_outlined, label: job.salaryRange),
                    _MetaItem(icon: Icons.source_outlined, label: job.source),
                    if (job.isRemote) _RemoteBadge(colors: colors),
                  ],
                ),
                const SizedBox(height: 24),

                // ── AI Analysis Card ──────────────────────────
                _AiAnalysisCard(jobId: jobId),
                const SizedBox(height: 24),

                // Skills
                Text(
                  '技能需求',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: job.skills.map((s) => SkillChip(label: s)).toList(),
                ),
                const SizedBox(height: 24),

                // Apply status
                _ApplyStatusRow(jobId: job.id),
                const SizedBox(height: 16),

                // ── 備忘錄 + 面試時間（M4c）─────────────────
                MemoCard(jobId: job.id),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Description
                Text(
                  '職缺描述',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  job.description,
                  style: textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 32),

                // ── 前往投遞 ─────────────────────────────────
                if (job.url != null && job.url!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(job.url!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('前往投遞'),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Analysis Card widget
// ---------------------------------------------------------------------------
class _AiAnalysisCard extends ConsumerWidget {
  const _AiAnalysisCard({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(_aiAnalysisProvider(jobId));
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: analysisAsync.when(
          loading: () => const Row(
            children: [
              SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('AI 分析中…'),
            ],
          ),
          error: (e, _) => Row(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 18),
              const SizedBox(width: 8),
              Text('AI 分析失敗', style: TextStyle(color: colors.error)),
            ],
          ),
          data: (analysis) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: match score
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'AI 分析',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  _MatchScoreBadge(score: analysis.matchScore, colors: colors),
                ],
              ),
              const SizedBox(height: 12),

              // Match reason
              Text(
                analysis.matchReason,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),

              // Summary bullets
              Text(
                '職缺摘要',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              ...analysis.summaryBullets
                  .where((b) => b.isNotEmpty)
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: colors.primary)),
                            Expanded(
                              child: Text(b,
                                  style: textTheme.bodySmall
                                      ?.copyWith(height: 1.5)),
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchScoreBadge extends StatelessWidget {
  const _MatchScoreBadge({required this.score, required this.colors});
  final int score;
  final ColorScheme colors;

  Color get _color {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '匹配 $score%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _ApplyStatusRow extends ConsumerWidget {
  const _ApplyStatusRow({required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(applyStatusNotifierProvider(jobId));
    final current = statusAsync.valueOrNull ?? ApplyStatus.none;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          '應徵狀態：',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: 8),
        DropdownButton<ApplyStatus>(
          value: current,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(12),
          items: ApplyStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
              .toList(),
          onChanged: (s) {
            if (s != null) {
              ref.read(applyStatusNotifierProvider(jobId).notifier).setStatus(s);
            }
          },
        ),
      ],
    );
  }
}

class _RemoteBadge extends StatelessWidget {
  const _RemoteBadge({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '遠端工作',
        style: TextStyle(
          fontSize: 13,
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
