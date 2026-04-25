# QR Code Flow - Smart Restaurant Ordering System

## Overview

The system uses QR codes placed on restaurant tables. Guests scan these codes with their phone's camera to access the ordering system.

## How It Works

### 1. Staff Generates QR Codes

**Staff/Admin uses the QR Generator screen:**
- Navigate to `/staff/qr-generator` route
- Enter table identifier (e.g., "table-1", "A5", "VIP-3")
- Click "Generate QR Code"
- Print the QR code and place it on the table

**Generated QR Code contains:**
```
https://restaurant.com/?table=table-1
```

### 2. Guest Scans QR Code

**Guest uses their phone's camera:**
- Point camera at QR code on table
- Phone recognizes the URL and shows a notification
- Tap notification to open the web app
- App automatically creates a session for that table

### 3. Session Flow

```
Guest scans QR → Opens URL with ?table=table-1 
              → SplashScreen receives table parameter
              → Creates session via API
              → Stores session token in localStorage
              → Redirects to MenuScreen
```

### 4. Session Persistence

- Session token stored in localStorage
- If guest closes and reopens app, session is restored
- No need to scan QR code again during the same visit
- Persistent user ID tracks preferences across multiple visits

## Implementation Details

### URL Structure

```
https://restaurant.com/?table={table_identifier}
```

**Example URLs:**
- `https://restaurant.com/?table=table-1`
- `https://restaurant.com/?table=A5`
- `https://restaurant.com/?table=VIP-3`

### Deep Link Handling

For Flutter web, the app reads the URL parameter on startup:

```dart
// In main.dart or app initialization
final uri = Uri.base;
final tableId = uri.queryParameters['table'];

// Pass to SplashScreen
SplashScreen(tableIdentifier: tableId)
```

### Files Modified

1. **lib/screens/staff/qr_generator_screen.dart** (NEW)
   - Staff interface to generate QR codes
   - Uses `qr_flutter` package
   - Displays printable QR codes

2. **lib/screens/splash/splash_screen.dart** (UPDATED)
   - Now accepts `tableIdentifier` parameter
   - Creates session if table ID provided
   - Resumes session if no table ID (returning user)

3. **lib/app.dart** (UPDATED)
   - Added routes for navigation
   - Supports deep linking

4. **lib/screens/qr/qr_scanner_screen.dart** (DEPRECATED)
   - Old in-app scanner no longer needed
   - Can be removed or kept for fallback

## Configuration

### Update Base URL

In `lib/screens/staff/qr_generator_screen.dart`, update:

```dart
static const String baseUrl = 'https://your-actual-domain.com';
```

### For Local Development

Use ngrok or similar to create a public URL:

```bash
ngrok http 3000
```

Then use the ngrok URL in the QR generator.

## Testing

### Test QR Code Generation

1. Run the app
2. Navigate to QR Generator screen
3. Enter "test-table-1"
4. Generate QR code
5. Scan with phone camera
6. Verify it opens the app with correct table ID

### Test Session Flow

1. Scan QR code → Should create session and show menu
2. Close app → Reopen → Should restore session (no QR scan needed)
3. Clear app data → Reopen → Should show "No Table Selected" message
4. Scan QR code again → Should create new session

## Production Deployment

### Web App

1. Deploy Flutter web app to your domain
2. Configure deep linking in `web/index.html`
3. Update base URL in QR generator
4. Generate QR codes for all tables
5. Print and laminate QR codes
6. Place on tables

### Mobile App (Optional)

If building native apps:

1. Configure deep links in `AndroidManifest.xml` (Android)
2. Configure universal links in `Info.plist` (iOS)
3. Register your domain with app stores
4. Test deep linking on physical devices

## Benefits of This Approach

✅ **No app installation required** - Works in browser
✅ **Native camera scanning** - Uses phone's built-in QR scanner
✅ **Simple for guests** - Just point and tap
✅ **Persistent sessions** - No need to rescan during visit
✅ **Cross-device support** - Works on any phone with camera
✅ **Easy table management** - Staff can generate QR codes as needed
