import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _skillController = TextEditingController();

  @override
  void dispose() {
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isEmpty) return;
    ref.read(userProfileNotifierProvider.notifier).addSkill(skill);
    _skillController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('我的技能檔案')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('錯誤：$e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('我的技能', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Skill input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _skillController,
                    decoration: InputDecoration(
                      hintText: '輸入技能（如 Flutter、Python）',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _addSkill(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addSkill,
                  child: const Text('新增'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Skill chips
            if (profile.skills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    '尚未新增任何技能\n新增技能後可查看職缺匹配度',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.skills
                    .map(
                      (s) => Chip(
                        label: Text(s),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => ref
                            .read(userProfileNotifierProvider.notifier)
                            .removeSkill(s),
                        backgroundColor: colors.primaryContainer,
                        labelStyle: TextStyle(color: colors.onPrimaryContainer),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 32),
            // Common skill suggestions
            Text('快速新增常用技能', style: textTheme.titleSmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedSkills
                  .where((s) => !profile.skills.contains(s))
                  .map(
                    (s) => ActionChip(
                      label: Text(s),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: () => ref
                          .read(userProfileNotifierProvider.notifier)
                          .addSkill(s),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static const _suggestedSkills = [
    'Flutter', 'Dart', 'Swift', 'Kotlin', 'React', 'TypeScript',
    'Node.js', 'Python', 'Go', 'PostgreSQL', 'Docker', 'AWS',
    'Firebase', 'Riverpod', 'GraphQL',
  ];
}
