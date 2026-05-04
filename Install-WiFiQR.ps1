# ================================================
# WiFi QR Exporter - Conflict-Free Installer v3
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"

Write-Host "`nWiFi QR Exporter Installer" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor DarkGray

# -----------------------------
# 1. REMOVE ALL OLD CONFLICTS
# -----------------------------
Write-Host "[+] Removing old functions..." -ForegroundColor Cyan
Remove-Item Function:\wifiqr -ErrorAction SilentlyContinue
Remove-Item Function:\WifiQR -ErrorAction SilentlyContinue

# Remove old install locations
Write-Host "[+] Removing old installations..." -ForegroundColor Cyan
Remove-Item "C:\Scripts\WiFiQR" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$HOME\WiFiQR" -Recurse -Force -ErrorAction SilentlyContinue

# -----------------------------
# 2. CLEAN POWERSHELL PROFILE
# -----------------------------
Write-Host "[+] Cleaning PowerShell profile..." -ForegroundColor Cyan

if (Test-Path $PROFILE) {
    $profileClean = Get-Content $PROFILE -ErrorAction SilentlyContinue |
        Where-Object { $_ -notmatch "WiFiQR|wifiqr" }

    Set-Content -Path $PROFILE -Value $profileClean -Encoding UTF8
}

# -----------------------------
# 3. CLEAN PATH
# -----------------------------
Write-Host "[+] Cleaning PATH..." -ForegroundColor Cyan

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath) {
    $cleanPath = ($currentPath -split ";") |
        Where-Object { $_ -and $_ -notmatch "WiFiQR|Scripts\\WiFiQR" }

    [Environment]::SetEnvironmentVariable("PATH", ($cleanPath -join ";"), "User")
}

# -----------------------------
# 4. INSTALL LOCATION
# -----------------------------
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

# -----------------------------
# 5. DOWNLOAD FILES
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
# 6. CREATE SAFE LAUNCHER
# -----------------------------
Write-Host "[+] Creating launcher..." -ForegroundColor Cyan

@"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0WiFiQR.ps1"
"@ | Set-Content "$Dest\wifiqr.bat" -Encoding ASCII

# -----------------------------
# 7. INSTALL QR MODULE
# -----------------------------
Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# -----------------------------
# 8. UPDATE PATH SAFELY
# -----------------------------
Write-Host "[+] Updating PATH..." -ForegroundColor Cyan

$envPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($envPath -notlike "*$Dest*") {
    [Environment]::SetEnvironmentVariable("PATH", "$envPath;$Dest", "User")
}

# -----------------------------
# 9. OPTIONAL POWERSHELL FUNCTION (SAFE)
# -----------------------------
Write-Host "[+] Adding PowerShell function..." -ForegroundColor Cyan

$func = 'function wifiqr { & "$HOME\WiFiQR\WiFiQR.ps1" }'

if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -notmatch "function wifiqr") {
    Add-Content -Path $PROFILE -Value "`n$func`n"
}

# -----------------------------
# 10. DONE
# -----------------------------
Write-Host "`n✅ INSTALL COMPLETE (CLEAN STATE)" -ForegroundColor Green
Write-Host "📁 Path: $Dest" -ForegroundColor Cyan
Write-Host "🚀 Run: wifiqr" -ForegroundColor Cyan

explorer $Dest
