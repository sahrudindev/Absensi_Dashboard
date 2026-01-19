import 'daily_trend.dart';

/// Absentee Model
/// 
/// Represents an employee who is absent today.

class Absentee {
  final String nama;
  final String nik;

  const Absentee({
    required this.nama,
    required this.nik,
  });

  factory Absentee.fromJson(Map<String, dynamic> json) {
    return Absentee(
      nama: json['nama']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'nik': nik,
    };
  }
}

/// Summary Model
/// 
/// Represents the dashboard summary data from the API.

class Summary {
  final String date;
  final int totalEmployees;
  final int hadir;
  final int terlambat;
  final int tidakHadir;
  final int attendanceRate;
  final List<DailyTrend> trend;
  final List<Absentee> absentees;
  final String timestamp;

  const Summary({
    required this.date,
    required this.totalEmployees,
    required this.hadir,
    required this.terlambat,
    required this.tidakHadir,
    required this.attendanceRate,
    required this.trend,
    required this.absentees,
    required this.timestamp,
  });

  /// Create Summary from API JSON response
  factory Summary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    
    // Parse trend list
    final trendList = (data['trend'] as List<dynamic>?)
        ?.map((e) => DailyTrend.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    
    // Parse absentees list
    final absenteesList = (data['absentees'] as List<dynamic>?)
        ?.map((e) => Absentee.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return Summary(
      date: data['date']?.toString() ?? '',
      totalEmployees: _parseInt(data['totalEmployees']),
      hadir: _parseInt(data['hadir']),
      terlambat: _parseInt(data['terlambat']),
      tidakHadir: _parseInt(data['tidakHadir']),
      attendanceRate: _parseInt(data['attendanceRate']),
      trend: trendList,
      absentees: absenteesList,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  /// Convert Summary to JSON map for caching
  Map<String, dynamic> toJson() {
    return {
      'data': {
        'date': date,
        'totalEmployees': totalEmployees,
        'hadir': hadir,
        'terlambat': terlambat,
        'tidakHadir': tidakHadir,
        'attendanceRate': attendanceRate,
        'trend': trend.map((e) => e.toJson()).toList(),
        'absentees': absentees.map((e) => e.toJson()).toList(),
      },
      'timestamp': timestamp,
    };
  }

  /// Create empty summary for initial state
  factory Summary.empty() {
    return const Summary(
      date: '',
      totalEmployees: 0,
      hadir: 0,
      terlambat: 0,
      tidakHadir: 0,
      attendanceRate: 0,
      trend: [],
      absentees: [],
      timestamp: '',
    );
  }

  /// Check if summary has data
  bool get hasData => date.isNotEmpty;

  /// Get total present (hadir + terlambat)
  int get totalPresent => hadir + terlambat;

  /// Get calculated attendance rate
  double get calculatedRate {
    if (totalEmployees == 0) return 0;
    return (totalPresent / totalEmployees) * 100;
  }

  /// Helper to parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  @override
  String toString() {
    return 'Summary(date: $date, hadir: $hadir, terlambat: $terlambat, tidakHadir: $tidakHadir)';
  }
}
