/// Context information for responsive time formatting
class TimeFormatContext {
  /// Duration of the visible time range
  final Duration visibleTimeSpan;

  /// Whether this is the first label
  final bool isFirstLabel;

  /// Whether this is the last label
  final bool isLastLabel;

  /// Position of the label (0-based)
  final int labelIndex;

  /// Total number of labels being displayed
  final int totalLabels;

  const TimeFormatContext({
    required this.visibleTimeSpan,
    required this.isFirstLabel,
    required this.isLastLabel,
    required this.labelIndex,
    required this.totalLabels,
  });
}

/// Flexible time formatter for custom time/date label formatting.
///
/// Implement this interface to provide custom time formatting logic.
/// Default implementation provides smart formatting based on time range.
abstract class TimeFormatter {
  /// Format a timestamp (seconds since epoch) for display
  ///
  /// [context] is optional and provides information about the visible time range
  /// and label position for responsive formatting. If not provided, formatters
  /// should use default behavior.
  String format(int timestamp, {TimeFormatContext? context});

  /// Default formatter that provides smart formatting based on time range
  factory TimeFormatter.smart() => _SmartTimeFormatter();

  /// Hour:Minute formatter (14:30)
  factory TimeFormatter.hourMinute() => _HourMinuteFormatter();

  /// Full date time formatter (2024-01-15 14:30)
  factory TimeFormatter.dateTime() => _DateTimeFormatter();

  /// Date only formatter (2024-01-15)
  factory TimeFormatter.dateOnly() => _DateOnlyFormatter();

  /// Day name formatter (Mon, Tue, etc.)
  factory TimeFormatter.dayName() => _DayNameFormatter();

  /// Custom formatter with format string (uses DateFormat pattern)
  factory TimeFormatter.custom(String pattern) => _CustomTimeFormatter(pattern);
}

/// Month name abbreviations (US format)
const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// Crosshair datetime formatter for "DD ShortMonth, YY HH:MM AM/PM" format
class CrosshairTimeFormatter implements TimeFormatter {
  /// Default constructor
  const CrosshairTimeFormatter();

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final day = date.day;
    final month = _monthNames[date.month - 1];
    final year = date.year.toString().substring(2); // Last 2 digits of year
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    // Convert to 12-hour format with AM/PM
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour < 12 ? 'AM' : 'PM';

    return '$day $month, $year $hour12:$minute $amPm';
  }
}

/// Responsive time formatter - adjusts format based on visible time range
/// TradingView-style: adapts format based on zoom level with proper date/time display
class _ResponsiveTimeFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    // If no context provided, use default hour:minute format
    if (context == null) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    final span = context.visibleTimeSpan;
    final isFirstOrLast = context.isFirstLabel || context.isLastLabel;
    final day = date.day;
    final month = date.month;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    // Format selection based on time span (TradingView-style logic)
    if (span.inDays >= 365) {
      // Years: Show year only (e.g., "2025", "2024")
      return year.toString();
    } else if (span.inDays >= 90) {
      // 3+ months: First/Last show "MMM YYYY", middle shows "MMM" (e.g., "Dec 2025", "Jan")
      if (isFirstOrLast) {
        return '${_monthNames[month - 1]} $year';
      } else {
        return _monthNames[month - 1];
      }
    } else if (span.inDays >= 30) {
      // 1-3 months: First/Last show "DD MMM YYYY", middle shows "DD MMM" (e.g., "15 Jan 2025", "15 Jan")
      if (isFirstOrLast) {
        // For first/last, show full date with year if span is large enough
        if (span.inDays >= 60) {
          return '$day ${_monthNames[month - 1]} $year';
        } else {
          return '$day ${_monthNames[month - 1]}'; // Use short month names consistently
        }
      } else {
        return '$day ${_monthNames[month - 1]}';
      }
    } else if (span.inDays >= 7) {
      // 1-4 weeks: Show "DD MMM" format (e.g., "15 Jan", "25 June")
      return '$day ${_monthNames[month - 1]}';
    } else if (span.inDays >= 1) {
      // 1-7 days: First/Last show "DD MMM HH:MM", middle shows "HH:MM" (e.g., "15 Jan 22:50", "22:50")
      if (isFirstOrLast) {
        return '$day ${_monthNames[month - 1]} $hour:$minute';
      } else {
        return '$hour:$minute';
      }
    } else if (span.inHours >= 1) {
      // 1-24 hours: First/Last show "DD MMM HH:MM", middle shows "HH:MM" (e.g., "15 Jan 22:50", "22:50")
      if (isFirstOrLast) {
        return '$day ${_monthNames[month - 1]} $hour:$minute';
      } else {
        return '$hour:$minute';
      }
    } else {
      // Less than 1 hour: First/Last show "DD MMM HH:MM:SS", middle shows "HH:MM:SS"
      final second = date.second.toString().padLeft(2, '0');
      if (isFirstOrLast) {
        return '$day ${_monthNames[month - 1]} $hour:$minute:$second';
      } else {
        return '$hour:$minute:$second';
      }
    }
  }
}

/// Legacy smart time formatter - kept for backward compatibility
/// Now uses responsive formatter internally
class _SmartTimeFormatter implements TimeFormatter {
  final _ResponsiveTimeFormatter _responsive = _ResponsiveTimeFormatter();

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    // If context provided, use responsive formatter
    if (context != null) {
      return _responsive.format(timestamp, context: context);
    }
    // Otherwise, default to hour:minute
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Hour:Minute formatter
class _HourMinuteFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Full date time formatter
class _DateTimeFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Date only formatter
class _DateOnlyFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Day name formatter
class _DayNameFormatter implements TimeFormatter {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return _dayNames[date.weekday - 1];
  }
}

/// Custom formatter using DateFormat pattern (requires intl package)
class _CustomTimeFormatter implements TimeFormatter {
  final String pattern;

  _CustomTimeFormatter(this.pattern);

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    // Basic implementation - can be enhanced with intl package for full DateFormat support
    // For now, provide common patterns manually
    if (pattern == 'MM/dd/yyyy') {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } else if (pattern == 'dd/MM/yyyy') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else if (pattern == 'HH:mm:ss') {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    }
    // Fallback to default
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
