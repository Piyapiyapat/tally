import 'package:hive_ce/hive_ce.dart';

part 'habit.g.dart';

@HiveType(typeId: 3)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3, defaultValue: 'category')
  late String iconName;

  @HiveField(4)
  int? reminderHour;

  @HiveField(5)
  int? reminderMinute;

  Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    this.iconName = 'category',
    this.reminderHour,
    this.reminderMinute,
  });
}