import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

/// Attendance API Service
/// 
/// Handles all HTTP communication with the Google Apps Script backend.

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  final http.Client _client = http.Client();
  final Connectivity _connectivity = Connectivity();

  // ============================================
  // API METHODS
  // ============================================

  /// Fetch all employees with optional month filter
  Future<ApiResponse<EmployeesResponse>> getEmployees({String? month}) async {
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOffline = connectivityResult == ConnectivityResult.none;

      if (isOffline) {
        return await _getCachedEmployees();
      }

      // Build URL with optional month filter
      String url = AppConfig.apiBaseUrl;
      if (month != null && month.isNotEmpty) {
        url += '?month=$month';
      }
      
      print('Fetching from: $url'); // Debug log
      
      final uri = Uri.parse(url);
      
      // Make request
      final response = await _client
          .get(uri)
          .timeout(Duration(seconds: AppConfig.requestTimeoutSeconds));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (json['success'] == true) {
          final employeesResponse = EmployeesResponse.fromJson(json);
          
          // Cache the response
          await _cacheEmployees(response.body, month);
          
          return ApiResponse(success: true, data: employeesResponse);
        } else {
          return ApiResponse(
            success: false,
            error: json['error']?.toString() ?? 'Unknown error',
          );
        }
      } else {
        // Try cached data on server error
        final cached = await _getCachedEmployees();
        if (cached.success) {
          return cached;
        }
        
        return ApiResponse(
          success: false,
          error: 'Server error: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return await _getCachedEmployees(errorMessage: 'Request timeout');
    } catch (e) {
      final cached = await _getCachedEmployees(errorMessage: e.toString());
      if (cached.success) {
        return cached;
      }
      
      return ApiResponse(
        success: false,
        error: 'Connection error: $e',
      );
    }
  }

  // ============================================
  // CACHING METHODS
  // ============================================

  Future<void> _cacheEmployees(String responseBody, String? month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = month != null 
          ? '${AppConfig.cacheKeyEmployees}_$month'
          : AppConfig.cacheKeyEmployees;
      await prefs.setString(cacheKey, responseBody);
      await prefs.setString(
        AppConfig.cacheKeyLastUpdate,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Cache save error: $e');
    }
  }

  Future<ApiResponse<EmployeesResponse>> _getCachedEmployees({
    String? errorMessage,
    String? month,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = month != null 
          ? '${AppConfig.cacheKeyEmployees}_$month'
          : AppConfig.cacheKeyEmployees;
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final employeesResponse = EmployeesResponse.fromJson(json);
        
        return ApiResponse(
          success: true,
          data: employeesResponse,
          isFromCache: true,
        );
      }
    } catch (e) {
      print('Cache read error: $e');
    }
    
    return ApiResponse(
      success: false,
      error: errorMessage ?? 'No cached data available',
    );
  }

  /// Get last update time
  Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(AppConfig.cacheKeyLastUpdate);
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
    } catch (e) {
      print('Get last update error: $e');
    }
    return null;
  }

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

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(AppConfig.cacheKeyEmployees)) {
          await prefs.remove(key);
        }
      }
      await prefs.remove(AppConfig.cacheKeyLastUpdate);
    } catch (e) {
      print('Clear cache error: $e');
    }
  }

  /// Check network connectivity
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _client.close();
  }
}
