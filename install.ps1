<#
Skybox to ReachPro -- installer

Downloads the latest published build, verifies SHA256, installs to
Documents\Skybox-to-reachpro(API) (no admin), adds shortcuts, and launches.

Safe to re-run to reinstall or force-update (close the app first if running).

PowerShell:
  irm https://raw.githubusercontent.com/Mustafahubs/Skybox-to-reachpro-public/main/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"

function Fail([string]$Context, $ErrorRecord) {
    $detail = $ErrorRecord.Exception.Message
    Write-Host ""
    Write-Host "$Context" -ForegroundColor Red
    Write-Host "  $detail" -ForegroundColor Red
    if ($detail -match "Access is denied") {
        Write-Host ""
        Write-Host "Windows may be blocking writes to Documents (Controlled Folder Access)." -ForegroundColor Yellow
        Write-Host "Allow powershell.exe or turn off CFA in Windows Security, then retry." -ForegroundColor Yellow
    }
    exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = "Mustafahubs/Skybox-to-reachpro-public"
$ExeName = "skybox_to_reachpro.exe"
$InstallDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Skybox-to-reachpro(API)"
$ExePath = Join-Path $InstallDir $ExeName
$Headers = @{ "User-Agent" = "skybox-to-reachpro-installer" }

Write-Host "Checking latest release..." -ForegroundColor Cyan
try {
    $Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $Headers
} catch {
    Fail "Couldn't reach GitHub to check the latest release." $_
}

$ExeAsset = $Release.assets | Where-Object { $_.name -eq $ExeName }
$ChecksumAsset = $Release.assets | Where-Object { $_.name -eq "$ExeName.sha256" }

if (-not $ExeAsset) {
    Write-Host "No '$ExeName' on release $($Release.tag_name)." -ForegroundColor Red
    exit 1
}
if (-not $ChecksumAsset) {
    Write-Host "No checksum file on release $($Release.tag_name) -- refusing unverified install." -ForegroundColor Red
    exit 1
}

Write-Host "Found $($Release.tag_name). Downloading..." -ForegroundColor Cyan
try {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
} catch {
    Fail "Couldn't create install folder '$InstallDir'." $_
}

$TempExe = Join-Path $env:TEMP "$ExeName.download"
$TempChecksum = Join-Path $env:TEMP "$ExeName.sha256.download"
try {
    Invoke-WebRequest -Uri $ExeAsset.browser_download_url -OutFile $TempExe -Headers $Headers
    Invoke-WebRequest -Uri $ChecksumAsset.browser_download_url -OutFile $TempChecksum -Headers $Headers
} catch {
    Fail "Couldn't download release files." $_
}

Write-Host "Verifying checksum..." -ForegroundColor Cyan
$Expected = (Get-Content $TempChecksum -Raw).Trim().Split()[0].ToLower()
$Actual = (Get-FileHash -Path $TempExe -Algorithm SHA256).Hash.ToLower()
Remove-Item $TempChecksum -Force -ErrorAction SilentlyContinue

if ($Actual -ne $Expected) {
    Remove-Item $TempExe -Force -ErrorAction SilentlyContinue
    Write-Host "Checksum mismatch -- aborting install." -ForegroundColor Red
    exit 1
}

if (Test-Path $ExePath) {
    Write-Host "Replacing existing installation." -ForegroundColor Yellow
    try {
        Remove-Item -Path $ExePath -Force -ErrorAction Stop
    } catch {
        Remove-Item $TempExe -Force -ErrorAction SilentlyContinue
        Fail "Couldn't remove '$ExePath' -- close the app if it's running and retry." $_
    }
}

try {
    Move-Item -Path $TempExe -Destination $ExePath -Force
} catch {
    Remove-Item $TempExe -Force -ErrorAction SilentlyContinue
    Fail "Couldn't install to '$ExePath'." $_
}

Write-Host "Installed $($Release.tag_name) to $ExePath" -ForegroundColor Green
Write-Host "Place your .env file in: $InstallDir" -ForegroundColor Cyan

function New-AppShortcut([string]$Path) {
    try {
        $Shell = New-Object -ComObject WScript.Shell
        $Shortcut = $Shell.CreateShortcut($Path)
        $Shortcut.TargetPath = $ExePath
        $Shortcut.WorkingDirectory = $InstallDir
        $Shortcut.IconLocation = $ExePath
        $Shortcut.Save()
        return $true
    } catch {
        Write-Host "Couldn't create shortcut '$Path': $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

$StartMenuPrograms = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
$startMenuOk = New-AppShortcut (Join-Path $StartMenuPrograms "Skybox to ReachPro.lnk")
$desktopOk = New-AppShortcut (Join-Path ([Environment]::GetFolderPath("Desktop")) "Skybox to ReachPro.lnk")
if ($startMenuOk -or $desktopOk) {
    Write-Host "Shortcuts created." -ForegroundColor Green
}

Write-Host "Launching..." -ForegroundColor Cyan
try {
    Start-Process -FilePath $ExePath
} catch {
    Write-Host "Installed; launch manually: $ExePath" -ForegroundColor Yellow
}
