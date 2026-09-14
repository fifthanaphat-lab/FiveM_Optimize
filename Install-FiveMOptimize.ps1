#Requires -Version 5.1
<#
  FiveM Optimize - installer (Less Project style, always latest from main)

  One-liner:
    irm "https://raw.githubusercontent.com/fifthanaphat-lab/FiveM_Optimize/main/Install-FiveMOptimize.ps1" | iex
#>
[CmdletBinding()]
param(
    [ValidatePattern('^[^/\\ ]+/[^/\\ ]+$')]
    [string]$Repository = "fifthanaphat-lab/FiveM_Optimize",
    # main = always latest (realtime). Pin a commit SHA only if you need a frozen build.
    [string]$Ref = "main",
    [string]$ProjectPath = "",
    [string]$ScriptName = "FiveM_Optimize.ps1",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

function Write-Step([string]$Message, [string]$Color = "Cyan") {
    Write-Host $Message -ForegroundColor $Color
}

# Cache-bust so GitHub/jsDelivr raw does not serve a stale copy after you push.
$cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

$appRoot = Join-Path $env:LOCALAPPDATA "FiveMOptimize"
$installRoot = Join-Path $appRoot "Release"
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("FiveMOptimize_" + [guid]::NewGuid().ToString("N"))

$rawBase = if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    "https://raw.githubusercontent.com/$Repository/$Ref"
} else {
    "https://raw.githubusercontent.com/$Repository/$Ref/$ProjectPath".TrimEnd("/")
}

$scriptUri = "$rawBase/$ScriptName`?t=$cacheBust"
$installSelfUri = "$rawBase/Install-FiveMOptimize.ps1`?t=$cacheBust"
$scriptMirrors = @(
    $scriptUri,
    "https://cdn.jsdelivr.net/gh/$Repository@$Ref/$ProjectPath/$ScriptName`?t=$cacheBust"
)

Write-Step "========================================"
Write-Step "  FiveM Optimize  /  Live Installer"
Write-Step "========================================"
Write-Step "Source : $Repository @ $Ref/$ProjectPath" "DarkCyan"
Write-Step "Mode   : realtime (main branch + cache bust)" "DarkCyan"
Write-Host ""

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$tempScript = Join-Path $tempRoot $ScriptName

$lastError = $null
foreach ($scriptUriTry in $scriptMirrors) {
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            Write-Step "Downloading $ScriptName ($scriptUriTry attempt $attempt)..." "DarkGray"
            Invoke-WebRequest -Uri $scriptUriTry -OutFile $tempScript -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
            if (-not (Test-Path -LiteralPath $tempScript) -or (Get-Item -LiteralPath $tempScript).Length -le 1024) {
                throw "Downloaded file is missing or too small."
            }
            $scriptUri = $scriptUriTry
            $lastError = $null
            break
        } catch {
            $lastError = $_
            Start-Sleep -Seconds $attempt
        }
    }
    if (-not $lastError) { break }
}
if ($lastError) {
    throw @"
Download failed: $($lastError.Exception.Message)

URL: $scriptUri

Checklist:
  1) Create folder FiveM_Optimize on the repo
  2) Upload FiveM_Optimize.ps1 and Install-FiveMOptimize.ps1 there
  3) Wait ~30s after push, then run irm again
"@
}

$sizeMB = [math]::Round((Get-Item -LiteralPath $tempScript).Length / 1MB, 2)
Write-Step "Downloaded $sizeMB MB" "Green"

# Hash for update detection
$newHash = (Get-FileHash -LiteralPath $tempScript -Algorithm SHA256).Hash
$target = Join-Path $installRoot $ScriptName
$oldHash = $null
if (Test-Path -LiteralPath $target) {
    try { $oldHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash } catch {}
}

if ($oldHash -and ($oldHash -eq $newHash) -and -not $Force) {
    Write-Step "Already up to date ($($newHash.Substring(0,12))...)" "Green"
} else {
    if ($oldHash -and ($oldHash -ne $newHash)) {
        Write-Step "Update found: $($oldHash.Substring(0,8)) -> $($newHash.Substring(0,8))" "Yellow"
    }
    if ((Test-Path -LiteralPath $installRoot) -and -not $Force -and $oldHash -and ($oldHash -ne $newHash)) {
        try {
            Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
            $answer = [System.Windows.MessageBox]::Show(
                "พบเวอร์ชันใหม่ของ FiveM Optimize`n`nติดตั้งทับของเดิมเลยหรือไม่?",
                "FiveM Optimize Update",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
            if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
                Write-Step "Update skipped. Launching current install..." "Yellow"
                $exe = (Get-Command powershell.exe -EA SilentlyContinue).Source
                if (-not $exe) { $exe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" }
                if (Test-Path -LiteralPath $target) {
                    Start-Process -FilePath $exe -ArgumentList @("-NoLogo","-NoProfile","-STA","-ExecutionPolicy","Bypass","-File",('"{0}"' -f $target)) -WorkingDirectory $installRoot -Verb RunAs | Out-Null
                }
                return
            }
        } catch {}
    }

    New-Item -ItemType Directory -Path $appRoot -Force | Out-Null
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -LiteralPath $installRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Copy-Item -LiteralPath $tempScript -Destination $target -Force
    try { Unblock-File -LiteralPath $target -ErrorAction SilentlyContinue } catch {}

    # Keep a local copy of this installer for offline re-run
    try {
        $selfOut = Join-Path $installRoot "Install-FiveMOptimize.ps1"
        if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
            Copy-Item -LiteralPath $PSCommandPath -Destination $selfOut -Force -ErrorAction SilentlyContinue
        } else {
            Invoke-WebRequest -Uri $installSelfUri -OutFile $selfOut -UseBasicParsing -TimeoutSec 60 -ErrorAction SilentlyContinue
        }
    } catch {}

    Set-Content -LiteralPath (Join-Path $appRoot "CurrentRelease.txt") -Value $installRoot -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $appRoot "InstalledHash.txt") -Value $newHash -Encoding UTF8
    Write-Step "Installed -> $installRoot" "Green"
}

Write-Step "Launching FiveM Optimize (Admin)..."
$exe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if ([string]::IsNullOrWhiteSpace($exe)) {
    $exe = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
}
$argList = @("-NoLogo","-NoProfile","-STA","-ExecutionPolicy","Bypass","-File",('"{0}"' -f $target))
Start-Process -FilePath $exe -ArgumentList $argList -WorkingDirectory $installRoot -Verb RunAs | Out-Null
Write-Step "Launched. You can close this window." "Green"
Start-Sleep -Seconds 5

try {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {}
