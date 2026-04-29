# Docker Status Diagnostic Script

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Desktop Diagnostic" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Is Docker Desktop installed?
Write-Host "[Check 1/6] Docker Desktop Installation..." -ForegroundColor Yellow
if (Test-Path "C:\Program Files\Docker\Docker\Docker Desktop.exe") {
    Write-Host "✓ Docker Desktop is installed" -ForegroundColor Green
} else {
    Write-Host "✗ Docker Desktop is NOT installed" -ForegroundColor Red
    Write-Host "  Solution: Install Docker Desktop from https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Check 2: Is Docker Desktop running?
Write-Host "[Check 2/6] Docker Desktop Process..." -ForegroundColor Yellow
$dockerProcess = Get-Process "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProcess) {
    Write-Host "✓ Docker Desktop process is running" -ForegroundColor Green
} else {
    Write-Host "✗ Docker Desktop is NOT running" -ForegroundColor Red
    Write-Host "  Solution: Start Docker Desktop from Start Menu" -ForegroundColor Yellow
}
Write-Host ""

# Check 3: Is WSL 2 installed?
Write-Host "[Check 3/6] WSL 2 Status..." -ForegroundColor Yellow
try {
    $wslVersion = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ WSL is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ WSL is NOT installed or not working" -ForegroundColor Red
        Write-Host "  Solution: Run 'wsl --install' as Administrator" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ WSL is NOT installed" -ForegroundColor Red
    Write-Host "  Solution: Run 'wsl --install' as Administrator" -ForegroundColor Yellow
}
Write-Host ""

# Check 4: Can we run docker command?
Write-Host "[Check 4/6] Docker Command..." -ForegroundColor Yellow
try {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $dockerVersion = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker command works: $dockerVersion" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker command failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Docker command not found" -ForegroundColor Red
    Write-Host "  Solution: Restart PowerShell or computer" -ForegroundColor Yellow
}
Write-Host ""

# Check 5: Can we connect to Docker Engine?
Write-Host "[Check 5/6] Docker Engine..." -ForegroundColor Yellow
try {
    $dockerInfo = & "C:\Program Files\Docker\Docker\resources\bin\docker.exe" info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker Engine is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker Engine is NOT running" -ForegroundColor Red
        Write-Host "  Error: $dockerInfo" -ForegroundColor Gray
        Write-Host "  Solution: Restart Docker Desktop or restart computer" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Cannot connect to Docker Engine" -ForegroundColor Red
    Write-Host "  Solution: Restart Docker Desktop or restart computer" -ForegroundColor Yellow
}
Write-Host ""

# Check 6: Windows version
Write-Host "[Check 6/6] Windows Version..." -ForegroundColor Yellow
$osInfo = Get-CimInstance Win32_OperatingSystem
$windowsVersion = $osInfo.Caption
$buildNumber = $osInfo.BuildNumber
Write-Host "  Windows: $windowsVersion" -ForegroundColor Gray
Write-Host "  Build: $buildNumber" -ForegroundColor Gray

if ($buildNumber -ge 19041) {
    Write-Host "✓ Windows version supports Docker Desktop" -ForegroundColor Green
} else {
    Write-Host "✗ Windows version may not support Docker Desktop" -ForegroundColor Red
    Write-Host "  Docker Desktop requires Windows 10 build 19041 or higher" -ForegroundColor Yellow
}
Write-Host ""

# Summary and Recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $dockerProcess) {
    Write-Host "→ Start Docker Desktop from Start Menu" -ForegroundColor Yellow
} elseif ($LASTEXITCODE -ne 0) {
    Write-Host "→ RESTART YOUR COMPUTER (most reliable fix)" -ForegroundColor Yellow
    Write-Host "→ After restart, Docker should work automatically" -ForegroundColor Yellow
} else {
    Write-Host "✓ Docker appears to be working!" -ForegroundColor Green
    Write-Host "→ Try running: .\QUICK_START.ps1" -ForegroundColor Yellow
}

Write-Host ""
