import 'package:hive/hive.dart';

part 'habit_record.g.dart';

@HiveType(typeId: 1)
class HabitRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late DateTime date;
}
