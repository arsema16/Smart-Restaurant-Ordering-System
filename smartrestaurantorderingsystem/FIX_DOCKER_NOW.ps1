# Docker Installation Fix Script
# Run this in PowerShell AS ADMINISTRATOR

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Installation Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Remove problematic directory
Write-Host "[Step 1/3] Removing problematic Docker directory..." -ForegroundColor Yellow
try {
    if (Test-Path "C:\ProgramData\DockerDesktop") {
        Remove-Item -Path "C:\ProgramData\DockerDesktop" -Recurse -Force -ErrorAction Stop
        Write-Host "✓ Directory removed successfully" -ForegroundColor Green
    } else {
        Write-Host "✓ Directory doesn't exist (good)" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Failed to remove directory" -ForegroundColor Red
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    
    # Try taking ownership first
    takeown /F "C:\ProgramData\DockerDesktop" /R /D Y 2>$null
    icacls "C:\ProgramData\DockerDesktop" /grant Administrators:F /T 2>$null
    Remove-Item -Path "C:\ProgramData\DockerDesktop" -Recurse -Force -ErrorAction SilentlyContinue
    
    if (-not (Test-Path "C:\ProgramData\DockerDesktop")) {
        Write-Host "✓ Directory removed with alternative method" -ForegroundColor Green
    }
}

Write-Host ""

# Step 2: Clean up any leftover Docker data
Write-Host "[Step 2/3] Cleaning up Docker data..." -ForegroundColor Yellow
$dockerDirs = @(
    "$env:LOCALAPPDATA\Docker",
    "$env:APPDATA\Docker"
)

foreach ($dir in $dockerDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "✓ Cleaned: $dir" -ForegroundColor Green
    }
}

Write-Host ""

# Step 3: Install Docker Desktop
Write-Host "[Step 3/3] Installing Docker Desktop..." -ForegroundColor Yellow
Write-Host "This will take 10-15 minutes..." -ForegroundColor Gray
Write-Host ""

winget install Docker.DockerDesktop

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Start Docker Desktop from Start Menu" -ForegroundColor White
Write-Host "2. Wait for Docker Engine to start (whale icon steady)" -ForegroundColor White
Write-Host "3. Run: docker --version" -ForegroundColor White
Write-Host "4. Then start the backend with the commands in NEXT_STEPS_AFTER_DOCKER.md" -ForegroundColor White
Write-Host ""
