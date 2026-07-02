import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/job_memo.dart';
import '../providers/job_memo_provider.dart';

/// 格式化面試日期為「7/10 14:30」樣式（無 intl 依賴）。
String formatInterviewAt(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.month}/${dt.day} $hh:$mm';
}

/// 備忘錄 + 面試日期卡片（職缺詳情頁使用）。
class MemoCard extends ConsumerStatefulWidget {
  const MemoCard({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<MemoCard> createState() => _MemoCardState();
}

class _MemoCardState extends ConsumerState<MemoCard> {
  final _controller = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickInterviewDate(DateTime? current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: current != null
          ? TimeOfDay.fromDateTime(current)
          : const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    ref.read(jobMemoNotifierProvider(widget.jobId).notifier).setInterviewDate(
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(jobMemoNotifierProvider(widget.jobId));
    final memo = memoAsync.valueOrNull ?? const JobMemo();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Seed controller once from persisted note.
    if (!_seeded && memoAsync.hasValue) {
      _controller.text = memo.note;
      _seeded = true;
    }

    return Card(
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  '我的備忘錄',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '寫點筆記，例如：記得帶作品集…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onEditingComplete: () {
                ref
                    .read(jobMemoNotifierProvider(widget.jobId).notifier)
                    .setNote(_controller.text);
                FocusScope.of(context).unfocus();
              },
              onTapOutside: (_) {
                ref
                    .read(jobMemoNotifierProvider(widget.jobId).notifier)
                    .setNote(_controller.text);
                FocusScope.of(context).unfocus();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('面試時間：',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(width: 4),
                if (memo.interviewAt != null) ...[
                  Text(
                    formatInterviewAt(memo.interviewAt!),
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: '清除面試時間',
                    onPressed: () => ref
                        .read(jobMemoNotifierProvider(widget.jobId).notifier)
                        .setInterviewDate(null),
                  ),
                ] else
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('設定'),
                    onPressed: () => _pickInterviewDate(memo.interviewAt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
