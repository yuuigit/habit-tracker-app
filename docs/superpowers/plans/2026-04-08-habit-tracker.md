# 習慣トラッカーアプリ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flutter で iOS/Android 両対応の習慣トラッカーアプリを構築し、Google AdMob バナー広告で収益化する。

**Architecture:** Hive をローカル DB、Riverpod を状態管理に使い、UI → HabitNotifier → HabitRepository → Hive の単方向データフローで構成する。画面は ホーム・習慣追加編集・統計・設定の4画面。

**Tech Stack:** Flutter (Dart), Hive, Riverpod, google_mobile_ads, flutter_local_notifications, uuid

---

## ファイル構成

```
lib/
  main.dart                          # アプリ起動・Hive初期化・Riverpod設定
  models/
    habit.dart                       # Habitデータクラス + Hiveアダプター
    habit.g.dart                     # Hive自動生成ファイル
    habit_record.dart                # HabitRecordデータクラス + Hiveアダプター
    habit_record.g.dart              # Hive自動生成ファイル
  repositories/
    habit_repository.dart            # Hive DBの読み書き
  providers/
    habit_provider.dart              # HabitNotifier + Riverpod Provider定義
  screens/
    home_screen.dart                 # 今日の習慣一覧・チェック操作
    habit_form_screen.dart           # 習慣追加・編集フォーム
    stats_screen.dart                # 連続日数・達成率表示
    settings_screen.dart             # 通知設定
  widgets/
    habit_tile.dart                  # 習慣一覧の1行ウィジェット
    ad_banner.dart                   # AdMobバナー広告ウィジェット
    empty_state.dart                 # 習慣0件時の空状態UI
  services/
    notification_service.dart        # flutter_local_notifications ラッパー
    ad_service.dart                  # AdMob初期化・インタースティシャル管理

test/
  repositories/
    habit_repository_test.dart
  providers/
    habit_provider_test.dart
  widgets/
    home_screen_test.dart
```

---

## Task 1: Flutter プロジェクトのセットアップ

**Files:**
- Create: `pubspec.yaml`（依存パッケージ追加）
- Create: `lib/main.dart`

- [ ] **Step 1: Flutter プロジェクトを作成する**

```bash
flutter create habit_tracker
cd habit_tracker
```

- [ ] **Step 2: pubspec.yaml に依存パッケージを追加する**

`pubspec.yaml` の `dependencies:` セクションを以下に置き換える：

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_riverpod: ^2.5.1
  google_mobile_ads: ^5.1.0
  flutter_local_notifications: ^17.2.2
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
  flutter_lints: ^3.0.0
```

- [ ] **Step 3: パッケージをインストールする**

```bash
flutter pub get
```

Expected: `Got dependencies!` と表示される

- [ ] **Step 4: main.dart を書く**

`lib/main.dart` を以下の内容にする：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'models/habit_record.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitRecordAdapter());
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<HabitRecord>('habit_records');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '習慣トラッカー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

- [ ] **Step 5: ビルド確認**

```bash
flutter run
```

Expected: アプリが起動する（まだ HomeScreen は空でよい）

- [ ] **Step 6: コミット**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git commit -m "feat: Flutter project setup with dependencies"
```

---

## Task 2: データモデル（Habit・HabitRecord）

**Files:**
- Create: `lib/models/habit.dart`
- Create: `lib/models/habit_record.dart`
- Generate: `lib/models/habit.g.dart`, `lib/models/habit_record.g.dart`

- [ ] **Step 1: Habit モデルを書く**

`lib/models/habit.dart`:

```dart
import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String icon;

  @HiveField(3)
  late List<int> frequency; // [1=月, 2=火, ..., 7=日]

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  DateTime? reminderTime;
}
```

- [ ] **Step 2: HabitRecord モデルを書く**

`lib/models/habit_record.dart`:

```dart
import 'package:hive/hive.dart';

part 'habit_record.g.dart';

@HiveType(typeId: 1)
class HabitRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late DateTime date;
}
```

- [ ] **Step 3: Hive アダプターを自動生成する**

```bash
dart run build_runner build
```

Expected: `lib/models/habit.g.dart` と `lib/models/habit_record.g.dart` が生成される

- [ ] **Step 4: コミット**

```bash
git add lib/models/
git commit -m "feat: add Habit and HabitRecord models with Hive adapters"
```

---

## Task 3: HabitRepository（DB読み書き）

**Files:**
- Create: `lib/repositories/habit_repository.dart`
- Create: `test/repositories/habit_repository_test.dart`

- [ ] **Step 1: テストを書く**

`test/repositories/habit_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/repositories/habit_repository.dart';

void main() {
  late HabitRepository repo;

  setUp(() async {
    Hive.init('test/hive_test');
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitRecordAdapter());
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitRecord>('habit_records');
    repo = HabitRepository();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('習慣を保存して取得できる', () async {
    final habit = Habit()
      ..id = 'test-id'
      ..name = 'テスト習慣'
      ..icon = '🏃'
      ..frequency = [1, 2, 3]
      ..createdAt = DateTime(2026, 4, 8);
    await repo.saveHabit(habit);
    final habits = repo.getAllHabits();
    expect(habits.length, 1);
    expect(habits.first.name, 'テスト習慣');
  });

  test('達成記録を保存して今日の記録を取得できる', () async {
    final record = HabitRecord()
      ..id = 'rec-id'
      ..habitId = 'habit-id'
      ..date = DateTime(2026, 4, 8);
    await repo.saveRecord(record);
    final records = repo.getRecordsForDate(DateTime(2026, 4, 8));
    expect(records.length, 1);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認する**

```bash
flutter test test/repositories/habit_repository_test.dart
```

Expected: FAIL（HabitRepository が存在しない）

- [ ] **Step 3: HabitRepository を実装する**

`lib/repositories/habit_repository.dart`:

```dart
import 'package:hive/hive.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';

class HabitRepository {
  Box<Habit> get _habitBox => Hive.box<Habit>('habits');
  Box<HabitRecord> get _recordBox => Hive.box<HabitRecord>('habit_records');

  List<Habit> getAllHabits() => _habitBox.values.toList();

  Future<void> saveHabit(Habit habit) async {
    await _habitBox.put(habit.id, habit);
  }

  Future<void> deleteHabit(String id) async {
    await _habitBox.delete(id);
    final toDelete = _recordBox.values
        .where((r) => r.habitId == id)
        .map((r) => r.id)
        .toList();
    for (final key in toDelete) {
      await _recordBox.delete(key);
    }
  }

  Future<void> saveRecord(HabitRecord record) async {
    await _recordBox.put(record.id, record);
  }

  Future<void> deleteRecord(String id) async {
    await _recordBox.delete(id);
  }

  List<HabitRecord> getRecordsForDate(DateTime date) {
    return _recordBox.values.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  List<HabitRecord> getAllRecordsForHabit(String habitId) {
    return _recordBox.values.where((r) => r.habitId == habitId).toList();
  }
}
```

- [ ] **Step 4: テストが通ることを確認する**

```bash
flutter test test/repositories/habit_repository_test.dart
```

Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/repositories/ test/repositories/
git commit -m "feat: add HabitRepository with Hive CRUD"
```

---

## Task 4: HabitNotifier（Riverpod 状態管理）

**Files:**
- Create: `lib/providers/habit_provider.dart`
- Create: `test/providers/habit_provider_test.dart`

- [ ] **Step 1: テストを書く**

`test/providers/habit_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/providers/habit_provider.dart';

void main() {
  setUp(() async {
    Hive.init('test/hive_test2');
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitRecordAdapter());
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitRecord>('habit_records');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('習慣を追加すると状態に反映される', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(habitNotifierProvider.notifier).addHabit(
      name: '朝のランニング',
      icon: '🏃',
      frequency: [1, 2, 3, 4, 5],
    );
    final state = container.read(habitNotifierProvider);
    expect(state.habits.length, 1);
    expect(state.habits.first.name, '朝のランニング');
  });

  test('連続達成日数が正しく計算される', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(habitNotifierProvider.notifier);
    notifier.addHabit(name: 'テスト', icon: '✅', frequency: [1,2,3,4,5,6,7]);
    final habit = container.read(habitNotifierProvider).habits.first;
    final today = DateTime.now();
    notifier.toggleRecord(habit.id, today);
    final streak = container.read(habitNotifierProvider.notifier).getStreak(habit.id);
    expect(streak, 1);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認する**

```bash
flutter test test/providers/habit_provider_test.dart
```

Expected: FAIL

- [ ] **Step 3: HabitState と HabitNotifier を実装する**

`lib/providers/habit_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../repositories/habit_repository.dart';

class HabitState {
  final List<Habit> habits;
  final List<HabitRecord> todayRecords;
  HabitState({required this.habits, required this.todayRecords});
}

class HabitNotifier extends Notifier<HabitState> {
  final _repo = HabitRepository();
  final _uuid = const Uuid();

  @override
  HabitState build() {
    return HabitState(
      habits: _repo.getAllHabits(),
      todayRecords: _repo.getRecordsForDate(DateTime.now()),
    );
  }

  Future<void> addHabit({
    required String name,
    required String icon,
    required List<int> frequency,
    DateTime? reminderTime,
  }) async {
    final habit = Habit()
      ..id = _uuid.v4()
      ..name = name
      ..icon = icon
      ..frequency = frequency
      ..createdAt = DateTime.now()
      ..reminderTime = reminderTime;
    await _repo.saveHabit(habit);
    _reload();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.saveHabit(habit);
    _reload();
  }

  Future<void> deleteHabit(String id) async {
    await _repo.deleteHabit(id);
    _reload();
  }

  Future<void> toggleRecord(String habitId, DateTime date) async {
    final existing = _repo.getRecordsForDate(date)
        .where((r) => r.habitId == habitId)
        .toList();
    if (existing.isNotEmpty) {
      await _repo.deleteRecord(existing.first.id);
    } else {
      final record = HabitRecord()
        ..id = _uuid.v4()
        ..habitId = habitId
        ..date = date;
      await _repo.saveRecord(record);
    }
    _reload();
  }

  int getStreak(String habitId) {
    final records = _repo.getAllRecordsForHabit(habitId)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (records.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    for (final record in records) {
      final diff = DateTime(check.year, check.month, check.day)
          .difference(DateTime(record.date.year, record.date.month, record.date.day))
          .inDays;
      if (diff == 0 || diff == 1) {
        streak++;
        check = record.date;
      } else {
        break;
      }
    }
    return streak;
  }

  bool isCompletedToday(String habitId) {
    return state.todayRecords.any((r) => r.habitId == habitId);
  }

  void _reload() {
    state = HabitState(
      habits: _repo.getAllHabits(),
      todayRecords: _repo.getRecordsForDate(DateTime.now()),
    );
  }
}

final habitNotifierProvider = NotifierProvider<HabitNotifier, HabitState>(
  HabitNotifier.new,
);
```

- [ ] **Step 4: テストが通ることを確認する**

```bash
flutter test test/providers/habit_provider_test.dart
```

Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/providers/ test/providers/
git commit -m "feat: add HabitNotifier with Riverpod state management"
```

---

## Task 5: AdBanner ウィジェット

**Files:**
- Create: `lib/widgets/ad_banner.dart`
- Create: `lib/services/ad_service.dart`

> **注意:** AdMob を使うには Android/iOS の設定が必要。開発中はテスト広告IDを使う。

- [ ] **Step 1: Android の AndroidManifest.xml に AdMob App ID を追加する**

`android/app/src/main/AndroidManifest.xml` の `<application>` タグ内に追加：

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

※ `ca-app-pub-3940256099942544~3347511713` はテスト用App ID

- [ ] **Step 2: iOS の Info.plist に AdMob App ID を追加する**

`ios/Runner/Info.plist` に追加：

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

※テスト用App ID

- [ ] **Step 3: AdService を実装する**

`lib/services/ad_service.dart`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // テスト用バナー広告ID（本番リリース時は実際のIDに変更）
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
```

- [ ] **Step 4: AdBanner ウィジェットを実装する**

`lib/widgets/ad_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
```

- [ ] **Step 5: main.dart に AdService.initialize() を追加する**

`lib/main.dart` の `main()` 関数に追加：

```dart
await AdService.initialize(); // Hive初期化の後に追加
```

importも追加：
```dart
import 'services/ad_service.dart';
```

- [ ] **Step 6: コミット**

```bash
git add lib/widgets/ad_banner.dart lib/services/ad_service.dart lib/main.dart android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "feat: add AdMob banner ad widget"
```

---

## Task 6: HabitTile・EmptyState ウィジェット

**Files:**
- Create: `lib/widgets/habit_tile.dart`
- Create: `lib/widgets/empty_state.dart`

- [ ] **Step 1: HabitTile を実装する**

`lib/widgets/habit_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.streak,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(habit.icon, style: const TextStyle(fontSize: 28)),
      title: Text(
        habit.name,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? Colors.grey : null,
        ),
      ),
      subtitle: Text('🔥 $streak 日連続'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.teal : Colors.grey,
            ),
            onPressed: onToggle,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('編集')),
              const PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: EmptyState を実装する**

`lib/widgets/empty_state.dart`:

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('最初の習慣を追加しましょう！',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('習慣を追加'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: コミット**

```bash
git add lib/widgets/
git commit -m "feat: add HabitTile and EmptyState widgets"
```

---

## Task 7: HomeScreen

**Files:**
- Create: `lib/screens/home_screen.dart`
- Create: `test/widgets/home_screen_test.dart`

- [ ] **Step 1: スモークテストを書く**

`test/widgets/home_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/screens/home_screen.dart';

void main() {
  setUp(() async {
    Hive.init('test/hive_test3');
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitRecordAdapter());
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitRecord>('habit_records');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('習慣が0件のとき EmptyState が表示される', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    await tester.pump();
    expect(find.text('最初の習慣を追加しましょう！'), findsOneWidget);
  });
}
```

- [ ] **Step 2: テストが失敗することを確認する**

```bash
flutter test test/widgets/home_screen_test.dart
```

Expected: FAIL

- [ ] **Step 3: HomeScreen を実装する**

`lib/screens/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/ad_banner.dart';
import 'habit_form_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitNotifierProvider);
    final notifier = ref.read(habitNotifierProvider.notifier);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の習慣'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.habits.isEmpty
                ? EmptyState(
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HabitFormScreen()),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.habits.length,
                    itemBuilder: (context, index) {
                      final habit = state.habits[index];
                      return HabitTile(
                        habit: habit,
                        isCompleted: notifier.isCompletedToday(habit.id),
                        streak: notifier.getStreak(habit.id),
                        onToggle: () => notifier.toggleRecord(habit.id, today),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HabitFormScreen(habit: habit),
                          ),
                        ),
                        onDelete: () => notifier.deleteHabit(habit.id),
                      );
                    },
                  ),
          ),
          const AdBanner(),
        ],
      ),
      floatingActionButton: state.habits.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HabitFormScreen()),
              ),
              child: const Icon(Icons.add),
            ),
    );
  }
}
```

- [ ] **Step 4: テストが通ることを確認する**

```bash
flutter test test/widgets/home_screen_test.dart
```

Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/screens/home_screen.dart test/widgets/
git commit -m "feat: add HomeScreen with habit list and empty state"
```

---

## Task 8: HabitFormScreen（習慣追加・編集）

**Files:**
- Create: `lib/screens/habit_form_screen.dart`

- [ ] **Step 1: HabitFormScreen を実装する**

`lib/screens/habit_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitFormScreen extends ConsumerStatefulWidget {
  final Habit? habit;
  const HabitFormScreen({super.key, this.habit});

  @override
  ConsumerState<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends ConsumerState<HabitFormScreen> {
  late TextEditingController _nameController;
  String _icon = '✅';
  List<int> _frequency = [1, 2, 3, 4, 5, 6, 7];

  final _icons = ['✅', '🏃', '📚', '💪', '🧘', '💧', '🥗', '😴', '🎯', '✍️'];
  final _dayLabels = ['月', '火', '水', '木', '金', '土', '日'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    if (widget.habit != null) {
      _icon = widget.habit!.icon;
      _frequency = List.from(widget.habit!.frequency);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(habitNotifierProvider.notifier);
    if (widget.habit == null) {
      notifier.addHabit(name: name, icon: _icon, frequency: _frequency);
    } else {
      widget.habit!
        ..name = name
        ..icon = _icon
        ..frequency = _frequency;
      notifier.updateHabit(widget.habit!);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit == null ? '習慣を追加' : '習慣を編集'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '習慣名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('アイコン', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: _icons.map((icon) => GestureDetector(
                onTap: () => setState(() => _icon = icon),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _icon == icon ? Colors.teal.shade100 : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('繰り返し', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _frequency.contains(day);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selected,
                  onSelected: (val) => setState(() {
                    if (val) _frequency.add(day);
                    else _frequency.remove(day);
                  }),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: ビルドして動作確認する**

```bash
flutter run
```

習慣を追加・編集できることを手動で確認する。

- [ ] **Step 3: コミット**

```bash
git add lib/screens/habit_form_screen.dart
git commit -m "feat: add HabitFormScreen for adding and editing habits"
```

---

## Task 9: StatsScreen（統計画面）

**Files:**
- Create: `lib/screens/stats_screen.dart`

- [ ] **Step 1: StatsScreen を実装する**

`lib/screens/stats_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';
import '../repositories/habit_repository.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitNotifierProvider);
    final notifier = ref.read(habitNotifierProvider.notifier);
    final repo = HabitRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('統計')),
      body: state.habits.isEmpty
          ? const Center(child: Text('まだ習慣がありません'))
          : ListView.builder(
              itemCount: state.habits.length,
              itemBuilder: (context, index) {
                final habit = state.habits[index];
                final records = repo.getAllRecordsForHabit(habit.id);
                final streak = notifier.getStreak(habit.id);
                final total = records.length;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Text(habit.icon, style: const TextStyle(fontSize: 28)),
                    title: Text(habit.name),
                    subtitle: Text('合計達成: $total 日'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        Text('$streak 日',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

- [ ] **Step 2: ビルドして動作確認する**

```bash
flutter run
```

統計画面で各習慣のストリークと合計達成日数が表示されることを確認する。

- [ ] **Step 3: コミット**

```bash
git add lib/screens/stats_screen.dart
git commit -m "feat: add StatsScreen with streak and total count"
```

---

## Task 10: 通知サービス（SettingsScreen）

**Files:**
- Create: `lib/services/notification_service.dart`
- Create: `lib/screens/settings_screen.dart`

- [ ] **Step 1: Android の通知パーミッション設定**

`android/app/src/main/AndroidManifest.xml` に追加（`<manifest>` 直下）：

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

- [ ] **Step 2: NotificationService を実装する**

`lib/services/notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required DateTime time,
    required List<int> weekdays,
  }) async {
    for (final day in weekdays) {
      await _plugin.periodicallyShow(
        id + day,
        title,
        '今日の習慣を完了しましょう！',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminder', '習慣リマインダー',
            importance: Importance.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
```

- [ ] **Step 3: main.dart に NotificationService.initialize() を追加する**

```dart
await NotificationService.initialize();
```

importも追加：
```dart
import 'services/notification_service.dart';
```

- [ ] **Step 4: SettingsScreen を実装する（シンプル版）**

`lib/screens/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(
        child: Text('通知設定は習慣の編集画面から設定できます'),
      ),
    );
  }
}
```

- [ ] **Step 5: ビルド確認**

```bash
flutter run
```

- [ ] **Step 6: コミット**

```bash
git add lib/services/notification_service.dart lib/screens/settings_screen.dart lib/main.dart android/app/src/main/AndroidManifest.xml
git commit -m "feat: add NotificationService and SettingsScreen"
```

---

## Task 11: 全テスト実行・最終確認

- [ ] **Step 1: 全テストを実行する**

```bash
flutter test
```

Expected: All tests PASS

- [ ] **Step 2: Android でビルド確認**

```bash
flutter build apk --debug
```

Expected: `Build complete.`

- [ ] **Step 3: iOS でビルド確認（Mac 環境の場合）**

```bash
flutter build ios --debug --no-codesign
```

- [ ] **Step 4: GitHub に push する**

```bash
export PATH="$PATH:/c/Program Files/GitHub CLI"
git push origin master
```

- [ ] **Step 5: 成功基準のチェック**

- [ ] 習慣の追加・編集・削除ができる
- [ ] 今日の習慣をチェックして達成記録ができる
- [ ] 連続達成日数（ストリーク）が正しく表示される
- [ ] バナー広告がホーム画面に表示される
- [ ] iOS/Android 両方でビルド確認できる
