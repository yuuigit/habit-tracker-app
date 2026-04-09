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
