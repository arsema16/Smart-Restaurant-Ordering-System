# Smart Restaurant Ordering System - Complete Test Suite Runner
# This script runs all backend tests after Docker services are ready

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Restaurant Ordering System" -ForegroundColor Cyan
Write-Host "Complete Test Suite Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check Docker is running
Write-Host "[1/7] Checking Docker status..." -ForegroundColor Yellow
try {
    docker --version | Out-Null
    Write-Host "✓ Docker is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop and try again" -ForegroundColor Red
    exit 1
}

# Step 2: Start Docker services
Write-Host ""
Write-Host "[2/7] Starting PostgreSQL and Redis..." -ForegroundColor Yellow
docker-compose up -d postgres redis
Start-Sleep -Seconds 5

# Check if services are running
$postgresRunning = docker-compose ps | Select-String "postgres.*Up"
$redisRunning = docker-compose ps | Select-String "redis.*Up"

if ($postgresRunning -and $redisRunning) {
    Write-Host "✓ PostgreSQL and Redis are running" -ForegroundColor Green
} else {
    Write-Host "✗ Services failed to start" -ForegroundColor Red
    Write-Host "Run 'docker-compose logs' to see errors" -ForegroundColor Red
    exit 1
}

# Step 3: Wait for PostgreSQL to be ready
Write-Host ""
Write-Host "[3/7] Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts -and -not $ready) {
    try {
        docker-compose exec -T postgres pg_isready -U postgres | Out-Null
        $ready = $true
        Write-Host "✓ PostgreSQL is ready" -ForegroundColor Green
    } catch {
        $attempt++
        Write-Host "  Waiting... ($attempt/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    Write-Host "✗ PostgreSQL failed to become ready" -ForegroundColor Red
    exit 1
}

# Step 4: Run database migrations
Write-Host ""
Write-Host "[4/7] Running database migrations..." -ForegroundColor Yellow
try {
    py -m alembic upgrade head
    Write-Host "✓ Migrations completed" -ForegroundColor Green
} catch {
    Write-Host "✗ Migration failed" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 5: Run property-based tests
Write-Host ""
Write-Host "[5/7] Running property-based tests (21 properties)..." -ForegroundColor Yellow
Write-Host "This may take a few minutes (200 examples per property)..." -ForegroundColor Gray
py -m pytest -m property -v --tb=short

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ All property tests passed" -ForegroundColor Green
} else {
    Write-Host "✗ Some property tests failed" -ForegroundColor Red
}

# Step 6: Run unit tests
Write-Host ""
Write-Host "[6/7] Running unit tests..." -ForegroundColor Yellow
py -m pytest -m unit -v --tb=short

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ All unit tests passed" -ForegroundColor Green
} else {
    Write-Host "✗ Some unit tests failed" -ForegroundColor Red
}

# Step 7: Run integration tests
Write-Host ""
Write-Host "[7/7] Running integration tests..." -ForegroundColor Yellow
py -m pytest -m integration -v --tb=short

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ All integration tests passed" -ForegroundColor Green
} else {
    Write-Host "✗ Some integration tests failed" -ForegroundColor Red
}

# Generate coverage report
Write-Host ""
Write-Host "Generating coverage report..." -ForegroundColor Yellow
py -m pytest --cov=app --cov-report=html --cov-report=term-missing

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Suite Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Coverage report: backend/htmlcov/index.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review test results above" -ForegroundColor White
Write-Host "2. Open coverage report in browser" -ForegroundColor White
Write-Host "3. Start backend server: py -m uvicorn app.main:app --reload" -ForegroundColor White
Write-Host "4. Run Flutter app: flutter run" -ForegroundColor White
Write-Host "5. Execute manual tests from MANUAL_TESTING_GUIDE.md" -ForegroundColor White
Write-Host ""
