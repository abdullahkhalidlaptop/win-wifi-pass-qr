# ================================================
#   WiFi QR Exporter - Production Installer (FIXED)
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Choose install location properly
if ($IsAdmin) {
    $Dest = "C:\Scripts\WiFiQR"
} else {
    $Dest = "$HOME\WiFiQR"
}

$ShortcutName = "WiFi QR Exporter.lnk"

Write-Host "`nWiFi QR Exporter Installer" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor DarkGray

# Desktop path (safe)
$Desktop = [Environment]::GetFolderPath("Desktop")

# Cleanup old install
Write-Host "[+] Cleaning previous install..." -ForegroundColor Cyan
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $Dest
Remove-Item -Force -ErrorAction SilentlyContinue "$Desktop\$ShortcutName"

New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# -----------------------------
# Download files
# -----------------------------
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

# -----------------------------
# Install QR module
# -----------------------------
Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# -----------------------------
# Create dynamic launcher (FIX)
# -----------------------------
Write-Host "[+] Creating wifiqr launcher..." -ForegroundColor Cyan

$batPath = "$Dest\wifiqr.bat"

@"
@echo off
set SCRIPT_DIR=$Dest
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\WiFiQR.ps1"
"@ | Set-Content -Path $batPath -Encoding ASCII

# -----------------------------
# PATH setup (safe)
# -----------------------------
Write-Host "[+] Updating PATH..." -ForegroundColor Cyan

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$Dest*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$Dest", "User")
}

# -----------------------------
# Shortcut
# -----------------------------
Write-Host "[+] Creating desktop shortcut..." -ForegroundColor Cyan

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Desktop\$ShortcutName")
$Shortcut.TargetPath = "$Dest\wifiqr.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()

# -----------------------------
# Optional PowerShell function
# -----------------------------
Write-Host "[+] Adding PowerShell function..." -ForegroundColor Cyan

$profileLine = @"
function wifiqr { & "$Dest\WiFiQR.ps1" }
"@

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -notmatch "function wifiqr") {
    Add-Content -Path $PROFILE -Value "`n$profileLine`n"
}

# -----------------------------
# Finish
# -----------------------------
Write-Host "`n✅ INSTALL COMPLETE" -ForegroundColor Green
Write-Host "📁 Path: $Dest" -ForegroundColor Cyan
Write-Host "🖥️ Shortcut: $Desktop\$ShortcutName" -ForegroundColor Cyan
Write-Host "🚀 Run: wifiqr" -ForegroundColor Cyan

explorer $Dest
