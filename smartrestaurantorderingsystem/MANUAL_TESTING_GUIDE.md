# Manual Testing Guide - Task 19.3

This guide provides step-by-step instructions for manually testing the complete end-to-end flows of the Smart Restaurant Ordering System.

## Prerequisites

1. Backend server running on `http://localhost:8000`
2. Flutter app running (use `flutter run` or run from IDE)
3. At least one staff user created in the database
4. Sample menu items in the database

## Test Flow 1: Guest Journey (QR Scan to Order Delivery)

**Validates Requirements:** 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2, 4.1, 4.2, 6.1, 6.2, 6.5

### Steps:

1. **QR Code Scan**
   - Open the app (should show Welcome screen)
   - Click "Test Mode (Simulate QR Scan)" button
   - Select a table (e.g., "table-1")
   - **Expected:** App navigates to Menu screen
   - **Verify:** Session token is stored in SharedPreferences

2. **Browse Menu**
   - **Expected:** Menu items are displayed grouped by category
   - **Verify:** Each item shows name, price, prep time, and availability status
   - **Verify:** Unavailable items are marked and cannot be added to cart

3. **Add Items to Cart**
   - Tap "Add to Cart" on an available item
   - **Expected:** Item is added to cart
   - **Verify:** Cart icon shows item count
   - Add the same item again
   - **Expected:** Quantity increments

4. **View Cart**
   - Navigate to Cart screen
   - **Expected:** All added items are displayed with quantities
   - **Verify:** Total price is calculated correctly
   - **Verify:** Can increase/decrease quantities
   - **Verify:** Can remove items

5. **Place Order**
   - Tap "Place Order" button
   - **Expected:** Order is created successfully
   - **Verify:** Unique order number is displayed (e.g., "ORD-0042")
   - **Verify:** Initial status is "Received"
   - **Verify:** Cart is cleared after order placement

6. **Track Order Status**
   - Navigate to Orders screen
   - **Expected:** Placed order is visible in order history
   - **Verify:** Order shows current status
   - **Verify:** Estimated wait time is displayed
   - Keep the screen open for real-time updates

7. **Receive Status Updates**
   - Have a staff member update the order status (see Test Flow 2)
   - **Expected:** Status updates appear within 2 seconds via WebSocket
   - **Verify:** Status changes: Received → Cooking → Ready → Delivered
   - **Verify:** When status reaches "Delivered", order is marked as complete

## Test Flow 2: Staff Order Management

**Validates Requirements:** 5.1, 5.2, 5.3, 5.4, 5.5, 5.6

### Steps:

1. **Staff Login**
   - Navigate to Staff Login (from Welcome screen or direct URL)
   - Enter staff credentials
   - **Expected:** Login successful, navigate to Staff Dashboard
   - **Verify:** JWT token is stored in SharedPreferences

2. **View New Orders**
   - Open Orders tab in Staff Dashboard
   - **Expected:** New order from Test Flow 1 appears within 2 seconds
   - **Verify:** Order shows order number, table identifier, items, quantities, and status

3. **Update Order Status**
   - Tap on order to view details
   - Update status from "Received" to "Cooking"
   - **Expected:** Status updates successfully
   - **Verify:** Guest receives WebSocket update (check Test Flow 1, step 7)

4. **Continue Status Updates**
   - Update status from "Cooking" to "Ready"
   - **Expected:** Status updates successfully
   - Update status from "Ready" to "Delivered"
   - **Expected:** Status updates successfully
   - **Verify:** Guest sees final "Delivered" status

5. **Test Invalid Transition**
   - Create a new order (as guest)
   - Try to update status from "Received" directly to "Delivered"
   - **Expected:** Error message displayed
   - **Verify:** Status remains "Received"

6. **Logout**
   - Tap logout button
   - **Expected:** Redirect to Staff Login
   - **Verify:** JWT token is removed from SharedPreferences

## Test Flow 3: Menu Availability Changes

**Validates Requirements:** 2.3, 2.4, 3.6

### Steps:

1. **Guest Views Menu**
   - As guest, open Menu screen
   - Note an available item

2. **Staff Changes Availability**
   - As staff, navigate to Menu Management
   - Toggle availability of the noted item to "Unavailable"
   - **Expected:** Change is saved

3. **Guest Sees Update**
   - Return to guest Menu screen
   - **Expected:** Item shows as unavailable within 5 seconds
   - **Verify:** "Add to Cart" button is disabled for that item

4. **Cart Item Removal**
   - As guest, add an available item to cart
   - As staff, mark that item as unavailable
   - Return to guest Cart screen
   - **Expected:** Item is removed from cart
   - **Verify:** Notification is shown to guest

## Test Flow 4: Session Restoration

**Validates Requirements:** 1.3, 10.1, 10.2

### Steps:

1. **Create Session and Add Items**
   - Scan QR code to create session
   - Add items to cart
   - Note the session token (check SharedPreferences or logs)

2. **Simulate Page Reload**
   - Close and restart the app
   - **Expected:** App shows Splash screen
   - **Expected:** App automatically navigates to Menu screen (session restored)

3. **Verify Session State**
   - Navigate to Cart
   - **Expected:** Previously added items are still in cart
   - **Verify:** Quantities and total price are correct

4. **Verify Order History**
   - Navigate to Orders screen
   - **Expected:** Previous orders are displayed
   - **Verify:** Order details are preserved

## Test Flow 5: Cross-Device Session Access

**Validates Requirements:** 1.4, 10.1, 10.2

### Steps:

1. **Create Session on Device A**
   - Scan QR code on first device/browser
   - Add items to cart
   - Place an order
   - Note the session token

2. **Access Session on Device B**
   - On second device/browser, manually set the session token in SharedPreferences
   - Or use a deep link with the session token
   - Restart the app
   - **Expected:** Session is restored

3. **Verify Shared State**
   - Navigate to Cart
   - **Expected:** Same cart items from Device A
   - Navigate to Orders
   - **Expected:** Same order history from Device A

4. **Test Concurrent Updates**
   - On Device A, add an item to cart
   - On Device B, refresh cart
   - **Expected:** New item appears on Device B

## Test Flow 6: Persistent User Identity

**Validates Requirements:** 7.4, 8.1

### Steps:

1. **First Session**
   - Scan QR code (creates persistent_user_id)
   - Place an order with specific items
   - Note the persistent_user_id (check SharedPreferences)
   - End session (clear session token but keep persistent_user_id)

2. **Second Session**
   - Scan QR code for a different table
   - **Expected:** New session created with same persistent_user_id
   - Navigate to Menu
   - **Expected:** Recommendations reflect previous orders

3. **Verify Preference Profile**
   - Check that recommended items include previously ordered items
   - **Verify:** Most-ordered items appear in recommendations
   - **Verify:** Recently ordered items influence suggestions

## Test Flow 7: Authentication Guards

**Validates Requirements:** 1.6, 2.5, 5.6

### Steps:

1. **Guest Routes Without Session**
   - Clear all SharedPreferences
   - Try to navigate directly to `/menu`
   - **Expected:** Redirect to Welcome screen

2. **Staff Routes Without JWT**
   - Clear JWT token from SharedPreferences
   - Try to navigate to `/staff/dashboard`
   - **Expected:** Redirect to Staff Login

3. **Invalid Session Token**
   - Set an invalid session token in SharedPreferences
   - Try to access Menu
   - **Expected:** API returns 401
   - **Expected:** App redirects to Welcome screen

4. **Invalid JWT Token**
   - Set an invalid JWT token in SharedPreferences
   - Try to access Staff Dashboard
   - **Expected:** API returns 401
   - **Expected:** App redirects to Staff Login

## Test Flow 8: Error Handling

**Validates Requirements:** 3.5, 4.6, 5.4, 5.5

### Steps:

1. **Empty Cart Order Placement**
   - Navigate to Cart with no items
   - **Expected:** "Place Order" button is disabled
   - Try to call API directly (if possible)
   - **Expected:** 422 error with message "Cart is empty"

2. **Unavailable Item in Cart**
   - Add item to cart
   - Staff marks item as unavailable
   - Try to place order
   - **Expected:** Item is removed from cart before order placement
   - **Expected:** Notification shown to user

3. **Invalid Status Transition**
   - Create order with status "Received"
   - Staff tries to update to "Delivered" (skipping states)
   - **Expected:** 422 error with message about invalid transition
   - **Expected:** Status remains "Received"

## Success Criteria

All test flows should complete successfully with:
- ✅ No crashes or unhandled exceptions
- ✅ All expected behaviors occur as described
- ✅ Real-time updates arrive within specified time limits (2-5 seconds)
- ✅ Session and authentication guards work correctly
- ✅ Error messages are descriptive and user-friendly
- ✅ Data persistence works across app restarts
- ✅ WebSocket connections remain stable

## Notes

- Some tests require multiple devices or browser instances
- WebSocket tests require keeping screens open to observe real-time updates
- Timing tests (2-second, 5-second limits) should be measured with a stopwatch
- Check browser console / app logs for any errors or warnings
- Verify network requests in browser DevTools / Flutter DevTools
