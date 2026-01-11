/// ---------------------------------------------------------------------------
/// TIME FORMAT CONTEXT
/// ---------------------------------------------------------------------------
///
/// Provides contextual information to time formatters so they can
/// adapt output based on:
/// - Current zoom level
/// - Visible time span
/// - Label position (first / middle / last)
///
/// This enables TradingView-style responsive time labels where:
/// - Zoomed out → show years / months
/// - Zoomed in → show hours / seconds
/// - First & last labels often include more information
class TimeFormatContext {
  /// Total duration covered by the currently visible candles
  ///
  /// Used to decide whether to show:
  /// - Year
  /// - Month
  /// - Date
  /// - Time
  final Duration visibleTimeSpan;

  /// Whether this label is the first visible label on the axis
  final bool isFirstLabel;

  /// Whether this label is the last visible label on the axis
  final bool isLastLabel;

  /// Zero-based index of this label among visible labels
  final int labelIndex;

  /// Total number of labels currently displayed
  final int totalLabels;

  const TimeFormatContext({
    required this.visibleTimeSpan,
    required this.isFirstLabel,
    required this.isLastLabel,
    required this.labelIndex,
    required this.totalLabels,
  });
}

/// ---------------------------------------------------------------------------
/// TIME FORMATTER API
/// ---------------------------------------------------------------------------
///
/// Strategy interface for formatting timestamps on the X-axis and crosshair.
///
/// Design goals:
/// - Stateless
/// - Replaceable by users
/// - Context-aware (via [TimeFormatContext])
/// - No dependency on chart internals
///
/// Timestamp unit:
/// - `int timestamp` is **seconds since epoch**
///
/// Example usage:
/// ```dart
/// ChartStyle(
///   timeLabelStyle: TimeLabelStyle(
///     formatter: TimeFormatter.smart(),
///   ),
/// )
/// ```
abstract class TimeFormatter {
  /// Formats a timestamp (seconds since epoch) into a display string.
  ///
  /// [context] provides information about:
  /// - Visible time span
  /// - Whether this label is first or last
  /// - Label density
  ///
  /// If [context] is null, formatters should fall back to a reasonable default.
  String format(int timestamp, {TimeFormatContext? context});

  /// -------------------------------------------------------------------------
  /// FACTORY CONSTRUCTORS (PUBLIC API)
  /// -------------------------------------------------------------------------

  /// Smart formatter that adapts output based on zoom level.
  ///
  /// This is the recommended default and mimics TradingView behavior.
  factory TimeFormatter.smart() => _SmartTimeFormatter();

  /// Simple hour:minute formatter (24h format).
  ///
  /// Example: "14:30"
  factory TimeFormatter.hourMinute() => _HourMinuteFormatter();

  /// Full date + time formatter.
  ///
  /// Example: "2024-01-15 14:30"
  factory TimeFormatter.dateTime() => _DateTimeFormatter();

  /// Date-only formatter.
  ///
  /// Example: "2024-01-15"
  factory TimeFormatter.dateOnly() => _DateOnlyFormatter();

  /// Day name formatter.
  ///
  /// Example: "Mon", "Tue"
  factory TimeFormatter.dayName() => _DayNameFormatter();

  /// Custom formatter using a format pattern.
  ///
  /// Note:
  /// - This is a lightweight implementation
  /// - Does NOT depend on `intl`
  /// - Supports a limited set of common patterns
  factory TimeFormatter.custom(String pattern) => _CustomTimeFormatter(pattern);
}

/// ---------------------------------------------------------------------------
/// SHARED CONSTANTS
/// ---------------------------------------------------------------------------

/// Month name abbreviations (US locale)
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

/// ---------------------------------------------------------------------------
/// CROSSHAIR FORMATTER
/// ---------------------------------------------------------------------------
///
/// Dedicated formatter for crosshair tooltips.
///
/// Format:
///   DD Mon, YY HH:MM AM/PM
///
/// Example:
///   "15 Jan, 25 10:42 PM"
///
/// This formatter:
/// - Ignores [TimeFormatContext]
/// - Always shows full precision
/// - Is designed for inspection, not axis labels
class CrosshairTimeFormatter implements TimeFormatter {
  const CrosshairTimeFormatter();

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    final day = date.day;
    final month = _monthNames[date.month - 1];
    final year = date.year.toString().substring(2);

    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');

    // Convert to 12-hour clock
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm = hour < 12 ? 'AM' : 'PM';

    return '$day $month, $year $hour12:$minute $amPm';
  }
}

/// ---------------------------------------------------------------------------
/// RESPONSIVE TIME FORMATTER (CORE LOGIC)
/// ---------------------------------------------------------------------------
///
/// Implements TradingView-style adaptive time formatting.
///
/// Formatting rules depend on:
/// - Total visible time span
/// - Label position (first / last get more info)
///
/// This formatter is INTERNAL and should not be used directly.
/// Public access is via [TimeFormatter.smart].
class _ResponsiveTimeFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    // No context → fallback to HH:MM
    if (context == null) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    final span = context.visibleTimeSpan;
    final isEdge = context.isFirstLabel || context.isLastLabel;

    final day = date.day;
    final month = date.month;
    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    // === YEAR SCALE ===
    if (span.inDays >= 365) {
      return year.toString();
    }

    // === MONTH SCALE (3+ months) ===
    if (span.inDays >= 90) {
      return isEdge
          ? '${_monthNames[month - 1]} $year'
          : _monthNames[month - 1];
    }

    // === DATE SCALE (1–3 months) ===
    if (span.inDays >= 30) {
      return isEdge && span.inDays >= 60
          ? '$day ${_monthNames[month - 1]} $year'
          : '$day ${_monthNames[month - 1]}';
    }

    // === WEEK SCALE ===
    if (span.inDays >= 7) {
      return '$day ${_monthNames[month - 1]}';
    }

    // === DAY / HOUR SCALE ===
    if (span.inDays >= 1 || span.inHours >= 1) {
      return isEdge
          ? '$day ${_monthNames[month - 1]} $hour:$minute'
          : '$hour:$minute';
    }

    // === MINUTE / SECOND SCALE ===
    final second = date.second.toString().padLeft(2, '0');
    return isEdge
        ? '$day ${_monthNames[month - 1]} $hour:$minute:$second'
        : '$hour:$minute:$second';
  }
}

/// ---------------------------------------------------------------------------
/// LEGACY SMART FORMATTER
/// ---------------------------------------------------------------------------
///
/// Kept for backward compatibility.
///
/// Internally delegates to [_ResponsiveTimeFormatter] when context is available.
class _SmartTimeFormatter implements TimeFormatter {
  final _ResponsiveTimeFormatter _responsive = _ResponsiveTimeFormatter();

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    if (context != null) {
      return _responsive.format(timestamp, context: context);
    }

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// ---------------------------------------------------------------------------
/// SIMPLE FORMATTERS
/// ---------------------------------------------------------------------------

/// Hour:Minute formatter (24-hour clock)
class _HourMinuteFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Full date + time formatter
class _DateTimeFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Date-only formatter
class _DateOnlyFormatter implements TimeFormatter {
  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

/// Day-of-week formatter
class _DayNameFormatter implements TimeFormatter {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return _dayNames[date.weekday - 1];
  }
}

/// ---------------------------------------------------------------------------
/// CUSTOM FORMATTER
/// ---------------------------------------------------------------------------
///
/// Lightweight custom formatter without intl dependency.
///
/// Supports a small subset of common patterns.
/// Falls back safely when pattern is unknown.
class _CustomTimeFormatter implements TimeFormatter {
  final String pattern;

  _CustomTimeFormatter(this.pattern);

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    if (pattern == 'MM/dd/yyyy') {
      return '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}/${date.year}';
    } else if (pattern == 'dd/MM/yyyy') {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else if (pattern == 'HH:mm:ss') {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}:'
          '${date.second.toString().padLeft(2, '0')}';
    }

    // Fallback
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Default **const-safe** time formatter used by [TimeLabelStyle].
///
/// This formatter is designed to:
/// - Be usable inside `const` constructors
/// - Support **responsive formatting** when [TimeFormatContext] is provided
/// - Mimic TradingView-style adaptive time labels
///
/// Behavior:
/// - If [context] is `null`:
///   → Falls back to simple `HH:mm` format
/// - If [context] is provided:
///   → Adapts formatting based on visible time span and label position
///
/// This formatter is intentionally duplicated (instead of reusing
/// `_ResponsiveTimeFormatter`) to:
/// - Preserve const compatibility
/// - Avoid runtime allocations
/// - Keep style defaults lightweight and deterministic
class DefaultTimeFormatter implements TimeFormatter {
  /// Const constructor for use in const widget/style trees
  const DefaultTimeFormatter();

  /// Month name abbreviations (US format).
  ///
  /// Duplicated here instead of reused from another file
  /// because:
  /// - Static const is required for const-safe formatting
  /// - Avoids indirect dependencies
  static const _monthNames = [
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

  @override
  String format(int timestamp, {TimeFormatContext? context}) {
    // Convert seconds since epoch → DateTime
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    // If no context is available, use a safe default
    // This keeps behavior predictable when formatter is used standalone
    if (context == null) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Responsive formatting based on visible time span
    final span = context.visibleTimeSpan;
    final isFirstOrLast = context.isFirstLabel || context.isLastLabel;

    final day = date.day;
    final month = date.month;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    // === TradingView-style adaptive formatting ===

    // Very large ranges → show year only
    if (span.inDays >= 365) {
      return year.toString();
    }

    // Multi-month ranges → emphasize first/last labels
    else if (span.inDays >= 90) {
      return isFirstOrLast
          ? '${_monthNames[month - 1]} $year'
          : _monthNames[month - 1];
    }

    // Monthly ranges → show day + month, optionally year
    else if (span.inDays >= 30) {
      if (isFirstOrLast) {
        return span.inDays >= 60
            ? '$day ${_monthNames[month - 1]} $year'
            : '$day ${_monthNames[month - 1]}';
      } else {
        return '$day ${_monthNames[month - 1]}';
      }
    }

    // Weekly ranges → date only
    else if (span.inDays >= 7) {
      return '$day ${_monthNames[month - 1]}';
    }

    // Daily ranges → mix date and time
    else if (span.inDays >= 1 || span.inHours >= 1) {
      return isFirstOrLast
          ? '$day ${_monthNames[month - 1]} $hour:$minute'
          : '$hour:$minute';
    }

    // Intraday / very small ranges → include seconds
    else {
      final second = date.second.toString().padLeft(2, '0');
      return isFirstOrLast
          ? '$day ${_monthNames[month - 1]} $hour:$minute:$second'
          : '$hour:$minute:$second';
    }
  }
}
