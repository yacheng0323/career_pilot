/// 職缺備忘錄：自由文字筆記 + 選填的面試日期。
/// 以 JSON 存於 SharedPreferences（key: job_memo_<jobId>）。
class JobMemo {
  const JobMemo({this.note = '', this.interviewAt});

  final String note;
  final DateTime? interviewAt;

  bool get isEmpty => note.isEmpty && interviewAt == null;

  JobMemo copyWith({String? note, DateTime? Function()? interviewAt}) {
    return JobMemo(
      note: note ?? this.note,
      interviewAt: interviewAt != null ? interviewAt() : this.interviewAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'note': note,
        'interviewAt': interviewAt?.toIso8601String(),
      };

  factory JobMemo.fromJson(Map<String, dynamic> json) => JobMemo(
        note: json['note'] as String? ?? '',
        interviewAt: json['interviewAt'] != null
            ? DateTime.parse(json['interviewAt'] as String)
            : null,
      );
}

/// 面試日期急迫度 — Tracker 卡片 chip 顏色與提醒 banner 依此分級。
enum InterviewUrgency { past, imminent, soon, scheduled }

InterviewUrgency interviewUrgency(DateTime interviewAt, DateTime now) {
  final diff = interviewAt.difference(now);
  if (diff.isNegative) return InterviewUrgency.past;
  if (diff.inDays < 3) return InterviewUrgency.imminent;
  if (diff.inDays < 7) return InterviewUrgency.soon;
  return InterviewUrgency.scheduled;
}
