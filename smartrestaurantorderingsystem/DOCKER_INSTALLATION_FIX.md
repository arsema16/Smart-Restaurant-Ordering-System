# Docker Installation Fix - Permission Error

## Error You're Seeing:
```
Installer failed with exit code: 4294967291
For security reasons C:\ProgramData\DockerDesktop must be owned by an elevated account
```

## Solution Options (Choose One):

---

## ✅ OPTION 1: Fix Permissions and Retry (Recommended - 5 minutes)

### Step 1: Delete the problematic directory

**Run PowerShell as Administrator**, then:

```powershell
# Remove the directory with permission issues
Remove-Item -Path "C:\ProgramData\DockerDesktop" -Recurse -Force -ErrorAction SilentlyContinue

# Verify it's gone
Test-Path "C:\ProgramData\DockerDesktop"
# Should return: False
```

### Step 2: Retry Docker installation

```powershell
# Still in Administrator PowerShell:
winget install Docker.DockerDesktop
```

This should work now! Wait 10-15 minutes for installation to complete.

---

## ✅ OPTION 2: Manual Download and Install (Fastest - 15 minutes)

### Step 1: Download Docker Desktop

1. Open browser: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe
2. Download will start automatically (~600 MB)

### Step 2: Install

1. Right-click the downloaded `Docker Desktop Installer.exe`
2. Select "Run as administrator"
3. Click "Yes" on UAC prompt
4. Follow installation wizard
5. Wait for installation to complete

### Step 3: Start Docker Desktop

1. Press Windows Key
2. Type "Docker Desktop"
3. Launch it
4. Wait for Docker Engine to start (whale icon in system tray should be steady)

---

## ✅ OPTION 3: Skip Docker - Use SQLite for Testing (Quick - 10 minutes)

If you want to test the app RIGHT NOW without waiting for Docker, I can help you modify the backend to use SQLite temporarily.

**Pros:**
- ✅ Works immediately
- ✅ No Docker needed
- ✅ Can test most features

**Cons:**
- ⚠️ Some features won't work (JSONB fields, Redis caching)
- ⚠️ Not production-ready
- ⚠️ Need to switch back to PostgreSQL later

**To use this option, let me know and I'll modify the backend configuration.**

---

## After Docker is Installed:

### Verify Installation:

```powershell
# Open NEW PowerShell window (to refresh PATH)
docker --version
# Should show: Docker version 4.70.0 or similar

docker-compose --version
# Should show: Docker Compose version v2.x.x
```

### Start the Backend:

```powershell
cd backend

# Start PostgreSQL and Redis
docker-compose up -d

# Wait 10 seconds for services to start
Start-Sleep -Seconds 10

# Run database migrations
py -m alembic upgrade head

# Start backend server
py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Test the App:

1. Backend should be running at: http://localhost:8000
2. API docs at: http://localhost:8000/docs
3. Flutter app is already running in Chrome
4. Refresh the Chrome browser
5. **The app should now work fully!** 🎉

---

## Troubleshooting:

### If Option 1 doesn't work:

```powershell
# Try taking ownership of the directory first
takeown /F "C:\ProgramData\DockerDesktop" /R /D Y
icacls "C:\ProgramData\DockerDesktop" /grant Administrators:F /T

# Then remove it
Remove-Item -Path "C:\ProgramData\DockerDesktop" -Recurse -Force

# Then retry installation
winget install Docker.DockerDesktop
```

### If Docker Desktop won't start:

1. Check Windows version: Docker Desktop requires Windows 10/11 Pro, Enterprise, or Education
2. Enable Hyper-V and WSL 2:
   ```powershell
   # Run as Administrator:
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   wsl --install
   ```
3. Restart computer
4. Start Docker Desktop again

---

## My Recommendation:

**Use Option 2 (Manual Download)** - it's the most reliable and you'll have Docker installed properly for future use.

The installation takes 15 minutes, but then you'll have the full app working with all features!

---

## Need Help?

Let me know which option you want to try and I'll guide you through it step by step!
