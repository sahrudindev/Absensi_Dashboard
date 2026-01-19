/// Attendance Model
/// 
/// Represents a single attendance record from the API.

class Attendance {
  final String timestamp;
  final String nama;
  final String nik;
  final String tanggal;
  final String jamMasuk;
  final String jamPulang;
  final String status;

  const Attendance({
    required this.timestamp,
    required this.nama,
    required this.nik,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamPulang,
    required this.status,
  });

  /// Create Attendance from JSON map
  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      timestamp: json['timestamp']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      jamMasuk: json['jamMasuk']?.toString() ?? '-',
      jamPulang: json['jamPulang']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'Unknown',
    );
  }

  /// Convert Attendance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'nama': nama,
      'nik': nik,
      'tanggal': tanggal,
      'jamMasuk': jamMasuk,
      'jamPulang': jamPulang,
      'status': status,
    };
  }

  /// Get status type for styling
  AttendanceStatus get statusType {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('hadir') && !statusLower.contains('tidak')) {
      return AttendanceStatus.hadir;
    } else if (statusLower.contains('terlambat')) {
      return AttendanceStatus.terlambat;
    } else {
      return AttendanceStatus.tidakHadir;
    }
  }

  @override
  String toString() {
    return 'Attendance(nama: $nama, nik: $nik, status: $status)';
  }
}

/// Attendance status enum for type-safe status handling
enum AttendanceStatus {
  hadir,
  terlambat,
  tidakHadir,
}
