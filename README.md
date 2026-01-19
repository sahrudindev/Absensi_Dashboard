# Attendance Dashboard
Real-time employee attendance dashboard with Google Sheets backend.

## Architecture
- **Backend:** Google Sheets (Source of Truth) -> Google Apps Script (Sync Engine) -> Firebase Firestore (Database)
- **Frontend:** Flutter Web (Reads from Firestore)

## Setup Guide

### 1. Google Apps Script (Backend)
The `backend/Code.gs` file contains the logic to sync Google Sheets data to Firestore. 

**Setup Steps:**
1. Open your Google Sheet -> **Extensions** -> **Apps Script**.
2. Copy the content of `backend/Code.gs` from your local machine (this folder is ignored in git).
3. The keys are already configured in your local `backend/Code.gs`.
4. **Initial Run:**
   - Run `setupTrigger` to schedule the daily sync (19:00).
   - Run `syncToFirestore` to test the connection.

**Feature: Data Merging**
- This script supports **merging data** from multiple Google Sheet files.
- Use this if you create a new spreadsheet for a new year (e.g., 2026) to keep the file light.
- **How to use:** Simply install this same script (with the same Firebase Keys) on the NEW spreadsheet. When both scripts run, they will combine their data in Firestore automatically.

### 2. Firebase Security Rules
1. Go to Firebase Console -> Firestore Database -> **Rules**.
2. Change the rules to allow read access:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
3. Click **Publish**.

### 3. Flutter App (Frontend)
1. **Clone the repository**
2. **Setup Environment**
   ```bash
   cp .env.example .env
   # No need to edit .env for Firestore version, but file must exist.
   ```
3. **Install Dependencies & Run**
   ```bash
   flutter pub get
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000
   ```

### Troubleshooting
- **Data Empty?** Check Apps Script executions. Ensure `syncToFirestore` ran successfully.
- **Permission Error?** Check Firebase Security Rules.


Real-Time Attendance Dashboard built with Flutter and Google Apps Script backend.

![Material 3](https://img.shields.io/badge/Material-3-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Android](https://img.shields.io/badge/Platform-Android-green)

## Features

- 📊 **Dashboard Overview** - Total attendance, hadir, terlambat, tidak hadir
- 📈 **7-Day Trend Chart** - Visual attendance trend analysis
- 👥 **Absentee List** - Today's absent employees
- 🔄 **Auto-Refresh** - Automatic data update every 5 minutes
- 📱 **Pull-to-Refresh** - Manual refresh with swipe gesture
- 🌙 **Dark Mode** - Automatic system theme support
- 📶 **Offline Support** - Cached data when offline
- 📐 **Responsive** - Optimized for phones and tablets

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Screens │→ │ Widgets │→ │Providers│→ │ Service │   │
│  └─────────┘  └─────────┘  └─────────┘  └────┬────┘   │
└──────────────────────────────────────────────│─────────┘
                                               │ HTTPS
┌──────────────────────────────────────────────▼─────────┐
│              Google Apps Script                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐               │
│  │ doGet() │→ │  Cache  │→ │ Sheets  │               │
│  └─────────┘  └─────────┘  └─────────┘               │
└────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Flutter SDK 3.0+
- Android Studio / VS Code
- Google Account (for Sheets)

### 1. Setup Backend

1. Create a Google Sheet with attendance data
2. Go to **Extensions > Apps Script**
3. Paste code from `backend/Code.gs`
4. Deploy as Web App: **Deploy > New deployment > Web app**
5. Copy the deployment URL

See [Backend README](backend/README.md) for detailed instructions.

### 2. Configure Flutter App

1. Open `lib/config/app_config.dart`
2. Update `apiBaseUrl` with your Apps Script URL:

```dart
static const String apiBaseUrl = 
    'https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec';
```

### 3. Run the App

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Build APK
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── config/
│   └── app_config.dart       # Configuration constants
├── models/
│   ├── attendance.dart       # Attendance data model
│   ├── daily_trend.dart      # Trend data model
│   ├── summary.dart          # Summary data model
│   └── models.dart           # Barrel export
├── services/
│   └── attendance_service.dart  # API client
├── providers/
│   └── attendance_provider.dart # Riverpod state
├── screens/
│   └── dashboard_screen.dart    # Main dashboard
└── widgets/
    ├── summary_card.dart        # Stat cards
    ├── trend_chart.dart         # Bar chart
    ├── absentee_list.dart       # Absentee list
    ├── loading_shimmer.dart     # Loading skeleton
    └── widgets.dart             # Barrel export
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| http | ^1.1.0 | HTTP client |
| flutter_riverpod | ^2.4.9 | State management |
| fl_chart | ^0.66.0 | Charts |
| intl | ^0.18.1 | Date formatting |
| shared_preferences | ^2.2.2 | Offline cache |
| connectivity_plus | ^5.0.2 | Network detection |

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `?action=summary` | Dashboard summary with stats & trends |
| `?action=today` | Today's attendance list |
| `?action=history&start=YYYY-MM-DD&end=YYYY-MM-DD` | Historical data |

## Configuration

Edit `lib/config/app_config.dart`:

| Option | Description | Default |
|--------|-------------|---------|
| `apiBaseUrl` | Apps Script URL | Required |
| `apiKey` | API authentication key | `attendance_api_key_2026` |
| `autoRefreshMinutes` | Auto-refresh interval | 5 |
| `primaryColorValue` | Theme primary color | Deep Purple |

## Building APK

```bash
# Debug build
flutter build apk --debug

# Release build (optimized, minified)
flutter build apk --release

# Split APK by ABI (smaller size)
flutter build apk --release --split-per-abi
```

Output location: `build/app/outputs/flutter-apk/`

## Performance Tips

### Backend Optimization
- Enable CacheService (5-minute cache)
- Use batch reads with `getDataRange()`
- Setup daily trigger for cache refresh

### Large Datasets (1000+ records)
- Implement server-side pagination
- Add date range filters
- Consider migrating to Firebase for very large datasets

### Offline Strategy
- Last successful response cached locally
- Auto-retry when connection restored
- Offline indicator shown to user

## Troubleshooting

### App shows "Connection error"
- Check internet connection
- Verify Apps Script URL is correct
- Ensure Apps Script is deployed with "Anyone" access

### Data not updating
- Pull down to manual refresh
- Check Apps Script execution logs
- Verify Google Sheets has recent data

### Build fails
- Run `flutter clean`
- Run `flutter pub get`
- Update dependencies with `flutter pub upgrade`

## License

MIT License - Free to use and modify.
