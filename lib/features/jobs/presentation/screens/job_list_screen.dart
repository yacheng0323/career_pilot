import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../sync/presentation/providers/sync_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/job_list_provider.dart';
import '../widgets/job_card.dart';

class JobListScreen extends ConsumerStatefulWidget {
  const JobListScreen({super.key});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _remoteOnly = false;
  bool _favOnly = false;
  String? _locationFilter;
  final Set<String> _skillFilter = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _clearAllFilters() {
    setState(() {
      _remoteOnly = false;
      _favOnly = false;
      _locationFilter = null;
      _skillFilter.clear();
    });
  }

  bool get _hasActiveFilter =>
      _remoteOnly || _favOnly || _locationFilter != null || _skillFilter.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListProvider(query: _query));
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Pilot'),
        centerTitle: false,
        elevation: 0,
        actions: [
          const _SyncButton(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '我的技能檔案',
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜尋職缺或公司名稱…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Filter chips row
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('遠端'),
                    selected: _remoteOnly,
                    onSelected: (v) => setState(() => _remoteOnly = v),
                    selectedColor: colors.primaryContainer,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('已收藏'),
                    selected: _favOnly,
                    onSelected: (v) => setState(() => _favOnly = v),
                    selectedColor: colors.primaryContainer,
                  ),
                ),
                // 地點 dropdown
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: jobsAsync.when(
                    loading: () => const SizedBox(),
                    error: (err, st) => const SizedBox(),
                    data: (jobs) {
                      final locations =
                          jobs.map((j) => j.location).toSet().toList()..sort();
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _locationFilter,
                          hint: const Text('地點'),
                          borderRadius: BorderRadius.circular(12),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('全部地點')),
                            ...locations.map((l) =>
                                DropdownMenuItem(value: l, child: Text(l))),
                          ],
                          onChanged: (v) =>
                              setState(() => _locationFilter = v),
                        ),
                      );
                    },
                  ),
                ),
                // 技能 multi-select
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_skillFilter.isEmpty
                        ? '技能'
                        : '技能 (${_skillFilter.length})'),
                    selected: _skillFilter.isNotEmpty,
                    selectedColor: colors.primaryContainer,
                    onSelected: (_) => _showSkillPicker(
                        context, jobsAsync.valueOrNull ?? []),
                  ),
                ),
                if (_hasActiveFilter)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('清除'),
                    onPressed: _clearAllFilters,
                  ),
              ],
            ),
          ),
          // Job list
          Expanded(
            child: jobsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                var filtered = jobs;
                if (_remoteOnly) {
                  filtered = filtered.where((j) => j.isRemote).toList();
                }
                if (_favOnly) {
                  filtered = filtered.where((j) => favIds.contains(j.id)).toList();
                }
                if (_locationFilter != null) {
                  filtered = filtered.where((j) => j.location == _locationFilter).toList();
                }
                if (_skillFilter.isNotEmpty) {
                  filtered = filtered
                      .where((j) => _skillFilter.any((s) => j.skills.any(
                          (js) =>
                              js.toLowerCase() == s.toLowerCase())))
                      .toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 48, color: colors.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('找不到符合的職缺'),
                        if (_hasActiveFilter) ...[
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _clearAllFilters,
                              child: const Text('清除篩選')),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (_, i) => JobCard(job: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSkillPicker(BuildContext context, List<dynamic> jobs) {
    final allSkills = jobs
        .expand((j) => j.skills as List<String>)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          builder: (_, controller) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text('選擇技能',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setInner(() => _skillFilter.clear());
                        setState(() {});
                      },
                      child: const Text('清除'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('確定'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: allSkills
                      .map((s) => CheckboxListTile(
                            title: Text(s),
                            value: _skillFilter.contains(s),
                            onChanged: (v) {
                              setInner(() {
                                v == true
                                    ? _skillFilter.add(s)
                                    : _skillFilter.remove(s);
                              });
                              setState(() {});
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncNotifierProvider);
    final isSyncing = sync.status == SyncStatus.syncing;

    return IconButton(
      icon: isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      tooltip: sync.lastSyncTime != null
          ? '上次同步：${_formatTime(sync.lastSyncTime!)}'
          : '同步職缺',
      onPressed: isSyncing
          ? null
          : () => ref.read(syncNotifierProvider.notifier).sync(),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
