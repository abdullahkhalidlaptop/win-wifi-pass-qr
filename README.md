# WiFi QR Export

A powerful PowerShell tool to **export saved WiFi passwords** as beautiful QR codes on Windows.

Instantly share your WiFi network with guests by letting them scan the QR code!

---

## Features

- Exports **SSID, Password, and Encryption type** (WPA2‑PSK, WPA3, etc.)  
- Generates **high‑quality PNG and SVG QR codes** for each network  
- Creates a clean `Share.html` landing page with **copy‑to‑clipboard buttons**  
- Shows **QR code preview directly in the terminal** for quick verification  
- Supports **bulk export**: scan all saved WiFi networks at once  
- Creates a **desktop shortcut** (`WiFi QR Exporter`) for one‑click access  
- Silent mode via `WiFiQR-Silent.bat` for background / script use  

---

## One-Click Installation

**Run this in PowerShell (as Administrator recommended):**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/abdullahkhalidlaptop/win-wifi-pass-qr/main/Install-WiFiQR.ps1 | iex"
```

This will:
- Download all necessary files  
- Install the required `QRCodeGenerator` module  
- Create a desktop shortcut  
- Open the installation folder automatically  

---

## Manual Usage

1. Open `C:\Users\YourName\WiFiQR`  
2. Double‑click `WiFiQR.bat`  
3. Choose **Single** or **Bulk** mode  

---

## Files Overview

| File                    | Purpose                          |
|-------------------------|----------------------------------|
| `WiFiQR.ps1`            | Main PowerShell script           |
| `WiFiQR.bat`            | Normal launcher                  |
| `WiFiQR-Silent.bat`     | Silent mode (no UI)              |
| `Install-WiFiQR.ps1`    | One‑click installer script       |

---

## Requirements

- Windows 10 / 11  
- Administrator rights (first run only, for elevation)  

---

## Star this repo if you find it useful ⭐

Made with ❤️ for easy WiFi sharing.
