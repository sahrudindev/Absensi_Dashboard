import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Summary Card Widget
/// 
/// Beautiful animated card for displaying statistics.

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  // Factory constructors for common card types
  factory SummaryCard.total({required int value}) => SummaryCard(
    title: 'Total',
    value: value.toString(),
    icon: Icons.people_rounded,
    color: const Color(AppConfig.colorCardTotal),
    subtitle: 'Karyawan',
  );

  factory SummaryCard.hadir({required int value}) => SummaryCard(
    title: 'Hadir',
    value: value.toString(),
    icon: Icons.check_circle_rounded,
    color: const Color(AppConfig.colorCardHadir),
    subtitle: 'Tepat waktu',
  );

  factory SummaryCard.terlambat({required int value}) => SummaryCard(
    title: 'Terlambat',
    value: value.toString(),
    icon: Icons.schedule_rounded,
    color: const Color(AppConfig.colorCardTerlambat),
    subtitle: 'Hari ini',
  );

  factory SummaryCard.tidakHadir({required int value}) => SummaryCard(
    title: 'Tidak Hadir',
    value: value.toString(),
    icon: Icons.cancel_rounded,
    color: const Color(AppConfig.colorCardTidakHadir),
    subtitle: 'Absen',
  );

  factory SummaryCard.rate({required double value}) => SummaryCard(
    title: 'Rate',
    value: '${value.toStringAsFixed(0)}%',
    icon: Icons.trending_up_rounded,
    color: const Color(AppConfig.colorCardTotal),
    subtitle: 'Kehadiran',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
              ],
            ),
            
            const Spacer(),
            
            // Value
            Text(
              value,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Title
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Attendance Rate Card with circular progress
class AttendanceRateCard extends StatelessWidget {
  final double rate;
  final int totalPresent;
  final int totalEmployees;

  const AttendanceRateCard({
    super.key,
    required this.rate,
    required this.totalPresent,
    required this.totalEmployees,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Circular progress
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: rate / 100,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 80 
                          ? const Color(AppConfig.colorPositive)
                          : rate >= 50 
                              ? const Color(AppConfig.colorWarning)
                              : const Color(AppConfig.colorNegative),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${rate.toStringAsFixed(0)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 24),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tingkat Kehadiran',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalPresent dari $totalEmployees karyawan hadir hari ini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
