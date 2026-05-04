# ================================================
#   WiFi QR Exporter - One-Click Installer
#   GitHub: https://github.com/abdullahkhalidlaptop/win-wifi-pass-qr
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"  # Fixed double \\

Write-Host "`nWiFi QR Exporter Installer" -ForegroundColor Cyan
Write-Host "=====================================`n" -ForegroundColor DarkGray

# Admin check (optional, for module install)
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[!] Run as admin for module install (or skip if already installed)" -ForegroundColor Yellow
}

mkdir -Force $Dest | Out-Null

Write-Host "[+] Downloading files..." -ForegroundColor Cyan

$files = @(
    "WiFiQR.ps1",
    "WiFiQR.bat",
    "WiFiQR-Silent.bat"
)

foreach ($file in $files) {
    $url = "https://raw.githubusercontent.com/$Repo/$Branch/$file"
    try {
        irm $url -OutFile "$Dest\$file" -ErrorAction Stop
        Write-Host "  ✓ $file" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ $file failed - check repo visibility/network" -ForegroundColor Red
        exit 1
    }
}

Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Verify files
if (-not (Test-Path "$Dest\WiFiQR.bat")) {
    Write-Host "[!] WiFiQR.bat missing - installer failed" -ForegroundColor Red
    exit 1
}

# Desktop Shortcut
$ShortcutPath = "$HOME\Desktop\WiFi QR Exporter.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "$Dest\WiFiQR.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()
Write-Host "[+] Desktop shortcut created" -ForegroundColor Green

# Add to PATH
$folderDir = $Dest
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User") -split ";"
if ($envPath -notcontains $folderDir) {
    $newPath = ($envPath + $folderDir) -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[+] Added to User PATH (restart shell for effect)" -ForegroundColor Green
}

# PowerShell function
$profilePath = $PROFILE
$functionCode = "function WiFiQR { & '$Dest\WiFiQR.bat' }`n"

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch 'function WiFiQR') {
    Add-Content -Path $profilePath -Value $functionCode -Encoding UTF8
    Write-Host "[+] PowerShell function 'WiFiQR' created (restart shell)" -ForegroundColor Green
} else {
    Write-Host "[~] PowerShell function already exists" -ForegroundColor DarkGray
}

Write-Host "`n✅ Installation Completed Successfully!" -ForegroundColor Green
Write-Host "🖥️  Desktop Shortcut: $ShortcutPath" -ForegroundColor Cyan
Write-Host "📁  Folder: $Dest" -ForegroundColor Cyan
Write-Host "⌨️  Type 'WiFiQR' in new PowerShell/CMD" -ForegroundColor Cyan

explorer $Dest
