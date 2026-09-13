import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/icon_badge.dart';

const Map<String, IconData> kHabitIcons = {
  'fitness_center': Icons.fitness_center,
  'directions_run': Icons.directions_run,
  'directions_walk': Icons.directions_walk,
  'self_improvement': Icons.self_improvement,
  'bedtime': Icons.bedtime,
  'water_drop': Icons.water_drop,
  'restaurant': Icons.restaurant,
  'local_drink': Icons.local_drink,
  'menu_book': Icons.menu_book,
  'music_note': Icons.music_note,
  'code': Icons.code,
  'palette': Icons.palette,
  'brush': Icons.brush,
  'spa': Icons.spa,
  'favorite': Icons.favorite,
  'psychology': Icons.psychology,
  'school': Icons.school,
  'work': Icons.work,
  'savings': Icons.savings,
  'pets': Icons.pets,
  'coffee': Icons.coffee,
  'camera_alt': Icons.camera_alt,
  'language': Icons.language,
  'checkroom': Icons.checkroom,
  'category': Icons.category,
};

IconData habitIconFor(String iconName) =>
    kHabitIcons[iconName] ?? Icons.category;

void showHabitSheet(BuildContext context, {Habit? existing}) {
  final controller = TextEditingController(text: existing?.name ?? '');
  String selectedIcon = existing?.iconName ?? kHabitIcons.keys.first;
  bool reminderEnabled = existing?.reminderHour != null;
  TimeOfDay reminderTime = existing?.reminderHour != null
      ? TimeOfDay(hour: existing!.reminderHour!, minute: existing.reminderMinute!)
      : const TimeOfDay(hour: 9, minute: 0);
  final colors = context.colors;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => StatefulBuilder(
      builder: (sheetCtx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'New habit' : 'Edit habit',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.deep,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.nunito(
                    color: colors.deep,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Exercise, Read, Meditate',
                    hintStyle: GoogleFonts.nunito(
                      color: colors.textDim,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: colors.surfaceFlat,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose an icon',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: kHabitIcons.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedIcon = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accent
                              : colors.surfaceFlat,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colors.accent : colors.border,
                          ),
                        ),
                        child: Icon(
                          entry.value,
                          color: isSelected ? colors.onAccent : colors.deep,
                          size: 22,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reminder',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                    ),
                    Switch(
                      value: reminderEnabled,
                      onChanged: (v) async {
                        if (v) {
                          final granted =
                              await NotificationService.requestPermission();
                          if (!granted) {
                            if (!sheetCtx.mounted) return;
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Notifications are blocked — enable them '
                                  "for Tally in your phone's settings to use "
                                  'reminders.',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w600,
                                    color: colors.onError,
                                  ),
                                ),
                                backgroundColor: colors.error,
                              ),
                            );
                            return;
                          }
                        }
                        setSheetState(() => reminderEnabled = v);
                      },
                      activeTrackColor: colors.accent,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.onAccent
                            : colors.textDim,
                      ),
                    ),
                  ],
                ),
                if (reminderEnabled) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: sheetCtx,
                        initialTime: reminderTime,
                        builder: (context, child) => MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: false),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => reminderTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceFlat,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 18, color: colors.accent),
                          const SizedBox(width: 8),
                          Text(
                            'Reminder time',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.deep,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            reminderTime.format(sheetCtx),
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      final provider = context.read<HabitProvider>();
                      final reminderHour =
                          reminderEnabled ? reminderTime.hour : null;
                      final reminderMinute =
                          reminderEnabled ? reminderTime.minute : null;
                      if (existing == null) {
                        provider.addHabit(
                          name,
                          selectedIcon,
                          reminderHour: reminderHour,
                          reminderMinute: reminderMinute,
                        );
                      } else {
                        provider.updateHabit(
                          existing,
                          name,
                          selectedIcon,
                          reminderHour: reminderHour,
                          reminderMinute: reminderMinute,
                        );
                      }
                      Navigator.pop(sheetCtx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accent,
                      foregroundColor: colors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      existing == null ? 'Add habit' : 'Save changes',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _confirmDelete(BuildContext context, Habit habit) {
  final colors = context.colors;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete habit?',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          color: colors.deep,
        ),
      ),
      content: Text(
        '"${habit.name}" and all its history will be deleted.',
        style: GoogleFonts.nunito(color: colors.accent),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: GoogleFonts.nunito(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<HabitProvider>().deleteHabit(habit);
            Navigator.pop(ctx);
          },
          child: Text(
            'Delete',
            style: GoogleFonts.nunito(
              color: colors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

void _showHabitOptionsSheet(BuildContext context, Habit habit) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: colors.accent),
            title: Text(
              'Edit',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: colors.deep,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetCtx);
              showHabitSheet(context, existing: habit);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.danger),
            title: Text(
              'Delete',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: colors.danger,
              ),
            ),
            onTap: () {
              _confirmDelete(context, habit);
              Navigator.pop(sheetCtx);
            },
          ),
        ],
      ),
    ),
  );
}

class HabitScreen extends StatelessWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final colors = context.colors;
    final habits = provider.habits;
    final doneCount = habits
        .where((h) => provider.isHabitDoneToday(h.id))
        .length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.deep,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Habits',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.deep,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.accent),
            onPressed: () => showHabitSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                habits.isEmpty
                    ? 'No habits yet'
                    : '$doneCount/${habits.length} done today',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: habits.isEmpty
                  ? Center(
                      child: Text(
                        'No habits yet\nTap + to add one',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: colors.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final isDone = provider.isHabitDoneToday(habit.id);
                        return GestureDetector(
                          onTap: () => provider.toggleHabit(habit.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 8,
                              bottom: 8,
                              right: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDone ? colors.mint : colors.surface,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: isDone ? null : colors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                if (isDone)
                                  Icon(
                                    habitIconFor(habit.iconName),
                                    color: colors.onMint,
                                    size: 22,
                                  )
                                else
                                  IconBadge(icon: habitIconFor(habit.iconName)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    habit.name,
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDone ? colors.onMint : colors.deep,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color:
                                        isDone ? colors.onMint : colors.accent,
                                  ),
                                  onPressed: () =>
                                      _showHabitOptionsSheet(context, habit),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
