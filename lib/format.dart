import 'package:cloud_firestore/cloud_firestore.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatTime(Timestamp? ts) {
  if (ts == null) return '';
  final d = ts.toDate().toLocal();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day} ${_months[d.month - 1]}, $h:$m $ampm';
}

String timeAgo(Timestamp? ts) {
  if (ts == null) return 'kabhi nahi';
  final diff = DateTime.now().difference(ts.toDate());
  if (diff.inSeconds < 60) return 'abhi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min pehle';
  if (diff.inHours < 24) return '${diff.inHours} ghante pehle';
  return '${diff.inDays} din pehle';
}
