# Setup Guide - QR Code System

## Current Issue: URL Configuration

The QR codes currently show `http://localhost:8080` which only works on your development machine.

## Solutions

### Option 1: For Local Testing (Same WiFi Network)

1. Find your computer's local IP address:
   - **Windows**: Open CMD and run `ipconfig`, look for "IPv4 Address" (e.g., 192.168.1.100)
   - **Mac/Linux**: Run `ifconfig` or `ip addr`, look for your local IP

2. Update the base URL in `lib/screens/staff/qr_generator_screen.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8080'; // Your IP
   ```

3. Make sure your phone and computer are on the same WiFi network

4. Generate QR code and scan with your phone

### Option 2: For Internet Testing (Using ngrok)

1. Install ngrok: https://ngrok.com/download

2. Run your Flutter web app:
   ```bash
   flutter run -d chrome --web-port 8080
   ```

3. In another terminal, run ngrok:
   ```bash
   ngrok http 8080
   ```

4. Copy the HTTPS URL from ngrok (e.g., `https://abc123.ngrok.io`)

5. Update the base URL in `lib/screens/staff/qr_generator_screen.dart`:
   ```dart
   static const String baseUrl = 'https://abc123.ngrok.io';
   ```

6. Generate QR code and scan with your phone from anywhere

### Option 3: For Production (Deploy to Web)

1. Deploy your Flutter web app to a hosting service:
   - Firebase Hosting
   - Netlify
   - Vercel
   - Your own domain

2. Update the base URL with your production domain:
   ```dart
   static const String baseUrl = 'https://your-restaurant.com';
   ```

## How to Test

### Step 1: Generate QR Code
1. Open the app
2. Click "Staff: Generate QR Codes"
3. Enter a table name (e.g., "table-1")
4. Click "Generate QR Code"
5. You'll see the QR code with the URL

### Step 2: Test the QR Code
1. Take a screenshot of the QR code OR print it
2. Open your phone's camera app
3. Point it at the QR code
4. Tap the notification that appears
5. The app should open in your phone's browser
6. You should see the menu for that table

## Understanding the Flow

### For Guests (Normal Users)
- **They DON'T open the app directly**
- They scan the QR code on the table with their phone camera
- The QR code contains a URL like: `http://your-url/?table=table-1`
- Their phone opens this URL in the browser
- The app loads and creates a session for that table

### For Staff (Restaurant Employees)
- They open the app directly
- Click "Staff: Generate QR Codes"
- Generate and print QR codes for each table
- Place the printed QR codes on tables

## Current App Behavior

When you open the app directly (without scanning):
- ✅ Shows "Welcome Screen"
- ✅ "For Guests" section - NOT clickable (guests should scan QR)
- ✅ "Staff: Generate QR Codes" button - Clickable (for staff)

## Troubleshooting

### QR Code doesn't work
- Check if the URL in the QR code is accessible from your phone
- Make sure your phone can reach the URL (same network or public URL)
- Try opening the URL manually in your phone's browser first

### App shows "No Table Selected"
- This means you opened the app directly without scanning a QR code
- This is expected behavior
- Scan a QR code to start a session

### Can't generate QR codes
- Make sure you clicked "Staff: Generate QR Codes" button
- Enter a table identifier
- Click "Generate QR Code"

## Next Steps

1. Choose which option above fits your needs (local testing, ngrok, or production)
2. Update the `baseUrl` in the QR generator
3. Hot restart the app: Press `R` in the terminal
4. Generate a new QR code
5. Test by scanning with your phone
