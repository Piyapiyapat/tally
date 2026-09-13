import 'package:hive_ce/hive_ce.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 5)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5, defaultValue: <String>[])
  late List<String> tags;

  JournalEntry({
    required this.id,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    List<String>? tags,
  }) : tags = tags ?? [];
}