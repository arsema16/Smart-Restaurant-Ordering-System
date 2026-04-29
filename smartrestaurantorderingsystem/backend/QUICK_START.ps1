# Quick Start Script for Smart Restaurant Ordering System Backend
# This script handles Docker Desktop startup delays

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Restaurant Backend - Quick Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if Docker Desktop is running
Write-Host "[Step 1/6] Checking Docker Desktop status..." -ForegroundColor Yellow

$maxAttempts = 30
$attempt = 0
$dockerReady = $false

while ($attempt -lt $maxAttempts -and -not $dockerReady) {
    try {
        $null = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $dockerReady = $true
            Write-Host "✓ Docker is ready!" -ForegroundColor Green
        }
    } catch {
        $attempt++
        if ($attempt -eq 1) {
            Write-Host "  Docker Desktop is starting... (this may take 2-3 minutes)" -ForegroundColor Gray
        }
        Write-Host "  Waiting... ($attempt/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

if (-not $dockerReady) {
    Write-Host "✗ Docker Desktop is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Start Docker Desktop from Start Menu" -ForegroundColor White
    Write-Host "2. Wait for the whale icon to be steady in system tray" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Step 2: Start PostgreSQL and Redis
Write-Host "[Step 2/6] Starting PostgreSQL and Redis..." -ForegroundColor Yellow
docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start services" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Services started" -ForegroundColor Green
Write-Host ""

# Step 3: Wait for PostgreSQL to be ready
Write-Host "[Step 3/6] Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$pgReady = $false
$attempt = 0
while ($attempt -lt 30 -and -not $pgReady) {
    try {
        docker-compose exec -T postgres pg_isready -U postgres 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $pgReady = $true
        }
    } catch {
        $attempt++
        Start-Sleep -Seconds 1
    }
}

if ($pgReady) {
    Write-Host "✓ PostgreSQL is ready" -ForegroundColor Green
} else {
    Write-Host "⚠ PostgreSQL may not be fully ready, but continuing..." -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Create database if it doesn't exist
Write-Host "[Step 4/6] Creating database..." -ForegroundColor Yellow
docker-compose exec -T postgres psql -U postgres -c "CREATE DATABASE restaurant_db;" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database created" -ForegroundColor Green
} else {
    Write-Host "✓ Database already exists" -ForegroundColor Green
}

Write-Host ""

# Step 5: Run database migrations
Write-Host "[Step 5/6] Running database migrations..." -ForegroundColor Yellow
py -m alembic upgrade head

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Migrations completed" -ForegroundColor Green
} else {
    Write-Host "✗ Migration failed" -ForegroundColor Red
    Write-Host "Check the error above for details" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Step 6: Start backend server
Write-Host "[Step 6/6] Starting backend server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Backend server starting..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API will be available at: http://localhost:8000" -ForegroundColor Green
Write-Host "API docs at: http://localhost:8000/docs" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
