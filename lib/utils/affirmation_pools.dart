/// Reactions tuned to the specific mood level (1-5, matching [MoodEntry.mood])
/// rather than one flat pool for every mood — warmer for a great day,
/// gentler for a hard one. Great/good entries lean, very lightly, toward
/// making a note feel like a nice next thought rather than an instruction —
/// no "you should journal about this", just wording that leaves the door
/// open. Bad/terrible entries stay purely comforting on purpose — people
/// don't need to be nudged to dwell on or write up a bad day; they'll note
/// it themselves if they want to.
///
/// Shown as a small persistent line under the saved mood on Home, picked
/// deterministically per entry (see `_moodMessageFor` in home_screen.dart)
/// rather than as a toast that disappears in a couple seconds.
const Map<int, List<String>> kMoodAffirmationsByLevel = {
  5: [
    'Sounds like a good one — worth holding onto',
    'Love that for you',
    'That’s a nice one to remember',
    'Days like this are easy to forget later — good thing it’s saved',
    'Today’s a keeper',
  ],
  4: [
    'Glad today treated you well',
    'That’s a solid one',
    'Nice — good to hear',
    'A good day, noted',
  ],
  3: [
    'Noted',
    'Logged',
    'Thanks for checking in',
    'Saved',
  ],
  2: [
    'Sounds like a tough one — hope it eases up',
    'Some days are just hard',
    'Thanks for being honest about it',
    'Hope the rest of your day goes easier',
    'Be kind to yourself today',
  ],
  1: [
    'That sounds really hard — thanks for showing up anyway',
    'Be gentle with yourself today',
    'Hope tomorrow’s kinder to you',
    'Hard days count too',
    'Sending you an easier tomorrow',
  ],
};
