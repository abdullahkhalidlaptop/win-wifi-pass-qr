# WiFi QR Exporter - One-Click Installer
# Repo: https://github.com/abdullahkhalidlaptop/win-wifi-pass-qr

$Repo = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest = "$HOME\WiFiQR"

Write-Host "Downloading WiFi QR Exporter..." -ForegroundColor Cyan

mkdir -Force $Dest | Out-Null

irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.ps1" -OutFile "$Dest\WiFiQR.ps1"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR.bat" -OutFile "$Dest\WiFiQR.bat"
irm "https://raw.githubusercontent.com/$Repo/$Branch/WiFiQR-Silent.bat" -OutFile "$Dest\WiFiQR-Silent.bat"

Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

Write-Host "`n✅ Installation Completed Successfully!" -ForegroundColor Green
Write-Host "📁 Folder: $Dest" -ForegroundColor White
Write-Host "`nDouble-click WiFiQR.bat to run" -ForegroundColor Cyan

explorer $Dest
