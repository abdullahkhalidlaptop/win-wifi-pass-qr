#Requires -Version 5.1
param([switch]$Silent)

# --- UAC Self-Elevation ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argString = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"$(if($Silent){' -Silent'})"
    Start-Process powershell -Verb RunAs -ArgumentList $argString
    exit
}

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web

# --- Config & Paths ---
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$ConfigDir   = Join-Path $env:APPDATA "WiFiQRExporter"
$ConfigFile  = Join-Path $ConfigDir "last.txt"
if (-not (Test-Path $ConfigDir)) { New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null }

# --- UI Helpers ---
function Write-Success($m) { Write-Host "  [+] $m" -ForegroundColor Green  }
function Write-Warn($m)    { Write-Host "  [!] $m" -ForegroundColor Yellow }
function Write-Err($m)     { Write-Host "  [x] $m" -ForegroundColor Red    }
function Write-Info($m)    { Write-Host "  [>] $m" -ForegroundColor Cyan   }
function Write-Sep         { Write-Host ("  " + ("-" * 54)) -ForegroundColor DarkGray }

# --- WiFi Functions ---
function Get-EncryptionType($ssid) {
    $lines = netsh wlan show profile name="`"$ssid`"" key=clear 2>$null
    $match = $lines | Select-String "Authentication" | Select-Object -First 1
    if (-not $match) { return "WPA2" }
    $a = ($match.ToString() -replace '.*:\s*', '').Trim()
    if     ($a -like "*WPA3*")  { return "WPA3"   }
    elseif ($a -like "*WPA2*")  { return "WPA2"   }
    elseif ($a -like "*WPA*")   { return "WPA"    }
    elseif ($a -like "*WEP*")   { return "WEP"    }
    elseif ($a -like "*Open*")  { return "nopass" }
    else                        { return "WPA2"   }
}

function Get-WiFiPassword($ssid) {
    $lines = netsh wlan show profile name="`"$ssid`"" key=clear 2>$null
    $line  = $lines | Select-String "Key Content" | Select-Object -First 1
    if ($line -match ':\s+(.*)') { return $Matches[1].Trim() }
    return ""
}

function Get-AllProfiles {
    $raw = netsh wlan show profiles 2>$null
    $profiles = @()
    foreach ($line in $raw) {
        if ($line -match 'All User Profile\s*:\s*(.+)') {
            $ssid = $Matches[1].Trim()
            $enc  = Get-EncryptionType $ssid
            $profiles += [PSCustomObject]@{ SSID = $ssid; Auth = $enc }
        }
    }
    return $profiles
}

# --- Export Function ---
function Export-WiFiNetwork($ssid) {
    $password = Get-WiFiPassword $ssid
    $encType  = Get-EncryptionType $ssid

    $folder = Join-Path $DesktopPath ($ssid + " WiFi")
    if (-not (Test-Path $folder)) { New-Item -Path $folder -ItemType Directory -Force | Out-Null }

    "SSID:        $ssid`r`nPassword:    $password`r`nEncryption:  $encType`r`nGenerated:   $(Get-Date)" | 
        Out-File -FilePath (Join-Path $folder "Password.txt") -Encoding UTF8 -Force

    $pngPath  = Join-Path $folder "QRCode.png"
    $svgPath  = Join-Path $folder "QRCode.svg"
    $htmlPath = Join-Path $folder "Share.html"

    # Generate QR
    New-QRCodeWifiAccess -SSID $ssid -Password $password -OutPath $pngPath -ErrorAction SilentlyContinue

    # Higher quality PNG for better Share.html
    if (Test-Path $pngPath) {
        $img = [System.Drawing.Bitmap]::FromFile($pngPath)
        $target = 480   # Increased for better quality
        $resized = New-Object System.Drawing.Bitmap($target, $target)
        $g = [System.Drawing.Graphics]::FromImage($resized)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, $target, $target)
        $g.Dispose()
        $img.Dispose()
        $resized.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $resized.Dispose()
    }

    # Optimized SVG (Good size + quality)
    $bmp = [System.Drawing.Bitmap]::FromFile($pngPath)
    $w = $bmp.Width
    $h = $bmp.Height
    $cell = 5
    $totalSize = $w * $cell

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine("<svg xmlns='http://www.w3.org/2000/svg' width='$totalSize' height='$totalSize' viewBox='0 0 $totalSize $totalSize'>")
    [void]$sb.AppendLine('<rect width="100%" height="100%" fill="white"/>')

    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            if ($bmp.GetPixel($x, $y).GetBrightness() -lt 0.5) {
                $px = $x * $cell
                $py = $y * $cell
                [void]$sb.Append("<rect x='$px' y='$py' width='$cell' height='$cell' fill='black'/>")
            }
        }
    }
    [void]$sb.AppendLine('</svg>')
    $bmp.Dispose()
    $sb.ToString() | Out-File -FilePath $svgPath -Encoding UTF8 -Force

    # High Quality Share.html
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($pngPath))
    $safeSSID = [System.Web.HttpUtility]::HtmlEncode($ssid)
    $safePass = [System.Web.HttpUtility]::HtmlEncode($password)

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WiFi: $safeSSID</title>
<style>
    body{font-family:system-ui,sans-serif;background:#f0f4f8;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
    .card{background:#fff;border-radius:20px;padding:30px;text-align:center;max-width:500px;width:100%;box-shadow:0 10px 40px rgba(0,0,0,.1)}
    h1{font-size:27px;margin:10px 0}
    .sub{color:#64748b;margin-bottom:25px}
    img{width:300px;height:300px;border:2px solid #e2e8f0;border-radius:16px;padding:12px;background:white}
    .field{background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:16px;margin:12px 0;position:relative}
    .label{font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:0.5px}
    .value{font-weight:600;font-size:17.5px;word-break:break-all}
    button{position:absolute;right:14px;top:50%;transform:translateY(-50%);color:#2563eb;background:none;border:none;font-weight:700;cursor:pointer}
</style>
</head>
<body>
<div class="card">
    <h1>$safeSSID</h1>
    <p class="sub">Scan QR to connect instantly</p>
    <img src="data:image/png;base64,$b64" alt="WiFi QR Code">
    
    <div class="field"><div class="label">Network Name</div><div class="value">$safeSSID</div><button onclick="navigator.clipboard.writeText('$safeSSID');this.innerText='✓'">Copy</button></div>
    <div class="field"><div class="label">Password</div><div class="value">$safePass</div><button onclick="navigator.clipboard.writeText('$safePass');this.innerText='✓'">Copy</button></div>
    
    <small style="color:#94a3b8;margin-top:20px;display:block">WiFi QR Exporter</small>
</div>
</body>
</html>
"@
    $html | Out-File -FilePath $htmlPath -Encoding UTF8 -Force

    Set-Clipboard $password
    return [PSCustomObject]@{ Password = $password; EncType = $encType; PNGPath = $pngPath; Folder = $folder }
}

# ======================================================
#                     MAIN
# ======================================================
Clear-Host
Write-Host "`n  WiFi QR Exporter" -ForegroundColor Cyan
Write-Sep

if (-not (Get-Module -ListAvailable -Name QRCodeGenerator)) {
    Write-Warn "Installing QRCodeGenerator module..."
    Install-Module -Name QRCodeGenerator -Scope CurrentUser -Force -ErrorAction Stop
    Write-Success "Module installed!"
}
Import-Module QRCodeGenerator -ErrorAction Stop

Write-Info "Loading saved WiFi networks..."
$allProfiles = Get-AllProfiles

if ($allProfiles.Count -eq 0) {
    Write-Err "No saved WiFi profiles found."
    pause; exit
}

Write-Success "Found $($allProfiles.Count) network(s)"
Write-Sep

Write-Host ("  {0,-4} {1,-36} {2}" -f " # ", "Network Name", "Security") -ForegroundColor DarkGray
Write-Sep
for ($i = 0; $i -lt $allProfiles.Count; $i++) {
    Write-Host ("  [{0,-2}] {1,-36} {2}" -f $i, $allProfiles[$i].SSID, $allProfiles[$i].Auth) -ForegroundColor White
}
Write-Sep

$mode = Read-Host "  Select mode [1] Single   [2] Bulk"

if ($mode -eq "2") {
    Write-Warn "`nThis will export ALL networks."
    if ((Read-Host "  Confirm? (y/n)") -ne 'y') { exit }
    foreach ($p in $allProfiles) {
        try { Export-WiFiNetwork $p.SSID | Out-Null; Write-Success $p.SSID } 
        catch { Write-Err $p.SSID }
    }
    Write-Success "Bulk export completed!"
    pause; exit
}

# Single Mode
$sel = Read-Host "`n  Enter index number"
if ($sel -notmatch '^\d+$' -or [int]$sel -ge $allProfiles.Count) {
    Write-Err "Invalid selection."; pause; exit
}

$selected = $allProfiles[[int]$sel]
$showPass = (Read-Host "`n  Show password on screen? (y/n)") -eq 'y'

$result = Export-WiFiNetwork $selected.SSID

if (-not $Silent) {
    Clear-Host
    Write-Host "`n  Scan to Connect → $($selected.SSID)" -ForegroundColor Cyan
    
    # Terminal QR Display
    $src = [System.Drawing.Bitmap]::FromFile($result.PNGPath)
    $size = 42
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = "NearestNeighbor"
    $g.DrawImage($src, 0, 0, $size, $size)
    $g.Dispose(); $src.Dispose()

    $e = [char]27
    $BLACK = "${e}[40m  ${e}[0m"
    $WHITE = "${e}[107m  ${e}[0m"
    for ($y=0; $y -lt $size; $y++) {
        $line = "  "
        for ($x=0; $x -lt $size; $x++) {
            $line += if ($bmp.GetPixel($x,$y).GetBrightness() -lt 0.5) { $BLACK } else { $WHITE }
        }
        Write-Host $line
    }
    $bmp.Dispose()

    Write-Sep
    Write-Host "  Name : $($selected.SSID)" -ForegroundColor Cyan
    if ($showPass) {
        Write-Host "  Pass : $($result.Password)" -ForegroundColor White
    }
    Write-Sep
    Write-Success "Files saved → Desktop\$($selected.SSID) WiFi"
    Write-Success "Password copied to clipboard!"
}

Start-Process explorer.exe $result.Folder
Write-Host "`n  Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")