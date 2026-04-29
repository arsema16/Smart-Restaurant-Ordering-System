# Check Virtualization Status

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Virtualization Status Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check CPU brand
Write-Host "[1/3] Checking CPU..." -ForegroundColor Yellow
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
Write-Host "  CPU: $($cpu.Name)" -ForegroundColor Gray

if ($cpu.Name -like "*Intel*") {
    Write-Host "  Type: Intel (needs VT-x enabled)" -ForegroundColor Gray
} elseif ($cpu.Name -like "*AMD*") {
    Write-Host "  Type: AMD (needs AMD-V/SVM enabled)" -ForegroundColor Gray
} else {
    Write-Host "  Type: Unknown" -ForegroundColor Gray
}
Write-Host ""

# Check if virtualization is enabled
Write-Host "[2/3] Checking Virtualization Status..." -ForegroundColor Yellow
$computerInfo = Get-ComputerInfo
$virtEnabled = $computerInfo.HyperVRequirementVirtualizationFirmwareEnabled

if ($virtEnabled -eq $true) {
    Write-Host "✓ Virtualization is ENABLED in BIOS" -ForegroundColor Green
    Write-Host "  Docker Desktop should work!" -ForegroundColor Green
} else {
    Write-Host "✗ Virtualization is DISABLED in BIOS" -ForegroundColor Red
    Write-Host "  You need to enable it in BIOS settings" -ForegroundColor Yellow
}
Write-Host ""

# Check Hyper-V status
Write-Host "[3/3] Checking Hyper-V..." -ForegroundColor Yellow
$hyperVPresent = $computerInfo.HyperVisorPresent

if ($hyperVPresent -eq $true) {
    Write-Host "✓ Hyper-V is present" -ForegroundColor Green
} else {
    Write-Host "✗ Hyper-V is not present" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($virtEnabled -eq $true) {
    Write-Host "✓ Your system supports Docker Desktop!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Start Docker Desktop from Start Menu" -ForegroundColor White
    Write-Host "2. Wait for whale icon to become steady" -ForegroundColor White
    Write-Host "3. Run: .\QUICK_START.ps1" -ForegroundColor White
} else {
    Write-Host "✗ Virtualization is disabled" -ForegroundColor Red
    Write-Host ""
    Write-Host "You need to enable virtualization in BIOS:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Restart your computer" -ForegroundColor White
    Write-Host "2. Press BIOS key during boot:" -ForegroundColor White
    Write-Host "   - Dell: F2 or F12" -ForegroundColor Gray
    Write-Host "   - HP: F10 or Esc" -ForegroundColor Gray
    Write-Host "   - Lenovo: F1 or F2" -ForegroundColor Gray
    Write-Host "   - ASUS: F2 or Del" -ForegroundColor Gray
    Write-Host "   - Acer: F2 or Del" -ForegroundColor Gray
    Write-Host "3. Find 'Virtualization Technology' or 'VT-x' or 'AMD-V'" -ForegroundColor White
    Write-Host "4. Change from Disabled to Enabled" -ForegroundColor White
    Write-Host "5. Save and Exit (usually F10)" -ForegroundColor White
    Write-Host ""
    Write-Host "See ENABLE_VIRTUALIZATION.md for detailed instructions" -ForegroundColor Cyan
}

Write-Host ""
