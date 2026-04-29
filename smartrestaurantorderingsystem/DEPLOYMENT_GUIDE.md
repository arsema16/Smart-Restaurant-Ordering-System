# Deployment Guide

## Step 1 — Deploy Backend to Railway (Free)

### 1.1 Create Railway account
- Go to https://railway.app
- Sign up with GitHub (recommended)

### 1.2 Install Railway CLI
```bash
npm install -g @railway/cli
```

### 1.3 Login and deploy
```bash
cd backend
railway login
railway init
railway up
```

### 1.4 Get your backend URL
After deployment, Railway gives you a URL like:
`https://smart-restaurant-backend-production.up.railway.app`

Copy this URL — you need it for Step 2.

---

## Step 2 — Update Flutter App with Backend URL

Open `lib/core/constants/api_constants.dart` and set:
```dart
static const String _productionBackendUrl = 'https://YOUR-RAILWAY-URL.up.railway.app';
```

---

## Step 3 — Build Flutter Web App
```bash
flutter build web --release
```

---

## Step 4 — Deploy Frontend to Firebase Hosting (Free)

### 4.1 Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 4.2 Login and deploy
```bash
firebase login
firebase init hosting
# Select "Use an existing project" or create new
# Public directory: build/web
# Single-page app: Yes
# Overwrite index.html: No

firebase deploy --only hosting
```

### 4.3 Get your frontend URL
Firebase gives you a URL like:
`https://smart-restaurant-xxxxx.web.app`

---

## Step 5 — Update QR Code URL

Open `lib/screens/welcome/welcome_screen.dart` and update:
```dart
static const String baseUrl = 'https://smart-restaurant-xxxxx.web.app';
```

Then rebuild and redeploy the frontend:
```bash
flutter build web --release
firebase deploy --only hosting
```

---

## Final Result

- Backend: `https://YOUR-RAILWAY-URL.up.railway.app`
- Frontend: `https://smart-restaurant-xxxxx.web.app`
- QR Code URL: `https://smart-restaurant-xxxxx.web.app/?table=table-1`

Anyone who scans the QR code will see the menu — no local network needed!
