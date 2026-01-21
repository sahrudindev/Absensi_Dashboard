import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/attendance_provider.dart';
import '../models/employee.dart';

/// Comparison Screen - Monthly comparison and employee rankings
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  String? _selectedMonth;
  String _selectedRanking = 'overall'; // 'overall', 'punctuality', 'balance'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final availableMonths = _getAvailableMonths(state.employees);
    
    if (_selectedMonth == null && availableMonths.isNotEmpty) {
      _selectedMonth = availableMonths.first;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rekap & Perbandingan'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: state.employees.isEmpty
            ? _buildEmptyState(colorScheme)
            : _buildContent(state, availableMonths, theme, colorScheme),
      ),
    );
  }

  List<String> _getAvailableMonths(List<Employee> employees) {
    final months = <String>{};
    for (final emp in employees) {
      for (final record in emp.data) {
        if (record.tanggal.length >= 7) {
          months.add(record.tanggal.substring(0, 7));
        }
      }
    }
    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_rounded, size: 64, color: colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Tidak ada data', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardState state, List<String> months, ThemeData theme, ColorScheme colorScheme) {
    List<Map<String, dynamic>> rankings;
    String title;
    String subtitle;

    switch (_selectedRanking) {
      case 'punctuality':
        rankings = _calculatePunctualityRanking(state.employees, _selectedMonth);
        title = '⏰ Ranking Ketepatan Waktu';
        subtitle = 'Karyawan dengan hari terlambat paling sedikit';
        break;
      case 'balance':
        rankings = _calculateBalanceRanking(state.employees, _selectedMonth);
        title = '💰 Ranking Balance Positif';
        subtitle = 'Karyawan dengan jam kerja lebih paling banyak';
        break;
      default:
        rankings = _calculateOverallRanking(state.employees, _selectedMonth);
        title = '🏆 Ranking Keseluruhan';
        subtitle = 'Kombinasi ketepatan waktu + balance';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Bulan:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      isExpanded: true,
                      items: months.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_formatMonthFull(m)),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedMonth = value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Ranking type toggle buttons
        Row(
          children: [
            Expanded(child: _buildRankingButton('overall', '🏆 Keseluruhan', colorScheme)),
            const SizedBox(width: 8),
            Expanded(child: _buildRankingButton('punctuality', '⏰ Tepat Waktu', colorScheme)),
            const SizedBox(width: 8),
            Expanded(child: _buildRankingButton('balance', '💰 Balance', colorScheme)),
          ],
        ),

        const SizedBox(height: 24),

        // Title
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 16),

        // Rankings list (original card style)
        ...rankings.asMap().entries.map((entry) {
          final index = entry.key;
          final ranking = entry.value;
          return _RankingCard(
            rank: index + 1,
            employee: ranking['employee'] as Employee,
            stats: ranking,
            rankingType: _selectedRanking,
            theme: theme,
            colorScheme: colorScheme,
          );
        }),

        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildRankingButton(String value, String label, ColorScheme colorScheme) {
    final isSelected = _selectedRanking == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRanking = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculatePunctualityRanking(List<Employee> employees, String? month) {
    final rankings = <Map<String, dynamic>>[];
    for (final emp in employees) {
      final records = month != null ? emp.data.where((r) => r.tanggal.startsWith(month)).toList() : emp.data;
      final lateDays = records.where((r) => r.isLate).length;
      final workingDays = records.where((r) => r.isWorkingDay).length;
      
      // Skip employees with no data for this month
      if (workingDays == 0 && records.isEmpty) continue;
      
      rankings.add({'employee': emp, 'lateDays': lateDays, 'workingDays': workingDays, 'balance': emp.totalBalanceFormatted, 'balanceMinutes': emp.totalBalanceMinutes});
    }
    rankings.sort((a, b) => (a['lateDays'] as int).compareTo(b['lateDays'] as int));
    return rankings;
  }

  List<Map<String, dynamic>> _calculateBalanceRanking(List<Employee> employees, String? month) {
    final rankings = <Map<String, dynamic>>[];
    for (final emp in employees) {
      final records = month != null ? emp.data.where((r) => r.tanggal.startsWith(month)).toList() : emp.data;
      
      // Skip employees with no data for this month
      final workingDays = records.where((r) => r.isWorkingDay).length;
      if (workingDays == 0 && records.isEmpty) continue;
      
      int totalMinutes = 0;
      for (final record in records) {
        if (record.balance != null && record.balance!.isNotEmpty) {
          final isNegative = record.balance!.contains('-');
          final parts = record.balance!.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
          if (parts.length >= 2) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final mins = int.tryParse(parts[1]) ?? 0;
            totalMinutes += isNegative ? -(hours * 60 + mins) : (hours * 60 + mins);
          }
        }
      }
      final hrs = totalMinutes.abs() ~/ 60;
      final mins = totalMinutes.abs() % 60;
      rankings.add({
        'employee': emp,
        'balance': '${totalMinutes < 0 ? "-" : "+"}$hrs:${mins.toString().padLeft(2, '0')}',
        'balanceMinutes': totalMinutes,
        'lateDays': records.where((r) => r.isLate).length,
        'workingDays': workingDays,
      });
    }
    rankings.sort((a, b) => (b['balanceMinutes'] as int).compareTo(a['balanceMinutes'] as int));
    return rankings;
  }

  List<Map<String, dynamic>> _calculateOverallRanking(List<Employee> employees, String? month) {
    final rankings = <Map<String, dynamic>>[];
    for (final emp in employees) {
      final records = month != null ? emp.data.where((r) => r.tanggal.startsWith(month)).toList() : emp.data;
      final workingDays = records.where((r) => r.isWorkingDay).length;
      final lateDays = records.where((r) => r.isLate).length;
      
      // Skip employees with no data for this month
      if (workingDays == 0 && records.isEmpty) continue;
      
      int totalMinutes = 0;
      for (final record in records) {
        if (record.balance != null && record.balance!.isNotEmpty) {
          final isNegative = record.balance!.contains('-');
          final parts = record.balance!.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
          if (parts.length >= 2) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final mins = int.tryParse(parts[1]) ?? 0;
            totalMinutes += isNegative ? -(hours * 60 + mins) : (hours * 60 + mins);
          }
        }
      }
      final score = (workingDays * 10) + (totalMinutes / 10) - (lateDays * 20);
      final hrs = totalMinutes.abs() ~/ 60;
      final mins = totalMinutes.abs() % 60;
      rankings.add({
        'employee': emp,
        'score': score.round(),
        'workingDays': workingDays,
        'lateDays': lateDays,
        'balance': '${totalMinutes < 0 ? "-" : "+"}$hrs:${mins.toString().padLeft(2, '0')}',
        'balanceMinutes': totalMinutes,
      });
    }
    rankings.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return rankings;
  }

  String _formatMonthFull(String yyyyMM) {
    if (yyyyMM.length < 7) return yyyyMM;
    final year = yyyyMM.substring(0, 4);
    final month = int.tryParse(yyyyMM.substring(5, 7)) ?? 0;
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[month]} $year';
  }
}

class _RankingCard extends StatelessWidget {
  final int rank;
  final Employee employee;
  final Map<String, dynamic> stats;
  final String rankingType;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _RankingCard({
    required this.rank,
    required this.employee,
    required this.stats,
    required this.rankingType,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    } else {
      rankColor = colorScheme.outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3 ? Border.all(color: rankColor.withOpacity(0.5), width: 2) : null,
        boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: rankColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Center(child: rank <= 3 ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 24) : Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: rankColor))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.nama, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _statChip(Icons.work_rounded, '${stats['workingDays']} hari'),
                    const SizedBox(width: 8),
                    _statChip(Icons.timer_rounded, '${stats['lateDays']} telat'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (stats['balanceMinutes'] as int) >= 0 ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              stats['balance'] as String,
              style: TextStyle(fontWeight: FontWeight.bold, color: (stats['balanceMinutes'] as int) >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }
}
