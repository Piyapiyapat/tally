import 'dart:math';

class _Greeting {
  final String withName;
  final String withoutName;
  const _Greeting(this.withName, this.withoutName);
}

const List<_Greeting> _morning = [
  _Greeting('Good morning, {name}', 'Good morning'),
  _Greeting('Morning, {name}', 'Morning'),
  _Greeting('Rise and shine, {name}', 'Rise and shine'),
  _Greeting('Hope you slept well, {name}', 'Hope you slept well'),
  _Greeting('A new day, {name}', 'A new day'),
];

const List<_Greeting> _afternoon = [
  _Greeting('Good afternoon, {name}', 'Good afternoon'),
  _Greeting("Hey {name}, how's your day going?", "How's your day going?"),
  _Greeting('Afternoon, {name}', 'Afternoon'),
  _Greeting(
    "Hope today's treating you well, {name}",
    "Hope today's treating you well",
  ),
];

const List<_Greeting> _evening = [
  _Greeting('Good evening, {name}', 'Good evening'),
  _Greeting('Evening, {name}', 'Evening'),
  _Greeting('Winding down, {name}?', 'Winding down?'),
  _Greeting(
    'Hope today treated you well, {name}',
    'Hope today treated you well',
  ),
];

const List<_Greeting> _lateNight = [
  _Greeting('Still up, {name}?', 'Still up?'),
  _Greeting('Late one tonight, {name}', 'Late one tonight'),
  _Greeting('Quiet hours, {name}', 'Quiet hours'),
  _Greeting('Burning the midnight oil, {name}?', 'Burning the midnight oil?'),
];

/// Deterministic-per-day greeting: the same time bracket on the same
/// calendar day always resolves to the same phrase (seeded from the date
/// + bracket index), and picks freshly again on the next day.
///
/// [name] is the display name to interpolate; pass `null` or an empty
/// string to fall back to phrasing that doesn't require a name.
String buildGreeting(DateTime now, String? name) {
  final hour = now.hour;
  late final List<_Greeting> pool;
  late final int bracketIndex;
  if (hour >= 5 && hour < 12) {
    pool = _morning;
    bracketIndex = 0;
  } else if (hour >= 12 && hour < 17) {
    pool = _afternoon;
    bracketIndex = 1;
  } else if (hour >= 17 && hour < 21) {
    pool = _evening;
    bracketIndex = 2;
  } else {
    pool = _lateNight;
    bracketIndex = 3;
  }

  final seed = now.year * 10000 + now.month * 100 + now.day + bracketIndex;
  final greeting = pool[Random(seed).nextInt(pool.length)];

  final trimmedName = name?.trim() ?? '';
  return trimmedName.isEmpty
      ? greeting.withoutName
      : greeting.withName.replaceAll('{name}', trimmedName);
}
