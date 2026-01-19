/// Employee and Attendance Record Models
///
/// Data models for the attendance dashboard API response.

/// Represents a single attendance record for one day
class AttendanceRecord {
  final String tanggal;
  final String? jamMasuk;
  final String? jamKeluar;
  final String keterangan;
  final String? jamMasukCalc;
  final String? jamKeluarCalc;
  final String? balance;

  const AttendanceRecord({
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.keterangan = '',
    this.jamMasukCalc,
    this.jamKeluarCalc,
    this.balance,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      tanggal: json['tanggal']?.toString() ?? '',
      jamMasuk: json['jamMasuk']?.toString(),
      jamKeluar: json['jamKeluar']?.toString(),
      keterangan: json['keterangan']?.toString() ?? '',
      jamMasukCalc: json['jamMasukCalc']?.toString(),
      jamKeluarCalc: json['jamKeluarCalc']?.toString(),
      balance: json['balance']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tanggal': tanggal,
    'jamMasuk': jamMasuk,
    'jamKeluar': jamKeluar,
    'keterangan': keterangan,
    'jamMasukCalc': jamMasukCalc,
    'jamKeluarCalc': jamKeluarCalc,
    'balance': balance,
  };

  /// Check if this is a working day (has check-in or check-out)
  bool get isWorkingDay => jamMasuk != null || jamKeluar != null;

  /// Check if employee was late (negative jamMasukCalc)
  bool get isLate {
    if (jamMasukCalc == null) return false;
    return jamMasukCalc!.startsWith('-');
  }

  /// Check if this day is a weekend (Saturday or Sunday)
  bool get isWeekend {
    try {
      final date = DateTime.parse(tanggal);
      return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    } catch (_) {
      return false;
    }
  }

  /// Check if this is a holiday, leave day, or weekend
  bool get isLeaveOrHoliday => 
    isWeekend || (keterangan.isNotEmpty && jamMasuk == null && jamKeluar == null);

  /// Parse balance to minutes (positive or negative)
  int get balanceMinutes {
    if (balance == null || balance!.isEmpty) return 0;
    
    final isNegative = balance!.startsWith('-');
    final cleaned = balance!.replaceAll('-', '');
    final parts = cleaned.split(':');
    
    if (parts.length < 2) return 0;
    
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final total = hours * 60 + minutes;
    
    return isNegative ? -total : total;
  }
}

/// Represents an employee with their attendance records
class Employee {
  final String sheet;
  final String nama;
  final String periode;
  final String? jamMasukAturan;
  final String? jamKeluarAturan;
  final dynamic cutiAwal;
  final dynamic cutiAkhir;
  final dynamic sakitAwal;
  final dynamic sakitAkhir;
  final int totalData;
  final List<AttendanceRecord> data;

  const Employee({
    required this.sheet,
    required this.nama,
    required this.periode,
    this.jamMasukAturan,
    this.jamKeluarAturan,
    this.cutiAwal,
    this.cutiAkhir,
    this.sakitAwal,
    this.sakitAkhir,
    required this.totalData,
    required this.data,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
        ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return Employee(
      sheet: json['sheet']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      periode: json['periode']?.toString() ?? '',
      jamMasukAturan: json['jamMasukAturan']?.toString(),
      jamKeluarAturan: json['jamKeluarAturan']?.toString(),
      cutiAwal: json['cutiAwal'],
      cutiAkhir: json['cutiAkhir'],
      sakitAwal: json['sakitAwal'],
      sakitAkhir: json['sakitAkhir'],
      totalData: json['totalData'] as int? ?? 0,
      data: dataList,
    );
  }

  Map<String, dynamic> toJson() => {
    'sheet': sheet,
    'nama': nama,
    'periode': periode,
    'totalData': totalData,
    'data': data.map((e) => e.toJson()).toList(),
  };

  /// Get total balance in minutes (sum of all daily balances)
  int get totalBalanceMinutes {
    return data.fold(0, (sum, record) => sum + record.balanceMinutes);
  }

  /// Get total balance formatted as string (e.g., "-2:30" or "1:45")
  String get totalBalanceFormatted {
    final total = totalBalanceMinutes;
    final isNegative = total < 0;
    final abs = total.abs();
    final hours = abs ~/ 60;
    final minutes = abs % 60;
    final sign = isNegative ? '-' : '';
    return '$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  /// Count working days (days with check-in or check-out)
  int get workingDays => data.where((r) => r.isWorkingDay).length;

  /// Count late arrivals
  int get lateDays => data.where((r) => r.isLate).length;

  /// Get latest attendance record (most recent date)
  AttendanceRecord? get latestRecord {
    if (data.isEmpty) return null;
    return data.reduce((a, b) => 
      a.tanggal.compareTo(b.tanggal) > 0 ? a : b);
  }

  /// Get today's attendance record if exists
  AttendanceRecord? getRecordForDate(String date) {
    try {
      return data.firstWhere((r) => r.tanggal == date);
    } catch (_) {
      return null;
    }
  }

  /// Get initials from name (e.g., "DHIKA PRIAMBODO" -> "DP")
  String get initials {
    final words = nama.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }
}

/// API Response wrapper for employees endpoint
class EmployeesResponse {
  final bool success;
  final String? filterMonth;
  final int totalEmployees;
  final List<Employee> employees;

  const EmployeesResponse({
    required this.success,
    this.filterMonth,
    required this.totalEmployees,
    required this.employees,
  });

  factory EmployeesResponse.fromJson(Map<String, dynamic> json) {
    final employeesList = (json['employees'] as List<dynamic>?)
        ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return EmployeesResponse(
      success: json['success'] as bool? ?? false,
      filterMonth: json['filterMonth']?.toString(),
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      employees: employeesList,
    );
  }
}
