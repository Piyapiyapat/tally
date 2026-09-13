import 'package:hive_ce/hive_ce.dart';

part 'mood_entry.g.dart';

@HiveType(typeId: 2)
class MoodEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late int mood;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(5)
  String? note;

  @HiveField(6, defaultValue: <String>[])
  late List<String> tags;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    List<String>? tags,
  }) : tags = tags ?? [];
}
