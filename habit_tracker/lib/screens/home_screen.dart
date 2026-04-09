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

  // 改善 #2: 削除前に確認ダイアログを表示
  Future<void> _confirmDelete(
      BuildContext context, String habitId, HabitNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('習慣を削除しますか？'),
        content: const Text('この習慣と達成記録がすべて削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteHabit(habitId);
    }
  }

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
                      MaterialPageRoute(
                          builder: (_) => const HabitFormScreen()),
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
                        onToggle: () =>
                            notifier.toggleRecord(habit.id, today),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HabitFormScreen(habit: habit),
                          ),
                        ),
                        onDelete: () =>
                            _confirmDelete(context, habit.id, notifier),
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
