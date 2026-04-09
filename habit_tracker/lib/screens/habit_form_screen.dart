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
          // 改善 #3: 曜日が未選択のとき保存ボタンを無効化
          TextButton(
            onPressed: _frequency.isNotEmpty ? _save : null,
            child: const Text('保存'),
          ),
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
            const Text('アイコン',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: _icons
                  .map((icon) => GestureDetector(
                        onTap: () => setState(() => _icon = icon),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _icon == icon
                                ? Colors.teal.shade100
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(icon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text('繰り返し',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _frequency.contains(day);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selected,
                  onSelected: (val) => setState(() {
                    if (val) {
                      _frequency.add(day);
                    } else {
                      _frequency.remove(day);
                    }
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
