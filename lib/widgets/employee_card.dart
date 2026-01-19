import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/employee.dart';

/// Employee Card Widget
/// 
/// Displays an employee with their attendance status and balance.

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final String? highlightDate;
  final VoidCallback? onTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.highlightDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get today's or highlighted date record
    final todayRecord = highlightDate != null 
        ? employee.getRecordForDate(highlightDate!)
        : employee.latestRecord;
    
    final totalBalance = employee.totalBalanceMinutes;
    final isPositive = totalBalance > 0;
    final isNeutral = totalBalance == 0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(colorScheme, isPositive, isNeutral),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      employee.nama,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Today's status
                    if (todayRecord != null)
                      _buildTodayStatus(theme, todayRecord)
                    else
                      Text(
                        'Tidak ada data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats row
                    Row(
                      children: [
                        _buildStatChip(
                          theme,
                          '${employee.workingDays} hari',
                          Icons.calendar_today_rounded,
                          colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        if (employee.lateDays > 0)
                          _buildStatChip(
                            theme,
                            '${employee.lateDays} terlambat',
                            Icons.schedule_rounded,
                            const Color(AppConfig.colorWarning),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Balance badge
              _buildBalanceBadge(theme, totalBalance, isPositive, isNeutral),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, bool isPositive, bool isNeutral) {
    Color bgColor;
    if (isNeutral) {
      bgColor = const Color(AppConfig.colorNeutral);
    } else if (isPositive) {
      bgColor = const Color(AppConfig.colorPositive);
    } else {
      bgColor = const Color(AppConfig.colorNegative);
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withOpacity(0.8),
            bgColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          employee.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatus(ThemeData theme, AttendanceRecord record) {
    final colorScheme = theme.colorScheme;
    
    if (record.isLeaveOrHoliday) {
      return Row(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              record.keterangan,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final jamMasuk = record.jamMasuk ?? '-';
    final jamKeluar = record.jamKeluar ?? '-';
    final isLate = record.isLate;

    return Row(
      children: [
        Icon(
          isLate ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          size: 14,
          color: isLate 
              ? const Color(AppConfig.colorWarning)
              : const Color(AppConfig.colorPositive),
        ),
        const SizedBox(width: 4),
        Text(
          '$jamMasuk - $jamKeluar',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        if (isLate) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(AppConfig.colorWarning).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Terlambat',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(AppConfig.colorWarning),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(ThemeData theme, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBadge(ThemeData theme, int minutes, bool isPositive, bool isNeutral) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    if (isNeutral) {
      bgColor = const Color(AppConfig.colorNeutral).withOpacity(0.1);
      textColor = const Color(AppConfig.colorNeutral);
      icon = Icons.remove;
    } else if (isPositive) {
      bgColor = const Color(AppConfig.colorPositive).withOpacity(0.1);
      textColor = const Color(AppConfig.colorPositive);
      icon = Icons.arrow_upward_rounded;
    } else {
      bgColor = const Color(AppConfig.colorNegative).withOpacity(0.1);
      textColor = const Color(AppConfig.colorNegative);
      icon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(height: 2),
          Text(
            employee.totalBalanceFormatted,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
