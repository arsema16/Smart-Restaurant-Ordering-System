# Changes Made to QR Code Flow

## Summary

Changed from **in-app QR scanner** to **URL-based QR codes** that guests scan with their phone's camera.

## What Changed

### Before (Old Flow)
1. Guest opens app
2. App shows QR scanner screen
3. Guest scans QR code **inside the app**
4. App creates session

### After (New Flow)
1. Staff generates QR code with URL
2. Guest scans QR code with **phone camera**
3. URL opens app automatically
4. App creates session from URL parameter

## Files Created

### 1. `lib/screens/staff/qr_generator_screen.dart`
**Purpose:** Staff interface to generate printable QR codes

**Features:**
- Input field for table identifier
- Generates QR code with URL
- Displays printable QR code
- Shows table name and URL

**Usage:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const QRGeneratorScreen(),
  ),
);
```

## Files Modified

### 1. `lib/app.dart`
**Changes:**
- Changed from `StatelessWidget` to `ConsumerWidget` (for Riverpod)
- Added route configuration
- Added routes for menu and QR generator

**Before:**
```dart
home: const SplashScreen(),
```

**After:**
```dart
initialRoute: '/',
routes: {
  '/': (context) => const SplashScreen(),
  '/menu': (context) => const MenuScreen(),
  '/staff/qr-generator': (context) => const QRGeneratorScreen(),
},
```

### 2. `lib/screens/splash/splash_screen.dart`
**Changes:**
- Added `tableIdentifier` parameter
- Removed navigation to QR scanner
- Added logic to create session from URL parameter
- Added error handling for missing table ID

**Before:**
```dart
const SplashScreen({super.key});

// Navigated to QRScannerScreen if no session
```

**After:**
```dart
const SplashScreen({super.key, this.tableIdentifier});

// Creates session from tableIdentifier if provided
// Shows error if no session and no table ID
```

## Files Deprecated

### `lib/screens/qr/qr_scanner_screen.dart`
- No longer needed for main flow
- Can be removed or kept as fallback
- Uses `mobile_scanner` package (can be removed from dependencies)

## Dependencies

### Already Installed
- ✅ `qr_flutter: ^4.1.0` - For generating QR codes

### Can Be Removed (Optional)
- `mobile_scanner: ^3.5.5` - Was used for in-app scanning

## Next Steps

### 1. Configure Deep Linking

For Flutter web, add to `web/index.html`:

```html
<head>
  <base href="/">
  <!-- Existing meta tags -->
</head>
```

### 2. Update Main.dart for URL Parameters

Add URL parameter parsing:

```dart
import 'dart:html' as html;

void main() {
  // Get table ID from URL
  final uri = Uri.parse(html.window.location.href);
  final tableId = uri.queryParameters['table'];
  
  runApp(
    ProviderScope(
      child: MyApp(initialTableId: tableId),
    ),
  );
}
```

### 3. Update Base URL

In `lib/screens/staff/qr_generator_screen.dart`:

```dart
static const String baseUrl = 'https://your-domain.com';
```

### 4. Test the Flow

1. Run app: `flutter run -d chrome`
2. Navigate to QR generator
3. Generate QR code for "table-1"
4. Scan with phone camera
5. Verify URL opens: `http://localhost:port/?table=table-1`
6. Verify session is created

## Benefits

✅ **Better UX** - Guests use familiar phone camera
✅ **No permissions** - No camera permission needed in app
✅ **Works everywhere** - Any device with camera
✅ **Simpler code** - No in-app scanner complexity
✅ **Standard approach** - How most QR systems work

## Migration Guide

If you have existing QR codes:

1. Keep old QR scanner as fallback
2. Generate new URL-based QR codes
3. Gradually replace old codes
4. Remove scanner after all codes replaced

## Documentation

See `QR_CODE_FLOW.md` for complete documentation of the new flow.
