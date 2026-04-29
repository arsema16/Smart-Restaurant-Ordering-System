# Access the App from Your Phone

## What I Fixed

Updated the QR code URLs to use your computer's IP address instead of "localhost":
- **Old URL**: `http://localhost:8080` (only works on the same computer)
- **New URL**: `http://10.163.23.62:8080` (works from any device on your network)

## How to Test

### 1. Refresh the Flutter App in Chrome
The QR code on the welcome screen now points to your computer's IP address.

### 2. Make Sure Your Phone and Computer are on the Same WiFi Network
Both devices must be connected to the same WiFi network for this to work.

### 3. Scan the QR Code with Your Phone
- Open your phone's camera app
- Point it at the QR code on the screen
- Tap the notification that appears
- The app should open in your phone's browser!

## Important Notes

### Backend API URL
The Flutter app also needs to connect to the backend API. Check if `lib/core/constants/api_constants.dart` has the correct URL:

**Current setting:**
```dart
static const String baseUrl = 'http://localhost:8000';
```

**For phone access, this should be:**
```dart
static const String baseUrl = 'http://10.163.23.62:8000';
```

### If Your IP Address Changes
Your computer's IP address (10.163.23.62) might change if you:
- Restart your router
- Reconnect to WiFi
- Connect to a different network

If the QR code stops working, run this command to find your new IP:
```powershell
ipconfig | Select-String "IPv4"
```

Then update the `baseUrl` in:
- `lib/screens/welcome/welcome_screen.dart`
- `lib/screens/staff/qr_generator_screen.dart`
- `lib/core/constants/api_constants.dart`

### Firewall Settings
If your phone still can't connect, you may need to allow the ports through Windows Firewall:
- Port 8080 (Flutter web app)
- Port 8000 (Backend API)

## Testing the Connection

### From Your Phone's Browser
Try opening these URLs directly in your phone's browser:

1. **Flutter App**: http://10.163.23.62:8080
2. **Backend API**: http://10.163.23.62:8000/health

If both work, the QR code should work too!

### From Your Computer
Test that the backend is accessible:
```powershell
curl -UseBasicParsing http://10.163.23.62:8000/health
```

Should return: `{"status":"healthy","app":"Smart Restaurant Ordering System"}`

## Next Steps

1. **Refresh your Flutter app in Chrome** to see the updated QR code
2. **Scan the QR code with your phone**
3. **The app should open and work on your phone!**

If you see any errors, check:
- Both devices are on the same WiFi
- Backend is running (`docker-compose ps` in backend folder)
- Windows Firewall allows the ports
- Your IP address hasn't changed
