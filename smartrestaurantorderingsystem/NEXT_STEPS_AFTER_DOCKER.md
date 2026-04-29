# Next Steps After Docker Installation Completes

## Quick Start Guide

Once Docker Desktop installation is complete, follow these steps to complete Task 20.

---

## Step 1: Verify Docker Installation (2 minutes)

```powershell
# Open a NEW PowerShell window (to refresh PATH)

# Verify Docker is installed
docker --version
# Expected: Docker version 4.70.0 or similar

# Verify Docker Compose is available
docker-compose --version
# Expected: Docker Compose version v2.x.x or similar

# Start Docker Desktop if not already running
# Look for the whale icon in system tray - it should be steady (not animated)
```

---

## Step 2: Run Automated Backend Tests (20-30 minutes)

```powershell
# Navigate to backend directory
cd backend

# Run the automated test suite
.\run_all_tests.ps1
```

**What this script does:**
1. Checks Docker status
2. Starts PostgreSQL and Redis containers
3. Waits for PostgreSQL to be ready
4. Runs database migrations
5. Executes all property-based tests (21 properties × 200 examples)
6. Executes all unit tests
7. Executes all integration tests
8. Generates HTML coverage report

**Expected Output:**
```
[1/7] Checking Docker status...
✓ Docker is installed

[2/7] Starting PostgreSQL and Redis...
✓ PostgreSQL and Redis are running

[3/7] Waiting for PostgreSQL to be ready...
✓ PostgreSQL is ready

[4/7] Running database migrations...
✓ Migrations completed

[5/7] Running property-based tests (21 properties)...
✓ All property tests passed

[6/7] Running unit tests...
✓ All unit tests passed

[7/7] Running integration tests...
✓ All integration tests passed

Coverage report: backend/htmlcov/index.html
```

---

## Step 3: Review Test Results (5 minutes)

```powershell
# Open coverage report in browser
start backend/htmlcov/index.html
```

**Check for:**
- ✅ All 21 property-based tests passed
- ✅ All unit tests passed
- ✅ All integration tests passed
- ✅ Coverage >80% on critical paths
- ✅ No critical failures

**If any tests fail:**
1. Check the error messages in console
2. Review `docker-compose logs` for infrastructure issues
3. Check database connection in `.env` file
4. Refer to TASK_20_TESTING_PLAN.md Troubleshooting section

---

## Step 4: Start Backend Server (2 minutes)

```powershell
# Open a NEW PowerShell window
cd backend

# Start the FastAPI server
py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected Output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Verify API is running:**
- Open browser: http://localhost:8000/docs
- You should see Swagger UI with all API endpoints

---

## Step 5: Run Flutter App (2 minutes)

```powershell
# Open a NEW PowerShell window (keep backend running)

# Run Flutter app on Chrome
flutter run -d chrome

# OR run on Windows
flutter run -d windows
```

**Expected Output:**
```
Launching lib/main.dart on Chrome in debug mode...
Building application for the web...
✓ Built build/web
```

---

## Step 6: Execute Manual Test Flows (40 minutes)

Follow the test scenarios in `MANUAL_TESTING_GUIDE.md`:

### Test Flow 1: Guest Journey (10 minutes)
1. Click "Test Mode (Simulate QR Scan)"
2. Select "table-1"
3. Browse menu items
4. Add items to cart
5. Place order
6. Track order status

**Expected:** ✅ Order placed successfully, status updates in real-time

### Test Flow 2: Staff Order Management (5 minutes)
1. Navigate to Staff Login
2. Login with credentials (username: `staff`, password: `password`)
3. View new order from Test Flow 1
4. Update order status: Received → Cooking → Ready → Delivered

**Expected:** ✅ Guest sees status updates within 2 seconds

### Test Flow 3: Menu Availability (3 minutes)
1. As staff, toggle menu item availability
2. As guest, verify item shows as unavailable within 5 seconds

**Expected:** ✅ Real-time availability updates work

### Test Flow 4: Session Restoration (2 minutes)
1. Add items to cart
2. Close and restart app
3. Verify cart contents preserved

**Expected:** ✅ Session restored automatically

### Test Flow 5: Cross-Device Session (3 minutes)
1. Create session on one device/browser
2. Access same session on another device/browser
3. Verify shared state

**Expected:** ✅ Session accessible from multiple devices

### Test Flow 6: Persistent User Identity (3 minutes)
1. Place orders in first session
2. Create new session (different table)
3. Verify recommendations reflect previous orders

**Expected:** ✅ Recommendations personalized across sessions

### Test Flow 7: Authentication Guards (2 minutes)
1. Try accessing staff routes without JWT
2. Try accessing guest routes without session token

**Expected:** ✅ Proper redirects to login/welcome screens

### Test Flow 8: Error Handling (3 minutes)
1. Try placing order with empty cart
2. Try invalid status transitions

**Expected:** ✅ Descriptive error messages shown

---

## Step 7: Test WebSocket Real-Time Updates (10 minutes)

### Test Order Status Updates
1. Keep guest app open on Orders screen
2. Update order status as staff
3. Verify guest receives update within 2 seconds

**Expected:** ✅ Real-time updates arrive quickly

### Test Menu Availability Updates
1. Keep guest app open on Menu screen
2. Toggle item availability as staff
3. Verify guest sees update within 5 seconds

**Expected:** ✅ Menu updates propagate to all guests

### Test WebSocket Reconnection
1. Stop backend server
2. Observe reconnection attempts in browser console
3. Restart backend server
4. Verify client reconnects and resyncs

**Expected:** ✅ Automatic reconnection with exponential backoff

---

## Step 8: Test Concurrent Operations (10 minutes)

### Test Concurrent Order Updates
1. Open staff dashboard in 2 browser windows
2. Update same order from both windows
3. Verify consistent final state

**Expected:** ✅ Last-write-wins, all instances updated

### Test Concurrent Cart Operations
1. Open same session in 2 browser windows
2. Add items from both windows
3. Verify cart state consistency

**Expected:** ✅ Cart updates synchronized

---

## Step 9: Mark Task Complete (5 minutes)

If all tests pass:

```powershell
# Create final test report
# Document any issues found
# Update tasks.md status to completed
```

**Create a summary:**
- Total tests run
- Tests passed/failed
- Coverage percentage
- Any issues found
- Time taken

---

## Troubleshooting

### Docker Issues

**Problem:** Docker containers won't start
```powershell
docker-compose down
docker-compose up -d --force-recreate
```

**Problem:** Port conflicts (5432, 6379, 8000)
```powershell
# Check what's using the port
netstat -ano | findstr :5432
# Kill the process or change port in docker-compose.yml
```

### Database Issues

**Problem:** Migration fails
```powershell
# Reset database
docker-compose down -v
docker-compose up -d postgres
py -m alembic upgrade head
```

**Problem:** Connection refused
- Verify PostgreSQL is running: `docker-compose ps`
- Check connection string in `.env`
- Verify firewall settings

### Backend Issues

**Problem:** Import errors
```powershell
# Reinstall dependencies
py -m pip install --upgrade -r requirements-test.txt
```

**Problem:** Tests fail with async errors
- Verify `pytest-asyncio` is installed
- Check `asyncio_mode = auto` in `pytest.ini`

### Frontend Issues

**Problem:** Flutter build fails
```powershell
flutter clean
flutter pub get
flutter run
```

**Problem:** WebSocket connection fails
- Verify backend is running on correct port
- Check API_CONSTANTS.baseUrl in Flutter code
- Verify CORS settings in FastAPI

---

## Success Checklist

### Backend
- [ ] Docker containers running (PostgreSQL, Redis)
- [ ] All 21 property-based tests pass
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Test coverage >80%
- [ ] Backend server starts without errors
- [ ] API documentation accessible at /docs

### Frontend
- [ ] Flutter app builds successfully
- [ ] Staff UI tests pass
- [ ] App runs on Chrome/Windows
- [ ] No compilation errors

### Integration
- [ ] Guest can complete full ordering flow
- [ ] Staff can manage orders end-to-end
- [ ] Real-time updates arrive within 2-5 seconds
- [ ] WebSocket connections stable
- [ ] Session restoration works
- [ ] Cross-device access works
- [ ] Authentication guards work
- [ ] Error scenarios handled gracefully

### Performance
- [ ] API response times <500ms
- [ ] WebSocket latency <100ms
- [ ] No memory leaks observed
- [ ] Database queries optimized
- [ ] Redis cache working

---

## Estimated Time

- **Docker verification:** 2 minutes
- **Automated backend tests:** 20-30 minutes
- **Review test results:** 5 minutes
- **Start servers:** 4 minutes
- **Manual E2E testing:** 40 minutes
- **WebSocket testing:** 10 minutes
- **Concurrent testing:** 10 minutes
- **Documentation:** 5 minutes

**Total:** ~1.5-2 hours

---

## Final Notes

- Keep all terminal windows open during testing
- Take screenshots of any issues found
- Document any unexpected behavior
- Note performance metrics (response times, latency)
- Save test results for future reference

**Good luck with testing! 🚀**
