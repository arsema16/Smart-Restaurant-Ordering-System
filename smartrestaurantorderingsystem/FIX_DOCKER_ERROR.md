# Fix Docker "500 Internal Server Error"

## What Happened:

Docker Desktop is installed but its engine isn't fully initialized. This is normal for a fresh installation.

## ✅ Simple Fix (2 minutes):

### Option 1: Restart Docker Desktop (Easiest)

1. **Find Docker Desktop in system tray** (bottom-right, whale icon 🐋)
2. **Right-click the whale icon**
3. **Click "Restart"**
4. **Wait 2 minutes** for Docker to restart
5. **Run the quick start script again:**
   ```powershell
   cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"
   .\QUICK_START.ps1
   ```

### Option 2: Use the Automated Restart Script

```powershell
cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"
.\RESTART_DOCKER_AND_START.ps1
```

This will automatically restart Docker and start the backend.

### Option 3: Restart Your Computer (Most Reliable)

Sometimes Docker Desktop needs a full system restart after first installation:

1. **Restart your computer**
2. **Docker Desktop should start automatically**
3. **Wait for whale icon to be steady**
4. **Run:**
   ```powershell
   cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"
   .\QUICK_START.ps1
   ```

---

## Why This Happens:

Docker Desktop was just installed and its Linux engine (WSL 2) needs to be fully initialized. A restart fixes this.

---

## After Docker Restarts:

The `QUICK_START.ps1` script should work perfectly and you'll see:

```
✓ Docker is ready!
✓ Services started
✓ PostgreSQL is ready
✓ Database created
✓ Migrations completed

Backend server starting...
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Then your app will work! 🎉

---

## Quick Decision:

- **Want it working in 2 minutes?** → Option 1 (Restart Docker Desktop)
- **Want it automated?** → Option 2 (Run the restart script)
- **Want most reliable?** → Option 3 (Restart computer)

I recommend **Option 1** - it's the fastest!
