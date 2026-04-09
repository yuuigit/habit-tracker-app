import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/repositories/habit_repository.dart';

void main() {
  late HabitRepository repo;

  setUp(() async {
    Hive.init('test/hive_repo');
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(HabitAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitRecordAdapter());
    }
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

  test('習慣を削除すると関連する達成記録も消える', () async {
    final habit = Habit()
      ..id = 'h1'
      ..name = '削除テスト'
      ..icon = '✅'
      ..frequency = [1]
      ..createdAt = DateTime(2026, 4, 8);
    await repo.saveHabit(habit);

    final record = HabitRecord()
      ..id = 'r1'
      ..habitId = 'h1'
      ..date = DateTime(2026, 4, 8);
    await repo.saveRecord(record);

    await repo.deleteHabit('h1');

    expect(repo.getAllHabits(), isEmpty);
    expect(repo.getAllRecordsForHabit('h1'), isEmpty);
  });

  test('達成記録を保存して日付で取得できる', () async {
    final record = HabitRecord()
      ..id = 'rec-id'
      ..habitId = 'habit-id'
      ..date = DateTime(2026, 4, 8);
    await repo.saveRecord(record);

    final records = repo.getRecordsForDate(DateTime(2026, 4, 8));
    expect(records.length, 1);
    expect(records.first.habitId, 'habit-id');
  });

  test('別の日付の達成記録は取得されない', () async {
    final record = HabitRecord()
      ..id = 'rec-id'
      ..habitId = 'habit-id'
      ..date = DateTime(2026, 4, 7);
    await repo.saveRecord(record);

    final records = repo.getRecordsForDate(DateTime(2026, 4, 8));
    expect(records, isEmpty);
  });
}
