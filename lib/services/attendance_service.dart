import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Keep for selected month preference
import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/app_config.dart';
import '../models/employee.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final bool isFromCache;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.isFromCache = false,
  });
}

/// Attendance Service (Firestore Version)
/// 
/// Listens to real-time updates from Firestore 'employees' collection.
/// Data structure in Firestore:
/// Collection: employees
/// Document ID: {Sheet Name}
/// Fields: 
///   - json_data: String (JSON String of the employee object)
///   - last_updated: String (ISO Date)

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // ============================================
  // API METHODS (Refactored to Stream)
  // ============================================

  /// Get real-time stream of all employees
  Stream<List<Employee>> getEmployeesStream() {
    return _firestore.collection('employees').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          // Backend Apps Script menyimpan data sebagai JSON string di field 'json_data'
          // atau sebagai object langsung (kita handle keduanya untuk jaga-jaga)
          
          if (data.containsKey('json_data')) {
            // New format (JSON String)
            final jsonStr = data['json_data'] as String;
            final jsonMap = jsonDecode(jsonStr);
            return Employee.fromJson(jsonMap);
          } else {
            // Direct object format (fallback)
            return Employee.fromJson(data);
          }
        } catch (e) {
          print('Error parsing employee ${doc.id}: $e');
          // Return dummy/empty or throw? Better to skip invalid docs
          return Employee(
            sheet: doc.id, 
            nama: 'Error Parsing', 
            periode: '', 
            totalData: 0, 
            data: []
          );
        }
      }).where((e) => e.nama != 'Error Parsing').toList();
    });
  }

  /// Check network connectivity
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  // ============================================
  // PREFERENCE METHODS (Keep existing logic)
  // ============================================

  /// Save selected month preference
  Future<void> saveSelectedMonth(String month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.cacheKeySelectedMonth, month);
    } catch (e) {
      print('Save month error: $e');
    }
  }

  /// Get saved selected month
  Future<String?> getSelectedMonth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConfig.cacheKeySelectedMonth);
    } catch (e) {
      print('Get month error: $e');
    }
    return null;
  }
}
