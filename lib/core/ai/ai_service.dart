import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI 摘要與匹配度分析結果
class AiJobAnalysis {
  const AiJobAnalysis({
    required this.summaryBullets,
    required this.matchScore,
    required this.matchReason,
  });

  /// 3 點職缺摘要
  final List<String> summaryBullets;

  /// 匹配分數 0–100
  final int matchScore;

  /// 匹配說明（1–2 句）
  final String matchReason;
}

/// Claude API 封裝。
/// 設定 [useMock] = true（預設 debug 模式）可跳過真實 API 呼叫。
class AiService {
  AiService({required this.apiKey, bool? useMock})
      : useMock = useMock ?? apiKey.isEmpty;

  final String apiKey;
  final bool useMock;

  static const _endpoint =
      'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-3-5-haiku-20241022';

  Future<AiJobAnalysis> analyze({
    required String jobTitle,
    required String company,
    required String description,
    required List<String> jobSkills,
    required List<String> userSkills,
  }) async {
    if (useMock) return _mockAnalysis(jobTitle, jobSkills, userSkills);

    final prompt = _buildPrompt(
      jobTitle: jobTitle,
      company: company,
      description: description,
      jobSkills: jobSkills,
      userSkills: userSkills,
    );

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 512,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['content'] as List).first['text'] as String;
    return _parseResponse(text);
  }

  // ---------- private helpers ----------

  String _buildPrompt({
    required String jobTitle,
    required String company,
    required String description,
    required List<String> jobSkills,
    required List<String> userSkills,
  }) =>
      '''
你是一位求職顧問。請根據以下職缺資訊與使用者技能，以 JSON 格式回覆，不要有任何額外說明。

職缺：$jobTitle（$company）
職缺描述：$description
職缺技能：${jobSkills.join(', ')}
使用者技能：${userSkills.isEmpty ? '未提供' : userSkills.join(', ')}

請回覆以下 JSON（不含 markdown code block）：
{
  "bullets": ["摘要第1點", "摘要第2點", "摘要第3點"],
  "score": 75,
  "reason": "匹配原因說明（1-2句）"
}
''';

  AiJobAnalysis _parseResponse(String text) {
    try {
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return AiJobAnalysis(
        summaryBullets: (json['bullets'] as List).cast<String>(),
        matchScore: (json['score'] as num).toInt().clamp(0, 100),
        matchReason: json['reason'] as String,
      );
    } catch (_) {
      return _fallback();
    }
  }

  AiJobAnalysis _mockAnalysis(
    String jobTitle,
    List<String> jobSkills,
    List<String> userSkills,
  ) {
    final overlap = jobSkills
        .where((s) => userSkills.any(
              (u) => u.toLowerCase() == s.toLowerCase(),
            ))
        .toList();
    final score = userSkills.isEmpty
        ? 50
        : (overlap.length / jobSkills.length * 100).round().clamp(0, 100);

    return AiJobAnalysis(
      summaryBullets: [
        '此職缺要求熟悉 ${jobSkills.take(2).join('、')} 等核心技術',
        '工作內容涵蓋產品開發與跨團隊協作',
        '適合有 ${jobSkills.isNotEmpty ? jobSkills.first : "相關"} 經驗的工程師',
      ],
      matchScore: score,
      matchReason: overlap.isEmpty
          ? '使用者技能與此職缺重疊度較低，建議補充相關技能後再投遞。'
          : '您具備 ${overlap.join("、")} 等技能，與此職缺要求高度吻合。',
    );
  }

  AiJobAnalysis _fallback() => const AiJobAnalysis(
        summaryBullets: ['摘要載入失敗', '請稍後再試', ''],
        matchScore: 0,
        matchReason: '無法分析',
      );
}
