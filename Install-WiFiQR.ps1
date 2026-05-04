# ================================================
#   WiFi QR Exporter - One-Click Installer
#   GitHub: https://github.com/abdullahkhalidlaptop/win-wifi-pass-qr
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"

Write-Host "`nWiFi QR Exporter Installer" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor DarkGray

# Create folder
mkdir -Force $Dest | Out-Null

Write-Host "[+] Downloading files..." -ForegroundColor Cyan

irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.ps1"       -OutFile "$Dest\WiFiQR.ps1"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.bat"      -OutFile "$Dest\WiFiQR.bat"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR-Silent.bat" -OutFile "$Dest\WiFiQR-Silent.bat"

Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Create Desktop Shortcut
$ShortcutPath = "$HOME\Desktop\WiFi QR Exporter.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "$Dest\WiFiQR.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()

# ╔════════════════════════════════════════════════════════╗
# ║  MAKE 'WiFiQR' WORK FROM ANY TERMINAL (Wi‑Fi passed)  ║
# ╚════════════════════════════════════════════════════════╝

$batPath = "$Dest\WiFiQR.bat"

# 1. Add destination folder to User PATH (for CMD / PowerShell / Terminal)
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User") -split ";"
$folderDir = (Split-Path $Dest -Resolve)

if ($envPath -notcontains $folderDir) {
    $newPath = $envPath + $folderDir | Where-Object { $_ } | Join-String -Separator ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[+] Added folder to User PATH:" -ForegroundColor Green
    Write-Host "    $folderDir" -ForegroundColor White
} else {
    Write-Host "[~] Folder already in PATH." -ForegroundColor DarkGray
}

# 2. (Optional) Add PowerShell alias WiFiQR in user profile
$profilePath = $PROFILE
$aliasLine = "function WiFiQR { & '$batPath' }"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw

if ($profileContent -notmatch [regex]::Escape("function WiFiQR")) {
    Add-Content -Path $profilePath -Value "`n$aliasLine"
    Write-Host "[+] Added PowerShell alias: `WiFiQR`" -ForegroundColor Green
} else {
    Write-Host "[~] PowerShell alias already exists." -ForegroundColor DarkGray
}

# ╔════════════════════════════════════════════════════════╗
# ║                    END GLOBAL SETUP                    ║
# ╚════════════════════════════════════════════════════════╝

Write-Host "`n✅ Installation Completed Successfully!" -ForegroundColor Green
Write-Host "📁 Installed in: $Dest" -ForegroundColor White
Write-Host "🖥️  Desktop Shortcut Created!" -ForegroundColor Green
Write-Host "⌨️  Type 'WiFiQR.bat' anywhere in terminal, or use 'WiFiQR' in PowerShell." -ForegroundColor Cyan

explorer $Dest
