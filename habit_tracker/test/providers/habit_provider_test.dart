import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/providers/habit_provider.dart';

void main() {
  setUp(() async {
    Hive.init('test/hive_provider');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitRecordAdapter());
    }
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<HabitRecord>('habit_records');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('習慣を追加すると状態に反映される', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(habitNotifierProvider.notifier).addHabit(
          name: '朝のランニング',
          icon: '🏃',
          frequency: [1, 2, 3, 4, 5],
        );

    final state = container.read(habitNotifierProvider);
    expect(state.habits.length, 1);
    expect(state.habits.first.name, '朝のランニング');
    expect(state.habits.first.icon, '🏃');
  });

  test('習慣を削除すると状態から消える', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(habitNotifierProvider.notifier).addHabit(
          name: '削除テスト',
          icon: '✅',
          frequency: [1],
        );

    final id = container.read(habitNotifierProvider).habits.first.id;
    await container.read(habitNotifierProvider.notifier).deleteHabit(id);

    expect(container.read(habitNotifierProvider).habits, isEmpty);
  });

  test('今日の達成チェックをトグルできる', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(habitNotifierProvider.notifier);

    await notifier.addHabit(
        name: 'チェックテスト', icon: '✅', frequency: [1, 2, 3, 4, 5, 6, 7]);

    final id = container.read(habitNotifierProvider).habits.first.id;

    await notifier.toggleRecord(id, DateTime.now());
    expect(notifier.isCompletedToday(id), true);

    await notifier.toggleRecord(id, DateTime.now());
    expect(notifier.isCompletedToday(id), false);
  });

  test('連続達成日数が正しく計算される', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(habitNotifierProvider.notifier);

    await notifier.addHabit(
        name: 'ストリークテスト', icon: '🔥', frequency: [1, 2, 3, 4, 5, 6, 7]);

    final id = container.read(habitNotifierProvider).habits.first.id;
    final today = DateTime.now();

    await notifier.toggleRecord(id, today);
    expect(notifier.getStreak(id), 1);
  });

  // 改善 #1: ストリークが HabitState にキャッシュされる
  test('HabitState にストリークのキャッシュが含まれる', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(habitNotifierProvider.notifier);

    await notifier.addHabit(
        name: 'キャッシュテスト', icon: '🔥', frequency: [1, 2, 3, 4, 5, 6, 7]);

    final id = container.read(habitNotifierProvider).habits.first.id;
    await notifier.toggleRecord(id, DateTime.now());

    final state = container.read(habitNotifierProvider);
    expect(state.streaks[id], 1);
  });
}
