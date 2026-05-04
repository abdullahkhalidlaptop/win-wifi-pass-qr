# ================================================
#   WiFi QR Exporter - One-Click Installer
#   GitHub: https://github.com/abdullahkhalidlaptop/win-wifi-pass-qr
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"

Write-Host "`nWiFi QR Exporter Installer" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor DarkGray

mkdir -Force $Dest | Out-Null

Write-Host "[+] Downloading files..." -ForegroundColor Cyan

irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.ps1"       -OutFile "$Dest\WiFiQR.ps1"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.bat"      -OutFile "$Dest\WiFiQR.bat"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR-Silent.bat" -OutFile "$Dest\WiFiQR-Silent.bat"

Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Desktop Shortcut
$ShortcutPath = "$HOME\Desktop\WiFi QR Exporter.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "$Dest\WiFiQR.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()

# Add to PATH (so WiFiQR.bat works from anywhere)
$folderDir = $Dest
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User") -split ";"
if ($envPath -notcontains $folderDir) {
    $newPath = ($envPath + $folderDir) -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[+] Added to User PATH" -ForegroundColor Green
}

# Create PowerShell function WiFiQR (so you can just type "WiFiQR")
$profilePath = $PROFILE
$functionCode = "function WiFiQR { & '$Dest\WiFiQR.bat' }"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue

if ($profileContent -notmatch 'function WiFiQR') {
    Add-Content -Path $profilePath -Value "`n$functionCode" -Encoding UTF8
    Write-Host "[+] PowerShell function 'WiFiQR' created" -ForegroundColor Green
} else {
    Write-Host "[~] PowerShell function already exists" -ForegroundColor DarkGray
}

Write-Host "`n✅ Installation Completed Successfully!" -ForegroundColor Green
Write-Host "🖥️  Desktop Shortcut Created" -ForegroundColor Green
Write-Host "⌨️  You can now type 'WiFiQR' in any new PowerShell window" -ForegroundColor Cyan

explorer $Dest
