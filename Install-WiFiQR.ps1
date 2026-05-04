# ================================================
#   WiFi QR Exporter - Bulletproof Installer (FIXED)
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"
$ShortcutName = "WiFi QR Exporter.lnk"

Write-Host "`nWiFi QR Exporter Installer (Fixed)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor DarkGray

# Ensure Desktop exists
$Desktop = [Environment]::GetFolderPath("Desktop")
if (-not (Test-Path $Desktop)) { New-Item -ItemType Directory -Force -Path $Desktop | Out-Null }

# Clean existing install
Write-Host "[+] Cleaning previous install..." -ForegroundColor Cyan
Remove-Item -Path $Dest -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$Desktop\$ShortcutName" -Force -ErrorAction SilentlyContinue

# Ensure folder exists
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# Remove from PATH safely
Write-Host "[+] Fixing PATH..." -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath) {
    $paths = $currentPath -split ";"
    $paths = $paths | Where-Object { $_ -and ($_ -ne $Dest) }
    [Environment]::SetEnvironmentVariable("PATH", ($paths -join ";"), "User")
}

# Clean profile safely (NO regex chaos)
Write-Host "[+] Cleaning PowerShell profile..." -ForegroundColor Cyan
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -ErrorAction SilentlyContinue
    $filtered = $profileContent | Where-Object { $_ -notmatch "WiFiQR" }
    Set-Content -Path $PROFILE -Value $filtered -Encoding UTF8 -ErrorAction SilentlyContinue
}

# Download files
Write-Host "[+] Downloading files..." -ForegroundColor Cyan
$files = @("WiFiQR.ps1", "WiFiQR.bat", "WiFiQR-Silent.bat")

foreach ($file in $files) {
    $url = "https://raw.githubusercontent.com/$Repo/$Branch/$file"
    try {
        Invoke-RestMethod $url -OutFile "$Dest\$file"
        Write-Host "  ✓ $file" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed: $file" -ForegroundColor Red
        exit 1
    }
}

# Install module
Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Verify install
if (-not (Test-Path "$Dest\WiFiQR.bat")) {
    Write-Host "[!] Install failed - missing core files" -ForegroundColor Red
    exit 1
}

# Create shortcut
Write-Host "[+] Creating desktop shortcut..." -ForegroundColor Cyan
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Desktop\$ShortcutName")
$Shortcut.TargetPath = "$Dest\WiFiQR.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()

# Add PATH properly
Write-Host "[+] Adding to PATH..." -ForegroundColor Cyan
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($envPath -notlike "*$Dest*") {
    [Environment]::SetEnvironmentVariable("PATH", "$envPath;$Dest", "User")
}

# Add function to profile safely (NO duplicates)
Write-Host "[+] Setting PowerShell function..." -ForegroundColor Cyan

$functionBlock = @"
# WiFiQR Exporter
function WiFiQR { & "$Dest\WiFiQR.bat" }
"@

if (-not (Test-Path $PROFILE)) {
    New-Item -Type File -Path $PROFILE -Force | Out-Null
}

$profileText = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileText -notmatch "function WiFiQR") {
    Add-Content -Path $PROFILE -Value $functionBlock -Encoding UTF8
}

Write-Host "`n✅ INSTALL COMPLETE!" -ForegroundColor Green
Write-Host "🖥️  Shortcut: $Desktop\$ShortcutName" -ForegroundColor Cyan
Write-Host "📁  Folder: $Dest" -ForegroundColor Cyan
Write-Host "🚀  Run: WiFiQR" -ForegroundColor Cyan

explorer $Dest
