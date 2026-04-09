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
