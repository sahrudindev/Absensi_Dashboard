import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/employee.dart';

/// Employee Detail Screen
/// 
/// Shows detailed attendance history for a single employee.

class EmployeeDetailScreen extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailScreen({
    super.key,
    required this.employee,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                employee.nama,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.3),
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        _buildAvatar(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Period info
                Text(
                  employee.periode,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Summary cards
                _buildSummaryRow(theme),
                
                const SizedBox(height: 24),
                
                // Section header
                Text(
                  'Riwayat Kehadiran',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Attendance list
                ...employee.data.reversed.map((record) =>
                  _buildRecordTile(theme, colorScheme, record),
                ),
                
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final isPositive = employee.totalBalanceMinutes > 0;
    final isNeutral = employee.totalBalanceMinutes == 0;
    
    Color bgColor;
    if (isNeutral) {
      bgColor = const Color(AppConfig.colorNeutral);
    } else if (isPositive) {
      bgColor = const Color(AppConfig.colorPositive);
    } else {
      bgColor = const Color(AppConfig.colorNegative);
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor.withOpacity(0.8), bgColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          employee.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isPositive = employee.totalBalanceMinutes > 0;
    final isNegative = employee.totalBalanceMinutes < 0;
    
    return Row(
      children: [
        // Working days
        Expanded(
          child: _buildSummaryCard(
            theme,
            '${employee.workingDays}',
            'Hari Kerja',
            Icons.calendar_today_rounded,
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        
        // Late days
        Expanded(
          child: _buildSummaryCard(
            theme,
            '${employee.lateDays}',
            'Terlambat',
            Icons.schedule_rounded,
            const Color(AppConfig.colorWarning),
          ),
        ),
        const SizedBox(width: 12),
        
        // Total balance
        Expanded(
          child: _buildSummaryCard(
            theme,
            employee.totalBalanceFormatted,
            'Balance',
            isPositive ? Icons.arrow_upward_rounded : 
              isNegative ? Icons.arrow_downward_rounded : Icons.remove,
            isPositive ? const Color(AppConfig.colorPositive) :
              isNegative ? const Color(AppConfig.colorNegative) :
              const Color(AppConfig.colorNeutral),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(
    ThemeData theme,
    ColorScheme colorScheme,
    AttendanceRecord record,
  ) {
    final isLate = record.isLate;
    final isHoliday = record.isLeaveOrHoliday;
    final hasData = record.isWorkingDay;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isHoliday) {
      statusColor = colorScheme.primary;
      statusIcon = Icons.event_busy_rounded;
      statusText = record.keterangan;
    } else if (!hasData) {
      statusColor = const Color(AppConfig.colorNegative);
      statusIcon = Icons.cancel_rounded;
      statusText = 'Tidak hadir';
    } else if (isLate) {
      statusColor = const Color(AppConfig.colorWarning);
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Terlambat';
    } else {
      statusColor = const Color(AppConfig.colorPositive);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Hadir';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDay(record.tanggal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      _getMonthShort(record.tanggal),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (hasData)
                      Text(
                        '${record.jamMasuk ?? '-'} - ${record.jamKeluar ?? '-'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (record.keterangan.isNotEmpty && !isHoliday)
                      Text(
                        record.keterangan,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Balance
              if (record.balance != null && record.balance!.isNotEmpty)
                _buildBalanceBadge(theme, record.balance!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(ThemeData theme, String balance) {
    final isNegative = balance.startsWith('-');
    final color = isNegative 
        ? const Color(AppConfig.colorNegative)
        : const Color(AppConfig.colorPositive);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        balance,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Simple date helpers without intl package
  String _getDay(String date) {
    try {
      final parts = date.split('-');
      return parts[2];
    } catch (e) {
      return '-';
    }
  }

  String _getMonthShort(String date) {
    const monthShort = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    try {
      final parts = date.split('-');
      final monthNum = int.parse(parts[1]);
      return monthShort[monthNum];
    } catch (e) {
      return '';
    }
  }
}
