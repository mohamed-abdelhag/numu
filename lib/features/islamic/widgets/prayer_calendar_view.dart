import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prayer_day_stats.dart';
import '../providers/prayer_stats_provider.dart';

/// Widget that displays a month calendar showing prayer completion for each day.
/// Shows colored indicators for obligatory and Nafila prayer completion.
///
/// **Validates: Requirements 4.1, 4.2**
class PrayerCalendarView extends ConsumerWidget {
  final Function(DateTime)? onDayTapped;

  const PrayerCalendarView({
    super.key,
    this.onDayTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(prayerStatsProvider);

    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Failed to load calendar: $error',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      data: (statsState) => _buildCalendar(context, ref, statsState),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    WidgetRef ref,
    PrayerStatsState statsState,
  ) {
    final selectedMonth = statsState.selectedMonth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month navigation header
            _buildMonthHeader(context, ref, selectedMonth),
            const SizedBox(height: 16),
            // Weekday headers
            _buildWeekdayHeaders(context),
            const SizedBox(height: 8),
            // Calendar grid
            _buildCalendarGrid(context, statsState),
            const SizedBox(height: 16),
            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }


  /// Build the month navigation header with arrows.
  Widget _buildMonthHeader(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedMonth,
  ) {
    final theme = Theme.of(context);
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _navigateMonth(ref, selectedMonth, -1),
          tooltip: 'Previous month',
        ),
        Text(
          '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _canNavigateForward(selectedMonth)
              ? () => _navigateMonth(ref, selectedMonth, 1)
              : null,
          tooltip: 'Next month',
        ),
      ],
    );
  }

  /// Navigate to previous or next month.
  void _navigateMonth(WidgetRef ref, DateTime currentMonth, int delta) {
    final newMonth = DateTime(
      currentMonth.year,
      currentMonth.month + delta,
      1,
    );
    ref.read(prayerStatsProvider.notifier).loadStatsForMonth(newMonth);
  }

  /// Check if we can navigate forward (not beyond current month).
  bool _canNavigateForward(DateTime selectedMonth) {
    final now = DateTime.now();
    return selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);
  }

  /// Build weekday headers (Mo, Tu, We, etc.).
  Widget _buildWeekdayHeaders(BuildContext context) {
    const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build the calendar grid with prayer completion indicators.
  Widget _buildCalendarGrid(BuildContext context, PrayerStatsState statsState) {
    final selectedMonth = statsState.selectedMonth;
    final dates = _generateMonthDates(selectedMonth);
    final weeks = _groupIntoWeeks(dates);

    return Column(
      children: weeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((date) {
              return Expanded(
                child: _buildDayCell(context, date, statsState),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  /// Generate all dates to display for a month (including padding days).
  List<DateTime?> _generateMonthDates(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;
    
    final dates = <DateTime?>[];
    
    // Add padding for days before the first of the month
    for (var i = 1; i < firstWeekday; i++) {
      dates.add(null);
    }
    
    // Add all days of the month
    for (var day = 1; day <= lastDayOfMonth.day; day++) {
      dates.add(DateTime(month.year, month.month, day));
    }
    
    // Add padding to complete the last week
    while (dates.length % 7 != 0) {
      dates.add(null);
    }
    
    return dates;
  }

  /// Group dates into weeks.
  List<List<DateTime?>> _groupIntoWeeks(List<DateTime?> dates) {
    final weeks = <List<DateTime?>>[];
    for (var i = 0; i < dates.length; i += 7) {
      weeks.add(dates.sublist(i, i + 7));
    }
    return weeks;
  }


  /// Build a single day cell in the calendar.
  Widget _buildDayCell(
    BuildContext context,
    DateTime? date,
    PrayerStatsState statsState,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Empty cell for padding days
    if (date == null) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }

    final isToday = _isToday(date);
    final isFuture = date.isAfter(DateTime.now());
    final stats = statsState.getStatsForDate(date);

    // Determine cell appearance based on completion
    Color backgroundColor;
    Widget? indicator;

    if (isFuture) {
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.2);
    } else if (stats == null) {
      // No data for this day
      backgroundColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.1);
    } else {
      // Calculate completion level
      final obligatoryPercent = stats.obligatoryPercentage;

      backgroundColor = _getBackgroundColor(colorScheme, obligatoryPercent);
      indicator = _buildCompletionIndicator(context, stats);
    }

    return InkWell(
      onTap: isFuture || stats == null
          ? null
          : () => onDayTapped?.call(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isToday
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isFuture
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                      : colorScheme.onSurface,
                ),
              ),
              if (indicator != null && !isFuture) indicator,
            ],
          ),
        ),
      ),
    );
  }

  /// Get background color based on obligatory prayer completion percentage.
  Color _getBackgroundColor(ColorScheme colorScheme, int percentage) {
    if (percentage == 100) {
      return Colors.green.withValues(alpha: 0.3);
    } else if (percentage >= 80) {
      return Colors.green.withValues(alpha: 0.2);
    } else if (percentage >= 60) {
      return Colors.amber.withValues(alpha: 0.2);
    } else if (percentage >= 40) {
      return Colors.orange.withValues(alpha: 0.2);
    } else if (percentage > 0) {
      return Colors.red.withValues(alpha: 0.15);
    } else {
      return Colors.red.withValues(alpha: 0.1);
    }
  }

  /// Build completion indicator showing obligatory and Nafila status.
  Widget _buildCompletionIndicator(BuildContext context, PrayerDayStats stats) {
    final obligatoryCount = stats.obligatoryCompletedCount;
    final nafilaCount = stats.definedNafilaCompletedCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Obligatory indicator (filled circle)
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getIndicatorColor(obligatoryCount, 5),
          ),
        ),
        const SizedBox(width: 2),
        // Nafila indicator (ring)
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _getIndicatorColor(nafilaCount, 3),
              width: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Get indicator color based on completion count.
  Color _getIndicatorColor(int completed, int total) {
    if (completed == total) {
      return Colors.green;
    } else if (completed > 0) {
      return Colors.amber;
    } else {
      return Colors.red.withValues(alpha: 0.5);
    }
  }

  /// Check if a date is today.
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Build the legend explaining the indicators.
  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          context,
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          'All prayers',
        ),
        _buildLegendItem(
          context,
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          'Partial',
        ),
        _buildLegendItem(
          context,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          'Obligatory',
        ),
        _buildLegendItem(
          context,
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 1.5),
            ),
          ),
          'Nafila',
        ),
      ],
    );
  }

  /// Build a single legend item.
  Widget _buildLegendItem(BuildContext context, Widget indicator, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
