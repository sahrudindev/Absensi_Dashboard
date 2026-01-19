/// Daily Trend Model
/// 
/// Represents attendance statistics for a single day.

class DailyTrend {
  final String date;
  final String dayName;
  final int hadir;
  final int terlambat;
  final int tidakHadir;
  final int total;

  const DailyTrend({
    required this.date,
    required this.dayName,
    required this.hadir,
    required this.terlambat,
    required this.tidakHadir,
    required this.total,
  });

  /// Create DailyTrend from JSON map
  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? '',
      hadir: _parseInt(json['hadir']),
      terlambat: _parseInt(json['terlambat']),
      tidakHadir: _parseInt(json['tidakHadir']),
      total: _parseInt(json['total']),
    );
  }

  /// Convert DailyTrend to JSON map
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dayName': dayName,
      'hadir': hadir,
      'terlambat': terlambat,
      'tidakHadir': tidakHadir,
      'total': total,
    };
  }

  /// Get attendance rate as percentage
  double get attendanceRate {
    if (total == 0) return 0;
    return ((hadir + terlambat) / total) * 100;
  }

  /// Get short day name (first 3 characters)
  String get shortDayName {
    if (dayName.length >= 3) {
      return dayName.substring(0, 3);
    }
    return dayName;
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
    return 'DailyTrend(date: $date, hadir: $hadir, terlambat: $terlambat, tidakHadir: $tidakHadir)';
  }
}
