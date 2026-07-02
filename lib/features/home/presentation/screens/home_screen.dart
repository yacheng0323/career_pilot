import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../../jobs/presentation/widgets/job_card_skeleton.dart';
import '../providers/swipe_job_provider.dart';
import '../widgets/swipe_job_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(int prevIndex, int? currentIndex, CardSwiperDirection direction) {
    final deck = ref.read(swipeJobDeckProvider).valueOrNull;
    if (deck == null || deck.isEmpty) return false;

    final job = deck[prevIndex % deck.length];

    if (direction == CardSwiperDirection.right) {
      ref.read(favoriteNotifierProvider.notifier).toggle(job.id);
      _showSnack('❤️  已收藏 ${job.title}', Colors.pink);
    } else if (direction == CardSwiperDirection.left) {
      _showSnack('跳過', Colors.grey);
    }

    ref.read(swipeJobDeckProvider.notifier).onSwiped(prevIndex % deck.length);
    return true;
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(swipeJobDeckProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Pilot'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Text('今日推薦',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: colors.primary)),
              const Spacer(),
              Text('右滑收藏 · 左滑跳過',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: deckAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _EmptyDeck(
                    onRefresh: () =>
                        ref.read(swipeJobDeckProvider.notifier).refresh(),
                  );
                }
                return CardSwiper(
                  controller: _swiperController,
                  cardsCount: jobs.length,
                  numberOfCardsDisplayed: 3,
                  backCardOffset: const Offset(0, 16),
                  scale: 0.92,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  onSwipe: _onSwipe,
                  allowedSwipeDirection: const AllowedSwipeDirection.only(
                    left: true, right: true),
                  cardBuilder: (context, index, _, _) {
                    final job = jobs[index % jobs.length];
                    return SwipeJobCard(job: job);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.celebration_outlined, size: 72,
          color: colors.primary.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      Text('今天的卡片都看完了！',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('前往探索頁查看更多職缺',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 24),
      FilledButton.tonal(onPressed: onRefresh, child: const Text('重新載入')),
    ]));
  }
}
