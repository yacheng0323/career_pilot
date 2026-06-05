import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorite_provider.dart';
import '../providers/job_list_paginated_provider.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/job_card_skeleton.dart';

// ── 來源選項（與 JobCard badge 一致）────────────────────────────────────────
const _sources = [
  (id: '104',       label: '104人力銀行', color: Color(0xFFFF6B00)),
  (id: 'yourator',  label: 'Yourator',   color: Color(0xFF00A86B)),
  (id: 'remotive',  label: 'Remotive',   color: Color(0xFF7C3AED)),
  (id: 'arbeitnow', label: 'Arbeitnow',  color: Color(0xFF2563EB)),
];

// ── 薪資範圍選項（月薪 TWD） ────────────────────────────────────────────────
const _salaryRanges = [
  (label: '不限',           min: 0,      max: 9999999),
  (label: '3 萬以上',       min: 30000,  max: 9999999),
  (label: '5 萬以上',       min: 50000,  max: 9999999),
  (label: '7 萬以上',       min: 70000,  max: 9999999),
  (label: '10 萬以上',      min: 100000, max: 9999999),
];

// ── 地區選項 ────────────────────────────────────────────────────────────────
const _locations = [
  '不限', '台北市', '新北市', '新竹市', '台中市', '台南市', '高雄市', '遠端', 'Remote',
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // ── Filter state ──────────────────────────────────────────────────────────
  String _query = '';
  bool _remoteOnly = false;
  bool _favOnly = false;
  final Set<String> _selectedSources = {}; // empty = all
  int _salaryIdx = 0;                       // index into _salaryRanges
  String _location = '不限';

  bool get _hasAdvancedFilter =>
      _selectedSources.isNotEmpty || _salaryIdx != 0 || _location != '不限';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobListPaginatedProvider.notifier).init();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobListPaginatedProvider.notifier).fetchMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(jobListPaginatedProvider.notifier).refresh(query: _query);
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    ref.read(jobListPaginatedProvider.notifier).refresh(query: value);
  }

  void _clearAllFilters() {
    setState(() {
      _remoteOnly = false;
      _favOnly = false;
      _selectedSources.clear();
      _salaryIdx = 0;
      _location = '不限';
    });
  }

  // ── 進階篩選 Bottom Sheet ─────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(
        selectedSources: Set.from(_selectedSources),
        salaryIdx: _salaryIdx,
        location: _location,
        onApply: (sources, salaryIdx, location) {
          setState(() {
            _selectedSources
              ..clear()
              ..addAll(sources);
            _salaryIdx = salaryIdx;
            _location = location;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListPaginatedProvider);
    final notifier = ref.read(jobListPaginatedProvider.notifier);
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final colors = Theme.of(context).colorScheme;
    final sync = ref.watch(syncNotifierProvider);

    // 計算有多少 active filter
    final activeFilterCount = (_remoteOnly ? 1 : 0) +
        (_favOnly ? 1 : 0) +
        (_selectedSources.isNotEmpty ? 1 : 0) +
        (_salaryIdx != 0 ? 1 : 0) +
        (_location != '不限' ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('探索職缺'),
        centerTitle: false,
        elevation: 0,
        actions: [
          // ── 進階篩選 icon ──────────────────────────────────────
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: _hasAdvancedFilter ? colors.primary : null,
                ),
                tooltip: '篩選',
                onPressed: _showFilterSheet,
              ),
              if (activeFilterCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$activeFilterCount',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // ── Sync ──────────────────────────────────────────────
          IconButton(
            icon: sync.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            tooltip: '同步職缺',
            onPressed: sync.status == SyncStatus.syncing
                ? null
                : () async {
                    await ref.read(syncNotifierProvider.notifier).sync();
                    if (mounted) _onRefresh();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋職缺或公司…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // ── Quick filter chips ────────────────────────────────
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
                    selectedColor: colors.primaryContainer,
                    onSelected: (v) => setState(() => _remoteOnly = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('已收藏'),
                    selected: _favOnly,
                    selectedColor: colors.primaryContainer,
                    onSelected: (v) => setState(() => _favOnly = v),
                  ),
                ),
                // Source active badges (quick view)
                ..._selectedSources.map((src) {
                  final s = _sources.firstWhere((e) => e.id == src,
                      orElse: () => (id: src, label: src, color: colors.primary));
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s.label),
                      selected: true,
                      selectedColor: s.color.withValues(alpha: 0.15),
                      onSelected: (_) {
                        setState(() => _selectedSources.remove(src));
                      },
                    ),
                  );
                }),
                if (activeFilterCount > 0)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('清除'),
                    onPressed: _clearAllFilters,
                  ),
              ],
            ),
          ),

          // ── Job list ──────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (ctx, idx) => const JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                var filtered = jobs;

                // Quick filters
                if (_remoteOnly) {
                  filtered = filtered.where((j) => j.isRemote).toList();
                }
                if (_favOnly) {
                  filtered = filtered.where((j) => favIds.contains(j.id)).toList();
                }

                // Advanced filters
                if (_selectedSources.isNotEmpty) {
                  filtered = filtered
                      .where((j) => _selectedSources.contains(j.source.toLowerCase()))
                      .toList();
                }
                if (_salaryIdx != 0) {
                  final range = _salaryRanges[_salaryIdx];
                  filtered = filtered.where((j) {
                    // Parse salaryRange string like "70K–100K" or "月薪 70,000 - 100,000"
                    final raw = j.salaryRange.replaceAll(RegExp(r'[^0-9]'), '');
                    if (raw.isEmpty) return true; // 面議：顯示
                    final first = int.tryParse(raw.length > 6
                        ? raw.substring(0, raw.length ~/ 2)
                        : raw) ??
                        0;
                    return first >= range.min;
                  }).toList();
                }
                if (_location != '不限') {
                  filtered = filtered
                      .where((j) => j.location.contains(_location))
                      .toList();
                }

                if (filtered.isEmpty && !notifier.hasMore) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('找不到符合的職缺'),
                        if (activeFilterCount > 0) ...[
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _clearAllFilters,
                              child: const Text('清除篩選')),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length + (notifier.hasMore ? 1 : 0),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (_, i) {
                      if (i == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return JobCard(job: filtered[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedSources,
    required this.salaryIdx,
    required this.location,
    required this.onApply,
  });

  final Set<String> selectedSources;
  final int salaryIdx;
  final String location;
  final void Function(Set<String> sources, int salaryIdx, String location) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _sources;
  late int _salaryIdx;
  late String _location;

  @override
  void initState() {
    super.initState();
    _sources = Set.from(widget.selectedSources);
    _salaryIdx = widget.salaryIdx;
    _location = widget.location;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('篩選',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sources.clear();
                    _salaryIdx = 0;
                    _location = '不限';
                  });
                },
                child: const Text('重置'),
              ),
            ]),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 職缺來源 ───────────────────────────────────
                  _SectionLabel('職缺來源'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _sourceChips(colors),
                  ),
                  const SizedBox(height: 20),

                  // ── 最低薪資 ───────────────────────────────────
                  _SectionLabel('最低薪資'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: List.generate(_salaryRanges.length, (i) {
                      final r = _salaryRanges[i];
                      final sel = _salaryIdx == i;
                      return ChoiceChip(
                        label: Text(r.label),
                        selected: sel,
                        selectedColor: colors.primaryContainer,
                        onSelected: (_) => setState(() => _salaryIdx = i),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // ── 地區 ──────────────────────────────────────
                  _SectionLabel('工作地點'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _locations.map((loc) {
                      final sel = _location == loc;
                      return ChoiceChip(
                        label: Text(loc),
                        selected: sel,
                        selectedColor: colors.primaryContainer,
                        onSelected: (_) => setState(() => _location = loc),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Apply button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(_sources, _salaryIdx, _location);
                        Navigator.pop(context);
                      },
                      child: const Text('套用篩選'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sourceChips(ColorScheme colors) {
    return _sourceOptions.map((src) {
      final sel = _sources.contains(src.id);
      return FilterChip(
        avatar: Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: src.color, shape: BoxShape.circle),
        ),
        label: Text(src.label),
        selected: sel,
        selectedColor: src.color.withValues(alpha: 0.15),
        checkmarkColor: src.color,
        onSelected: (v) => setState(() {
          if (v) {
            _sources.add(src.id);
          } else {
            _sources.remove(src.id);
          }
        }),
      );
    }).toList();
  }
}

// Renamed to avoid conflict with top-level const
final _sourceOptions = _sources;

// ── Helper widget ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
}
