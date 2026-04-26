# Quick Start Testing Guide

## Prerequisites

1. **Backend Server**
   ```bash
   cd backend
   docker-compose up -d  # Start PostgreSQL and Redis
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Flutter App**
   ```bash
   flutter pub get
   flutter run
   ```

## Quick Test Scenarios

### Scenario 1: Guest Orders Food (5 minutes)

1. **Start App**
   - App opens to Welcome screen
   - Click "Test Mode (Simulate QR Scan)"
   - Select "table-1"
   - ✅ Should navigate to Menu screen

2. **Browse and Order**
   - Browse menu items by category
   - Click "Add" on 2-3 items
   - ✅ Cart badge should show item count
   - Tap cart icon
   - ✅ Should see added items with quantities
   - Tap "Place Order"
   - ✅ Should see order confirmation with order number

3. **Track Order**
   - Navigate to Orders screen
   - ✅ Should see placed order with status "Received"
   - Keep screen open for next scenario

### Scenario 2: Staff Manages Order (3 minutes)

1. **Staff Login**
   - From Welcome screen, navigate to Staff Login
   - Enter credentials (username: `staff`, password: `password`)
   - ✅ Should navigate to Staff Dashboard

2. **View and Update Order**
   - Go to Orders tab
   - ✅ Should see the order from Scenario 1 within 2 seconds
   - Click "Mark as Cooking"
   - ✅ Order status should update

3. **Verify Real-time Update**
   - Switch back to guest app (Scenario 1, step 3)
   - ✅ Order status should update to "Cooking" within 2 seconds
   - Return to staff app
   - Click "Mark as Ready"
   - Click "Mark as Delivered"
   - ✅ Guest should see final "Delivered" status

### Scenario 3: Menu Availability (2 minutes)

1. **Guest Views Menu**
   - As guest, open Menu screen
   - Note an available item (e.g., "Pizza")

2. **Staff Changes Availability**
   - As staff, go to Menu Management tab
   - Find the same item
   - Toggle availability to "Unavailable"
   - ✅ Change should save

3. **Guest Sees Update**
   - Return to guest Menu screen
   - ✅ Item should show as unavailable within 5 seconds
   - ✅ "Add to Cart" button should be disabled

### Scenario 4: Session Restoration (1 minute)

1. **Create Session**
   - Scan QR code (or use Test Mode)
   - Add items to cart
   - Note the cart count

2. **Restart App**
   - Close and restart the Flutter app
   - ✅ Should automatically navigate to Menu screen
   - Tap cart icon
   - ✅ Should see same items from step 1

## Expected Results

All scenarios should complete without errors:
- ✅ No crashes or exceptions
- ✅ Real-time updates arrive within 2-5 seconds
- ✅ Session persists across app restarts
- ✅ Authentication guards work correctly
- ✅ WebSocket connections remain stable

## Troubleshooting

### Backend Not Running
**Error:** "Failed to connect to localhost:8000"
**Solution:** Start backend server (see Prerequisites)

### WebSocket Not Connecting
**Error:** Red WiFi icon in staff dashboard
**Solution:** 
1. Check backend WebSocket endpoint is running
2. Verify API_CONSTANTS.baseUrl is correct
3. Check browser console for WebSocket errors

### Session Not Restoring
**Error:** Redirected to Welcome screen after restart
**Solution:**
1. Check SharedPreferences is working
2. Verify session token is stored
3. Check backend session is still valid

### Orders Not Appearing
**Error:** "No active orders" in staff dashboard
**Solution:**
1. Verify order was placed successfully
2. Check backend database for order
3. Verify WebSocket connection is active

## Debug Mode

To see detailed logs:

```bash
# Flutter logs
flutter run --verbose

# Backend logs
# Check docker-compose logs or uvicorn console output
```

## Success Criteria

- ✅ All 4 scenarios complete successfully
- ✅ No error messages or crashes
- ✅ Real-time updates work as expected
- ✅ Session restoration works
- ✅ Authentication guards prevent unauthorized access

## Next Steps

After quick testing succeeds:
1. Run full manual tests from `MANUAL_TESTING_GUIDE.md`
2. Test edge cases (invalid tokens, network errors, etc.)
3. Implement automated E2E tests in `test/integration/e2e_flow_test.dart`
