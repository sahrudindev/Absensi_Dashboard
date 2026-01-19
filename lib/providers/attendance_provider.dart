import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/employee.dart';
import '../services/attendance_service.dart';

// ============================================
// STATE CLASS
// ============================================

/// Dashboard state containing all data and status
class DashboardState {
  final List<Employee> employees;
  final String? selectedMonth;
  final String? selectedEmployee; // Filter by employee name
  final String searchQuery;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool isFromCache;
  final DateTime? lastUpdate;

  const DashboardState({
    this.employees = const [],
    this.selectedMonth,
    this.selectedEmployee,
    this.searchQuery = '',
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.isFromCache = false,
    this.lastUpdate,
  });

  DashboardState copyWith({
    List<Employee>? employees,
    String? selectedMonth,
    String? selectedEmployee,
    bool clearSelectedEmployee = false,
    String? searchQuery,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? isFromCache,
    DateTime? lastUpdate,
  }) {
    return DashboardState(
      employees: employees ?? this.employees,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedEmployee: clearSelectedEmployee ? null : (selectedEmployee ?? this.selectedEmployee),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  /// Check if data is available
  bool get hasData => employees.isNotEmpty;

  /// Get filtered employees based on search query and selected month
  List<Employee> get filteredEmployees {
    var result = employees;
    
    // Filter by selected employee first
    if (selectedEmployee != null && selectedEmployee!.isNotEmpty) {
      result = result.where((e) => e.sheet == selectedEmployee).toList();
    }
    
    // Filter by selected month (filter data records, not employees)
    if (selectedMonth != null && selectedMonth!.isNotEmpty) {
      result = result.map((e) {
        final filteredData = e.data.where((r) => 
          r.tanggal.startsWith(selectedMonth!)
        ).toList();
        return Employee(
          sheet: e.sheet,
          nama: e.nama,
          periode: e.periode,
          totalData: filteredData.length,
          data: filteredData,
        );
      }).where((e) => e.data.isNotEmpty).toList();
    }
    
    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((e) => 
        e.nama.toLowerCase().contains(query) ||
        e.sheet.toLowerCase().contains(query)
      ).toList();
    }
    
    return result;
  }

  /// Get list of available employees for filter dropdown
  List<Map<String, String>> get availableEmployees {
    return employees.map((e) => {
      'sheet': e.sheet,
      'nama': e.nama,
    }).toList()..sort((a, b) => a['nama']!.compareTo(b['nama']!));
  }

  /// Get total employees count
  int get totalEmployees => employees.length;

  /// Get today's date string (YYYY-MM-DD format)
  String get todayDate {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Count employees who are present today
  int get hadirToday {
    return employees.where((e) {
      final record = e.getRecordForDate(todayDate);
      return record != null && record.isWorkingDay && !record.isLate;
    }).length;
  }

  /// Count employees who are late today
  int get terlambatToday {
    return employees.where((e) {
      final record = e.getRecordForDate(todayDate);
      return record != null && record.isLate;
    }).length;
  }

  /// Count employees with no record today (excluding holidays)
  int get tidakHadirToday {
    return employees.where((e) {
      final record = e.getRecordForDate(todayDate);
      return record == null || (!record.isWorkingDay && !record.isLeaveOrHoliday);
    }).length;
  }

  /// Calculate overall attendance rate
  double get attendanceRate {
    if (totalEmployees == 0) return 0;
    return ((hadirToday + terlambatToday) / totalEmployees) * 100;
  }

  /// Get list of available months from employee data
  List<String> get availableMonths {
    final Set<String> months = {};
    for (final employee in employees) {
      for (final record in employee.data) {
        if (record.tanggal.length >= 7) {
          months.add(record.tanggal.substring(0, 7)); // YYYY-MM
        }
      }
    }
    final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
    return sortedMonths;
  }

  factory DashboardState.initial() => const DashboardState(isLoading: true);
}

// ============================================
// NOTIFIER CLASS
// ============================================

class DashboardNotifier extends StateNotifier<DashboardState> {
  final AttendanceService _service;
  Timer? _refreshTimer;

  DashboardNotifier(this._service) : super(DashboardState.initial()) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Load saved month preference
    final savedMonth = await _service.getSelectedMonth();
    if (savedMonth != null) {
      state = state.copyWith(selectedMonth: savedMonth);
    }
    await loadData();
    _startAutoRefresh();
  }

  /// Load all employees data (always load all, filter locally)
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Always load ALL data (no month filter) - filter locally for speed
      final response = await _service.getEmployees();

      if (response.success && response.data != null) {
        final employees = response.data!.employees;
        
        // Set defaults if not already set
        String? defaultEmployee = state.selectedEmployee;
        String? defaultMonth = state.selectedMonth;
        
        // Default to first employee if none selected
        if (defaultEmployee == null && employees.isNotEmpty) {
          defaultEmployee = employees.first.sheet;
        }
        
        // Default to most recent month if none selected
        if (defaultMonth == null && employees.isNotEmpty) {
          final Set<String> months = {};
          for (final emp in employees) {
            for (final record in emp.data) {
              if (record.tanggal.length >= 7) {
                months.add(record.tanggal.substring(0, 7));
              }
            }
          }
          if (months.isNotEmpty) {
            final sortedMonths = months.toList()..sort((a, b) => b.compareTo(a));
            defaultMonth = sortedMonths.first; // Most recent month
          }
        }
        
        state = state.copyWith(
          employees: employees,
          selectedEmployee: defaultEmployee,
          selectedMonth: defaultMonth,
          isLoading: false,
          isFromCache: response.isFromCache,
          lastUpdate: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load data',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// Refresh data (pull-to-refresh)
  Future<void> refreshData() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final response = await _service.getEmployees(month: state.selectedMonth);

      if (response.success && response.data != null) {
        state = state.copyWith(
          employees: response.data!.employees,
          isRefreshing: false,
          isFromCache: response.isFromCache,
          lastUpdate: DateTime.now(),
          error: null,
        );
      } else {
        state = state.copyWith(
          isRefreshing: false,
          error: response.error,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Refresh error: $e',
      );
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Update selected month (no reload needed - filter locally)
  Future<void> setSelectedMonth(String? month) async {
    state = state.copyWith(selectedMonth: month);
    if (month != null) {
      await _service.saveSelectedMonth(month);
    }
    // No reload needed - filteredEmployees getter will handle filtering
  }

  /// Update selected employee (no reload needed - filter locally)
  void setSelectedEmployee(String? employeeSheet) {
    if (employeeSheet == null) {
      state = state.copyWith(clearSelectedEmployee: true);
    } else {
      state = state.copyWith(selectedEmployee: employeeSheet);
    }
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(minutes: AppConfig.autoRefreshMinutes),
      (_) => refreshData(),
    );
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void resumeAutoRefresh() {
    _startAutoRefresh();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// ============================================
// PROVIDERS
// ============================================

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final service = ref.watch(attendanceServiceProvider);
  return DashboardNotifier(service);
});

/// Filtered employees provider
final filteredEmployeesProvider = Provider<List<Employee>>((ref) {
  return ref.watch(dashboardProvider).filteredEmployees;
});

/// Loading state provider
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardProvider).isLoading;
});

/// Error state provider
final errorProvider = Provider<String?>((ref) {
  return ref.watch(dashboardProvider).error;
});

/// Selected month provider
final selectedMonthProvider = Provider<String?>((ref) {
  return ref.watch(dashboardProvider).selectedMonth;
});

/// Available months provider
final availableMonthsProvider = Provider<List<String>>((ref) {
  return ref.watch(dashboardProvider).availableMonths;
});
