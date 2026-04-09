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
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Text(habit.icon,
                        style: const TextStyle(fontSize: 28)),
                    title: Text(habit.name),
                    subtitle: Text('合計達成: $total 日'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        Text('$streak 日',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
