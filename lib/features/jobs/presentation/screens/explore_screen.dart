import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorite_provider.dart';
import '../providers/job_list_paginated_provider.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/job_card_skeleton.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _remoteOnly = false;
  bool _favOnly = false;

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

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListPaginatedProvider);
    final notifier = ref.read(jobListPaginatedProvider.notifier);
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final colors = Theme.of(context).colorScheme;
    final sync = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('探索職缺'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: sync.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
              ],
            ),
          ),
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (context, i) => const JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                var filtered = jobs;
                if (_remoteOnly) {
                  filtered = filtered.where((j) => j.isRemote).toList();
                }
                if (_favOnly) {
                  filtered = filtered.where((j) => favIds.contains(j.id)).toList();
                }

                if (filtered.isEmpty && !notifier.hasMore) {
                  return const Center(child: Text('找不到符合的職缺'));
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
