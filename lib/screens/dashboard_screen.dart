import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../config/app_config.dart';
import '../models/employee.dart';
import '../providers/attendance_provider.dart';

/// Dashboard Screen - Premium Mobile-Friendly Design
/// 
/// Displays attendance data for a selected employee and month
/// with modern glassmorphism cards, smooth animations, and responsive layout.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'all'; // 'all', 'hadir', 'terlambat', 'libur'

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: state.isLoading
            ? _buildLoadingView(colorScheme)
            : state.error != null
                ? _buildErrorView(state.error!, colorScheme)
                : _buildDashboard(state, theme, colorScheme, isSmallScreen),
      ),
    );

  }

  Widget _buildLoadingView(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat Data...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.cloud_off_rounded, 
                size: 56, 
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).refreshData(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(DashboardState state, ThemeData theme, ColorScheme colorScheme, bool isSmallScreen) {
    final selectedEmployee = state.filteredEmployees.isNotEmpty 
        ? state.filteredEmployees.first 
        : null;

    // Calculate expanded height based on screen size
    final expandedHeight = isSmallScreen ? 200.0 : 170.0;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardProvider.notifier).refreshData(),
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Pinned Header - stays visible during scroll
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: expandedHeight,
            collapsedHeight: 70,
            toolbarHeight: 70,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            title: FadeTransition(
              opacity: _animationController,
              child: _buildAppTitle(theme, colorScheme),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOutCubic,
                  )),
                  child: _buildHeaderContent(theme, colorScheme, state, isSmallScreen),
                ),
              ),
            ),
          ),

          if (selectedEmployee != null) ...[
            // Employee Info Card
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.2, 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _buildEmployeeInfoCard(selectedEmployee, state, theme, colorScheme),
                ),
              ),
            ),
            
            // Summary cards
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSummaryRow(selectedEmployee, state, theme, colorScheme, isSmallScreen),
                ),
              ),
            ),

            // Monthly bar chart
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.4, 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildMonthlyChart(selectedEmployee, theme, colorScheme),
                ),
              ),
            ),


            // Attendance list header with filter chips
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.5, 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Riwayat Kehadiran',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_getFilteredData(selectedEmployee.data).length} hari',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'Semua', Icons.list_rounded, colorScheme),
                            const SizedBox(width: 8),
                            _buildFilterChip('hadir', 'Hadir', Icons.check_circle_outline_rounded, colorScheme),
                            const SizedBox(width: 8),
                            _buildFilterChip('terlambat', 'Terlambat', Icons.access_time_rounded, colorScheme),
                            const SizedBox(width: 8),
                            _buildFilterChip('libur', 'Libur/Cuti', Icons.event_busy_rounded, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Daily attendance list (filtered)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final filteredData = _getFilteredData(selectedEmployee.data);
                  if (index >= filteredData.length) return null;
                  final record = filteredData[index];
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.5 + (index * 0.02).clamp(0.0, 0.4),
                        1.0,
                      ),
                    ),
                    child: Dismissible(
                      key: Key(record.tanggal),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Swipe left -> Show detail
                          _showKeteranganDialog(context, record, theme);
                        } else {
                          // Swipe right -> Show quick info
                          _showQuickInfo(context, record, colorScheme);
                        }
                        return false; // Don't dismiss the item
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Info', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      secondaryBackground: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Detail', style: TextStyle(color: colorScheme.tertiary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, color: colorScheme.tertiary),
                          ],
                        ),
                      ),
                      child: _buildAttendanceItem(record, theme, colorScheme),
                    ),
                  );
                },
                childCount: _getFilteredData(selectedEmployee.data).length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ] else
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih karyawan untuk melihat data',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the pinned app title (visible when collapsed)
  Widget _buildAppTitle(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Attendance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              AppConfig.companyName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the header content for flexible space (only selectors, title is in SliverAppBar)
  Widget _buildHeaderContent(ThemeData theme, ColorScheme colorScheme, DashboardState state, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 100 : 90, // Space below the pinned title
        isSmallScreen ? 16 : 20,
        16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter selectors only (no duplicate title)
          if (isSmallScreen)
            Column(
              children: [
                _buildEmployeeSelector(theme, colorScheme, state),
                const SizedBox(height: 10),
                _buildMonthSelector(theme, colorScheme, state),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildEmployeeSelector(theme, colorScheme, state)),
                const SizedBox(width: 12),
                Expanded(child: _buildMonthSelector(theme, colorScheme, state)),
              ],
            ),
        ],
      ),
    );
  }

  // Legacy method kept for compatibility - redirects to new implementation  
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, DashboardState state, bool isSmallScreen) {
    return _buildHeaderContent(theme, colorScheme, state, isSmallScreen);
  }

  Widget _buildEmployeeSelector(ThemeData theme, ColorScheme colorScheme, DashboardState state) {
    final employees = state.availableEmployees;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedEmployee,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary, size: 20),
          ),
          hint: const Text('Pilih Karyawan'),
          items: employees.map((e) => DropdownMenuItem<String>(
            value: e['sheet'],
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_rounded, size: 18, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e['nama'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.selectedMonth,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.secondary, size: 20),
          ),
          hint: const Text('Pilih Bulan'),
          items: months.map((month) => DropdownMenuItem<String>(
            value: month,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_month_rounded, size: 18, color: colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatMonth(month),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
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
    final fullEmployee = state.employees.firstWhere(
      (e) => e.sheet == employee.sheet,
      orElse: () => employee,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.tertiary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Employee name & schedule
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.surface,
                  child: Text(
                    employee.initials,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.nama,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fullEmployee.jamMasukAturan != null || fullEmployee.jamKeluarAturan != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${fullEmployee.jamMasukAturan ?? "-"} - ${fullEmployee.jamKeluarAturan ?? "-"}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cuti & Sakit row
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  icon: Icons.beach_access_rounded,
                  label: 'Cuti',
                  value: '${fullEmployee.cutiAkhir ?? 0}',
                  subValue: fullEmployee.cutiAwal != null ? 'Awal: ${fullEmployee.cutiAwal}' : null,
                  color: const Color(0xFF3B82F6),
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoChip(
                  icon: Icons.local_hospital_rounded,
                  label: 'Sakit',
                  value: '${fullEmployee.sakitAkhir ?? 0}',
                  subValue: fullEmployee.sakitAwal != null ? 'Awal: ${fullEmployee.sakitAwal}' : null,
                  color: const Color(0xFFEF4444),
                  theme: theme,
                  colorScheme: colorScheme,
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
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (subValue != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        subValue,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
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

  Widget _buildSummaryRow(Employee employee, DashboardState state, ThemeData theme, ColorScheme colorScheme, bool isSmallScreen) {
    final workingDays = employee.data.where((r) => r.isWorkingDay).length;
    final lateDays = employee.data.where((r) => r.isLate).length;
    final balance = employee.totalBalanceFormatted;
    final isNegativeBalance = employee.totalBalanceMinutes < 0;

    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.work_history_rounded,
            label: 'Hari Kerja',
            value: '$workingDays',
            color: colorScheme.primary,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.timer_rounded,
            label: 'Terlambat',
            value: '$lateDays',
            color: const Color(0xFFF59E0B),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Balance',
            value: balance,
            color: isNegativeBalance ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(Employee employee, ThemeData theme, ColorScheme colorScheme) {
    final sortedData = List<AttendanceRecord>.from(employee.data)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kehadiran Bulanan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _legendDot(const Color(0xFF10B981), 'Hadir', colorScheme),
                  _legendDot(const Color(0xFFF59E0B), 'Terlambat', colorScheme),
                  _legendDot(const Color(0xFF3B82F6), 'Balance+', colorScheme),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedData.map((record) {
                final isPresent = record.isWorkingDay;
                final isLate = record.isLate;
                final isHoliday = record.isLeaveOrHoliday;
                final hasPositiveBalance = record.balanceMinutes > 0;
                
                Color barColor;
                double baseHeight;
                
                if (isHoliday) {
                  barColor = Colors.grey.shade400;
                  baseHeight = 30;
                } else if (isLate) {
                  barColor = const Color(0xFFF59E0B);
                  baseHeight = 55;
                } else if (isPresent) {
                  barColor = const Color(0xFF10B981);
                  baseHeight = 85;
                } else {
                  barColor = const Color(0xFFEF4444);
                  baseHeight = 20;
                }

                // Calculate balance bar height (max 30px for positive balance)
                double balanceHeight = 0;
                if (hasPositiveBalance && isPresent) {
                  // Scale balance: 30 minutes = 15px, max 30px
                  balanceHeight = (record.balanceMinutes / 30 * 15).clamp(5, 30).toDouble();
                }

                final day = record.tanggal.length >= 10 
                    ? record.tanggal.substring(8, 10) 
                    : '';

                final tooltipMsg = '${record.tanggal}\n'
                    '${isPresent ? (isLate ? "Terlambat" : "Hadir") : (isHoliday ? record.keterangan : "Tidak Hadir")}'
                    '${record.balance != null && record.balance!.isNotEmpty ? "\nBalance: ${record.balance}" : ""}';

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message: tooltipMsg,
                      decoration: BoxDecoration(
                        color: colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Stacked bar container
                          SizedBox(
                            height: baseHeight + balanceHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Balance bar (blue, on top) - only if positive
                                if (balanceHeight > 0)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutCubic,
                                    height: balanceHeight,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF60A5FA),
                                          Color(0xFF3B82F6),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                // Main status bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  height: baseHeight,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        barColor.withOpacity(0.8),
                                        barColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(balanceHeight > 0 ? 0 : 4),
                                      topRight: Radius.circular(balanceHeight > 0 ? 0 : 4),
                                      bottomLeft: const Radius.circular(4),
                                      bottomRight: const Radius.circular(4),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: barColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
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


  Widget _legendDot(Color color, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
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
      statusColor = Colors.grey.shade500;
      statusIcon = Icons.event_busy_rounded;
      statusText = record.keterangan.isNotEmpty ? record.keterangan : 'Libur';
    } else if (isLate) {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.access_time_rounded;
      statusText = 'Terlambat';
    } else if (isPresent) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Hadir';
    } else {
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
      statusText = 'Tidak Hadir';
    }

    String dayName = '';
    try {
      final date = DateTime.parse(record.tanggal);
      const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      dayName = days[date.weekday - 1];
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date box
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  record.tanggal.length >= 10 
                      ? record.tanggal.substring(8, 10) : '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  dayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Status and times
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (record.keterangan.isNotEmpty && !isHoliday) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showKeteranganDialog(context, record, theme),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isPresent) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.jamMasuk ?? '-',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.logout_rounded,
                        size: 14,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.jamKeluar ?? '-',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Balance
          if (record.balance != null && record.balance!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: record.balanceMinutes < 0 
                      ? [const Color(0xFFEF4444).withOpacity(0.15), const Color(0xFFEF4444).withOpacity(0.05)]
                      : [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF10B981).withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                record.balance!,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: record.balanceMinutes < 0 
                      ? const Color(0xFFEF4444) 
                      : const Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showKeteranganDialog(BuildContext context, AttendanceRecord record, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.info_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text('Detail ${record.tanggal}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.jamMasuk != null)
              _detailRow(Icons.login_rounded, 'Jam Masuk', record.jamMasuk!, colorScheme),
            if (record.jamKeluar != null) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.logout_rounded, 'Jam Keluar', record.jamKeluar!, colorScheme),
            ],
            if (record.balance != null) ...[
              const SizedBox(height: 8),
              _detailRow(Icons.account_balance_wallet_rounded, 'Balance', record.balance!, colorScheme),
            ],
            if (record.keterangan.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Keterangan',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.keterangan,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
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

  Widget _detailRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showQuickInfo(BuildContext context, AttendanceRecord record, ColorScheme colorScheme) {
    final isPresent = record.isWorkingDay;
    final isLate = record.isLate;
    final isHoliday = record.isLeaveOrHoliday;
    
    String status;
    IconData icon;
    Color color;
    
    if (isHoliday) {
      status = record.keterangan.isNotEmpty ? record.keterangan : 'Libur';
      icon = Icons.event_busy_rounded;
      color = Colors.grey;
    } else if (isLate) {
      status = 'Terlambat';
      icon = Icons.access_time_rounded;
      color = const Color(0xFFF59E0B);
    } else if (isPresent) {
      status = 'Hadir';
      icon = Icons.check_circle_rounded;
      color = const Color(0xFF10B981);
    } else {
      status = 'Tidak Hadir';
      icon = Icons.cancel_rounded;
      color = const Color(0xFFEF4444);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.tanggal,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$status${record.balance != null ? " • Balance: ${record.balance}" : ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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

  Widget _buildFilterChip(String value, String label, IconData icon, ColorScheme colorScheme) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      checkmarkColor: colorScheme.onPrimary,
      showCheckmark: false,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  List<AttendanceRecord> _getFilteredData(List<AttendanceRecord> data) {
    final sortedData = List<AttendanceRecord>.from(data)
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    
    if (_selectedFilter == 'all') {
      return sortedData;
    } else if (_selectedFilter == 'hadir') {
      return sortedData.where((r) => r.isWorkingDay && !r.isLate).toList();
    } else if (_selectedFilter == 'terlambat') {
      return sortedData.where((r) => r.isLate).toList();
    } else if (_selectedFilter == 'libur') {
      return sortedData.where((r) => r.isLeaveOrHoliday).toList();
    }
    return sortedData;
  }
}
