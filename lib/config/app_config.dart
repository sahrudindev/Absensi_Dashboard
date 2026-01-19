import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application Configuration
/// 
/// Contains API URLs and app-wide constants.

class AppConfig {
  // ============================================
  // API CONFIGURATION
  // ============================================
  
  /// Google Apps Script Web App URL (New API)
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  
  // ============================================
  // REFRESH CONFIGURATION
  // ============================================
  
  /// Auto-refresh interval in minutes
  static const int autoRefreshMinutes = 5;
  
  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 60;
  
  // ============================================
  // CACHE CONFIGURATION
  // ============================================
  
  /// Cache keys
  static const String cacheKeyEmployees = 'cached_employees';
  static const String cacheKeyLastUpdate = 'last_update_time';
  static const String cacheKeySelectedMonth = 'selected_month';
  
  /// Cache expiry in hours
  static const int cacheExpiryHours = 24;
  
  // ============================================
  // UI CONFIGURATION
  // ============================================
  
  /// App name shown in title bar
  static const String appName = 'Attendance Dashboard';
  
  /// Company name
  static const String companyName = 'PT. AP&M Indonesia';
  
  // ============================================
  // THEME COLORS
  // ============================================
  
  /// Primary seed color for Material 3
  static const int primaryColorValue = 0xFF2563EB; // Blue-600
  
  /// Status colors
  static const int colorPositive = 0xFF10B981;    // Emerald-500 (positive balance)
  static const int colorNegative = 0xFFEF4444;    // Red-500 (negative balance)
  static const int colorNeutral = 0xFF6B7280;     // Gray-500 (neutral)
  static const int colorWarning = 0xFFF59E0B;     // Amber-500 (late)
  
  /// Card colors
  static const int colorCardHadir = 0xFF10B981;
  static const int colorCardTerlambat = 0xFFF59E0B;
  static const int colorCardTidakHadir = 0xFFEF4444;
  static const int colorCardTotal = 0xFF3B82F6;
}
