import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/models/habit_record.dart';
import 'package:habit_tracker/screens/home_screen.dart';

void main() {
  setUp(() async {
    Hive.init('test/hive_widget');
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

  testWidgets('習慣が0件のとき EmptyState が表示される', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('最初の習慣を追加しましょう！'), findsOneWidget);
  });

  testWidgets('AppBar に「今日の習慣」と表示される', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('今日の習慣'), findsOneWidget);
  });
}
