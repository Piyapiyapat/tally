import 'package:hive_ce/hive_ce.dart';

part 'habit_log.g.dart';

@HiveType(typeId: 4)
class HabitLog extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String habitId;

  @HiveField(2)
  late DateTime date;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
  });
}