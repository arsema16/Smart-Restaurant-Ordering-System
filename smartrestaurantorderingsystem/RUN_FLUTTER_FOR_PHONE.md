# Run Flutter Web App for Phone Access

## The Problem

The Flutter app is running in Chrome on your computer, but it's not accessible from your phone. We need to run Flutter as a web server that listens on all network interfaces.

## Solution: Run Flutter Web Server

### Step 1: Stop the Current Flutter App
If Flutter is running in Chrome, close it or stop the process.

### Step 2: Run Flutter Web Server
Open a new terminal/PowerShell in the project root and run:

```powershell
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

This will:
- Start a web server on port 8080
- Listen on all network interfaces (0.0.0.0)
- Make the app accessible from your phone

### Step 3: Access from Your Phone
Once the server is running, you'll see output like:
```
Flutter run key commands.
h List all available interactive commands.
c Clear the screen
q Quit (terminate the application on the device).

💪 Running with sound null safety 💪

🔥  To hot restart changes while running, press "r" or "R".
For a more detailed help message, press "h". To quit, press "q".

An Observatory debugger and profiler on Web Server is available at: http://127.0.0.1:8080/
The web-server is listening on http://0.0.0.0:8080/
```

Now you can:
1. **From your computer**: Open http://localhost:8080
2. **From your phone**: Open http://10.163.23.62:8080
3. **Scan the QR code**: It will work!

## Alternative: Build and Serve

If the above doesn't work, you can build the Flutter app and serve it with a simple HTTP server:

### Step 1: Build the Flutter Web App
```powershell
flutter build web
```

### Step 2: Serve with Python
```powershell
cd build/web
python -m http.server 8080 --bind 0.0.0.0
```

Or with Node.js (if you have it):
```powershell
cd build/web
npx http-server -p 8080 -a 0.0.0.0
```

## Firewall Note

If your phone still can't connect, you may need to allow port 8080 through Windows Firewall:

```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Flutter Web Server" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

## Testing

### From Your Computer
```powershell
curl -UseBasicParsing http://localhost:8080
```

### From Your Phone's Browser
Open: http://10.163.23.62:8080

If you see the Flutter app, the QR code will work!

## Current Status

Right now:
- ❌ Flutter is running in Chrome (localhost only)
- ❌ Not accessible from phone
- ✅ Backend API is accessible (port 8000)

After running the command:
- ✅ Flutter web server on all interfaces
- ✅ Accessible from phone
- ✅ QR code will work!
