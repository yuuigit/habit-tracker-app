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
    final existing = _repo
        .getRecordsForDate(date)
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
          .difference(
              DateTime(record.date.year, record.date.month, record.date.day))
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
