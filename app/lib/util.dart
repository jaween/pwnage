import 'package:intl/intl.dart';

String formatDateTime(DateTime target) {
  final now = DateTime.now();
  final difference = now.difference(target);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
  } else if (difference.inHours < 12) {
    return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
  } else {
    final targetDate = DateTime(target.year, target.month, target.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final timeString = DateFormat('h:mm a').format(target);

    if (targetDate == today) {
      return timeString;
    } else if (targetDate == yesterday) {
      return 'Yesterday at $timeString';
    } else {
      final dateString = DateFormat('yyyy.MM.dd').format(target);
      return dateString;
    }
  }
}
