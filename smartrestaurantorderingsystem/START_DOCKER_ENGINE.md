# Start Docker Desktop Engine

## The Problem
Docker Desktop is installed, but the Docker Engine is not running.

Error: `The system cannot find the file specified: //./pipe/dockerDesktopLinuxEngine`

## Solution

### Step 1: Start Docker Desktop
1. Press **Windows Key**
2. Type "Docker Desktop"
3. Click on **Docker Desktop** to launch it
4. Wait for the whale icon to appear in your system tray (bottom-right corner)
5. Wait until the whale icon stops animating (becomes steady)
6. This may take 2-3 minutes on first start

### Step 2: Verify Docker Engine is Running
Open PowerShell and run:
```powershell
docker info
```

If you see server information (not an error), Docker Engine is running!

### Step 3: Start the Backend
```powershell
cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"
.\QUICK_START.ps1
```

## What to Look For

**Docker Desktop System Tray Icon:**
- 🐋 **Animating (moving up/down)** = Docker is starting (wait)
- 🐋 **Steady (not moving)** = Docker is ready (proceed)
- ❌ **Red X or warning** = Docker failed to start (restart computer)

## If Docker Desktop Won't Start

1. **Close Docker Desktop completely**
2. **Open PowerShell as Administrator**
3. **Run:**
   ```powershell
   wsl --install
   wsl --set-default-version 2
   wsl --update
   ```
4. **Restart your computer**
5. **Start Docker Desktop again**

## After Docker Starts Successfully

The backend will:
- ✓ Start PostgreSQL database
- ✓ Start Redis cache
- ✓ Run database migrations
- ✓ Start FastAPI server at http://localhost:8000

Then you can:
- Open http://localhost:8000/docs (API documentation)
- Refresh your Flutter app in Chrome
- Test the full ordering system!
