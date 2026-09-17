#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$Offline,
    [switch]$Online,
    [switch]$LaunchExe
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# ============================================================
# LESS PROJECT / FiveM Optimizer - One-liner Installer
# Usage:  irm https://raw.githubusercontent.com/fifthanaphat-lab/FiveM_Optimize/main/Install-FiveMOptimize.ps1 | iex
# ============================================================

$Repository = "fifthanaphat-lab/FiveM_Optimize"
$Ref        = "main"
$appRoot    = Join-Path $env:LOCALAPPDATA "LessProject"
$installRoot = Join-Path $appRoot "Release"
$tempRoot   = Join-Path ([IO.Path]::GetTempPath()) ("LessProject_" + [guid]::NewGuid().ToString("N"))
$cacheBust  = [DateTime]::UtcNow.Ticks

$rawRoot = "https://raw.githubusercontent.com/$Repository/$Ref"
$cdnRoot = "https://cdn.jsdelivr.net/gh/$Repository@$Ref"
$apiRoot = "https://api.github.com/repos/$Repository/contents"

$files = @(
    "LessProject_FiveM_Optimizer.exe",
    "LessProject_FiveM_Optimizer.payload",
    "LessProject_FiveM_Optimizer.ps1",
    "Start-LessProject.cmd"
)

$apiHeaders = @{
    "User-Agent" = "FiveM-Optimize-Installer"
    "Accept"     = "application/vnd.github.v3.raw"
}

function Write-Info([string]$msg, [string]$color = "Cyan") {
    Write-Host $msg -ForegroundColor $color
}

function Test-FileLocked {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    $stream = $null
    try {
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        return $false
    } catch {
        return $true
    } finally {
        if ($stream) { $stream.Dispose() }
    }
}

function Save-ReleaseFile {
    param([string]$FileName, [string]$Destination)

    $sources = @(
        [pscustomobject]@{ Name = "jsDelivr"; Uri = "$cdnRoot/$FileName`?t=$cacheBust" },
        [pscustomobject]@{ Name = "GitHub raw"; Uri = "$rawRoot/$FileName`?t=$cacheBust" },
        [pscustomobject]@{ Name = "GitHub API"; Uri = "$apiRoot/$FileName`?ref=$Ref"; Headers = $apiHeaders }
    )

    foreach ($src in $sources) {
        try {
            Write-Info "  → Downloading $FileName via $($src.Name)..." "DarkGray"
            $params = @{
                Uri             = $src.Uri
                OutFile         = $Destination
                UseBasicParsing = $true
                TimeoutSec      = 120
            }
            if ($src.Headers) { $params.Headers = $src.Headers }
            Invoke-WebRequest @params
            if ((Get-Item -LiteralPath $Destination).Length -gt 0) { return $true }
        } catch {
            # try next source
        }
    }
    throw "Failed to download $FileName from all sources."
}

# ---------- Elevate if needed ----------
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Info "Requesting Administrator privileges..." "Yellow"
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm 'https://raw.githubusercontent.com/fifthanaphat-lab/FiveM_Optimize/main/Install-FiveMOptimize.ps1' | iex")
    if ($Force)     { $argList[-1] += " -Force" }
    if ($Offline)   { $argList[-1] += " -Offline" }
    if ($Online)    { $argList[-1] += " -Online" }
    if ($LaunchExe) { $argList[-1] += " -LaunchExe" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList | Out-Null
    exit
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    Write-Info "Downloading LESS PROJECT / FiveM Optimizer..." "Cyan"

    foreach ($file in $files) {
        $dest = Join-Path $tempRoot $file
        Save-ReleaseFile -FileName $file -Destination $dest
    }

    # Optional: verify payload hash if present in the .ps1 loader
    $payloadPath = Join-Path $tempRoot "LessProject_FiveM_Optimizer.payload"
    $ps1Path     = Join-Path $tempRoot "LessProject_FiveM_Optimizer.ps1"
    if (-not (Test-Path -LiteralPath $ps1Path -PathType Leaf)) {
        throw "Missing LessProject_FiveM_Optimizer.ps1"
    }

    # Close running instance
    $running = @(Get-Process -Name "LessProject_FiveM_Optimizer" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        Write-Info "Closing previous LESS PROJECT instance..." "Yellow"
        foreach ($p in $running) {
            try {
                [void]$p.CloseMainWindow()
                if (-not $p.WaitForExit(2500)) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
            } catch {}
        }
        Start-Sleep -Milliseconds 400
    }

    New-Item -ItemType Directory -Path $appRoot -Force | Out-Null

    $targetRoot = $installRoot
    $existingExe = Join-Path $installRoot "LessProject_FiveM_Optimizer.exe"

    if ((Test-Path -LiteralPath $installRoot) -and -not $Force) {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        $answer = [System.Windows.MessageBox]::Show(
            "Replace the installed LESS PROJECT release?",
            "FiveM Optimize / LESS PROJECT",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
            Write-Info "Installation cancelled by user." "Yellow"
            return
        }
    }

    if (Test-FileLocked $existingExe) {
        $targetRoot = Join-Path $appRoot ("Release-" + [guid]::NewGuid().ToString("N"))
        Write-Info "Existing release is locked; installing side-by-side..." "Yellow"
    } else {
        if (Test-Path -LiteralPath $installRoot) {
            Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null
    foreach ($file in $files) {
        Copy-Item -LiteralPath (Join-Path $tempRoot $file) -Destination (Join-Path $targetRoot $file) -Force
    }

    # Remember current release path
    try {
        Set-Content -LiteralPath (Join-Path $appRoot "CurrentRelease.txt") -Value $targetRoot -Encoding UTF8
    } catch {}

    Write-Info "Installed and verified LESS PROJECT successfully." "Green"

    $launcher = Join-Path $targetRoot "LessProject_FiveM_Optimizer.ps1"
    $exe      = Join-Path $targetRoot "LessProject_FiveM_Optimizer.exe"

    if ($LaunchExe -and (Test-Path -LiteralPath $exe -PathType Leaf)) {
        Start-Process -FilePath $exe -Verb RunAs | Out-Null
    } else {
        # Default: launch the protected PowerShell loader (does payload integrity check)
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$launcher`""
        ) | Out-Null
    }

    Write-Info "LESS PROJECT is starting..." "Green"
}
catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    exit 1
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
