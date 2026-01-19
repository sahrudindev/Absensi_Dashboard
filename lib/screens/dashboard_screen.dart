import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/employee.dart';
import '../providers/attendance_provider.dart';

/// Dashboard Screen - Per Employee View
/// 
/// Displays attendance data for a selected employee and month
/// with bar chart, summary, and daily attendance list.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? _buildErrorView(state.error!, colorScheme)
                : _buildDashboard(state, theme, colorScheme),
      ),
    );
  }

  Widget _buildErrorView(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('Gagal Memuat Data', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.error)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => ref.read(dashboardProvider.notifier).refreshData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(DashboardState state, ThemeData theme, ColorScheme colorScheme) {
    final selectedEmployee = state.filteredEmployees.isNotEmpty 
        ? state.filteredEmployees.first 
        : null;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refreshData(),
      child: CustomScrollView(
        slivers: [
          // Header with selectors
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(AppConfig.companyName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 16),
                  // Filter chips row
                  Row(
                    children: [
                      Expanded(child: _buildEmployeeSelector(theme, colorScheme, state)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMonthSelector(theme, colorScheme, state)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (selectedEmployee != null) ...[
            // Employee info card (jadwal, cuti, sakit)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildEmployeeInfoCard(selectedEmployee, state, theme, colorScheme),
              ),
            ),
            
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummaryRow(selectedEmployee, state, theme, colorScheme),
              ),
            ),

            // Monthly bar chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMonthlyChart(selectedEmployee, theme, colorScheme),
              ),
            ),

            // Attendance list header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Riwayat Kehadiran',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                    Text('${selectedEmployee.data.length} hari',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
            ),

            // Daily attendance list (sorted descending - newest first)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Sort descending (newest first)
                  final sortedData = List<AttendanceRecord>.from(selectedEmployee.data)
                    ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
                  final record = sortedData[index];
                  return _buildAttendanceItem(record, theme, colorScheme);
                },
                childCount: selectedEmployee.data.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ] else
            SliverFillRemaining(
              child: Center(
                child: Text('Pilih karyawan untuk melihat data',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector(ThemeData theme, ColorScheme colorScheme, DashboardState state) {
    final employees = state.availableEmployees;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedEmployee,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
          hint: const Text('Pilih Karyawan'),
          items: employees.map((e) => DropdownMenuItem<String>(
            value: e['sheet'],
            child: Row(
              children: [
                Icon(Icons.person, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(e['nama'] ?? '', overflow: TextOverflow.ellipsis)),
              ],
            ),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(dashboardProvider.notifier).setSelectedEmployee(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme, ColorScheme colorScheme, DashboardState state) {
    final months = state.availableMonths;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedMonth,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.secondary),
          hint: const Text('Pilih Bulan'),
          items: months.map((month) => DropdownMenuItem<String>(
            value: month,
            child: Row(
              children: [
                Icon(Icons.calendar_month, size: 18, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(_formatMonth(month), overflow: TextOverflow.ellipsis)),
              ],
            ),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              ref.read(dashboardProvider.notifier).setSelectedMonth(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard(Employee employee, DashboardState state, ThemeData theme, ColorScheme colorScheme) {
    // Get full employee data for metadata (not filtered by month)
    final fullEmployee = state.employees.firstWhere(
      (e) => e.sheet == employee.sheet,
      orElse: () => employee,
    );
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer.withOpacity(0.3), colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee name & schedule
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(employee.initials, style: TextStyle(color: colorScheme.onPrimary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee.nama, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    if (fullEmployee.jamMasukAturan != null || fullEmployee.jamKeluarAturan != null)
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Jadwal: ${fullEmployee.jamMasukAturan ?? "-"} - ${fullEmployee.jamKeluarAturan ?? "-"}',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cuti & Sakit row
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  icon: Icons.beach_access,
                  label: 'Cuti',
                  value: '${fullEmployee.cutiAkhir ?? 0}',
                  subValue: fullEmployee.cutiAwal != null ? 'Awal: ${fullEmployee.cutiAwal}' : null,
                  color: Colors.blue,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoChip(
                  icon: Icons.local_hospital,
                  label: 'Sakit',
                  value: '${fullEmployee.sakitAkhir ?? 0}',
                  subValue: fullEmployee.sakitAwal != null ? 'Awal: ${fullEmployee.sakitAwal}' : null,
                  color: Colors.red.shade400,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
                Row(
                  children: [
                    Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                    if (subValue != null) ...[
                      const SizedBox(width: 6),
                      Text(subValue, style: theme.textTheme.labelSmall?.copyWith(color: color.withOpacity(0.7))),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Employee employee, DashboardState state, ThemeData theme, ColorScheme colorScheme) {
    final workingDays = employee.data.where((r) => r.isWorkingDay).length;
    final lateDays = employee.data.where((r) => r.isLate).length;
    
    final balance = employee.totalBalanceFormatted;
    final isNegativeBalance = employee.totalBalanceMinutes < 0;

    // Single row with 3 cards: Hari Kerja, Terlambat, Balance
    // Cuti & Sakit already shown in employee info card above
    return Row(
      children: [
        Expanded(child: _summaryCard(
          icon: Icons.calendar_today,
          label: 'Hari Kerja',
          value: '$workingDays',
          color: colorScheme.primary,
          theme: theme,
        )),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(
          icon: Icons.access_time,
          label: 'Terlambat',
          value: '$lateDays',
          color: Colors.orange,
          theme: theme,
        )),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(
          icon: Icons.account_balance_wallet,
          label: 'Balance',
          value: balance,
          color: isNegativeBalance ? Colors.red : Colors.green,
          theme: theme,
        )),
      ],
    );
  }

  Widget _summaryCardWithSubtitle({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7))),
              ),
            ],
          ),
          Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, color: color)),
          Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Employee employee, ThemeData theme, ColorScheme colorScheme) {
    // Sort data by date
    final sortedData = List<AttendanceRecord>.from(employee.data)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kehadiran Bulanan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
              // Legend
              Row(
                children: [
                  _legendDot(Colors.green, 'Hadir'),
                  const SizedBox(width: 12),
                  _legendDot(Colors.orange, 'Terlambat'),
                  const SizedBox(width: 12),
                  _legendDot(Colors.grey.shade400, 'Libur'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedData.map((record) {
                final isPresent = record.isWorkingDay;
                final isLate = record.isLate;
                final isHoliday = record.isLeaveOrHoliday;
                
                Color barColor;
                double height;
                
                if (isHoliday) {
                  barColor = Colors.grey.shade400;
                  height = 30;
                } else if (isLate) {
                  barColor = Colors.orange;
                  height = 60;
                } else if (isPresent) {
                  barColor = Colors.green;
                  height = 80;
                } else {
                  barColor = Colors.red.shade300;
                  height = 20;
                }

                // Get day number
                final day = record.tanggal.length >= 10 
                    ? record.tanggal.substring(8, 10) 
                    : '';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${record.tanggal}\n${record.keterangan.isNotEmpty ? record.keterangan : (isPresent ? (isLate ? "Terlambat" : "Hadir") : "Tidak Hadir")}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: height,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(day,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildAttendanceItem(AttendanceRecord record, ThemeData theme, ColorScheme colorScheme) {
    final isPresent = record.isWorkingDay;
    final isLate = record.isLate;
    final isHoliday = record.isLeaveOrHoliday;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (isHoliday) {
      statusColor = Colors.grey;
      statusIcon = Icons.event_busy;
      statusText = record.keterangan.isNotEmpty ? record.keterangan : 'Libur';
    } else if (isLate) {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
      statusText = 'Terlambat';
    } else if (isPresent) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Hadir';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Tidak Hadir';
    }

    // Parse date for day name
    String dayName = '';
    try {
      final date = DateTime.parse(record.tanggal);
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      dayName = days[date.weekday - 1];
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(record.tanggal.length >= 10 
                    ? record.tanggal.substring(8, 10) : '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: statusColor)),
                Text(dayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Status and times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: statusColor)),
                    // Keterangan info button
                    if (record.keterangan.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showKeteranganDialog(context, record, theme),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 12, color: colorScheme.primary),
                              const SizedBox(width: 2),
                              Text('Info', style: TextStyle(
                                fontSize: 10, color: colorScheme.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isPresent) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Masuk: ${record.jamMasuk ?? "-"} • Keluar: ${record.jamKeluar ?? "-"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ],
            ),
          ),
          // Balance
          if (record.balance != null && record.balance!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: record.balanceMinutes < 0 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(record.balance!,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: record.balanceMinutes < 0 ? Colors.red : Colors.green)),
            ),
        ],
      ),
    );
  }

  void _showKeteranganDialog(BuildContext context, AttendanceRecord record, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail ${record.tanggal}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.jamMasuk != null) ...[
              Text('Jam Masuk: ${record.jamMasuk}'),
              const SizedBox(height: 4),
            ],
            if (record.jamKeluar != null) ...[
              Text('Jam Keluar: ${record.jamKeluar}'),
              const SizedBox(height: 4),
            ],
            if (record.balance != null) ...[
              Text('Balance: ${record.balance}'),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Text('Keterangan:', style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.keterangan.isNotEmpty ? record.keterangan : '-',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String yyyyMM) {
    if (yyyyMM.length < 7) return yyyyMM;
    final year = yyyyMM.substring(0, 4);
    final month = int.tryParse(yyyyMM.substring(5, 7)) ?? 0;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${months[month]} $year';
  }
}
