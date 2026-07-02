# Plan B — Flutter API Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 Flutter App 的資料來源從靜態 mock JSON 換成呼叫本地 FastAPI 後端，保留離線 fallback，並在 JobListScreen 加入手動同步按鈕。

**Architecture:** 新增 `ApiClient`（Dio 封裝）和 `JobRemoteDataSource`，`JobRepository` 改為優先 API、失敗 fallback mock JSON。`Job` model 新增 `url` / `crawledAt` nullable 欄位。`SyncNotifier` 管理手動 sync 狀態。

**Tech Stack:** Flutter, Dio, Riverpod code-gen, Freezed, GoRouter（現有）

**Branch:** `feature/plan-b-api-integration`

---

## File Structure

```
lib/
├── core/
│   └── network/
│       ├── api_client.dart              # NEW — Dio singleton，baseUrl from --dart-define
│       └── api_exception.dart           # NEW — ApiException 統一錯誤型別
├── features/
│   ├── jobs/
│   │   ├── data/
│   │   │   ├── job_repository.dart      # MODIFY — API 優先 + mock fallback
│   │   │   └── job_remote_datasource.dart  # NEW — GET /api/v1/jobs HTTP call
│   │   ├── domain/
│   │   │   └── job.dart                 # MODIFY — 新增 url?, crawledAt? 欄位
│   │   └── presentation/
│   │       └── screens/
│   │           └── job_list_screen.dart # MODIFY — sync button + last updated chip
│   └── sync/
│       └── presentation/
│           └── providers/
│               └── sync_provider.dart   # NEW — SyncNotifier（觸發 POST /sync）
└── test/
    ├── job_repository_test.dart         # NEW — API success / fallback tests
    └── api_client_test.dart             # NEW — ApiClient baseUrl / exception tests
```

---

## Task 1: pubspec.yaml — 啟用 Dio

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: 取消 dio 的 comment，更新版本**

開啟 `C:\dev\career_pilot\pubspec.yaml`，將：
```yaml
  # (Reserved for future API)
  # dio: ^5.7.0
```
改為：
```yaml
  dio: ^5.8.0
```

- [ ] **Step 2: 安裝依賴**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
flutter pub get
```

Expected: `Got dependencies!`

- [ ] **Step 3: 確認 dio 可 import**

```powershell
dart analyze lib/ 2>&1 | Select-Object -Last 3
```

Expected: `No issues found!`（此時 dio 尚未用到，不會有錯）

- [ ] **Step 4: Commit**

```powershell
git add pubspec.yaml pubspec.lock
git commit -m "chore: enable dio dependency"
```

---

## Task 2: ApiClient + ApiException

**Files:**
- Create: `lib/core/network/api_client.dart`
- Create: `lib/core/network/api_exception.dart`
- Create: `test/api_client_test.dart`

- [ ] **Step 1: 寫失敗測試**

建立 `C:\dev\career_pilot\test\api_client_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/network/api_client.dart';
import 'package:career_pilot/core/network/api_exception.dart';

void main() {
  group('ApiClient', () {
    test('default baseUrl is localhost:8000', () {
      final client = ApiClient();
      expect(client.baseUrl, 'http://localhost:8000');
    });

    test('accepts custom baseUrl via constructor', () {
      final client = ApiClient(baseUrl: 'http://10.0.2.2:8000');
      expect(client.baseUrl, 'http://10.0.2.2:8000');
    });
  });

  group('ApiException', () {
    test('toString includes statusCode and message', () {
      final ex = ApiException(statusCode: 404, message: 'Not found');
      expect(ex.toString(), contains('404'));
      expect(ex.toString(), contains('Not found'));
    });

    test('network error has statusCode 0', () {
      final ex = ApiException.network('timeout');
      expect(ex.statusCode, 0);
      expect(ex.message, contains('timeout'));
    });
  });
}
```

- [ ] **Step 2: 執行確認失敗**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
flutter test test/api_client_test.dart 2>&1 | Select-Object -Last 5
```

Expected: compile error（ApiClient 不存在）

- [ ] **Step 3: 實作 ApiException**

建立 `C:\dev\career_pilot\lib\core\network\api_exception.dart`：

```dart
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  factory ApiException.network(String detail) =>
      ApiException(statusCode: 0, message: 'Network error: $detail');

  factory ApiException.fromStatus(int statusCode) => ApiException(
        statusCode: statusCode,
        message: 'HTTP $statusCode',
      );

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

- [ ] **Step 4: 實作 ApiClient**

建立 `C:\dev\career_pilot\lib\core\network\api_client.dart`：

```dart
import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000',
            ) {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  final String baseUrl;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromStatus(e.response!.statusCode ?? 0);
      }
      throw ApiException.network(e.message ?? 'unknown');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromStatus(e.response!.statusCode ?? 0);
      }
      throw ApiException.network(e.message ?? 'unknown');
    }
  }
}
```

- [ ] **Step 5: 執行測試確認通過**

```powershell
flutter test test/api_client_test.dart 2>&1 | Select-Object -Last 5
```

Expected: `+4: All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git add lib/core/network/ test/api_client_test.dart
git commit -m "feat: add ApiClient and ApiException"
```

---

## Task 3: Job model — 新增 url / crawledAt 欄位

**Files:**
- Modify: `lib/features/jobs/domain/job.dart`
- Re-generate: `job.freezed.dart`, `job.g.dart`

- [ ] **Step 1: 更新 Job Freezed model**

覆寫 `C:\dev\career_pilot\lib\features\jobs\domain\job.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String title,
    required String company,
    required String location,
    required bool isRemote,
    required String salaryRange,
    required List<String> skills,
    required String description,
    required String source,
    String? url,
    DateTime? crawledAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

`url` 和 `crawledAt` 設為 nullable，確保現有 mock JSON（不含這兩欄）不會 break。

- [ ] **Step 2: 執行 build_runner 重新產生 .g.dart / .freezed.dart**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

Expected: `Built with build_runner in Ns; wrote N outputs.`

- [ ] **Step 3: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 4: 執行現有測試確認不 break**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected: `All tests passed!`（舊的 30 tests 全過）

- [ ] **Step 5: Commit**

```powershell
git add lib/features/jobs/domain/
git commit -m "feat: add url and crawledAt nullable fields to Job model"
```

---

## Task 4: JobRemoteDataSource

**Files:**
- Create: `lib/features/jobs/data/job_remote_datasource.dart`

- [ ] **Step 1: 寫失敗測試（加入 job_repository_test.dart）**

建立 `C:\dev\career_pilot\test\job_repository_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/network/api_client.dart';
import 'package:career_pilot/features/jobs/data/job_remote_datasource.dart';

// Minimal fake ApiClient that returns controlled responses
class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.fakeResponse}) : super(baseUrl: 'http://test');

  final dynamic fakeResponse;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    return fakeResponse;
  }
}

void main() {
  group('JobRemoteDataSource', () {
    test('fetchAll returns list of Jobs on success', () async {
      final fakeData = {
        'items': [
          {
            'id': '104_001',
            'title': 'Flutter Dev',
            'company': 'Acme',
            'location': '台北市',
            'isRemote': false,
            'salaryRange': '80K',
            'skills': ['Flutter', 'Dart'],
            'description': 'desc',
            'source': '104',
            'url': 'https://example.com',
            'crawledAt': '2026-06-04T00:00:00.000',
          }
        ],
        'total': 1,
      };
      final ds = JobRemoteDataSource(client: _FakeApiClient(fakeResponse: fakeData));
      final jobs = await ds.fetchAll();
      expect(jobs.length, 1);
      expect(jobs.first.id, '104_001');
      expect(jobs.first.url, 'https://example.com');
    });

    test('fetchAll returns empty list on empty items', () async {
      final ds = JobRemoteDataSource(
        client: _FakeApiClient(fakeResponse: {'items': [], 'total': 0}),
      );
      final jobs = await ds.fetchAll();
      expect(jobs, isEmpty);
    });
  });
}
```

- [ ] **Step 2: 執行確認失敗**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
flutter test test/job_repository_test.dart 2>&1 | Select-Object -Last 5
```

Expected: compile error（JobRemoteDataSource 不存在）

- [ ] **Step 3: 實作 JobRemoteDataSource**

建立 `C:\dev\career_pilot\lib\features\jobs\data\job_remote_datasource.dart`：

```dart
import '../../../core/network/api_client.dart';
import '../domain/job.dart';

class JobRemoteDataSource {
  const JobRemoteDataSource({required this.client});

  final ApiClient client;

  /// Fetches all jobs from the API.
  /// [query] maps to ?q= param; empty string = no filter.
  Future<List<Job>> fetchAll({String query = ''}) async {
    final params = <String, dynamic>{
      'limit': 100,
      if (query.isNotEmpty) 'q': query,
    };
    final data = await client.get('/api/v1/jobs', params: params);
    final items = (data['items'] as List<dynamic>);
    return items
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 4: 執行測試確認通過**

```powershell
flutter test test/job_repository_test.dart 2>&1 | Select-Object -Last 5
```

Expected: `+2: All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/jobs/data/job_remote_datasource.dart test/job_repository_test.dart
git commit -m "feat: add JobRemoteDataSource"
```

---

## Task 5: JobRepository — API 優先 + mock fallback

**Files:**
- Modify: `lib/features/jobs/data/job_repository.dart`

- [ ] **Step 1: 新增 fallback 測試到 job_repository_test.dart**

在 `C:\dev\career_pilot\test\job_repository_test.dart` 末尾補充：

```dart
import 'package:career_pilot/core/network/api_exception.dart';
import 'package:career_pilot/features/jobs/data/job_repository.dart';

// Fake that always throws network error
class _ErrorApiClient extends ApiClient {
  _ErrorApiClient() : super(baseUrl: 'http://test');

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    throw ApiException.network('connection refused');
  }
}

// Add to main() group:
// group('JobRepository', () {
//   test('falls back to mock JSON when API throws', ...);
//   test('returns API data when API succeeds', ...);
// });
```

實際測試寫在 `job_repository_test.dart` 的 `main()` 裡：

```dart
  group('JobRepository', () {
    test('falls back to mock JSON when API throws ApiException', () async {
      final repo = JobRepository(
        remoteDataSource: JobRemoteDataSource(client: _ErrorApiClient()),
      );
      // Should not throw — falls back to mock JSON
      final jobs = await repo.fetchAll();
      expect(jobs, isNotEmpty);   // mock JSON has 6 jobs
      expect(jobs.first.id, isNotEmpty);
    });
  });
```

- [ ] **Step 2: 執行確認失敗**

```powershell
flutter test test/job_repository_test.dart 2>&1 | Select-Object -Last 5
```

Expected: compile error（JobRepository constructor 不接受 remoteDataSource）

- [ ] **Step 3: 更新 JobRepository**

覆寫 `C:\dev\career_pilot\lib\features\jobs\data\job_repository.dart`：

```dart
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../domain/job.dart';
import 'job_remote_datasource.dart';

class JobRepository {
  JobRepository({JobRemoteDataSource? remoteDataSource})
      : _remote = remoteDataSource;

  static const _assetPath = 'assets/mock/jobs.json';

  final JobRemoteDataSource? _remote;

  /// Fetches jobs: API first, falls back to mock JSON on any error.
  Future<List<Job>> fetchAll({String query = ''}) async {
    if (_remote != null) {
      try {
        return await _remote.fetchAll(query: query);
      } on ApiException {
        // API unavailable — fall through to mock
      } catch (_) {
        // Any other error (e.g. parse error) — fall through to mock
      }
    }
    return _loadMock(query: query);
  }

  Future<List<Job>> _loadMock({String query = ''}) async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final all = jsonList
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all
        .where(
          (j) =>
              j.title.toLowerCase().contains(q) ||
              j.company.toLowerCase().contains(q),
        )
        .toList();
  }
}
```

- [ ] **Step 4: 更新 jobListProvider 注入 ApiClient**

覆寫 `C:\dev\career_pilot\lib\features\jobs\presentation\providers\job_list_provider.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../lib/core/network/api_client.dart';
import '../../data/job_remote_datasource.dart';
import '../../data/job_repository.dart';
import '../../domain/job.dart';

part 'job_list_provider.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

@riverpod
Future<List<Job>> jobList(JobListRef ref, {String query = ''}) async {
  final client = ref.watch(apiClientProvider);
  final repo = JobRepository(
    remoteDataSource: JobRemoteDataSource(client: client),
  );
  return repo.fetchAll(query: query);
}
```

**注意：** import path 中不要出現 `../../../../../lib`。正確路徑應為：

```dart
import '../../../../core/network/api_client.dart';
import '../../data/job_remote_datasource.dart';
import '../../data/job_repository.dart';
import '../../domain/job.dart';
```

- [ ] **Step 5: 重新執行 build_runner**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

- [ ] **Step 6: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 7: 執行所有測試**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected: All passed（30 舊 + 3 新 = 33）

- [ ] **Step 8: Commit**

```powershell
git add lib/features/jobs/data/job_repository.dart lib/features/jobs/presentation/providers/job_list_provider.dart test/job_repository_test.dart
git commit -m "feat: JobRepository with API-first + mock fallback"
```

---

## Task 6: SyncNotifier + JobListScreen sync button

**Files:**
- Create: `lib/features/sync/presentation/providers/sync_provider.dart`
- Modify: `lib/features/jobs/presentation/screens/job_list_screen.dart`

- [ ] **Step 1: 建立目錄**

```powershell
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\features\sync\presentation\providers"
```

- [ ] **Step 2: 實作 SyncNotifier**

建立 `C:\dev\career_pilot\lib\features\sync\presentation\providers\sync_provider.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';

part 'sync_provider.g.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.jobsUpserted,
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncTime;
  final int? jobsUpserted;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    int? jobsUpserted,
    String? errorMessage,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        jobsUpserted: jobsUpserted ?? this.jobsUpserted,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncState build() => const SyncState();

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final client = ref.read(apiClientProvider);
      final result = await client.post('/api/v1/sync');
      final count = (result['jobsUpserted'] as num?)?.toInt() ?? 0;
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        jobsUpserted: count,
      );
      // Invalidate job list so UI refreshes
      ref.invalidate(jobListProvider);
    } on ApiException catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
```

- [ ] **Step 3: 執行 build_runner**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

- [ ] **Step 4: 更新 JobListScreen AppBar 加 sync button**

在 `C:\dev\career_pilot\lib\features\jobs\presentation\screens\job_list_screen.dart` 的 AppBar actions 中加入 sync 按鈕（現有 person_outline 按鈕之前）：

找到這段：
```dart
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '我的技能檔案',
            onPressed: () => context.push('/profile'),
          ),
        ],
```

替換為：
```dart
        actions: [
          _SyncButton(),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '我的技能檔案',
            onPressed: () => context.push('/profile'),
          ),
        ],
```

並在檔案最下方（`_JobListScreenState` class 結束後）加入：

```dart
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
```

記得在 `job_list_screen.dart` 頂端加入 import：
```dart
import '../../../sync/presentation/providers/sync_provider.dart';
```

- [ ] **Step 5: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Fix any issues found.

- [ ] **Step 6: 執行所有測試**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected: All passed

- [ ] **Step 7: Commit**

```powershell
git add lib/features/sync/ lib/features/jobs/presentation/screens/job_list_screen.dart
git commit -m "feat: add SyncNotifier and sync button to JobListScreen"
```

---

## Task 7: 最終驗收

- [ ] **Step 1: dart analyze — zero issues**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart analyze lib/ 2>&1
```

Expected: `No issues found!`

- [ ] **Step 2: flutter test — all passed**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected: All tests passed

- [ ] **Step 3: 確認 mock fallback 正常（無需後端）**

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:9999 2>&1 | Select-Object -First 10
```

App 應正常顯示 6 筆 mock 職缺（後端不存在時 fallback 生效）。

- [ ] **Step 4: 最終 commit**

```powershell
git add -A
git commit -m "feat(plan-b): Flutter API integration complete"
```

- [ ] **Step 5: Merge feature branch → dev**

```powershell
git checkout dev
git merge --no-ff feature/plan-b-api-integration -m "feat: merge plan-b API integration into dev"
git checkout feature/plan-b-api-integration
```

---

## 驗收標準

- [ ] `dart analyze lib/` → No issues found
- [ ] `flutter test` → All tests passed
- [ ] App 在後端啟動時顯示真實職缺
- [ ] App 在後端關閉時 fallback 顯示 mock 職缺（不 crash）
- [ ] JobListScreen 右上角 sync 按鈕可點擊，syncing 時顯示 spinner
- [ ] sync 完成後 job list 自動重新整理
