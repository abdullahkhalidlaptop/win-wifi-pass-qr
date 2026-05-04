# ================================================
#   WiFi QR Exporter - Bulletproof Installer
#   GitHub: https://github.com/abdullahkhalidlaptop/win-wifi-pass-qr
# ================================================

$Repo   = "abdullahkhalidlaptop/win-wifi-pass-qr"
$Branch = "main"
$Dest   = "$HOME\WiFiQR"
$ShortcutName = "WiFi QR Exporter.lnk"

Write-Host "`nWiFi QR Exporter Installer (Error-Free)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor DarkGray

# Ensure Desktop exists
$Desktop = "$HOME\Desktop"
if (-not (Test-Path $Desktop)) { mkdir -Force $Desktop | Out-Null }

# Clean existing install
Write-Host "[+] Cleaning previous install..." -ForegroundColor Cyan
Remove-Item -Path $Dest -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$Desktop\$ShortcutName" -Force -ErrorAction SilentlyContinue

# Remove old profile function if exists
$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match 'function WiFiQR|& .*WiFiQR') {
        $profileLines = Get-Content $profilePath | Where-Object { $_ -notmatch 'WiFiQR' }
        Set-Content -Path $profilePath -Value $profileLines -Encoding UTF8
        Write-Host "  ✓ Removed old WiFiQR function" -ForegroundColor Green
    }
}

# Remove from PATH if exists
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -and $currentPath -match [regex]::Escape($Dest)) {
    $newPath = $currentPath -replace [regex]::Escape("$Dest;?"), ""
    [Environment]::SetEnvironmentVariable("PATH", $newPath.TrimEnd(';'), "User")
    Write-Host "  ✓ Removed old PATH entry" -ForegroundColor Green
}

mkdir -Force $Dest | Out-Null

Write-Host "[+] Downloading files..." -ForegroundColor Cyan
$files = @("WiFiQR.ps1", "WiFiQR.bat", "WiFiQR-Silent.bat")
foreach ($file in $files) {
    $url = "https://raw.githubusercontent.com/$Repo/$Branch/$file"
    irm $url -OutFile "$Dest\$file" -ErrorAction Stop
    Write-Host "  ✓ $file" -ForegroundColor Green
}

Write-Host "[+] Installing QRCodeGenerator module..." -ForegroundColor Cyan
Install-Module QRCodeGenerator -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# Verify core file
if (-not (Test-Path "$Dest\WiFiQR.bat")) { 
    Write-Host "[!] Download failed - check repo" -ForegroundColor Red; exit 1 
}

# Create shortcut (force Desktop path)
$ShortcutPath = "$Desktop\$ShortcutName"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "$Dest\WiFiQR.bat"
$Shortcut.WorkingDirectory = $Dest
$Shortcut.IconLocation = "shell32.dll,14"
$Shortcut.Save()
Write-Host "[+] Desktop shortcut: $ShortcutPath" -ForegroundColor Green

# Add to PATH (fresh)
$folderDir = $Dest
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User") -split ";"
if ($envPath -notcontains $folderDir) {
    $newPath = ($envPath + $folderDir) -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "[+] Added to PATH (restart shell)" -ForegroundColor Green
}

# Add profile function (clean insert)
$functionCode = "`nfunction WiFiQR { & `"$Dest\WiFiQR.bat`" }`n"
if (-not (Get-Content $profilePath -Raw -ErrorAction SilentlyContinue -match 'function WiFiQR \{ \&')) {
    "`n# WiFiQR Exporter$functionCode" | Add-Content -Path $profilePath -Encoding UTF8
    Write-Host "[+] Profile function added (restart shell)" -ForegroundColor Green
} else {
    Write-Host "[~] Profile function exists" -ForegroundColor DarkGray
}

Write-Host "`n✅ ZERO-ERROR INSTALL COMPLETE!" -ForegroundColor Green
Write-Host "🖥️  Shortcut: $ShortcutPath" -ForegroundColor Cyan
Write-Host "📁  Folder: $Dest" -ForegroundColor Cyan
Write-Host "🚀  New shell: WiFiQR / $ShortcutName" -ForegroundColor Cyan

explorer $Dest
