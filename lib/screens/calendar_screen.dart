import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/attendance_provider.dart';
import '../models/employee.dart';

/// Calendar Screen - Monthly calendar view of attendance
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Set default employee if not set
    if (_selectedEmployeeId == null && state.employees.isNotEmpty) {
      _selectedEmployeeId = state.employees.first.nama;
    }

    // Find selected employee
    Employee? selectedEmployee;
    if (state.employees.isNotEmpty) {
      selectedEmployee = state.employees.firstWhere(
        (e) => e.nama == _selectedEmployeeId,
        orElse: () => state.employees.first,
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Kalender Kehadiran'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: state.employees.isEmpty
            ? _buildEmptyState(colorScheme)
            : _buildCalendar(state.employees, selectedEmployee!, theme, colorScheme),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Tidak ada data', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<Employee> employees, Employee employee, ThemeData theme, ColorScheme colorScheme) {
    final records = employee.data;
    final recordMap = <String, AttendanceRecord>{};
    for (final record in records) {
      recordMap[record.tanggal] = record;
    }

    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    return Column(
      children: [
        // Employee selector
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.person_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEmployeeId,
                      isExpanded: true,
                      items: employees.map((e) => DropdownMenuItem(
                        value: e.nama,
                        child: Text(e.nama, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedEmployeeId = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Month navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(_formatMonth(_focusedMonth), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(day, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6))),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox();
              final day = dayOffset + 1;
              final dateStr = '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final record = recordMap[dateStr];
              return _buildDayCell(day, record, theme, colorScheme);
            },
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(const Color(0xFF10B981), 'Hadir', colorScheme),
              _legendItem(const Color(0xFFF59E0B), 'Terlambat', colorScheme),
              _legendItem(const Color(0xFFEF4444), 'Tidak Hadir', colorScheme),
              _legendItem(Colors.grey, 'Libur/Cuti', colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(int day, AttendanceRecord? record, ThemeData theme, ColorScheme colorScheme) {
    Color bgColor = colorScheme.surfaceContainerHighest;
    Color textColor = colorScheme.onSurface.withOpacity(0.4);

    if (record != null) {
      // Priority: Libur/Cuti > Terlambat (working) > Hadir (working) > Tidak Hadir
      if (record.isLeaveOrHoliday) {
        // Libur, Cuti, Weekend, Sakit
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
      } else if (record.isWorkingDay && record.isLate) {
        // Hadir tapi terlambat
        bgColor = const Color(0xFFF59E0B).withOpacity(0.3);
        textColor = const Color(0xFFD97706);
      } else if (record.isWorkingDay) {
        // Hadir tepat waktu
        bgColor = const Color(0xFF10B981).withOpacity(0.3);
        textColor = const Color(0xFF059669);
      } else {
        // Tidak hadir (ada record tapi tidak ada jam masuk/keluar)
        bgColor = const Color(0xFFEF4444).withOpacity(0.3);
        textColor = const Color(0xFFDC2626);
      }
    }
    // If record is null = no data for that day (shown as default gray)

    return GestureDetector(
      onTap: record != null ? () => _showDayDetail(record, theme) : null,
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('$day', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: textColor))),
      ),
    );
  }

  Widget _legendItem(Color color, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.7))),
      ],
    );
  }

  void _showDayDetail(AttendanceRecord record, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.tanggal, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (record.jamMasuk != null) _detailRow(Icons.login_rounded, 'Jam Masuk', record.jamMasuk!, colorScheme),
            if (record.jamKeluar != null) _detailRow(Icons.logout_rounded, 'Jam Keluar', record.jamKeluar!, colorScheme),
            if (record.balance != null && record.balance!.isNotEmpty) _detailRow(Icons.account_balance_wallet_rounded, 'Balance', record.balance!, colorScheme),
            if (record.keterangan.isNotEmpty) _detailRow(Icons.info_outline_rounded, 'Keterangan', record.keterangan, colorScheme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[date.month]} ${date.year}';
  }
}
