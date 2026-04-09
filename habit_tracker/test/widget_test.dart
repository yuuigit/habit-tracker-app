import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/widgets/habit_tile.dart';

// HabitTile の UI テスト（Hive 不要 - モデルを直接渡す）
void main() {
  // 改善 #6: ストリークが 0 のとき連続日数テキストを表示しない
  testWidgets('HabitTile はストリーク0のとき連続日数を表示しない', (tester) async {
    final habit = Habit()
      ..id = 'h1'
      ..name = 'テスト'
      ..icon = '✅'
      ..frequency = [1]
      ..createdAt = DateTime(2026, 4, 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitTile(
            habit: habit,
            isCompleted: false,
            streak: 0,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('🔥 0 日連続'), findsNothing);
  });

  // 改善 #6: ストリークが1以上のとき表示される
  testWidgets('HabitTile はストリーク1以上のとき連続日数を表示する', (tester) async {
    final habit = Habit()
      ..id = 'h1'
      ..name = 'テスト'
      ..icon = '✅'
      ..frequency = [1]
      ..createdAt = DateTime(2026, 4, 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitTile(
            habit: habit,
            isCompleted: true,
            streak: 3,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('🔥 3 日連続'), findsOneWidget);
  });

  // AppBar タイトルのスモークテスト（HomeScreen を直接テストしない）
  testWidgets('HabitTile は習慣名を表示する', (tester) async {
    final habit = Habit()
      ..id = 'h1'
      ..name = '朝のランニング'
      ..icon = '🏃'
      ..frequency = [1, 2, 3]
      ..createdAt = DateTime(2026, 4, 8);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HabitTile(
            habit: habit,
            isCompleted: false,
            streak: 5,
            onToggle: () {},
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    expect(find.text('朝のランニング'), findsOneWidget);
    expect(find.text('🔥 5 日連続'), findsOneWidget);
  });
}
