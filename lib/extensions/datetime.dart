import 'package:intl/intl.dart';

/// Small helpers on top of [DateTime]. Centralised here instead of the two
/// separate anonymous extensions that used to live in `home.dart` and
/// `notification_service.dart`.
extension DateTimeX on DateTime {
  /// 1-based day of the year (Jan 1 = 1, Dec 31 = 365 or 366).
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }

  /// `true` when this date's day/month/year matches `DateTime.now()`.
  bool get isToday {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  /// HH:mm formatter — used for chat message timestamps.
  String formatChatTimestamp() => DateFormat('HH:mm').format(this);

  /// Human-readable date for chat message groupings: 'Yesterday' for 1
  /// day ago, weekday name for the past week, otherwise dd/MM/yy.
  String formatChatDate() {
    final now = DateTime.now();
    final difference = now.difference(this);
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return DateFormat('EEEE').format(this);
    return DateFormat('dd/MM/yy').format(this);
  }
}

/// Smoke-free duration formatter used by friend/profile rows. Replaces two
/// near-identical inline helpers that lived in `friends_main.dart` and
/// `forum.dart` with the same `days + remainder(24) hours` math.
extension QuitDuration on DateTime? {
  /// "5 days, 3 hours" for non-null `this`. If `this` is null returns the
  /// human-readable `Not available` fallback (some friend records don't
  /// expose a quit date).
  String formatSmokeFreeDuration() {
    final value = this;
    if (value == null) return 'Not available';
    final d = DateTime.now().difference(value);
    return '${d.inDays} days, ${d.inHours.remainder(24)} hours';
  }
}
