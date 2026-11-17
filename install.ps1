# IPChat Windows PowerShell Installer
# Usage: irm https://raw.githubusercontent.com/Mahamudul-Dev/ipchat/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Repo = "Mahamudul-Dev/ipchat"
$BinaryName = "ipchat.exe"
$ZipName = "ipchat-windows-x64.zip"
$DownloadUrl = "https://github.com/$Repo/releases/latest/download/$ZipName"
$InstallDir = "$env:LOCALAPPDATA\Programs\ipchat"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       IPChat Windows Installer          " -ForegroundColor Cyan
Write-Host "   Secure Zero-Knowledge Terminal Chat   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Create Installation Directory
if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
}

$TempZip = Join-Path $env:TEMP $ZipName

Write-Host "Downloading latest release from $DownloadUrl..." -ForegroundColor Yellow

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip -UseBasicParsing
} catch {
    Write-Host "Failed to download $DownloadUrl" -ForegroundColor Red
    Write-Host "Make sure a release exists on https://github.com/$Repo/releases" -ForegroundColor Red
    exit 1
}

Write-Host "Extracting to $InstallDir..." -ForegroundColor Yellow
Expand-Archive -Path $TempZip -DestinationPath $InstallDir -Force
Remove-Item -Path $TempZip -Force

# 2. Add to User PATH if not already present
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$InstallDir*") {
    Write-Host "Adding $InstallDir to User PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
    $env:Path = "$env:Path;$InstallDir"
}

Write-Host ""
Write-Host "[OK] IPChat installed successfully!" -ForegroundColor Green
Write-Host "Binary Location: $InstallDir\$BinaryName" -ForegroundColor Gray
Write-Host ""
Write-Host "Open a new PowerShell or Command Prompt window and type:" -ForegroundColor Cyan
Write-Host "   ipchat" -ForegroundColor White -NoNewline
Write-Host " to start chatting!" -ForegroundColor Cyan
