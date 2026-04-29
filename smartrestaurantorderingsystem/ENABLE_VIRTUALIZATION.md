# Enable Virtualization in BIOS

## The Problem
Docker Desktop requires hardware virtualization to be enabled in your computer's BIOS/UEFI settings.

Error: "Virtualization support not detected"

## Solution: Enable Virtualization in BIOS

### Step 1: Check Your CPU Brand
Open PowerShell and run:
```powershell
Get-CimInstance -ClassName Win32_Processor | Select-Object Name
```

This will show if you have:
- **Intel** processor → Look for "Intel VT-x" or "Virtualization Technology"
- **AMD** processor → Look for "AMD-V" or "SVM Mode"

### Step 2: Enter BIOS/UEFI Settings

**Method 1: From Windows (Easiest)**
1. Press **Windows Key + I** to open Settings
2. Go to **Update & Security** → **Recovery**
3. Under "Advanced startup", click **Restart now**
4. After restart, choose: **Troubleshoot** → **Advanced options** → **UEFI Firmware Settings**
5. Click **Restart**

**Method 2: During Boot**
1. Restart your computer
2. Immediately press the BIOS key repeatedly:
   - **Dell**: F2 or F12
   - **HP**: F10 or Esc
   - **Lenovo**: F1 or F2
   - **ASUS**: F2 or Del
   - **Acer**: F2 or Del
   - **MSI**: Del

### Step 3: Enable Virtualization

Once in BIOS/UEFI, look for these settings (location varies by manufacturer):

**Intel Processors:**
- Look for: "Intel Virtualization Technology", "Intel VT-x", "VT-x", or "Virtualization"
- Usually found in: **Advanced** → **CPU Configuration** or **Security**
- Change from **Disabled** to **Enabled**

**AMD Processors:**
- Look for: "AMD-V", "SVM Mode", or "Secure Virtual Machine"
- Usually found in: **Advanced** → **CPU Configuration**
- Change from **Disabled** to **Enabled**

### Step 4: Save and Exit
1. Press **F10** (or look for "Save & Exit" option)
2. Confirm "Yes" to save changes
3. Computer will restart

### Step 5: Verify Virtualization is Enabled

After restart, open PowerShell and run:
```powershell
# Check if virtualization is enabled
Get-ComputerInfo | Select-Object HyperVisorPresent, HyperVRequirementVirtualizationFirmwareEnabled
```

You should see:
- `HyperVRequirementVirtualizationFirmwareEnabled: True`

### Step 6: Start Docker Desktop

1. Open Docker Desktop from Start Menu
2. Wait for the whale icon to become steady
3. Run the backend:
   ```powershell
   cd "C:\Users\dell\Documents\GitHub\Smart-Restaurant-Ordering-System\smartrestaurantorderingsystem\backend"
   .\QUICK_START.ps1
   ```

## Common BIOS Menu Locations by Brand

### Dell
- **Advanced** → **Virtualization Support** → Enable "Intel Virtualization Technology"

### HP
- **System Configuration** → **Virtualization Technology** → Enable

### Lenovo
- **Security** → **Virtualization** → Enable "Intel Virtualization Technology"

### ASUS
- **Advanced** → **CPU Configuration** → Enable "Intel Virtualization Technology"

### Acer
- **Main** → **Intel Virtualization Technology** → Enable

## Important Notes

- **Don't change other BIOS settings** unless you know what they do
- **Write down current settings** before making changes
- If you can't find the virtualization option, it might be:
  - Hidden in a submenu
  - Called something slightly different
  - Already enabled (check with PowerShell command above)
- Some computers have virtualization locked by IT policies (corporate laptops)

## Alternative: Use Docker Without Virtualization (Not Recommended)

If you cannot enable virtualization, you could:
1. Use Docker Toolbox (older, less reliable)
2. Run PostgreSQL and Redis directly on Windows (without Docker)
3. Use a cloud-based development environment

But enabling virtualization is the best solution!

## After Virtualization is Enabled

Your app will be fully functional:
- ✓ Docker Desktop will start successfully
- ✓ PostgreSQL and Redis will run in containers
- ✓ Backend API will start at http://localhost:8000
- ✓ Flutter app will connect to real backend
- ✓ Full ordering system with QR codes, menu, and order tracking will work!
