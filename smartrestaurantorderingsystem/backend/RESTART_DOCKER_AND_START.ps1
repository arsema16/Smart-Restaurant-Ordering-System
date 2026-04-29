# Restart Docker Desktop and Start Backend
# This fixes the "500 Internal Server Error" issue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Desktop Restart & Backend Start" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "The error you saw means Docker Desktop's engine needs to be restarted." -ForegroundColor Yellow
Write-Host ""

# Step 1: Stop Docker Desktop
Write-Host "[Step 1/4] Stopping Docker Desktop..." -ForegroundColor Yellow
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Write-Host "✓ Docker Desktop stopped" -ForegroundColor Green
Write-Host ""

# Step 2: Start Docker Desktop
Write-Host "[Step 2/4] Starting Docker Desktop..." -ForegroundColor Yellow
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Write-Host "✓ Docker Desktop starting..." -ForegroundColor Green
Write-Host ""

# Step 3: Wait for Docker to be ready
Write-Host "[Step 3/4] Waiting for Docker Engine to be ready..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Gray
Write-Host ""

$maxAttempts = 60
$attempt = 0
$dockerReady = $false

while ($attempt -lt $maxAttempts -and -not $dockerReady) {
    try {
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        $result = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info 2>&1
        if ($LASTEXITCODE -eq 0) {
            $dockerReady = $true
            Write-Host "✓ Docker Engine is ready!" -ForegroundColor Green
        }
    } catch {
        # Ignore errors
    }
    
    if (-not $dockerReady) {
        $attempt++
        Write-Host "  Waiting... ($attempt/$maxAttempts)" -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
}

if (-not $dockerReady) {
    Write-Host "✗ Docker Engine did not start in time" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Check Docker Desktop window - it should say 'Docker Desktop is running'" -ForegroundColor White
    Write-Host "2. Wait a bit longer and try running QUICK_START.ps1 again" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""

# Step 4: Run the quick start script
Write-Host "[Step 4/4] Running backend startup..." -ForegroundColor Yellow
Write-Host ""

& ".\QUICK_START.ps1"
