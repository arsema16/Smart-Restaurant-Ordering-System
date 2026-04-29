# Task 20: Final Checkpoint - Full System Integration Test

## Testing Plan and Execution Guide

### Prerequisites Status

✅ **Python 3.14.3** - Installed and working
✅ **All Python Dependencies** - Installed (FastAPI, pytest, hypothesis, SQLAlchemy, etc.)
✅ **Flutter 3.41.6** - Installed and ready
⏳ **Docker Desktop** - Currently installing (617 MB download in progress)
⏳ **PostgreSQL 15** - Will be available via Docker
⏳ **Redis 7** - Will be available via Docker

---

## Phase 1: Complete Docker Installation

### Step 1.1: Wait for Docker Installation to Complete
The Docker Desktop installation is currently in progress. Once complete:

1. **Start Docker Desktop**
   - Open Docker Desktop from Start Menu
   - Wait for Docker Engine to start (whale icon in system tray should be steady)
   - Verify installation:
     ```bash
     docker --version
     docker-compose --version
     ```

2. **Configure Docker Resources** (Optional but recommended)
   - Open Docker Desktop Settings
   - Go to Resources → Advanced
   - Allocate at least:
     - CPUs: 2
     - Memory: 4 GB
     - Disk: 20 GB

---

## Phase 2: Backend Infrastructure Setup

### Step 2.1: Start PostgreSQL and Redis with Docker Compose

```bash
cd backend
docker-compose up -d postgres redis
```

**Expected Output:**
```
Creating network "backend_default" with the default driver
Creating backend_postgres_1 ... done
Creating backend_redis_1    ... done
```

### Step 2.2: Verify Services are Running

```bash
# Check running containers
docker-compose ps

# Test PostgreSQL connection
docker-compose exec postgres psql -U postgres -c "SELECT version();"

# Test Redis connection
docker-compose exec redis redis-cli ping
```

**Expected Output:**
- PostgreSQL: Version information
- Redis: `PONG`

### Step 2.3: Run Database Migrations

```bash
# Create database
py -m app.database  # or use the create_test_db.py script

# Run Alembic migrations
py -m alembic upgrade head
```

**Expected Output:**
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> <revision>, Initial migration
```

---

## Phase 3: Backend Testing

### Step 3.1: Run All Backend Tests

```bash
cd backend

# Run all tests with coverage
py -m pytest --cov=app --cov-report=html --cov-report=term-missing -v

# Or run specific test categories:

# Unit tests only
py -m pytest -m unit -v

# Integration tests only
py -m pytest -m integration -v

# Property-based tests only
py -m pytest -m property -v

# End-to-end tests only
py -m pytest -m e2e -v
```

### Step 3.2: Expected Test Results

**Property-Based Tests (21 properties):**
- ✅ Property 1: Session Token Uniqueness
- ✅ Property 2: Session Token Round-Trip
- ✅ Property 3: Menu Grouping Completeness
- ✅ Property 4: Unavailable Item Rejection
- ✅ Property 5: Cart Quantity Invariant
- ✅ Property 6: Unavailable Cart Item Removal
- ✅ Property 7: Order Number Uniqueness and Initial Status
- ✅ Property 8: Multiple Orders Per Session
- ✅ Property 9: Order Status Transition Guard
- ✅ Property 10: Staff Order Response Completeness
- ✅ Property 11: Order Status Persistence Round-Trip
- ✅ Property 12: Estimated Wait Time Calculation
- ✅ Property 13: Preference Profile Update Invariants
- ✅ Property 14: Preference Profile Persistence
- ✅ Property 15: Preference Profile Serialization Round-Trip
- ✅ Property 16: Recommendation Exclusion and Size
- ✅ Property 17: Upsell Inclusion When Main Course Present
- ✅ Property 18: Popularity Fallback Ordering
- ✅ Property 19: Menu Item Validation
- ✅ Property 20: Menu Item CRUD Round-Trip
- ✅ Property 21: Session State Round-Trip

**Unit Tests:**
- Model validation tests
- Service layer tests
- Authentication tests
- Middleware tests

**Integration Tests:**
- API endpoint tests
- WebSocket connection tests
- Database integration tests
- Redis caching tests

### Step 3.3: Review Test Coverage

```bash
# Open HTML coverage report
start htmlcov/index.html  # Windows
# or
open htmlcov/index.html   # Mac/Linux
```

**Target Coverage:** >80% on critical paths

---

## Phase 4: Start Backend Server

### Step 4.1: Start the FastAPI Server

```bash
cd backend
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

### Step 4.2: Verify API is Running

Open browser and navigate to:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/api/v1/health (if implemented)

---

## Phase 5: Frontend Testing

### Step 5.1: Run Flutter Tests

```bash
# Run all Flutter tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
flutter test test/staff_ui_test.dart
```

### Step 5.2: Run Integration Tests

```bash
# Run integration tests
flutter test test/integration/
```

---

## Phase 6: Manual End-to-End Testing

### Step 6.1: Start Flutter App

```bash
# Run on Chrome (web)
flutter run -d chrome

# Or run on Windows
flutter run -d windows

# Or run on connected device
flutter run
```

### Step 6.2: Execute Test Scenarios

Follow the comprehensive test scenarios in `MANUAL_TESTING_GUIDE.md`:

**Test Flow 1: Guest Journey** (10 minutes)
- ✅ QR Code scan/simulation
- ✅ Browse menu by category
- ✅ Add items to cart
- ✅ Update quantities
- ✅ Place order
- ✅ Track order status in real-time

**Test Flow 2: Staff Order Management** (5 minutes)
- ✅ Staff login
- ✅ View new orders (real-time)
- ✅ Update order status (Received → Cooking → Ready → Delivered)
- ✅ Verify guest receives updates within 2 seconds

**Test Flow 3: Menu Availability Changes** (3 minutes)
- ✅ Staff toggles menu item availability
- ✅ Guest sees update within 5 seconds
- ✅ Unavailable items removed from cart

**Test Flow 4: Session Restoration** (2 minutes)
- ✅ Create session and add items
- ✅ Close and restart app
- ✅ Verify session restored
- ✅ Verify cart contents preserved

**Test Flow 5: Cross-Device Session Access** (3 minutes)
- ✅ Create session on Device A
- ✅ Access same session on Device B
- ✅ Verify shared state

**Test Flow 6: Persistent User Identity** (3 minutes)
- ✅ Place orders in first session
- ✅ Create new session (different table)
- ✅ Verify recommendations reflect previous orders

**Test Flow 7: Authentication Guards** (2 minutes)
- ✅ Guest routes require session token
- ✅ Staff routes require JWT
- ✅ Invalid tokens redirect appropriately

**Test Flow 8: Error Handling** (3 minutes)
- ✅ Empty cart blocks order placement
- ✅ Unavailable items handled gracefully
- ✅ Invalid status transitions rejected

---

## Phase 7: WebSocket and Real-Time Testing

### Step 7.1: Test WebSocket Connections

**Guest WebSocket:**
```bash
# Use wscat or similar tool
wscat -c "ws://localhost:8000/ws/guest/{session_id}?token={session_token}"
```

**Staff WebSocket:**
```bash
wscat -c "ws://localhost:8000/ws/staff?token={jwt_token}"
```

### Step 7.2: Test Real-Time Updates

1. **Order Status Updates**
   - Place order as guest
   - Update status as staff
   - Verify guest receives update within 2 seconds

2. **Menu Availability Changes**
   - Toggle availability as staff
   - Verify all guests receive update within 5 seconds

3. **New Order Notifications**
   - Place order as guest
   - Verify staff dashboard receives notification within 2 seconds

### Step 7.3: Test WebSocket Reconnection

1. Stop backend server
2. Observe client reconnection attempts (exponential backoff: 1s, 2s, 4s, 8s)
3. Restart backend server
4. Verify client reconnects and resyncs state

---

## Phase 8: Concurrent Testing

### Step 8.1: Test Concurrent Order Updates

1. Open multiple staff dashboard instances
2. Update same order from different instances
3. Verify consistent final state (last-write-wins)
4. Verify all instances receive updates

### Step 8.2: Test Concurrent Cart Operations

1. Open same session on multiple devices
2. Add items from different devices
3. Verify cart state consistency
4. Place order and verify all devices see update

---

## Phase 9: Performance and Load Testing

### Step 9.1: Property-Based Test Performance

```bash
# Run with CI profile (500 examples)
HYPOTHESIS_PROFILE=ci py -m pytest -m property -v
```

### Step 9.2: API Load Testing (Optional)

```bash
# Install locust or similar tool
pip install locust

# Create locustfile.py with test scenarios
# Run load test
locust -f locustfile.py --host=http://localhost:8000
```

---

## Phase 10: Final Verification Checklist

### Backend Verification
- [ ] All 21 property-based tests pass
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Test coverage >80%
- [ ] No critical security vulnerabilities
- [ ] API documentation is accurate (Swagger UI)
- [ ] Database migrations run successfully
- [ ] Redis caching works correctly

### Frontend Verification
- [ ] All Flutter tests pass
- [ ] No compilation errors or warnings
- [ ] UI renders correctly on all target platforms
- [ ] Navigation works as expected
- [ ] State management works correctly
- [ ] Error handling is user-friendly

### Integration Verification
- [ ] Guest can complete full ordering flow
- [ ] Staff can manage orders end-to-end
- [ ] Real-time updates arrive within SLA (2-5 seconds)
- [ ] WebSocket connections are stable
- [ ] Session restoration works across restarts
- [ ] Cross-device session access works
- [ ] Authentication guards work correctly
- [ ] Error scenarios handled gracefully

### Performance Verification
- [ ] API response times <500ms for most endpoints
- [ ] WebSocket latency <100ms
- [ ] No memory leaks in long-running sessions
- [ ] Database queries are optimized (no N+1 queries)
- [ ] Redis cache hit rate >80%

---

## Troubleshooting Guide

### Docker Issues

**Problem:** Docker containers won't start
**Solution:**
```bash
docker-compose down
docker-compose up -d --force-recreate
```

**Problem:** Port conflicts (5432, 6379, 8000)
**Solution:**
```bash
# Check what's using the port
netstat -ano | findstr :5432
# Kill the process or change port in docker-compose.yml
```

### Database Issues

**Problem:** Migration fails
**Solution:**
```bash
# Reset database
docker-compose down -v
docker-compose up -d postgres
py -m alembic upgrade head
```

**Problem:** Connection refused
**Solution:**
- Verify PostgreSQL is running: `docker-compose ps`
- Check connection string in `.env`
- Verify firewall settings

### Redis Issues

**Problem:** Redis connection fails
**Solution:**
```bash
# Restart Redis
docker-compose restart redis
# Test connection
docker-compose exec redis redis-cli ping
```

### Backend Issues

**Problem:** Import errors
**Solution:**
```bash
# Reinstall dependencies
py -m pip install --upgrade -r requirements-test.txt
```

**Problem:** Tests fail with async errors
**Solution:**
- Verify `pytest-asyncio` is installed
- Check `asyncio_mode = auto` in `pytest.ini`

### Frontend Issues

**Problem:** Flutter build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

**Problem:** WebSocket connection fails
**Solution:**
- Verify backend is running on correct port
- Check API_CONSTANTS.baseUrl in Flutter code
- Verify CORS settings in FastAPI

---

## Success Criteria

✅ **All tests pass:**
- 21 property-based tests
- All unit tests
- All integration tests
- All Flutter tests

✅ **Manual testing complete:**
- All 8 test flows executed successfully
- No crashes or unhandled exceptions
- Real-time updates work within SLA

✅ **Performance acceptable:**
- API response times <500ms
- WebSocket latency <100ms
- No memory leaks

✅ **Documentation accurate:**
- API docs match implementation
- Testing guides are up-to-date
- README instructions work

---

## Next Steps After Testing

1. **Document Test Results**
   - Create test report with pass/fail status
   - Document any issues found
   - Create tickets for bugs

2. **Update Documentation**
   - Update README with any changes
   - Update API documentation
   - Update deployment guide

3. **Prepare for Deployment**
   - Review security settings
   - Configure production environment variables
   - Set up CI/CD pipeline

4. **Mark Task Complete**
   - Update tasks.md status to completed
   - Document completion in project log
   - Notify stakeholders

---

## Estimated Time

- **Docker Installation:** 10-15 minutes (in progress)
- **Infrastructure Setup:** 5 minutes
- **Backend Testing:** 15-20 minutes
- **Frontend Testing:** 10 minutes
- **Manual E2E Testing:** 30-40 minutes
- **WebSocket Testing:** 10 minutes
- **Concurrent Testing:** 10 minutes
- **Documentation:** 10 minutes

**Total:** ~2-2.5 hours

---

## Contact for Issues

If you encounter any issues during testing:
1. Check the Troubleshooting Guide above
2. Review error logs in terminal/console
3. Check Docker logs: `docker-compose logs`
4. Review backend logs in uvicorn output
5. Check Flutter logs: `flutter logs`

