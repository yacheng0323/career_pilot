import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../jobs/presentation/providers/apply_status_provider.dart';
import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl     = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _salaryCtrl   = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _skillCtrl    = TextEditingController();
  bool _initialized   = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose();
    _salaryCtrl.dispose(); _locationCtrl.dispose(); _skillCtrl.dispose();
    super.dispose();
  }

  void _initControllers(dynamic profile) {
    if (_initialized) return;
    _nameCtrl.text     = profile.name;
    _bioCtrl.text      = profile.bio;
    _salaryCtrl.text   = profile.expectedSalary;
    _locationCtrl.text = profile.expectedLocation;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      await ref.read(userProfileNotifierProvider.notifier).setAvatarPath(image.path);
    }
  }

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isEmpty) return;
    ref.read(userProfileNotifierProvider.notifier).addSkill(s);
    _skillCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final jobsAsync = ref.watch(jobListProvider());
    final colors    = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sync      = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('個人中心'), elevation: 0),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          _initControllers(profile);
          final jobs = jobsAsync.valueOrNull ?? [];
          int appliedCount = 0, interviewCount = 0;
          for (final j in jobs) {
            final s = ref.read(applyStatusNotifierProvider(j.id)).valueOrNull;
            if (s == ApplyStatus.applied || s == ApplyStatus.interview || s == ApplyStatus.rejected) appliedCount++;
            if (s == ApplyStatus.interview) interviewCount++;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar + Name ─────────────────────────────
              Center(child: Column(children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: profile.avatarPath != null
                          ? FileImage(File(profile.avatarPath!)) : null,
                      backgroundColor: colors.primary,
                      child: profile.avatarPath == null
                          ? Icon(Icons.person, size: 48, color: colors.onPrimary) : null,
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: CircleAvatar(radius: 14,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(Icons.camera_alt, size: 14, color: colors.primary))),
                  ]),
                ),
                const SizedBox(height: 12),
                _EditableField(
                  controller: _nameCtrl, hint: '你的名字',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  onSubmitted: (v) => ref.read(userProfileNotifierProvider.notifier).setName(v),
                ),
                const SizedBox(height: 4),
                _EditableField(
                  controller: _bioCtrl, hint: '一句話介紹自己…',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  onSubmitted: (v) => ref.read(userProfileNotifierProvider.notifier).setBio(v),
                ),
              ])),
              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────────
              Card(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: '已收藏', value: '${favIds.length}', color: colors.primary),
                    _StatItem(label: '已投遞', value: '$appliedCount',    color: const Color(0xFFF59E0B)),
                    _StatItem(label: '面試中', value: '$interviewCount',  color: const Color(0xFF8B5CF6)),
                  ],
                ),
              )),
              const SizedBox(height: 24),

              // ── 求職偏好 ───────────────────────────────────
              _SectionTitle('求職偏好'),
              const SizedBox(height: 8),
              _LabeledField(
                icon: Icons.payments_outlined, label: '期望薪資',
                controller: _salaryCtrl, hint: '例：80K–120K',
                onSubmitted: (v) => ref.read(userProfileNotifierProvider.notifier).setExpectedSalary(v),
              ),
              const SizedBox(height: 8),
              _LabeledField(
                icon: Icons.location_on_outlined, label: '期望地點',
                controller: _locationCtrl, hint: '例：台北市、遠端',
                onSubmitted: (v) => ref.read(userProfileNotifierProvider.notifier).setExpectedLocation(v),
              ),
              const SizedBox(height: 24),

              // ── 技能 ──────────────────────────────────────
              _SectionTitle('我的技能'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _skillCtrl,
                    decoration: const InputDecoration(hintText: '輸入技能…'),
                    onSubmitted: (_) => _addSkill(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addSkill, child: const Text('新增')),
              ]),
              const SizedBox(height: 8),
              if (profile.skills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('尚未新增技能',
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                )
              else
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: profile.skills.map((s) => Chip(
                    label: Text(s),
                    onDeleted: () => ref.read(userProfileNotifierProvider.notifier).removeSkill(s),
                    backgroundColor: colors.primaryContainer,
                    labelStyle: TextStyle(color: colors.onPrimaryContainer),
                  )).toList(),
                ),
              const SizedBox(height: 24),

              // ── 設定 ──────────────────────────────────────
              _SectionTitle('設定'),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('同步職缺'),
                subtitle: sync.lastSyncTime != null
                    ? Text('上次：${_fmtTime(sync.lastSyncTime!)}')
                    : const Text('尚未同步'),
                trailing: sync.status == SyncStatus.syncing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right),
                onTap: sync.status == SyncStatus.syncing
                    ? null
                    : () => ref.read(syncNotifierProvider.notifier).sync(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('關於 Career Pilot'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Career Pilot',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.month}/${t.day} ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ));
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    const SizedBox(height: 4),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller, required this.hint,
    this.textAlign = TextAlign.start, this.style,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;
  final TextStyle? style;
  final ValueChanged<String> onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, textAlign: textAlign, style: style,
    decoration: InputDecoration(hintText: hint, border: InputBorder.none, filled: false),
    onSubmitted: onSubmitted,
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.icon, required this.label, required this.controller,
    required this.hint, required this.onSubmitted,
  });
  final IconData icon;
  final String label, hint;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
    const SizedBox(width: 8),
    SizedBox(width: 70, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
    Expanded(child: TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hint, border: InputBorder.none, filled: false),
      onSubmitted: onSubmitted,
    )),
  ]);
}
