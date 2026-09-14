#Requires -Version 5.1
<#
  irm https://raw.githubusercontent.com/fifthanaphat-lab/FiveM_Optimize/main/Install-FiveMOptimize.ps1 | iex
#>
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
try { [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } } catch {}

$Repository = "fifthanaphat-lab/FiveM_Optimize"
$Ref = "main"
$ScriptName = "FiveM_Optimize.ps1"
$bust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$urls = @(
    "https://raw.githubusercontent.com/$Repository/$Ref/$ScriptName`?t=$bust",
    "https://cdn.jsdelivr.net/gh/$Repository@$Ref/$ScriptName`?t=$bust"
)

$appRoot = Join-Path $env:LOCALAPPDATA "FiveMOptimize"
$installRoot = Join-Path $appRoot "Release"
$target = Join-Path $installRoot $ScriptName
$tempRoot = Join-Path $env:TEMP ("FiveMOptimize_" + [guid]::NewGuid().ToString("N"))
$tempScript = Join-Path $tempRoot $ScriptName

Write-Host "FiveM Optimize live installer" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

$ok = $false
$last = $null
foreach ($url in $urls) {
    try {
        Write-Host "Downloading $url" -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $url -OutFile $tempScript -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
        if ((Test-Path -LiteralPath $tempScript) -and ((Get-Item -LiteralPath $tempScript).Length -gt 50000)) {
            $ok = $true
            break
        }
    } catch { $last = $_.Exception.Message }
}
if (-not $ok) { throw "Download failed. $last" }

$replace = $true
if (Test-Path -LiteralPath $target) {
    try { Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue } catch {}
    $ans = [System.Windows.MessageBox]::Show(
        "Replace the installed FiveM Optimize release?",
        "FiveM Optimize Update",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    $replace = ($ans -eq [System.Windows.MessageBoxResult]::Yes)
}

if ($replace) {
    New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
    Copy-Item -LiteralPath $tempScript -Destination $target -Force
    try { Unblock-File -LiteralPath $target -ErrorAction SilentlyContinue } catch {}
    Write-Host "Installed -> $target" -ForegroundColor Green
} else {
    Write-Host "Keeping current install." -ForegroundColor Yellow
}

$pwsh = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
Start-Process -FilePath $pwsh -WorkingDirectory $installRoot -Verb RunAs -ArgumentList "-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File `"$target`"" | Out-Null
try { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue } catch {}
Write-Host "Launched. Press Yes on UAC if asked." -ForegroundColor Green
