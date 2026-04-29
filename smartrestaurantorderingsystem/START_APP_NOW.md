# 🚀 Start the App NOW - Final Steps

## ✅ Docker Desktop is Installed!

Docker Desktop is starting up. Follow these steps to get the full app running:

---

## Step 1: Wait for Docker Desktop to Start (2-3 minutes)

**Look for the Docker whale icon in your system tray (bottom-right corner):**

- 🐋 **Animated/spinning** = Docker is starting (wait)
- 🐋 **Steady/still** = Docker is ready (proceed!)

**Or check the Docker Desktop window** - it should say "Docker Desktop is running"

---

## Step 2: Verify Docker is Ready

**Open a NEW PowerShell window** (to refresh PATH), then run:

```powershell
docker --version
```

**Expected output:**
```
Docker version 4.70.0, build...
```

If you see this, Docker is ready! If not, wait another minute and try again.

---

## Step 3: Start Backend Services (2 minutes)

```powershell
# Navigate to backend directory
cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"

# Start PostgreSQL and Redis
docker-compose up -d

# Wait for services to start
Start-Sleep -Seconds 10

# Check services are running
docker-compose ps
```

**Expected output:**
```
NAME                  STATUS
backend-postgres-1    Up
backend-redis-1       Up
```

---

## Step 4: Run Database Migrations (30 seconds)

```powershell
# Still in backend directory
py -m alembic upgrade head
```

**Expected output:**
```
INFO  [alembic.runtime.migration] Running upgrade  -> xxxxx, Initial migration
```

---

## Step 5: Start Backend Server (1 minute)

```powershell
# Still in backend directory
py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Application startup complete.
```

**✅ Backend is now running!**

---

## Step 6: Test the App (NOW!)

### Your Flutter app is already running in Chrome!

1. **Go to the Chrome window** with your app
2. **Refresh the page** (F5 or Ctrl+R)
3. **The app should now work fully!** 🎉

### Test These Features:

1. **Click "Test Mode (Simulate QR Scan)"**
2. **Select a table** (e.g., "table-1")
3. **Browse the menu** - you should see menu items!
4. **Add items to cart**
5. **Place an order**
6. **Track order status**

### Open Staff Dashboard:

1. **In Chrome, open new tab:** http://localhost:8000/docs
2. **You should see the API documentation!**

---

## Step 7: Test Staff Features

### Create a Staff User (First Time Only):

```powershell
# In a NEW PowerShell window, navigate to backend:
cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"

# Create a staff user (you'll need to create a script or use the API)
# For now, you can test with the API docs at http://localhost:8000/docs
```

---

## 🎉 Success Checklist:

- [ ] Docker Desktop running (whale icon steady)
- [ ] `docker --version` works
- [ ] PostgreSQL and Redis containers running
- [ ] Database migrations completed
- [ ] Backend server running on port 8000
- [ ] API docs accessible at http://localhost:8000/docs
- [ ] Flutter app refreshed and working
- [ ] Can browse menu items
- [ ] Can add items to cart
- [ ] Can place orders

---

## Troubleshooting:

### Docker Desktop won't start:

1. **Restart your computer** (Docker Desktop sometimes needs this after first install)
2. **Check Windows version:** Docker requires Windows 10/11 Pro, Enterprise, or Education
3. **Enable WSL 2:**
   ```powershell
   wsl --install
   ```
4. **Restart Docker Desktop** from Start Menu

### Backend won't start:

```powershell
# Check if services are running:
docker-compose ps

# View logs:
docker-compose logs postgres
docker-compose logs redis

# Restart services:
docker-compose down
docker-compose up -d
```

### Flutter app still shows "null is unreachable":

1. **Verify backend is running:** http://localhost:8000/docs
2. **Refresh the Flutter app** in Chrome (F5)
3. **Check browser console** for errors (F12 → Console tab)

---

## Quick Commands Reference:

```powershell
# Check Docker status
docker --version
docker-compose ps

# Start services
cd backend
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart backend
# Press Ctrl+C in the uvicorn terminal, then:
py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 🎊 You're Almost There!

Once Docker Desktop finishes starting (look for the steady whale icon), run the commands in Steps 2-5, and your app will be **fully functional**!

The hard part is done - Docker is installed! Now it's just a few commands and you'll see the complete Smart Restaurant Ordering System working! 🚀
