import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/attendance_provider.dart';
import '../config/app_config.dart';

/// Report Screen - Export attendance reports to PDF
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedEmployee = state.filteredEmployees.isNotEmpty 
        ? state.filteredEmployees.first 
        : null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee info
              if (selectedEmployee != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        child: Text(
                          selectedEmployee.initials,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedEmployee.nama,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state.selectedMonth != null 
                                  ? _formatMonth(state.selectedMonth!)
                                  : 'Semua Bulan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                'Export Laporan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Export options
              _ExportCard(
                icon: Icons.picture_as_pdf_rounded,
                title: 'Export PDF',
                subtitle: 'Laporan dengan format dokumen',
                color: const Color(0xFFEF4444),
                onTap: selectedEmployee != null 
                    ? () => _exportPdf(context, selectedEmployee, state.selectedMonth)
                    : null,
              ),
              const SizedBox(height: 12),
              _ExportCard(
                icon: Icons.print_rounded,
                title: 'Print / Preview',
                subtitle: 'Preview dan print langsung',
                color: const Color(0xFF3B82F6),
                onTap: selectedEmployee != null 
                    ? () => _printPreview(context, selectedEmployee, state.selectedMonth)
                    : null,
              ),

              const SizedBox(height: 24),

              // Summary stats
              if (selectedEmployee != null) ...[
                Text(
                  'Ringkasan Data',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Hari',
                        value: '${selectedEmployee.data.length}',
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Hari Kerja',
                        value: '${selectedEmployee.data.where((r) => r.isWorkingDay).length}',
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Terlambat',
                        value: '${selectedEmployee.data.where((r) => r.isLate).length}',
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Pilih karyawan di Dashboard untuk export laporan',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, dynamic employee, String? month) async {
    final pdf = await _generatePdf(employee, month);
    
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'laporan_${employee.nama.replaceAll(' ', '_')}_${month ?? 'all'}.pdf',
    );
  }

  Future<void> _printPreview(BuildContext context, dynamic employee, String? month) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = await _generatePdf(employee, month);
        return pdf.save();
      },
    );
  }

  Future<pw.Document> _generatePdf(dynamic employee, String? month) async {
    final pdf = pw.Document();
    final data = employee.data as List;
    
    // Sort data by date
    final sortedData = List.from(data)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    // Calculate summary
    final workingDays = data.where((r) => r.isWorkingDay).length;
    final lateDays = data.where((r) => r.isLate).length;
    final totalBalance = employee.totalBalanceFormatted;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LAPORAN KEHADIRAN',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      AppConfig.companyName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      employee.nama,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      month != null ? _formatMonth(month) : 'Semua Periode',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 16),
            // Summary row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pdfSummaryBox('Hari Kerja', '$workingDays'),
                _pdfSummaryBox('Terlambat', '$lateDays'),
                _pdfSummaryBox('Balance', totalBalance),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellHeight: 28,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
            },
            headers: ['Tanggal', 'Masuk', 'Keluar', 'Balance', 'Keterangan'],
            data: sortedData.map((r) => [
              r.tanggal,
              r.jamMasuk ?? '-',
              r.jamKeluar ?? '-',
              r.balance ?? '-',
              r.keterangan.length > 30 
                  ? '${r.keterangan.substring(0, 30)}...' 
                  : r.keterangan,
            ]).toList(),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ),
    );

    return pdf;
  }

  pw.Widget _pdfSummaryBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _formatMonth(String yyyyMM) {
    if (yyyyMM.length < 7) return yyyyMM;
    final year = yyyyMM.substring(0, 4);
    final month = int.tryParse(yyyyMM.substring(5, 7)) ?? 0;
    const months = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[month]} $year';
  }
}

class _ExportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ExportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
