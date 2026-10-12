import 'l10n.dart';

const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _monthsHi = ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'];

String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String dayMonth(DateTime d) =>
    '${d.day} ${(isHindi ? _monthsHi : _monthsEn)[d.month - 1]}';

String formatTime(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return '${tr('today')}, ${clock(d)}';
  if (day == today.subtract(const Duration(days: 1))) return '${tr('yesterday')}, ${clock(d)}';
  return '${dayMonth(d)}, ${clock(d)}';
}

String timeAgo(DateTime? d) {
  if (d == null) return tr('never');
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return tr('just_now');
  if (diff.inMinutes < 60) return tr('mins_ago', {'n': '${diff.inMinutes}'});
  if (diff.inHours < 24) return tr('hours_ago', {'n': '${diff.inHours}'});
  return tr('days_ago', {'n': '${diff.inDays}'});
}

String shortDuration(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
  return '${d.inHours}h ${d.inMinutes % 60}m';
}

/// "22:00" -> "10:00 PM"
String hhmmLabel(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p.first) ?? 0;
  final m = int.tryParse(p.length > 1 ? p[1] : '0') ?? 0;
  return clock(DateTime(2000, 1, 1, h, m));
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return tr('good_morning');
  if (h < 17) return tr('good_afternoon');
  return tr('good_evening');
}
