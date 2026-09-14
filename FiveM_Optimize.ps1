#Requires -Version 5.1
# [SYNC-PROJECT-PROTECTED-SCRIPT]
# MD5: 0f2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d
$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'

# Anti-Tamper Check
$scriptContent = Get-Content -Path $PSCommandPath -Raw -ErrorAction SilentlyContinue
if($null -ne $scriptContent -and $scriptContent -notmatch "SYNC-PROJECT-PROTECTED-SCRIPT"){
    [System.Windows.MessageBox]::Show("Script integrity check failed. Please download the original file.","Security Alert",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error)|Out-Null
    exit
}
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    try {
        $scriptPath = $PSCommandPath; if (-not $scriptPath) { $scriptPath = $MyInvocation.MyCommand.Path }
        if (-not $scriptPath) {
            # Path detection failed - will exit without elevation
        } else {
            Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$scriptPath`"") -Verb RunAs; exit
        }
    } catch { }
}
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$Global:Orig = @{}; $Global:AppliedKeys = @{}; $Global:OrigServices = @{}; $Global:OrigMisc = @{}; $Global:ActiveNetPreset = $null; $Global:ActiveGpuPreset = $null; $Global:SelectAllActive = $false
$Global:StateDir = Join-Path $env:LOCALAPPDATA "QueenProject-FiveMOptimize"; $Global:StateFile = Join-Path $Global:StateDir "state.json"
function Save-TweakState {
    try {
        if(-not(Test-Path $Global:StateDir)){New-Item -Path $Global:StateDir -ItemType Directory -Force|Out-Null}
        $json = @{Orig=$Global:Orig;AppliedKeys=$Global:AppliedKeys;TweakToggles=$Global:TweakToggles;OrigServices=$Global:OrigServices;OrigMisc=$Global:OrigMisc;ActiveNetPreset=$Global:ActiveNetPreset;ActiveGpuPreset=$Global:ActiveGpuPreset;SelectAllActive=$Global:SelectAllActive}|ConvertTo-Json -Depth 10
        # Basic protection: Base64 + simple obfuscation
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        $encoded = [System.Convert]::ToBase64String($bytes)
        $protected = ""
        foreach($char in $encoded.ToCharArray()){ $protected += [char]([int]$char -bxor 0x13) }
        $protected | Set-Content -Path $Global:StateFile -Encoding UTF8 -EA Stop
    } catch {}
}
function ConvertTo-HashtableDeep($obj) { if($null -eq $obj){return $null}; if($obj -is [System.Collections.IDictionary]){$h=@{};foreach($k in $obj.Keys){$h[$k]=ConvertTo-HashtableDeep $obj[$k]};return $h}; if($obj -is [PSCustomObject]){$h=@{};foreach($p in $obj.PSObject.Properties){$h[$p.Name]=ConvertTo-HashtableDeep $p.Value};return $h}; if(($obj -is [System.Collections.IEnumerable]) -and ($obj -isnot [string])){return @($obj|ForEach-Object{ConvertTo-HashtableDeep $_})}; return $obj }
function Load-TweakState {
    try {
        if(Test-Path $Global:StateFile){
            $protected = Get-Content -Path $Global:StateFile -Raw -EA Stop
            $encoded = ""
            foreach($char in $protected.ToCharArray()){ $encoded += [char]([int]$char -bxor 0x13) }
            $bytes = [System.Convert]::FromBase64String($encoded)
            $json = [System.Text.Encoding]::UTF8.GetString($bytes)
            $raw = $json | ConvertFrom-Json -EA Stop
            if($raw.Orig){$Global:Orig=ConvertTo-HashtableDeep $raw.Orig}
            if($raw.AppliedKeys){$Global:AppliedKeys=ConvertTo-HashtableDeep $raw.AppliedKeys}
            if($raw.TweakToggles){$Global:SavedTweakToggles=ConvertTo-HashtableDeep $raw.TweakToggles}
            if($raw.OrigServices){$Global:OrigServices=ConvertTo-HashtableDeep $raw.OrigServices}
            if($raw.OrigMisc){$Global:OrigMisc=ConvertTo-HashtableDeep $raw.OrigMisc}
            if($raw.ActiveNetPreset){$Global:ActiveNetPreset=$raw.ActiveNetPreset}
            if($raw.ActiveGpuPreset){$Global:ActiveGpuPreset=$raw.ActiveGpuPreset}
            if($null -ne $raw.SelectAllActive){$Global:SelectAllActive=[bool]$raw.SelectAllActive}
        }
    } catch {}
}
Load-TweakState
$Global:TweakToggles = @{ NetThrottle=$true;BcdTimer=$true;TcpGlobal=$true;KbQueue=$true;NduDisable=$true;GamingMemory=$true;FiveMBooster=$false;GM_FiveMPerfOptions=$false;NET_KillerFix=$true;NET_FiveMQos=$true;NET_FiveMFirewall=$true;GM_FiveMCoreAffinity=$true;DriverHealth=$true;LanOptimize=$true;WifiOptimize=$true;PWR_Throttling=$true;GM_FSOptim=$true;GM_MouseAccel=$true;UX_MenuInstant=$true;UX_Notifications=$true;ADV_HPET=$true;GM_SmoothMotion=$true;CLEAN_SmoothOptim=$true;NET_NoNagle=$true;PWR_UltimatePlan=$true;SYS_NoCoreParking=$true;GM_HAGS=$true;NET_PowerSaving=$true;NET_USBSelSuspend=$true;SYS_TimerRes=$true;SYS_PauseUpdates=$true;GM_GameMode=$true;GM_NoGameDVR=$true;GM_GameBarOff=$true;GM_StandbyClean=$true;CLEAN_NoSearchIndex=$true;CLEAN_NoTelemetry=$true;CLEAN_NoStorageSense=$true;SYS_Win32Priority=$true;GM_MMCSS=$true;NET_TcpTimedWait=$true;NET_PortRange=$true;NET_QoSReserve=$true;GM_MouseQueue=$true;GM_NoStickyKeys=$true;SYS_NoBackgroundApps=$true;CLEAN_NoWER=$true;CLEAN_NoPrintSpooler=$true;CLEAN_RemoveBloat=$true;GPU_TdrDelay_Nvidia=$true;GPU_TdrDelay_Amd=$true;GPU_NvidiaPowerMode=$true;GPU_NvidiaTelemetryOff=$true;GPU_AmdUlps=$true;GPU_AmdEventsUtil=$true;GPU_NvidiaMSIMode=$true;GPU_NvidiaOverlayOff=$true;GPU_AmdMSIMode=$true;GPU_AmdCrashDefenderOff=$true;NetThrottle_WiFi=$true;TcpGlobal_WiFi=$true;NduDisable_WiFi=$true;NET_NoNagle_WiFi=$true;NET_PowerSaving_WiFi=$true;NET_TcpTimedWait_WiFi=$true;NET_PortRange_WiFi=$true;NET_QoSReserve_WiFi=$true;NET_LanJumboFrame=$true;NET_LanInterruptModeration=$true;NET_WifiPowerSaveMode=$true;NET_WifiRoamingAggressiveness=$true;NET_DnsFast=$true;NET_DnsFast_WiFi=$true;NET_DeliveryOptOff=$true;NET_DnsCacheAggressive=$true;GPU_ClearShaderCache=$true;CLEAN_ClearTempJunk=$true;CLEAN_ClearFiveMCache=$true;SYS_BottleneckCheck=$true;NET_Ipv6Disable=$false;NET_RssEnable=$true;NET_FlowControlOff=$true;NET_Ipv6Disable_WiFi=$false;DEF_GameExclusion=$true;SYS_PageFileAuto=$true;NET_Ipv6Transition=$true;NET_DnsClientPolicy=$true;NET_LltdDisable=$true;NET_BitsNoLimit=$true;NET_NetbiosDisable=$true;NET_NcsiNoActiveProbe=$true;NET_NoAutoRootCertUpdate=$true;SYS_NoBkgndGPRefresh=$true;SYS_NoSmartScreenCheck=$true;NET_RemoteAssistanceOff=$true;SYS_OneDriveSyncOff=$true;SYS_WidgetsOff=$true;SYS_ConsumerFeaturesOff=$true;CLEAN_KillBackgroundProcs=$true;CLEAN_DisableLauncherStartup=$true }
# --- Shared lists used by BOTH the Run-* tweak functions and the pre-run confirmation dialog,
# so the dialog can never show a different list than what actually gets removed/killed. ---
$Global:BloatList = @(
    "Microsoft.XboxApp","Microsoft.Xbox.TCUI","Microsoft.XboxGamingOverlay","Microsoft.XboxSpeechToTextOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxGameOverlay",
    "Microsoft.3DBuilder","Microsoft.Microsoft3DViewer","Microsoft.MixedRealityPortal","Microsoft.SkypeApp","Microsoft.YourPhone",
    "Microsoft.MicrosoftSolitaireCollection","Microsoft.BingWeather","Microsoft.BingNews","Microsoft.BingFinance","Microsoft.ZuneMusic","Microsoft.ZuneVideo",
    "Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.Messaging","Microsoft.MicrosoftOfficeHub","Microsoft.People","Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps","Microsoft.MixedReality.Portal","Microsoft.Wallet","Microsoft.WindowsAlarms","Microsoft.WindowsCommunicationsApps",
    "Microsoft.OneConnect","Microsoft.Print3D","Microsoft.Todos","Clipchamp.Clipchamp"
)
$Global:KillProcList = @(
    "OneDrive","Spotify","SpotifyWebHelper","Discord","DiscordCanary","DiscordPTB","Skype","Teams",
    "SteamWebHelper","EpicGamesLauncher","EpicWebHelper","OriginWebHelperService","UbisoftConnectWebHelper",
    "GoogleCrashHandler","GoogleCrashHandler64","GoogleUpdate","AdobeUpdateService","AdobeIPCBroker",
    "OneDriveStandaloneUpdater","YourPhone","GameBar","GameBarFTServer","XboxAppServices","Nvidia Share",
    "NVIDIA GeForce Experience","AMDRSSrcExt","RtkAudUService64","iCloudServices","CCleaner64","CCleaner",
    "Dropbox","Cortana","SearchApp","WidgetService","Widgets"
    # msedgewebview2 / TeamViewer / AnyDesk intentionally excluded - see review notes.
)
$Global:StartupDisableTargets = @("Steam","Discord","Epic","Battle.net","Origin","Ubisoft","Uplay","Riot","GOG","Spotify")
# --- QUEEN PROJECT (customized): only Network + Input Lag tweaks are enabled by default. ---
# --- GPU tweaks are auto-detected. If only one vendor is found, only that vendor's category/tweaks are shown/enabled. ---
# --- If BOTH an NVIDIA and an AMD GPU are detected (hybrid/multi-GPU systems), both categories stay visible so the user can pick. ---
$Global:DetectedGpuVendor = $null
try {
    $__gpuNames = @(Get-CimInstance -ClassName Win32_VideoController -EA SilentlyContinue | Select-Object -ExpandProperty Name)
    $__hasNvidia = [bool]($__gpuNames -match "NVIDIA")
    $__hasAmd = [bool]($__gpuNames -match "AMD|ATI|Radeon")
    if ($__hasNvidia -and $__hasAmd) { $Global:DetectedGpuVendor = "BOTH" }
    elseif ($__hasNvidia) { $Global:DetectedGpuVendor = "NVIDIA" }
    elseif ($__hasAmd) { $Global:DetectedGpuVendor = "AMD" }
} catch {}
$Global:NvidiaOnlyKeys = @("GPU_NvidiaPowerMode","GPU_NvidiaTelemetryOff","GPU_NvidiaMSIMode","GPU_NvidiaOverlayOff")
$Global:AmdOnlyKeys    = @("GPU_AmdUlps","GPU_AmdEventsUtil","GPU_AmdMSIMode","GPU_AmdCrashDefenderOff")
if (-not $Global:SavedTweakToggles) {
    # Auto-select AND auto-deselect based on detected vendor, so a single-vendor
    # system never has the other vendor's (unsupported) tweaks left enabled.
    if ($Global:DetectedGpuVendor -eq "NVIDIA") {
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $false }
    }
    elseif ($Global:DetectedGpuVendor -eq "AMD") {
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
    }
    elseif ($Global:DetectedGpuVendor -eq "BOTH") {
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $true }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $true }
    }
    else {
        # No GPU vendor detected at all (e.g. Get-CimInstance failed) - disable both
        # vendor-specific sets rather than silently trying both and logging warnings.
        foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
        foreach ($k in $Global:AmdOnlyKeys)    { $Global:TweakToggles[$k] = $false }
    }
    # GPU_TdrDelay_Nvidia / GPU_TdrDelay_Amd both map to the same vendor-agnostic
    # TdrDelay tweak (see Run-GpuTdrDelay), so keep whichever one matches what was detected.
    if ($Global:DetectedGpuVendor -eq "AMD") { $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $false; $Global:TweakToggles["GPU_TdrDelay_Amd"] = $true }
    elseif ($Global:DetectedGpuVendor -eq "NVIDIA") { $Global:TweakToggles["GPU_TdrDelay_Amd"] = $false; $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $true }
}
if($Global:SavedTweakToggles){ foreach($k in $Global:SavedTweakToggles.Keys){ if($Global:TweakToggles.ContainsKey($k)){ $Global:TweakToggles[$k]=[bool]$Global:SavedTweakToggles[$k] } } }
# Safety net: even if an OLD state.json (saved before this fix) has the wrong vendor's
# tweaks set to $true, force them off every run - they can never apply on this hardware.
if ($Global:DetectedGpuVendor -ne "AMD" -and $Global:DetectedGpuVendor -ne "BOTH") {
    foreach ($k in $Global:AmdOnlyKeys) { $Global:TweakToggles[$k] = $false }
    if ($Global:DetectedGpuVendor -ne "NVIDIA") { $Global:TweakToggles["GPU_TdrDelay_Amd"] = $false }
}
if ($Global:DetectedGpuVendor -ne "NVIDIA" -and $Global:DetectedGpuVendor -ne "BOTH") {
    foreach ($k in $Global:NvidiaOnlyKeys) { $Global:TweakToggles[$k] = $false }
    if ($Global:DetectedGpuVendor -ne "AMD") { $Global:TweakToggles["GPU_TdrDelay_Nvidia"] = $false }
}

# --- Queen Project defaults ---
# This edition uses an isolated state file and starts with only reversible, low-risk
# client-side options. It deliberately does not claim to reduce server/ISP RTT.
# --- Queen Project Defaults ---
# This list includes all recommended performance tweaks for a smooth experience.
$Global:RecommendedFiveMBalancedKeys = @(
    # --- Gaming & Performance (Always On) ---
    "GM_FiveMPerfOptions", "GM_FiveMCoreAffinity", "GM_GameMode", "GM_NoGameDVR", "GM_GameBarOff",
    "GM_FSOptim", "GM_SmoothMotion", "GM_MMCSS", "GM_StandbyClean", "GamingMemory", "DEF_GameExclusion",
    "CLEAN_ClearFiveMCache", "FiveMBooster", "NET_FiveMQos", "NET_FiveMFirewall",

    # --- Input Lag (Always On) ---
    "KbQueue", "GM_MouseAccel", "NET_USBSelSuspend", "GM_MouseQueue", "GM_NoStickyKeys",

    # --- System & Timing (Always On) ---
    "PWR_Throttling", "SYS_TimerRes", "SYS_Win32Priority", "UX_MenuInstant", "CLEAN_SmoothOptim",
    "CLEAN_NoWER", "CLEAN_NoTelemetry", "BcdTimer", "ADV_HPET", "PWR_UltimatePlan", "SYS_NoCoreParking",
    "SYS_PauseUpdates", "SYS_NoBackgroundApps", "SYS_NoBkgndGPRefresh", "SYS_NoSmartScreenCheck",
    "UX_Notifications", "CLEAN_NoSearchIndex", "CLEAN_NoStorageSense", "SYS_PageFileAuto",

    # --- Global Network Tweaks (Safe for both LAN/WiFi) ---
    "NetThrottle", "TcpGlobal", "NduDisable", "NET_NoNagle", "NET_PowerSaving", "NET_TcpTimedWait",
    "NET_PortRange", "NET_QoSReserve", "NET_DeliveryOptOff", "NET_DnsCacheAggressive", "NET_Ipv6Transition",
    "NET_DnsClientPolicy", "NET_LltdDisable", "NET_BitsNoLimit", "NET_NcsiNoActiveProbe",
    "NET_NoAutoRootCertUpdate", "NET_NetbiosDisable", "NET_RemoteAssistanceOff", "NET_KillerFix"
)
if (-not $Global:SavedTweakToggles) {
    foreach ($key in @($Global:TweakToggles.Keys)) { $Global:TweakToggles[$key] = $false }
    foreach ($key in $Global:RecommendedFiveMBalancedKeys) { $Global:TweakToggles[$key] = $true }
}

$Global:TweakInfo = @(
    @{Key="NetThrottle"; Title="Network Throttling -> Absolute Max"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="Removes Windows' built-in network throttling limit so traffic isn't capped."}
    @{Key="TcpGlobal";   Title="TCP Global Stack Overhaul";           Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Tunes the TCP stack (auto-tuning, RSS, fast open) for lower latency."}
    @{Key="NduDisable";  Title="Ndu Driver -> Disabled";              Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="Disables the Network Data Usage driver, which some report adds overhead."}
    @{Key="LanOptimize"; Title="LAN Optimization";                    Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Applies auto-tuning settings tailored for wired connections."}
    @{Key="NET_NoNagle";      Title="Nagle's Algorithm -> Disabled";  Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Disables TCP ACK delay/coalescing per adapter so small packets (shots, positions) send immediately instead of waiting to batch."}
    @{Key="NET_PowerSaving";  Title="Adapter Power Saving -> Off";    Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Stops Windows from powering down network adapters and disables Energy-Efficient Ethernet, which can cause mid-match latency spikes."}
    @{Key="NET_TcpTimedWait"; Title="TCP TIME_WAIT Delay -> 30s";     Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Shrinks the TIME_WAIT hold from 240s to 30s so ports free up fast during frequent connect/disconnect (voice chat, reconnects) - more stable under bursty traffic."}
    @{Key="NET_PortRange";    Title="Dynamic Port Range -> Widened";  Category="Network"; Group="LAN NETWORK"; Tag="TCP"; Desc="Expands the TCP/UDP ephemeral port range (10000-65535, IPv4 & IPv6) so a game with many simultaneous connections never runs out of ports."}
    @{Key="NET_QoSReserve";   Title="QoS Reserved Bandwidth -> 0% (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > QoS Packet Scheduler > Limit reservable bandwidth. Windows reserves 20% of bandwidth by default; this returns all of it to your traffic."}
    @{Key="NET_LanJumboFrame";Title="Jumbo Frame -> 9014 Bytes";      Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Raises the wired adapter's max frame size so large TCP transfers move in fewer, bigger frames instead of many small ones, cutting per-packet CPU/interrupt overhead. Skipped if the adapter/switch doesn't support it."}
    @{Key="NET_LanInterruptModeration";Title="Interrupt Moderation -> Disabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Stops the wired NIC from batching interrupts before notifying the CPU, trading a little CPU load for lower per-packet latency."}
    @{Key="NET_DnsFast";      Title="DNS -> Google (8.8.4.4 / 8.8.8.8)"; Category="Network"; Group="LAN NETWORK"; Tag="DNS"; Desc="Wired only. Points the wired adapter at fast, widely stable public resolvers (Google primary and secondary) instead of the ISP's default DNS, which can cut name-lookup delay."}
    @{Key="NET_DeliveryOptOff";Title="Delivery Optimization (P2P Updates) -> Off"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="System-wide. Stops Windows Update from uploading update chunks to other PCs on the internet/LAN in the background, which can silently eat upload bandwidth and cause mid-match latency spikes."}
    @{Key="NET_DnsCacheAggressive";Title="DNS Client Cache -> Aggressive"; Category="Network"; Group="LAN NETWORK"; Tag="REG"; Desc="System-wide. Lengthens how long the local DNS resolver cache holds entries, so repeat lookups (game servers, CDNs) are served from cache instead of re-querying."}
    @{Key="NET_Ipv6Disable";  Title="IPv6 -> Disabled";              Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Unbinds IPv6 on the wired adapter. Some ISPs/routers resolve and route IPv6 poorly, adding lookup/connect delay when a game or DNS falls back to it."}
    @{Key="NET_RssEnable";    Title="Receive Side Scaling -> Enabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Spreads incoming network interrupts across multiple CPU cores instead of one, preventing a single core from bottlenecking throughput/latency under heavy traffic."}
    @{Key="NET_FlowControlOff";Title="Flow Control -> Disabled";     Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Wired only. Disables 802.3x flow control pause frames on the NIC, which some switches/routers mishandle in a way that causes brief stalls."}
    @{Key="NET_Ipv6Transition"; Title="IPv6 Transition Tech -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > TCPIP Settings > IPv6 Transition Technologies. Disables Teredo/6to4/ISATAP/IP-HTTPS tunneling attempts so nothing wastes time falling back to a dead IPv6 tunnel before using IPv4."}
    @{Key="NET_DnsClientPolicy"; Title="DNS Client Multicast/Smart Resolution -> Off (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > DNS Client > 'Turn off multicast name resolution' + 'Turn off smart multi-homed name resolution'. Stops the DNS client from firing extra parallel LLMNR/multi-homed lookups in the background."}
    @{Key="NET_LltdDisable"; Title="Link-Layer Topology Discovery -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Link-Layer Topology Discovery (Mapper I/O + Responder). Stops periodic LLTD broadcast traffic used only for Windows' network map feature."}
    @{Key="NET_BitsNoLimit"; Title="BITS Bandwidth Limit -> Removed (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Background Intelligent Transfer Service (BITS). Removes any background-transfer bandwidth cap so Windows Update/BITS jobs don't quietly reserve bandwidth during play."}
    @{Key="NET_NcsiNoActiveProbe"; Title="Network Connectivity Active Probing -> Off (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > Network Connectivity Status Indicator settings. Stops Windows from periodically pinging Microsoft's connectivity-check endpoint in the background, removing a small recurring source of background traffic and CPU wakeups."}
    @{Key="NET_NoAutoRootCertUpdate"; Title="Automatic Root Certificate Update -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > System > Internet Communication Management > Internet Communication settings > 'Turn off Automatic Root Certificates Update'. Stops Windows from silently reaching out to Microsoft to fetch new trusted root certificates in the background."}
    @{Key="NET_NetbiosDisable"; Title="NetBIOS over TCP/IP -> Disabled"; Category="Network"; Group="LAN NETWORK"; Tag="ADAPTER"; Desc="Disables legacy NetBIOS over TCP/IP on every adapter, cutting local broadcast/name-resolution chatter that isn't used by modern games or apps."}
    @{Key="NET_RemoteAssistanceOff"; Title="Solicited Remote Assistance -> Disabled (gpedit)"; Category="Network"; Group="LAN NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Computer Configuration > System > Remote Assistance > 'Configure Solicited Remote Assistance', set to Disabled. Stops the PC from being reachable for incoming Remote Assistance sessions, removing an always-listening background feature."}

    @{Key="WifiOptimize";Title="Wi-Fi Optimization";                  Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Prefers the 5GHz band for a more stable, lower-latency Wi-Fi link."}
    @{Key="NetThrottle_WiFi"; Title="Network Throttling -> Absolute Max"; Category="Network"; Group="WI-FI NETWORK"; Tag="REG"; Desc="Removes Windows' built-in network throttling limit so traffic isn't capped."}
    @{Key="TcpGlobal_WiFi";   Title="TCP Global Stack Overhaul";           Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Tunes the TCP stack (auto-tuning, RSS, fast open) for lower latency."}
    @{Key="NduDisable_WiFi";  Title="Ndu Driver -> Disabled";              Category="Network"; Group="WI-FI NETWORK"; Tag="REG"; Desc="Disables the Network Data Usage driver, which some report adds overhead."}
    @{Key="NET_NoNagle_WiFi";      Title="Nagle's Algorithm -> Disabled";  Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Disables TCP ACK delay/coalescing per adapter so small packets (shots, positions) send immediately instead of waiting to batch."}
    @{Key="NET_PowerSaving_WiFi";  Title="Adapter Power Saving -> Off";    Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Stops Windows from powering down network adapters and disables Energy-Efficient Ethernet, which can cause mid-match latency spikes."}
    @{Key="NET_TcpTimedWait_WiFi"; Title="TCP TIME_WAIT Delay -> 30s";     Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Shrinks the TIME_WAIT hold from 240s to 30s so ports free up fast during frequent connect/disconnect (voice chat, reconnects) - more stable under bursty traffic."}
    @{Key="NET_PortRange_WiFi";    Title="Dynamic Port Range -> Widened";  Category="Network"; Group="WI-FI NETWORK"; Tag="TCP"; Desc="Expands the TCP/UDP ephemeral port range (10000-65535, IPv4 & IPv6) so a game with many simultaneous connections never runs out of ports."}
    @{Key="NET_QoSReserve_WiFi";   Title="QoS Reserved Bandwidth -> 0% (gpedit)"; Category="Network"; Group="WI-FI NETWORK"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Network > QoS Packet Scheduler > Limit reservable bandwidth. Windows reserves 20% of bandwidth by default; this returns all of it to your traffic."}
    @{Key="NET_WifiPowerSaveMode";Title="802.11 Power Saving -> Disabled"; Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Forces the Wi-Fi adapter's driver-level power save mode off so the radio stays fully awake between packets instead of dozing and adding latency."}
    @{Key="NET_WifiRoamingAggressiveness";Title="Roaming Aggressiveness -> Lowest"; Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Makes the adapter stick to the current access point instead of hunting for a 'better' one mid-match, avoiding the brief drop when it roams."}
    @{Key="NET_DnsFast_WiFi"; Title="DNS -> Google (8.8.4.4 / 8.8.8.8)"; Category="Network"; Group="WI-FI NETWORK"; Tag="DNS"; Desc="Wi-Fi only. Points the Wi-Fi adapter at fast, widely stable public resolvers (Google primary and secondary) instead of the ISP's default DNS, which can cut name-lookup delay."}
    @{Key="NET_Ipv6Disable_WiFi";Title="IPv6 -> Disabled";           Category="Network"; Group="WI-FI NETWORK"; Tag="ADAPTER"; Desc="Wi-Fi only. Unbinds IPv6 on the Wi-Fi adapter. Some ISPs/routers resolve and route IPv6 poorly, adding lookup/connect delay when a game or DNS falls back to it."}

    @{Key="KbQueue";     Title="Keyboard Queue Size -> 10";           Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Shrinks the keyboard input buffer so keystrokes register with less delay."}
    @{Key="GM_MouseAccel";    Title="Mouse Acceleration -> Disabled"; Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Turns off pointer acceleration for 1:1 raw mouse movement."}
    @{Key="NET_USBSelSuspend";Title="USB Selective Suspend -> Off";   Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Stops USB mice/keyboards from being suspended when idle, removing the wake-up delay."}
    @{Key="GM_MouseQueue";    Title="Mouse Data Queue Size -> 100 (safe default)"; Category="Input"  ; Group="INPUT LAG"; Tag="REG"; Desc="Keeps the mouse input buffer at Windows' own default (100). Shrinking this below default can cause dropped input on high polling-rate mice, which shows up as cursor ghosting/skipping."}
    @{Key="GM_NoStickyKeys";  Title="Sticky/Toggle/Filter Keys -> Disabled"; Category="Input"; Group="INPUT LAG"; Tag="REG"; Desc="Turns off the accessibility hotkeys so holding Shift/Ctrl while spamming WASD never triggers the Sticky Keys popup mid-fight."}

    @{Key="BcdTimer";    Title="BCD Timer Tweaks";                   Category="System"; Group="SYSTEM & TIMING"; Tag="BCD"; Desc="Adjusts boot timer settings for more precise system clock ticks (needs reboot)."}
    @{Key="ADV_HPET";         Title="Dynamic Tick and HPET -> Disabled";    Category="System"; Group="SYSTEM & TIMING"; Tag="BCD"; Desc="Disables dynamic tick and HPET, which can reduce micro-stutter (needs reboot)."}
    @{Key="PWR_Throttling";   Title="Power Throttling -> Off";              Category="Power" ; Group="SYSTEM & TIMING"; Tag="REG"; Desc="Stops Windows from throttling background process power to keep performance steady."}
    @{Key="PWR_UltimatePlan"; Title="Ultimate Performance Power Plan";      Category="Power" ; Group="SYSTEM & TIMING"; Tag="POWERCFG"; Desc="Enables and activates the Ultimate Performance plan so the CPU never idles down during a match."}
    @{Key="SYS_NoCoreParking";Title="CPU Core Parking -> Disabled";        Category="System"; Group="SYSTEM & TIMING"; Tag="POWERCFG"; Desc="Keeps all CPU cores active instead of parking them, cutting the delay when a core has to spin back up."}
    @{Key="SYS_TimerRes";     Title="System Timer Resolution -> 0.5ms";    Category="System"; Group="SYSTEM & TIMING"; Tag="API"; Desc="Requests the finest Windows timer resolution for smoother frame pacing. Only holds while this app stays open."}
    @{Key="SYS_PauseUpdates"; Title="No Auto-Restart for Windows Update";  Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Stops Windows Update from silently rebooting the PC while you're logged in and mid-session."}
    @{Key="SYS_Win32Priority";Title="Win32PrioritySeparation -> Lowest Input Lag (0xFA322A)"; Category="System"; Group="SYSTEM & TIMING"; Tag="REG"; Desc="Sets Win32PrioritySeparation to 0xFA322A. Windows only reads the low 6 bits of this value, so it effectively behaves as 0x2A / 42 decimal (Short quantum / Variable length / No foreground boost) - CPU time is split equally and quickly between all processes with no single app hogging a turn, which competitive players cite as giving the best raw response time for mouse/keyboard input."}
    @{Key="SYS_NoBackgroundApps";Title="UWP Background Apps -> Blocked (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > App Privacy > Let Windows apps run in the background, set to Force Deny. Stops Store apps from using CPU/network while minimized."}
    @{Key="SYS_NoBkgndGPRefresh";Title="Background Group Policy Refresh -> Disabled (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > System > Group Policy > 'Turn off background refresh of Group Policy'. Stops Windows from silently re-applying policy every ~90 minutes, which can cause a brief hitch if it lands mid-session."}
    @{Key="SYS_NoSmartScreenCheck";Title="SmartScreen App Reputation Check -> Off (gpedit)"; Category="System"; Group="SYSTEM & TIMING"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > File Explorer > 'Configure Windows Defender SmartScreen', set to Off. Skips the online reputation lookup Windows normally does when launching a new .exe, cutting the small delay/stutter on first launch of a game or tool."}
    @{Key="DriverHealth";Title="Driver Health Check";                 Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Scans installed drivers and flags any reporting an error."}
    @{Key="SYS_PageFileAuto"; Title="Page File -> System Managed";    Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Sets the page file back to Windows' automatically-managed size. Fixes cases where a manual pagefile was left too small/misplaced, which can cause stutter when RAM gets tight."}
    @{Key="SYS_BottleneckCheck"; Title="CPU/GPU Bottleneck Check"; Category="System"; Group="SYSTEM & TIMING"; Tag="WMI"; Desc="Samples CPU and GPU load for a few seconds and reports which is more taxed right now. This is an idle-desktop snapshot, not a per-game reading - use an in-game overlay (RTSS/Afterburner) for real numbers while actually playing."}

    @{Key="GamingMemory";Title="Gaming Memory Mode";                  Category="Memory"; Group="GAMING & MEMORY"; Tag="SVC"; Desc="Disables Superfetch so memory prioritization favors active games."}
        @{Key="FiveMBooster";Title="FiveM Booster (High priority - advanced)"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="PROC"; Desc="Sets the running FiveM process to High priority. This is an advanced option and can reduce system responsiveness on some PCs."}

    @{Key="GM_FiveMPerfOptions";Title="FiveM_GTAProcess.exe -> CpuPriorityClass 3 (AboveNormal IFEO)"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Adds an Image File Execution Options entry for FiveM_GTAProcess.exe with PerfOptions\\CpuPriorityClass set to 3 (AboveNormal). This is applied by Windows automatically every time the process starts. It works even if the game is not currently running."}
    @{Key="GM_FiveMCoreAffinity"; Title="FiveM Core Affinity -> Auto-Optimized"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="PROC"; Desc="Pins FiveM_GTAProcess.exe / FiveM.exe to cores 1 through (logical cores - 1, capped at 6), leaving core 0 free for system/interrupt work. If FiveM isn't running yet, watches for it in the background for up to 10 minutes and applies the affinity as soon as it starts. Skipped on 2-core-or-fewer systems."}
    @{Key="NET_KillerFix";    Title="Killer NIC Traffic Analysis -> Disabled";  Category="Network"; Group="GAMING & MEMORY"; Tag="SVC"; Desc="If a Killer-branded network adapter is detected, stops only its user-mode 'smart traffic' analytics service (not the adapter driver itself), which is a well-known cause of random ping spikes and packet loss in games. The adapter keeps working normally through the standard Windows driver. Skipped entirely if no Killer adapter is found."}
    @{Key="NET_FiveMQos";     Title="FiveM Traffic -> QoS Priority Tag";        Category="Network"; Group="GAMING & MEMORY"; Tag="QOS"; Desc="Tags outbound traffic from FiveM.exe / FiveM_GTAProcess.exe with a DSCP priority marker (Expedited Forwarding) so routers/ISPs that respect QoS tagging queue it ahead of other traffic. Also enables Windows to apply DSCP tagging on home (non-domain) networks, which is off by default. Purely additive - it does not throttle or block any other traffic, so it cannot slow down or drop your connection."}
    @{Key="NET_FiveMFirewall";Title="FiveM -> Explicit Firewall Allow Rule";     Category="Network"; Group="GAMING & MEMORY"; Tag="FW"; Desc="Adds an explicit Windows Firewall allow rule for the running FiveM.exe / FiveM_GTAProcess.exe so their traffic is never silently dropped by a delayed firewall prompt or a conflicting security app. Only adds allow rules - never removes or restricts existing ones, so it cannot cause disconnects. Skipped if FiveM isn't running when you click Run."}
    @{Key="GM_FSOptim";       Title="Fullscreen Optimizations -> Disabled"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Disables Windows' fullscreen optimizations layer, which can add input delay."}
    @{Key="GM_SmoothMotion";  Title="Smooth Motion -> MPO Disabled";        Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Disables Multi-Plane Overlay, which some GPUs mishandle causing stutter."}
    @{Key="GM_HAGS";          Title="Hardware-Accelerated GPU Scheduling -> On"; Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Lets the GPU manage its own scheduling queue, which can lower render latency on supported GPUs (needs reboot)."}
    @{Key="GM_GameMode";      Title="Windows Game Mode -> Forced On";       Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Forces Windows Game Mode on so the foreground game reliably gets CPU/GPU scheduling priority."}
    @{Key="GM_NoGameDVR";     Title="Game Bar / Game DVR -> Disabled";      Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Turns off Xbox Game Bar's background recording, which quietly eats CPU/GPU while you play."}
    @{Key="GM_GameBarOff";    Title="Xbox Game Bar Overlay -> Disabled";    Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Goes further than the DVR toggle above: stops the Xbox Game Bar overlay itself (Win+G panel) from loading in the background, freeing up the memory/CPU it reserves and removing another source of input-hook overhead."}
    @{Key="GM_StandbyClean";  Title="Clear Standby Memory List";            Category="Memory"; Group="GAMING & MEMORY"; Tag="API"; Desc="Purges the standby (cached) memory list so the game gets clean free RAM instead of waiting on the cache."}
    @{Key="GM_MMCSS";         Title="MMCSS Games Profile -> Smooth Max";     Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Sets the Multimedia Class Scheduler's Games task profile to the best-known values (max GPU/CPU priority, High scheduling category) for the smoothest frame delivery."}
    @{Key="DEF_GameExclusion";Title="Defender Exclusions -> Game Folders";   Category="Gaming"; Group="GAMING & MEMORY"; Tag="REG"; Desc="Adds Windows Defender real-time scan exclusions for common launcher/game folders (Steam, Epic, Riot, FiveM) that are found on this PC, so on-access scanning doesn't add disk I/O stutter while loading. Only paths that exist are added."}

    @{Key="UX_MenuInstant";   Title="Instant Menus and Animations Off";     Category="UX"  ; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Sets menu show delay to 0ms and trims UI animations."}
    @{Key="UX_Notifications"; Title="Toast Notifications -> Disabled";      Category="UX"  ; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Silences Windows toast pop-ups so they don't interrupt gameplay."}
    @{Key="CLEAN_SmoothOptim";Title="Smooth Background Maintenance";        Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="TASK"; Desc="Disables scheduled background maintenance so it can't kick in mid-session."}
    @{Key="CLEAN_NoWER";      Title="Windows Error Reporting -> Disabled";  Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the WerSvc service so a crashed app can't trigger a dump-write/popup that stutters the system."}
    @{Key="CLEAN_NoPrintSpooler";Title="Print Spooler -> Disabled (OFF by default)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Disables the Print Spooler service. Off by default - only enable this if you don't use a printer, since it will stop printing from working."}
    @{Key="CLEAN_NoSearchIndex";Title="Windows Search Indexing -> Disabled";Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the Windows Search service so it can't chew disk I/O in the background."}
    @{Key="CLEAN_NoTelemetry"; Title="Telemetry Service -> Disabled";       Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="SVC"; Desc="Stops the Connected User Experiences and Telemetry (DiagTrack) service."}
    @{Key="CLEAN_NoStorageSense";Title="Storage Sense -> Disabled";         Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Stops Windows from automatically scanning and cleaning storage in the background."}
    @{Key="CLEAN_KillBackgroundProcs";Title="Non-Essential Background Processes -> Closed"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="PROC"; Desc="Closes a curated list of common non-essential background apps that are currently running (updaters, chat/overlay clients, cloud-sync helpers, etc.) to immediately lower the process count in Task Manager. Never touches Windows system processes, drivers, security software, or the foreground game - only known safe-to-close third-party helper apps."}
    @{Key="CLEAN_DisableLauncherStartup";Title="Game Launchers & Chat Apps -> Startup Disabled"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="REG"; Desc="Removes Steam, Discord, Epic Games, Battle.net, Origin, Ubisoft Connect, Riot Client, GOG Galaxy and Spotify from Windows startup (HKCU/HKLM Run keys) so they no longer auto-launch when you turn on the PC. You can still open them manually anytime - this only stops the automatic launch. Fully reversible via Restore."}
    @{Key="SYS_OneDriveSyncOff"; Title="OneDrive Background Sync -> Off (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > OneDrive > 'Prevent the usage of OneDrive for file storage'. Stops OneDrive from syncing in the background and also ends any currently-running OneDrive process."}
    @{Key="SYS_WidgetsOff"; Title="Windows Widgets -> Disabled (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > Widgets > 'Allow widgets', set to Disabled. Stops the Widgets/News-and-interests board from loading content in the background."}
    @{Key="SYS_ConsumerFeaturesOff"; Title="Consumer Features / Suggested Apps -> Blocked (gpedit)"; Category="Clean"; Group="INTERFACE & CLEANUP"; Tag="GPEDIT"; Desc="Same effect as gpedit.msc > Administrative Templates > Windows Components > Cloud Content > 'Turn off Microsoft consumer experiences'. Stops Windows from silently re-installing bundled/suggested apps in the background."}

    @{Key="GPU_TdrDelay_Nvidia"; Title="GPU Timeout Detection (TDR) -> Extended"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="Extends the driver timeout from 2s to 8s (works for any GPU vendor) so heavy frames don't trigger a driver reset/crash."}
    @{Key="GPU_NvidiaPowerMode";Title="NVIDIA Power Mode -> Prefer Max Performance"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Sets PowerMizer to Prefer Maximum Performance so the GPU doesn't downclock between frames. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaTelemetryOff";Title="NVIDIA Telemetry Service -> Disabled"; Category="GPU"; Group="NVIDIA GPU"; Tag="SVC"; Desc="NVIDIA (green) only. Disables the NvTelemetryContainer service. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaMSIMode";  Title="NVIDIA MSI Mode -> Enabled";       Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Switches the GPU from line-based to Message-Signaled Interrupts, cutting interrupt/DPC latency for smoother frame delivery. Skipped automatically if no NVIDIA GPU is detected."}
    @{Key="GPU_NvidiaOverlayOff";Title="NVIDIA In-Game Overlay -> Disabled"; Category="GPU"; Group="NVIDIA GPU"; Tag="REG"; Desc="NVIDIA (green) only. Disables the ShadowPlay/GeForce Experience in-game overlay so its input hook and capture pipeline stop eating frame time in the background. Skipped automatically if no NVIDIA GPU is detected."}

    @{Key="GPU_TdrDelay_Amd";    Title="GPU Timeout Detection (TDR) -> Extended"; Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="Extends the driver timeout from 2s to 8s (works for any GPU vendor) so heavy frames don't trigger a driver reset/crash."}
    @{Key="GPU_AmdUlps";       Title="AMD ULPS -> Disabled";              Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="AMD (red) only. Disables Ultra Low Power State, a known cause of micro-stutter/black screens on some Radeon cards. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdEventsUtil"; Title="AMD External Events Utility -> Disabled"; Category="GPU"; Group="AMD GPU"; Tag="SVC"; Desc="AMD (red) only. Disables the AMD External Events Utility service, commonly cited as a source of periodic stutter. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdMSIMode";    Title="AMD MSI Mode -> Enabled";           Category="GPU"; Group="AMD GPU"; Tag="REG"; Desc="AMD (red) only. Switches the GPU from line-based to Message-Signaled Interrupts, cutting interrupt/DPC latency for smoother frame delivery. Skipped automatically if no AMD GPU is detected."}
    @{Key="GPU_AmdCrashDefenderOff";Title="AMD Crash Defender -> Disabled"; Category="GPU"; Group="AMD GPU"; Tag="SVC"; Desc="AMD (red) only. Disables the background driver-crash monitoring service so it stops polling in the background during a match. Skipped automatically if no AMD GPU is detected."}

    @{Key="GPU_ClearShaderCache"; Title="Clear Shader Cache (NVIDIA/AMD, Auto-Detect)"; Category="GPU"; Group="GPU & CACHE"; Tag="WMI"; Desc="Deletes cached compiled shaders for whichever GPU vendor's folders are found, forcing a fresh compile on next launch. Can fix stutter or corrupted shader artifacts, but the first load after clearing will be slower while shaders recompile."}
    @{Key="CLEAN_ClearTempJunk";  Title="Clear Temp & Junk Files";           Category="Cleanup"; Group="GPU & CACHE"; Tag="WMI"; Desc="Empties the Windows and user Temp folders of leftover files to free disk space. Skips anything currently locked/in use."}
    @{Key="CLEAN_ClearFiveMCache";Title="Clear FiveM Cache";                 Category="Cleanup"; Group="GPU & CACHE"; Tag="WMI"; Desc="Deletes FiveM's local cache folder so the client re-downloads fresh server assets on next connect. Useful if streamed textures/models got corrupted. Skipped if FiveM isn't installed."}
    @{Key="CLEAN_RemoveBloat";    Title="Remove Unnecessary Pre-Installed Apps"; Category="Cleanup"; Group="GPU & CACHE"; Tag="APPX"; Desc="Uninstalls a curated list of non-essential pre-installed Windows apps (Xbox extras, 3D Viewer, Mixed Reality Portal, Skype, etc.) for the current user to free up RAM/disk. Core system apps and anything not found are left alone/skipped."}
)
function Get-SystemInfo {
    $info = @{}
    try {
        $os=Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        if($os){
            $cap=$os.Caption -replace "Microsoft\s*","" -replace "\s+"," "
            $cap=$cap.Trim()
            # Keep it short: e.g. "Windows 10 IoT Enterprise LTSC 2021" -> "Windows 10 IoT Enterprise"
            if($cap -match "^(Windows\s+\S+(\s+IoT)?(\s+Enterprise|\s+Pro|\s+Home)?)"){ $info.OS=$Matches[1].Trim() } else { $info.OS=$cap }
        } else { $info.OS="Windows" }
    } catch { $info.OS="Windows" }
    try { $cpu=Get-CimInstance Win32_Processor -EA SilentlyContinue|Select -First 1; $info.CPU=if($cpu){($cpu.Name -replace "\(R\)|\(TM\)|CPU|Processor","").Trim()}else{"Unknown CPU"} } catch { $info.CPU="Unknown CPU" }
    try { $gpu=Get-CimInstance Win32_VideoController -EA SilentlyContinue|Select -First 1; $info.GPU=if($gpu){$gpu.Name}else{"Unknown GPU"} } catch { $info.GPU="Unknown GPU" }
    try { $ram=Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue; $info.RAM=if($ram){[math]::Round($ram.TotalPhysicalMemory/1GB)}else{16}; $info.RAMType="DDR4" } catch { $info.RAM=16; $info.RAMType="DDR4" }
    try { $net=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up"}|Select -First 1; if($net){$info.Adapter=$net.InterfaceDescription; $info.NetType=if($net.InterfaceDescription -match "Wi-Fi|Wireless"){"Wi-Fi"}else{"Ethernet"}}else{$info.Adapter="No Adapter";$info.NetType="None"} } catch { $info.Adapter="Ethernet";$info.NetType="Ethernet" }
    try { $freeRam=(Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).FreePhysicalMemory; $totalRam=(Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1KB; if($freeRam -and $totalRam){$info.RAMUsedPct=[math]::Round((($totalRam-$freeRam)/$totalRam)*100)}else{$info.RAMUsedPct=45} } catch { $info.RAMUsedPct=45 }
    return $info
}
$Global:SysInfo = Get-SystemInfo
$mainXamlStr = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="QUEEN PROJECT" Height="820" Width="1280" MinHeight="700" MinWidth="1100"
        WindowStartupLocation="CenterScreen" Background="Transparent"
        FontFamily="Segoe UI" UseLayoutRounding="True" SnapsToDevicePixels="True"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="CanResize">
  <Window.Resources>
    <Style TargetType="ScrollBar">
      <Setter Property="Background" Value="Transparent"/>
      <Style.Triggers>
        <Trigger Property="Orientation" Value="Vertical">
          <Setter Property="Width" Value="6"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="ScrollBar">
                <Grid Background="Transparent">
                  <Track x:Name="PART_Track" IsDirectionReversed="True">
                    <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/></Track.DecreaseRepeatButton>
                    <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/></Track.IncreaseRepeatButton>
                    <Track.Thumb>
                      <Thumb>
                        <Thumb.Template>
                          <ControlTemplate TargetType="Thumb">
                            <Border Background="#D6B25A" Opacity="0.55" CornerRadius="3" Margin="1,0"/>
                          </ControlTemplate>
                        </Thumb.Template>
                      </Thumb>
                    </Track.Thumb>
                  </Track>
                </Grid>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Trigger>
        <Trigger Property="Orientation" Value="Horizontal">
          <Setter Property="Height" Value="7"/>
          <Setter Property="Template">
            <Setter.Value>
              <ControlTemplate TargetType="ScrollBar">
                <Grid Background="Transparent" Height="7">
                  <Track x:Name="PART_Track" Orientation="Horizontal">
                    <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageLeftCommand" Opacity="0" Focusable="False"/></Track.DecreaseRepeatButton>
                    <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageRightCommand" Opacity="0" Focusable="False"/></Track.IncreaseRepeatButton>
                    <Track.Thumb>
                      <Thumb>
                        <Thumb.Template>
                          <ControlTemplate TargetType="Thumb">
                            <Border Background="#D6B25A" Opacity="0.7" CornerRadius="3" Margin="8,1"/>
                          </ControlTemplate>
                        </Thumb.Template>
                      </Thumb>
                    </Track.Thumb>
                  </Track>
                </Grid>
              </ControlTemplate>
            </Setter.Value>
          </Setter>
        </Trigger>
      </Style.Triggers>
    </Style>
    <Style x:Key="ToggleStyle" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="MinWidth" Value="44"/>
      <Setter Property="MinHeight" Value="24"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <Border x:Name="Track" Width="44" Height="24" CornerRadius="12" Background="#1A1814" BorderBrush="#3A352C" BorderThickness="1">
              <Border x:Name="Thumb" Width="18" Height="18" CornerRadius="9" Background="#7A7468" HorizontalAlignment="Left" Margin="3,0,0,0"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="#D6B25A"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="#F0D78C"/>
                <Setter TargetName="Thumb" Property="Background" Value="#16140E"/>
                <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Thumb" Property="Margin" Value="0,0,3,0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="ChromeBtn" TargetType="Button">
      <Setter Property="Width" Value="34"/>
      <Setter Property="Height" Value="34"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Foreground" Value="#8A8478"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bg" CornerRadius="17" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Background" Value="#1A1814"/>
                <Setter Property="Foreground" Value="#F6F1E8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="ChromeClose" TargetType="Button" BasedOn="{StaticResource ChromeBtn}">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bg" CornerRadius="17" Background="Transparent">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bg" Property="Background" Value="#3A1A1E"/>
                <Setter Property="Foreground" Value="#FF8A93"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="GhostBtn" TargetType="Button">
      <Setter Property="Height" Value="36"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Foreground" Value="#F6F1E8"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" CornerRadius="10" Background="#14120E" BorderBrush="#2C281F" BorderThickness="1" Padding="12,0">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="BorderBrush" Value="#D6B25A"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Border BorderThickness="1" CornerRadius="22" BorderBrush="#2C281F">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#09080A" Offset="0"/>
        <GradientStop Color="#070709" Offset="0.5"/>
        <GradientStop Color="#0C0B0E" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Grid x:Name="RootGrid">
      <Grid.Clip>
        <RectangleGeometry x:Name="RootClipGeom" Rect="0,0,1278,818" RadiusX="21" RadiusY="21"/>
      </Grid.Clip>
      <Image x:Name="MainLogoWatermark" Width="0" Height="0" Stretch="Uniform" Opacity="0" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False" SnapsToDevicePixels="True"/>
      <Canvas x:Name="MainBgCanvas" IsHitTestVisible="False" CacheMode="BitmapCache">
        <Ellipse Width="640" Height="420" Canvas.Left="-180" Canvas.Top="-140">
          <Ellipse.Fill>
            <RadialGradientBrush>
              <GradientStop Color="#33D6B25A" Offset="0"/>
              <GradientStop Color="#00000000" Offset="1"/>
            </RadialGradientBrush>
          </Ellipse.Fill>
        </Ellipse>
        <Ellipse Width="520" Height="380" Canvas.Left="860" Canvas.Top="520">
          <Ellipse.Fill>
            <RadialGradientBrush>
              <GradientStop Color="#22F0D78C" Offset="0"/>
              <GradientStop Color="#00000000" Offset="1"/>
            </RadialGradientBrush>
          </Ellipse.Fill>
        </Ellipse>
      </Canvas>
      <Grid Margin="22">
        <Grid.RowDefinitions>
          <RowDefinition Height="56"/>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="86"/>
          <RowDefinition Height="88"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" x:Name="TopBar" Background="Transparent" Margin="2,0,0,12">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
            <Border Width="40" Height="40" CornerRadius="20" Margin="0,0,12,0">
              <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                  <GradientStop Color="#F0D78C" Offset="0"/>
                  <GradientStop Color="#C9A24A" Offset="1"/>
                </LinearGradientBrush>
              </Border.Background>
              <TextBlock Text="&#9819;" Foreground="#16140E" FontSize="18" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <StackPanel VerticalAlignment="Center">
              <TextBlock FontSize="18" FontWeight="Black">
                <Run Text="QUEEN" Foreground="#F6F1E8"/>
                <Run Text="  ATELIER" Foreground="#D6B25A"/>
              </TextBlock>
              <TextBlock Text="Choose a room. Tune. Deploy." Foreground="#8A8478" FontSize="11"/>
            </StackPanel>
          </StackPanel>
          <Border Grid.Column="1" Height="40" Width="320" CornerRadius="20" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" HorizontalAlignment="Center" VerticalAlignment="Center">
            <Grid Margin="14,0">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
              </Grid.ColumnDefinitions>
              <TextBlock Text="&#x2315;" Foreground="#6B675E" FontSize="15" VerticalAlignment="Center" Margin="0,0,8,0"/>
              <Grid Grid.Column="1">
                <TextBlock x:Name="SearchPlaceholder" Text="Find a room or tweak" Foreground="#4A453C" FontSize="12" VerticalAlignment="Center" IsHitTestVisible="False"/>
                <TextBox x:Name="SearchBox" Background="Transparent" Foreground="#F6F1E8" FontSize="12" BorderThickness="0" VerticalContentAlignment="Center" CaretBrush="#D6B25A"/>
              </Grid>
            </Grid>
          </Border>
          <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
            <Border CornerRadius="18" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="12,7" Margin="0,0,10,0">
              <StackPanel Orientation="Horizontal">
                <Ellipse x:Name="StatusDotEllipse" Width="8" Height="8" Fill="#D6B25A" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <TextBlock x:Name="StatusText" Text="READY" Foreground="#F6F1E8" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <Button x:Name="BtnMin" Style="{StaticResource ChromeBtn}" Content="&#8212;" Margin="0,0,2,0"/>
            <Button x:Name="BtnMax" Style="{StaticResource ChromeBtn}" Content="&#9633;" FontSize="10" Margin="0,0,2,0"/>
            <Button x:Name="BtnClose" Style="{StaticResource ChromeClose}" Content="&#10005;"/>
          </StackPanel>
        </Grid>

        <UniformGrid Grid.Row="1" Columns="6" Margin="0,0,0,14">
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12" Margin="0,0,8,0">
            <StackPanel>
              <TextBlock Text="OS" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="InfoOS" Text="Windows" Foreground="#F6F1E8" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12" Margin="0,0,8,0">
            <StackPanel>
              <TextBlock Text="CPU" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="InfoCPU" Text="CPU" Foreground="#F6F1E8" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12" Margin="0,0,8,0">
            <StackPanel>
              <TextBlock Text="GPU" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="InfoGPU" Text="GPU" Foreground="#F6F1E8" FontSize="13" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12" Margin="0,0,8,0">
            <StackPanel>
              <TextBlock Text="NETWORK" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="InfoNET" Text="Ethernet" Foreground="#F6F1E8" FontSize="13" FontWeight="SemiBold" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12" Margin="0,0,8,0">
            <StackPanel>
              <TextBlock Text="MEMORY" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="InfoRAM" Text="16 GB" Foreground="#F6F1E8" FontSize="13" FontWeight="SemiBold" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <Border CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="14,12">
            <StackPanel>
              <Grid>
                <TextBlock Text="RAM LOAD" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
                <TextBlock x:Name="RamUsageText" Text="0%" Foreground="#D6B25A" FontSize="9" FontWeight="Bold" HorizontalAlignment="Right"/>
              </Grid>
              <TextBlock x:Name="InfoAdapter" Text="Ethernet" Foreground="#F6F1E8" FontSize="12" FontWeight="SemiBold" TextTrimming="CharacterEllipsis" Margin="0,4,0,6"/>
              <Border Background="#0A0908" CornerRadius="4" Height="5">
                <Border x:Name="RamUsageFill" CornerRadius="4" HorizontalAlignment="Left" Width="0">
                  <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                      <GradientStop Color="#C9A24A" Offset="0"/>
                      <GradientStop Color="#F0D78C" Offset="1"/>
                    </LinearGradientBrush>
                  </Border.Background>
                </Border>
              </Border>
            </StackPanel>
          </Border>
        </UniformGrid>

        <Grid Grid.Row="2" Margin="0,0,0,12">
          <Border CornerRadius="20" Background="#0C0B0E" BorderBrush="#2C281F" BorderThickness="1" ClipToBounds="True">
            <Grid>
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
              </Grid.RowDefinitions>
              <Grid Margin="20,16,20,8">
                <TextBlock Text="ROOMS" Foreground="#8A8478" FontSize="11" FontWeight="Bold"/>
                <TextBlock Text="Open a room to review and toggle tweaks" Foreground="#5A564C" FontSize="11" HorizontalAlignment="Right"/>
              </Grid>
              <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="16,0,10,16">
                <WrapPanel x:Name="StagesPanel"/>
              </ScrollViewer>
            </Grid>
          </Border>
          <Border x:Name="CategoryOverlay" CornerRadius="20" BorderBrush="#3A3428" BorderThickness="1" Visibility="Collapsed" ClipToBounds="True">
            <Border.Background>
              <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                <GradientStop Color="#100E0C" Offset="0"/>
                <GradientStop Color="#0A0908" Offset="1"/>
              </LinearGradientBrush>
            </Border.Background>
            <Grid>
              <Grid.Clip>
                <RectangleGeometry x:Name="CatOverlayClipGeom" Rect="0,0,1200,500" RadiusX="19" RadiusY="19"/>
              </Grid.Clip>
              <Canvas x:Name="CatOverlayBgCanvas" IsHitTestVisible="False" CacheMode="BitmapCache">
                <Ellipse Width="360" Height="240" Canvas.Left="-80" Canvas.Top="-40">
                  <Ellipse.Fill>
                    <RadialGradientBrush>
                      <GradientStop Color="#33D6B25A" Offset="0"/>
                      <GradientStop Color="#00000000" Offset="1"/>
                    </RadialGradientBrush>
                  </Ellipse.Fill>
                </Ellipse>
              </Canvas>
              <Grid Margin="24,20">
                <Grid.RowDefinitions>
                  <RowDefinition Height="Auto"/>
                  <RowDefinition Height="Auto"/>
                  <RowDefinition Height="*"/>
                  <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <Grid>
                  <StackPanel>
                    <TextBlock Text="ROOM" Foreground="#D6B25A" FontSize="10" FontWeight="Bold"/>
                    <TextBlock x:Name="CatOverlayTitle" Text="CATEGORY" FontSize="22" FontWeight="Black" Foreground="#F6F1E8" Margin="0,2,80,0" TextTrimming="CharacterEllipsis"/>
                  </StackPanel>
                  <Button x:Name="CatOverlayCloseX" Style="{StaticResource ChromeClose}" Content="&#10005;" HorizontalAlignment="Right" VerticalAlignment="Top"/>
                </Grid>
                <TextBlock Grid.Row="1" x:Name="CatOverlayDesc" Text="" Foreground="#8A8478" FontSize="13" TextWrapping="Wrap" Margin="0,8,0,14"/>
                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="0,0,8,0">
                  <StackPanel x:Name="CatOverlayItems"/>
                </ScrollViewer>
                <Button Grid.Row="3" x:Name="CatOverlayCloseBtn" Height="46" Margin="0,16,0,0" Cursor="Hand" BorderThickness="0" Content="BACK TO ROOMS">
                  <Button.Template>
                    <ControlTemplate TargetType="Button">
                      <Border x:Name="Bd" CornerRadius="14" Background="#D6B25A">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center">
                          <ContentPresenter.Resources>
                            <Style TargetType="TextBlock">
                              <Setter Property="Foreground" Value="#16140E"/>
                              <Setter Property="FontWeight" Value="Black"/>
                              <Setter Property="FontSize" Value="13"/>
                            </Style>
                          </ContentPresenter.Resources>
                        </ContentPresenter>
                      </Border>
                      <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                          <Setter TargetName="Bd" Property="Opacity" Value="0.88"/>
                        </Trigger>
                      </ControlTemplate.Triggers>
                    </ControlTemplate>
                  </Button.Template>
                </Button>
              </Grid>
            </Grid>
          </Border>
        </Grid>

        <Border Grid.Row="3" CornerRadius="16" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="16,12" Margin="0,0,0,12">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="160"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel VerticalAlignment="Center">
              <TextBlock Text="ACTIVITY" Foreground="#6B675E" FontSize="9" FontWeight="Bold"/>
              <TextBlock x:Name="CurrentTaskText" Text="Waiting to start..." Foreground="#F6F1E8" FontSize="12" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/>
            </StackPanel>
            <ScrollViewer Grid.Column="1" x:Name="LogScrollViewer" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="16,0">
              <TextBlock x:Name="LogBox" Foreground="#8A8478" FontSize="11" FontFamily="Consolas" TextWrapping="Wrap" LineHeight="18"/>
            </ScrollViewer>
            <StackPanel Grid.Column="2" VerticalAlignment="Center">
              <TextBlock x:Name="ProgressPercent" Text="0%" Foreground="#D6B25A" FontSize="16" FontWeight="Black" HorizontalAlignment="Right"/>
              <Border Background="#0A0908" CornerRadius="4" Height="6" Width="140" Margin="0,6,0,0">
                <Border x:Name="ProgressFill" CornerRadius="4" HorizontalAlignment="Left" Width="0">
                  <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                      <GradientStop Color="#C9A24A" Offset="0"/>
                      <GradientStop Color="#F0D78C" Offset="1"/>
                    </LinearGradientBrush>
                  </Border.Background>
                </Border>
              </Border>
            </StackPanel>
          </Grid>
        </Border>

        <Border Grid.Row="4" CornerRadius="18" Background="#100E0C" BorderBrush="#2C281F" BorderThickness="1" Padding="12,10">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="34"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="34"/>
              </Grid.ColumnDefinitions>
              <Button x:Name="BtnDockScrollLeft" Width="32" Height="56" Cursor="Hand" BorderThickness="0" ToolTip="Scroll presets left">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="12" Background="#14120E" BorderBrush="#2C281F" BorderThickness="1">
                      <TextBlock Text="&#8249;" Foreground="#D6B25A" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#D6B25A"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <ScrollViewer x:Name="DockPresetScroll" Grid.Column="1" Height="68" Margin="6,0"
                            HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Disabled"
                            PanningMode="HorizontalOnly" CanContentScroll="False">
            <StackPanel Orientation="Horizontal">
              <Button x:Name="BtnPresetAllExceptGpuLan" Width="168" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0" ToolTip="Enable the recommended Queen Project profile.">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" BorderBrush="#3A3428" BorderThickness="1">
                      <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                          <GradientStop Color="#1A160F" Offset="0"/>
                          <GradientStop Color="#241E14" Offset="1"/>
                        </LinearGradientBrush>
                      </Border.Background>
                      <StackPanel VerticalAlignment="Center" Margin="12,0">
                        <TextBlock Text="QUEEN PROFILE" Foreground="#F6F1E8" FontSize="11" FontWeight="Black"/>
                        <TextBlock Text="recommended stack" Foreground="#8A8478" FontSize="9"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#D6B25A"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="NetPresetLan" Width="86" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,6,0" ToolTip="Enable all wired LAN network tweaks and disable all Wi-Fi tweaks">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#101820" BorderBrush="#1E3344" BorderThickness="1">
                      <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="LAN" Foreground="#E8F4FF" FontSize="12" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="wired" Foreground="#6B8496" FontSize="9" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#5BB8FF"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="NetPresetWifi" Width="86" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,6,0" ToolTip="Enable all Wi-Fi network tweaks and disable all wired LAN tweaks">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#101918" BorderBrush="#1E3A36" BorderThickness="1">
                      <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="WI-FI" Foreground="#E8FFFB" FontSize="12" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="radio" Foreground="#6B8A86" FontSize="9" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#4ECDC4"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="GpuPresetAmd" Width="86" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,6,0" ToolTip="Enable all AMD GPU tweaks and disable all NVIDIA GPU tweaks">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#1A1012" BorderBrush="#3A2024" BorderThickness="1">
                      <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="AMD" Foreground="#FFB4B8" FontSize="12" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="Radeon" Foreground="#8A5C60" FontSize="9" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#ED1C24"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="GpuPresetNvidia" Width="96" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0" ToolTip="Enable all NVIDIA GPU tweaks and disable all AMD GPU tweaks">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#101810" BorderBrush="#27361F" BorderThickness="1">
                      <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="NVIDIA" Foreground="#D4F5B8" FontSize="12" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="GeForce" Foreground="#65785C" FontSize="9" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#76B900"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="BtnNetTwakes" Width="120" Height="56" Cursor="Hand" BorderThickness="0" ToolTip="Net Twakes console shortcut">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#10151C" BorderBrush="#1D3344" BorderThickness="1">
                      <TextBlock Text="NET TWAKES" Foreground="#CDE8F8" FontSize="10" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#5BB8FF"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
            </StackPanel>
              </ScrollViewer>
              <Button x:Name="BtnDockScrollRight" Grid.Column="2" Width="32" Height="56" Cursor="Hand" BorderThickness="0" ToolTip="Scroll presets right">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="12" Background="#14120E" BorderBrush="#2C281F" BorderThickness="1">
                      <TextBlock Text="&#8250;" Foreground="#D6B25A" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#D6B25A"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
            </Grid>
            <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center" Margin="12,0">
              <Button x:Name="BtnTaskMgr" Style="{StaticResource GhostBtn}" Content="Task Manager" Margin="0,0,6,0"/>
              <Button x:Name="BtnGpedit" Style="{StaticResource GhostBtn}" Content="Group Policy" Margin="0,0,6,0"/>
              <Button x:Name="BtnClean" Style="{StaticResource GhostBtn}" Content="Clean"/>
            </StackPanel>
            <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
              <Button x:Name="BtnExit" Width="88" Height="56" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="Bd" CornerRadius="14" Background="#160D10" BorderBrush="#3D1515" BorderThickness="1">
                      <TextBlock Text="EXIT" Foreground="#F0A8A8" FontSize="12" FontWeight="Black" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#EF4444"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
              <Button x:Name="BtnRun" Width="200" Height="56" Cursor="Hand" BorderThickness="0">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="RunBorder" CornerRadius="16">
                      <Border.Effect>
                        <DropShadowEffect Color="#D6B25A" BlurRadius="18" ShadowDepth="0" Opacity="0.3"/>
                      </Border.Effect>
                      <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                          <GradientStop Color="#F0D78C" Offset="0"/>
                          <GradientStop Color="#D6B25A" Offset="0.55"/>
                          <GradientStop Color="#B8923E" Offset="1"/>
                        </LinearGradientBrush>
                      </Border.Background>
                      <StackPanel VerticalAlignment="Center">
                        <TextBlock Text="DEPLOY QUEEN" Foreground="#16140E" FontSize="14" FontWeight="Black" HorizontalAlignment="Center"/>
                        <TextBlock Text="apply selected rooms" Foreground="#5A4A20" FontSize="10" FontWeight="SemiBold" HorizontalAlignment="Center"/>
                      </StackPanel>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="RunBorder" Property="Opacity" Value="0.9"/>
                      </Trigger>
                      <Trigger Property="IsEnabled" Value="False">
                        <Setter TargetName="RunBorder" Property="Opacity" Value="0.45"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
            </StackPanel>
          </Grid>
        </Border>
      </Grid>
    </Grid>
  </Border>
</Window>
"@

# =========================================================
# SPLASH HELPER FUNCTIONS (chime sounds, click FX, background aura)
# =========================================================
# [console]::Beep() blocks the calling thread for the full note duration. Called directly
# on the UI thread it froze the window for ~0.4-1s (the reported "START hangs for 1-3s" bug).
# Running the beep sequence on a background thread keeps the UI fully responsive.
function Invoke-BeepSequenceAsync([scriptblock]$Beeps) {
    try {
        $ps = [PowerShell]::Create()
        [void]$ps.AddScript($Beeps.ToString())
        # BeginInvoke() runs on a threadpool thread and returns immediately -
        # the UI thread never blocks waiting for the beeps to finish.
        [void]$ps.BeginInvoke()
    } catch {}
}

function Play-StartupChime {
    # Distinct "power-on" chime for the splash START button - a soft rising sweep,
    # separate from the completion chime so the two moments feel different.
    try {
        [System.Media.SystemSounds]::Beep.Play()
    } catch {}
    Invoke-BeepSequenceAsync {
        [console]::Beep(523,90)
        [console]::Beep(659,90)
        [console]::Beep(784,90)
        [console]::Beep(1046,200)
    }
}

# ---------- Lightweight "premium" aura for the splash card: a soft breathing glow behind the ----------
# ---------- title + a handful of slow, faint drifting particles. No lightning, no busy grid   ----------
# ---------- - just enough motion/light to give the flat card some dimension.                  ----------
function New-SplashAura {
    param(
        $Canvas,
        [double]$Width = 360,
        [double]$Height = 330,
        [double]$CenterX = 180,
        [double]$CenterY = 110,
        [int]$ParticleCount = 9
    )
    try {
        $rnd = New-Object System.Random

        # ---- One very soft, faint ambient glow behind everything (keeps things clean, not busy) ----
        $ambientBrush = New-Object System.Windows.Media.RadialGradientBrush
        [void]$ambientBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(42,212,175,90)), 0))
        [void]$ambientBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop ([System.Windows.Media.Color]::FromArgb(0,212,175,90)), 1))
        $ambient = New-Object System.Windows.Shapes.Ellipse
        $ambient.Width = $Width * 0.85
        $ambient.Height = $Width * 0.85
        $ambient.Fill = $ambientBrush
        [System.Windows.Controls.Canvas]::SetLeft($ambient, $CenterX - ($ambient.Width / 2))
        [System.Windows.Controls.Canvas]::SetTop($ambient, $CenterY - ($ambient.Height / 2))
        [void]$Canvas.Children.Add($ambient)

        # ---- Clean constellation network: sparse nodes linked by thin, faint lines ----
        $nodeCount = [Math]::Max($ParticleCount + 5, 14)
        $nodes = @()
        for ($n = 0; $n -lt $nodeCount; $n++) {
            $nodes += [PSCustomObject]@{
                X = $rnd.Next(6, [int]($Width - 6))
                Y = $rnd.Next(6, [int]($Height - 6))
            }
        }

        $linkDist = $Width * 0.30
        for ($a = 0; $a -lt $nodes.Count; $a++) {
            for ($b = $a + 1; $b -lt $nodes.Count; $b++) {
                $dx = $nodes[$a].X - $nodes[$b].X
                $dy = $nodes[$a].Y - $nodes[$b].Y
                $dist = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
                if ($dist -le $linkDist) {
                    $line = New-Object System.Windows.Shapes.Line
                    $line.X1 = $nodes[$a].X; $line.Y1 = $nodes[$a].Y
                    $line.X2 = $nodes[$b].X; $line.Y2 = $nodes[$b].Y
                    $lineAlpha = 18 + ((1 - ($dist / $linkDist)) * 34)
                    $line.Stroke = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb([byte]$lineAlpha,212,175,90))
                    $line.StrokeThickness = 0.7
                    [void]$Canvas.Children.Add($line)
                }
            }
        }

        foreach ($node in $nodes) {
            $dotSize = 2 + ($rnd.NextDouble() * 1.6)
            $isBright = ($rnd.NextDouble() -gt 0.72)
            $dot = New-Object System.Windows.Shapes.Ellipse
            $dot.Width = $dotSize
            $dot.Height = $dotSize
            if ($isBright) {
                $dot.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(235,240,215,140))
            } else {
                $dot.Fill = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(170,212,175,90))
            }
            [System.Windows.Controls.Canvas]::SetLeft($dot, $node.X - ($dotSize / 2))
            [System.Windows.Controls.Canvas]::SetTop($dot, $node.Y - ($dotSize / 2))
            [void]$Canvas.Children.Add($dot)

            $twinkle = New-Object System.Windows.Media.Animation.DoubleAnimation
            $twinkle.From = 0.35 + ($rnd.NextDouble() * 0.2)
            $twinkle.To = 0.8 + ($rnd.NextDouble() * 0.2)
            $twinkle.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(2 + $rnd.NextDouble() * 3))
            $twinkle.AutoReverse = $true
            $twinkle.BeginTime = [TimeSpan]::FromSeconds($rnd.NextDouble() * 2)
            $twinkle.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
            $dot.BeginAnimation([System.Windows.Shapes.Ellipse]::OpacityProperty, $twinkle)
        }
    } catch { }
}

# ---------- Click feedback FX (scale bounce) for main action buttons ----------
function Add-ClickFX($btn) {
    if (-not $btn) { return }
    $btn.RenderTransformOrigin = New-Object -TypeName System.Windows.Point -ArgumentList 0.5,0.5
    $scaleT = New-Object System.Windows.Media.ScaleTransform
    $scaleT.ScaleX = 1; $scaleT.ScaleY = 1
    $btn.RenderTransform = $scaleT

    $btn.Add_PreviewMouseLeftButtonDown({
        $sender = $args[0]
        $down = New-Object System.Windows.Media.Animation.DoubleAnimation
        $down.To = 0.92
        $down.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(70))
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $down)
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $down)
    })
    $btn.Add_PreviewMouseLeftButtonUp({
        $sender = $args[0]
        $up = New-Object System.Windows.Media.Animation.DoubleAnimation
        $up.To = 1.0
        $up.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromMilliseconds(150))
        $bounce = New-Object System.Windows.Media.Animation.BackEase
        $bounce.Amplitude = 0.5
        $up.EasingFunction = $bounce
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $up)
        $sender.RenderTransform.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $up)
    })
}

# ---------- Shared background drift (continuous, automatic - no mouse movement needed) so the ----------
# ---------- Splash screen and the Main Console background move the exact same way.              ----------
function Add-BackgroundParallax {
    param(
        $TargetWindow,
        $Canvas,
        [double]$MaxOffset = 20,
        [double]$DurationX = 9,
        [double]$DurationY = 7
    )
    if (-not $Canvas) { return }
    $translate = New-Object System.Windows.Media.TranslateTransform
    $Canvas.RenderTransform = $translate

    $animX = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animX.From = -$MaxOffset
    $animX.To = $MaxOffset
    $animX.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($DurationX))
    $animX.AutoReverse = $true
    $animX.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $animX.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $translate.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $animX)

    $animY = New-Object System.Windows.Media.Animation.DoubleAnimation
    $animY.From = -($MaxOffset * 0.6)
    $animY.To = ($MaxOffset * 0.6)
    $animY.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds($DurationY))
    $animY.AutoReverse = $true
    $animY.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $animY.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $translate.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animY)
}

# SPLASH / START SCREEN
# =========================================================
$Global:SplashLogoPath = Join-Path $PSScriptRoot "QueenProject-logo-transparent.png"

[xml]$splashXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="QUEEN PROJECT" Height="420" Width="760"
        WindowStartupLocation="CenterScreen"
        Background="Transparent" FontFamily="Segoe UI"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="NoResize" Topmost="True">
  <Border x:Name="SplashOuterBorder" BorderThickness="1" CornerRadius="22" BorderBrush="#D6B25A">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#0C0B0E" Offset="0"/>
        <GradientStop Color="#070709" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Grid>
      <Grid.Clip>
        <RectangleGeometry Rect="0,0,758,418" RadiusX="21" RadiusY="21"/>
      </Grid.Clip>
      <Canvas x:Name="SplashBgCanvas" ClipToBounds="True" IsHitTestVisible="False"/>
      <Grid x:Name="SplashRoot">
        <Grid.RowDefinitions>
          <RowDefinition Height="44"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid Grid.Row="0" x:Name="SplashTopBar" Background="Transparent">
          <TextBlock Text="QUEEN ATELIER" Foreground="#8A8478" FontSize="11" FontWeight="Bold" VerticalAlignment="Center" Margin="22,0,0,0"/>
          <Button x:Name="BtnSplashMinimize" Content="&#8212;" Width="28" Height="28" FontSize="10" Foreground="#D6B25A" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,44,0">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="MinBg" CornerRadius="14" Background="Transparent">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="MinBg" Property="Background" Value="#1A1814"/>
                    <Setter Property="Foreground" Value="#F6F1E8"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
          <Button x:Name="BtnSplashClose" Content="&#10005;" Width="28" Height="28" FontSize="11" Foreground="#D6B25A" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,14,0">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <Border x:Name="CloseBg" CornerRadius="14" Background="Transparent">
                  <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="CloseBg" Property="Background" Value="#3A1A1E"/>
                    <Setter Property="Foreground" Value="#FF8A93"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
        </Grid>
        <Grid Grid.Row="1" Margin="28,0,28,28">
          <Grid x:Name="SplashStartGroup">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="280"/>
            </Grid.ColumnDefinitions>
            <StackPanel VerticalAlignment="Center" Margin="8,0,20,0">
              <Border Width="10" Height="10" CornerRadius="5" Background="#D6B25A" HorizontalAlignment="Left" Margin="0,0,0,16"/>
              <TextBlock Text="QUEEN" Foreground="#F6F1E8" FontSize="42" FontWeight="Black"/>
              <TextBlock Text="PERFORMANCE ATELIER" Foreground="#D6B25A" FontSize="14" FontWeight="Bold" Margin="0,2,0,12"/>
              <TextBlock Text="A new control room for FiveM. Open a room, pick the tweaks, then deploy." Foreground="#8A8478" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,22"/>
              <Button x:Name="BtnSplashStart" Content="ENTER THE ATELIER" Height="52" FontSize="13" FontWeight="Black" Foreground="#16140E" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Left" Width="260">
                <Button.Template>
                  <ControlTemplate TargetType="Button">
                    <Border x:Name="StartBorder" CornerRadius="16">
                      <Border.Background>
                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                          <GradientStop Color="#F0D78C" Offset="0"/>
                          <GradientStop Color="#D6B25A" Offset="1"/>
                        </LinearGradientBrush>
                      </Border.Background>
                      <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="StartBorder" Property="Effect">
                          <Setter.Value>
                            <DropShadowEffect Color="#F0D78C" BlurRadius="22" ShadowDepth="0" Opacity="0.5"/>
                          </Setter.Value>
                        </Setter>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </Button.Template>
              </Button>
            </StackPanel>
            <Grid Grid.Column="1">
              <Border Width="220" Height="220" CornerRadius="110" HorizontalAlignment="Center" VerticalAlignment="Center" Opacity="0.32">
                <Border.Background>
                  <RadialGradientBrush>
                    <GradientStop Color="#D6B25A" Offset="0"/>
                    <GradientStop Color="#00000000" Offset="1"/>
                  </RadialGradientBrush>
                </Border.Background>
              </Border>
              <Border Width="188" Height="188" CornerRadius="94" BorderBrush="#D6B25A" BorderThickness="1.2" Background="#0A0908" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Grid>
                  <TextBlock x:Name="SplashLogoFallback" Text="&#9819;" FontSize="84" Foreground="#D6B25A" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  <Image x:Name="SplashLogoImage" Width="150" Height="150" Stretch="Uniform" RenderTransformOrigin="0.5,0.5">
                    <Image.RenderTransform>
                      <TranslateTransform x:Name="SplashLogoFloat" Y="0"/>
                    </Image.RenderTransform>
                  </Image>
                </Grid>
              </Border>
            </Grid>
          </Grid>
          <Grid x:Name="SplashLoadingGroup" Opacity="0" IsHitTestVisible="False">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="260"/>
            </Grid.ColumnDefinitions>
            <StackPanel VerticalAlignment="Center" Margin="8,0,16,0">
              <TextBlock Text="OPENING THE ATELIER" Foreground="#F6F1E8" FontSize="26" FontWeight="Black"/>
              <TextBlock FontFamily="Consolas" Foreground="#D6B25A" FontSize="12" FontWeight="Bold" Margin="0,6,0,18">
                <Run Text="PREPARING ROOMS"/><Run x:Name="SplashConnectingDots" Text="..."/>
              </TextBlock>
              <Grid Margin="0,0,0,8">
                <TextBlock Text="Loading interface" Foreground="#8A8478" FontSize="11"/>
                <TextBlock Text="SECURE" Foreground="#D6B25A" FontSize="11" FontWeight="Bold" HorizontalAlignment="Right"/>
              </Grid>
              <Border Height="12" CornerRadius="6" Background="#0A0908" BorderBrush="#2C281F" BorderThickness="1">
                <Grid Margin="2" ClipToBounds="True">
                  <Border x:Name="SplashLoadingFill" CornerRadius="4" HorizontalAlignment="Left" Width="0">
                    <Border.Background>
                      <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                        <GradientStop Color="#F0D78C" Offset="0"/>
                        <GradientStop Color="#D6B25A" Offset="1"/>
                      </LinearGradientBrush>
                    </Border.Background>
                  </Border>
                </Grid>
              </Border>
            </StackPanel>
            <Grid Grid.Column="1" x:Name="SplashRingWrap" Width="214" Height="214" HorizontalAlignment="Center" VerticalAlignment="Center">
              <Ellipse Width="214" Height="214" Stroke="#3A3428" StrokeThickness="1.2" StrokeDashArray="2,9">
                <Ellipse.RenderTransform>
                  <RotateTransform x:Name="SplashRingAmbientRotate" Angle="0" CenterX="107" CenterY="107"/>
                </Ellipse.RenderTransform>
              </Ellipse>
              <Ellipse Width="176" Height="176" Stroke="#1A1814" StrokeThickness="8"/>
              <Ellipse x:Name="SplashRingProgress" Width="176" Height="176" Stroke="#D6B25A" StrokeThickness="8" StrokeStartLineCap="Round" StrokeEndLineCap="Round">
                <Ellipse.RenderTransform>
                  <RotateTransform Angle="-90" CenterX="88" CenterY="88"/>
                </Ellipse.RenderTransform>
              </Ellipse>
              <Border Width="124" Height="124" CornerRadius="62" Background="#0A0908" HorizontalAlignment="Center" VerticalAlignment="Center">
                <Grid>
                  <TextBlock Text="&#9819;" FontSize="40" Foreground="#D6B25A" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  <Image x:Name="SplashLoadingLogoImage" Width="96" Height="96" Stretch="Uniform" RenderTransformOrigin="0.5,0.5">
                    <Image.RenderTransform>
                      <ScaleTransform x:Name="SplashLogoBreathe" ScaleX="1" ScaleY="1"/>
                    </Image.RenderTransform>
                  </Image>
                </Grid>
              </Border>
              <TextBlock x:Name="SplashRingPercentText" Text="0%" Foreground="#F0D78C" FontFamily="Consolas" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,-8"/>
            </Grid>
          </Grid>
        </Grid>
      </Grid>
    </Grid>
  </Border>
</Window>
"@
$splashReader = New-Object System.Xml.XmlNodeReader $splashXaml
$splashWindow = [Windows.Markup.XamlReader]::Load($splashReader)

$SplashRoot           = $splashWindow.FindName("SplashRoot")
$SplashBgCanvas       = $splashWindow.FindName("SplashBgCanvas")
$SplashTopBar         = $splashWindow.FindName("SplashTopBar")
$BtnSplashMinimize    = $splashWindow.FindName("BtnSplashMinimize")
$BtnSplashClose       = $splashWindow.FindName("BtnSplashClose")
$BtnSplashStart       = $splashWindow.FindName("BtnSplashStart")
$SplashLogoImage      = $splashWindow.FindName("SplashLogoImage")
$SplashStartGroup     = $splashWindow.FindName("SplashStartGroup")
$SplashLoadingGroup   = $splashWindow.FindName("SplashLoadingGroup")
$SplashLoadingFill    = $splashWindow.FindName("SplashLoadingFill")
$SplashRingPercentText = $splashWindow.FindName("SplashRingPercentText")
$SplashRingProgress   = $splashWindow.FindName("SplashRingProgress")
$SplashLoadingLogoImage = $splashWindow.FindName("SplashLoadingLogoImage")
$SplashRingAmbientRotate = $splashWindow.FindName("SplashRingAmbientRotate")
$SplashLogoBreathe       = $splashWindow.FindName("SplashLogoBreathe")
$SplashLogoFloat         = $splashWindow.FindName("SplashLogoFloat")
$SplashConnectingDots    = $splashWindow.FindName("SplashConnectingDots")
$SplashLogoFallback      = $splashWindow.FindName("SplashLogoFallback")

try {
    if(-not $PSScriptRoot){
        $script:__QueenProjectRoot = Split-Path -Parent $PSCommandPath
        $Global:SplashLogoPath = Join-Path $script:__QueenProjectRoot "QueenProject-logo-transparent.png"
    }
    if(Test-Path $Global:SplashLogoPath){
        $splashLogoBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $splashLogoBitmap.BeginInit()
        $splashLogoBitmap.UriSource = [Uri]::new($Global:SplashLogoPath)
        $splashLogoBitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $splashLogoBitmap.EndInit()
        $splashLogoBitmap.Freeze()
        $SplashLogoImage.Source = $splashLogoBitmap
        $SplashLoadingLogoImage.Source = $splashLogoBitmap
        if($SplashLogoFallback){ $SplashLogoFallback.Visibility = "Collapsed" }
    }
} catch { }

# Gentle continuous float/bob for the logo on the START screen, so it feels alive even before loading starts.
$logoFloat = New-Object System.Windows.Media.Animation.DoubleAnimationUsingKeyFrames
$logoFloat.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
$lf0 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]0,  [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(0)))
$lf1 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]-8, [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(1.4)))
$lf2 = [System.Windows.Media.Animation.EasingDoubleKeyFrame]::new([double]0,  [System.Windows.Media.Animation.KeyTime]::FromTimeSpan([TimeSpan]::FromSeconds(2.8)))
foreach ($kf in @($lf0,$lf1,$lf2)) {
    $ease = New-Object System.Windows.Media.Animation.SineEase
    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseInOut
    $kf.EasingFunction = $ease
    $logoFloat.KeyFrames.Add($kf) | Out-Null
}
$SplashLogoFloat.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $logoFloat)

# Soft premium glow + faint drifting particles behind the title, for depth (no lightning/busy grid).
New-SplashAura -Canvas $SplashBgCanvas -Width 740 -Height 400 -CenterX 500 -CenterY 200 -ParticleCount 11
Add-BackgroundParallax -TargetWindow $splashWindow -Canvas $SplashBgCanvas -MaxOffset 12 -DurationX 8 -DurationY 6.5

# Simple fade-in for the whole card
$SplashRoot.Opacity = 0
$fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
$fadeIn.From = 0
$fadeIn.To = 1
$fadeIn.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.5))
$SplashRoot.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)

# Tracks whether the user closed the splash with the X button (full program exit)
# rather than pressing START (proceed into the main console).
$Global:SplashClosedByX = $false

# Animates the loading bar from 0 -> 100% and then hands off to the main console.
# Runs on a DispatcherTimer so the UI stays responsive while it fills.
# NOTE: the timer and its width constant are stored in Global scope (not local to this
# function) because the Tick event fires later, after this function has already returned -
# a local variable would fall out of scope and read back as $null.
function Start-SplashLoading {
    $BtnSplashStart.IsEnabled = $false
    $BtnSplashStart.Content = "LOADING"
    $SplashLoadingFill.Width = 0
    $SplashRingPercentText.Text = "0%"

    # Circular ring math: dash-array units in WPF are multiples of StrokeThickness,
    # so total "distance" around the ring = circumference / thickness.
    $Global:SplashRingThickness = 8.0
    $Global:SplashRingCircumference = [math]::PI * (176 - $Global:SplashRingThickness)
    $Global:SplashRingDashUnits = $Global:SplashRingCircumference / $Global:SplashRingThickness
    $initialDashArray = New-Object System.Windows.Media.DoubleCollection
    $initialDashArray.Add(0)
    $initialDashArray.Add([double]($Global:SplashRingDashUnits * 3))
    $SplashRingProgress.StrokeDashArray = $initialDashArray

    # Continuous ambient ring spin - decorative only, unrelated to actual % progress, just for depth/motion.
    $ambientSpin = New-Object System.Windows.Media.Animation.DoubleAnimation
    $ambientSpin.From = 0; $ambientSpin.To = 360
    $ambientSpin.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(6))
    $ambientSpin.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $SplashRingAmbientRotate.BeginAnimation([System.Windows.Media.RotateTransform]::AngleProperty, $ambientSpin)

    # Gentle breathing pulse on the center logo for a touch of depth/life.
    $breatheX = New-Object System.Windows.Media.Animation.DoubleAnimation
    $breatheX.From = 1.0; $breatheX.To = 1.08
    $breatheX.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(1.1))
    $breatheX.AutoReverse = $true
    $breatheX.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
    $breatheX.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
    $breatheY = $breatheX.Clone()
    $SplashLogoBreathe.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $breatheX)
    $SplashLogoBreathe.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $breatheY)

    # Animated loading dots after INITIALIZING QUEEN PROJECT.
    $Global:SplashDotsFrames = @(".", "..", "...")
    $Global:SplashDotsIndex = 2
    $Global:SplashDotsTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:SplashDotsTimer.Interval = [TimeSpan]::FromMilliseconds(450)
    $Global:SplashDotsTimer.Add_Tick({
        $Global:SplashDotsIndex = ($Global:SplashDotsIndex + 1) % $Global:SplashDotsFrames.Count
        $SplashConnectingDots.Text = $Global:SplashDotsFrames[$Global:SplashDotsIndex]
    })
    $Global:SplashDotsTimer.Start()

    $splashFadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
    $splashFadeOut.From = 1
    $splashFadeOut.To = 0
    $splashFadeOut.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.2))
    $SplashStartGroup.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $splashFadeOut)
    $SplashStartGroup.IsHitTestVisible = $false

    $splashFadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $splashFadeIn.From = 0
    $splashFadeIn.To = 1
    $splashFadeIn.Duration = New-Object System.Windows.Duration ([TimeSpan]::FromSeconds(0.25))
    $SplashLoadingGroup.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $splashFadeIn)

    # Inner width of the bottom progress rail: match the current rail width at runtime.
    $Global:SplashLoadFullWidth = [math]::Max(1, $SplashLoadingFill.Parent.ActualWidth)
    if($Global:SplashLoadFullWidth -le 1){ $Global:SplashLoadFullWidth = 354 }
    $Global:SplashLoadPct = 0

    $Global:SplashLoadTimer = New-Object System.Windows.Threading.DispatcherTimer
    $Global:SplashLoadTimer.Interval = [TimeSpan]::FromMilliseconds(50)
    $Global:SplashLoadTimer.Add_Tick({
        $Global:SplashLoadPct += 1
        if ($Global:SplashLoadPct -ge 100) {
            $Global:SplashLoadPct = 100
        }
        $fillWidthNow = [double]$Global:SplashLoadFullWidth * ($Global:SplashLoadPct / 100.0)
        $SplashLoadingFill.Width = $fillWidthNow
        $SplashRingPercentText.Text = "$($Global:SplashLoadPct)%"

        $ringDash = $Global:SplashRingDashUnits * ($Global:SplashLoadPct / 100.0)
        $ringGap  = $Global:SplashRingDashUnits * 3
        $ringDashArray = New-Object System.Windows.Media.DoubleCollection
        $ringDashArray.Add([double]$ringDash)
        $ringDashArray.Add([double]$ringGap)
        $SplashRingProgress.StrokeDashArray = $ringDashArray

        if ($Global:SplashLoadPct -ge 100) {
            $Global:SplashLoadTimer.Stop()
            $Global:SplashDotsTimer.Stop()
            $splashWindow.Close()
        }
    })
    $Global:SplashLoadTimer.Start()
}

Add-ClickFX $BtnSplashStart
Add-ClickFX $BtnSplashMinimize
Add-ClickFX $BtnSplashClose
$BtnSplashStart.Add_Click({ Start-SplashLoading })
$BtnSplashClose.Add_Click({ $Global:SplashClosedByX = $true; $splashWindow.Close() })
$BtnSplashMinimize.Add_Click({ $splashWindow.WindowState = 'Minimized' })
$SplashTopBar.Add_MouseLeftButtonDown({ $splashWindow.DragMove() })

$splashWindow.ShowDialog() | Out-Null

if ($Global:SplashClosedByX) {
    # User closed the splash screen with the X button - exit before the main console ever opens.
    exit
}


[xml]$xaml = $mainXamlStr
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$MainBgCanvas = $window.FindName("MainBgCanvas")
$RootClipGeom = $window.FindName("RootClipGeom")
$MainLogoWatermark = $window.FindName("MainLogoWatermark")
try { $MainLogoWatermark.Visibility = "Collapsed" } catch {}
Add-BackgroundParallax -TargetWindow $window -Canvas $MainBgCanvas -MaxOffset 22 -DurationX 11 -DurationY 8.5

$TopBar=$window.FindName("TopBar"); $SearchBox=$window.FindName("SearchBox"); $SearchPH=$window.FindName("SearchPlaceholder")
$StatusText=$window.FindName("StatusText"); $StatusDotE=$window.FindName("StatusDotEllipse")
$BtnMin=$window.FindName("BtnMin"); $BtnMax=$window.FindName("BtnMax"); $BtnClose=$window.FindName("BtnClose")
$StagesPanel=$window.FindName("StagesPanel")
$ProgressFill=$window.FindName("ProgressFill"); $ProgressPct=$window.FindName("ProgressPercent")
$BtnRun=$window.FindName("BtnRun")
$NetPresetLan=$window.FindName("NetPresetLan"); $NetPresetWifi=$window.FindName("NetPresetWifi")
$BtnNetTwakes=$window.FindName("BtnNetTwakes")
$GpuPresetAmd=$window.FindName("GpuPresetAmd"); $GpuPresetNvidia=$window.FindName("GpuPresetNvidia")
$BtnPresetAllExceptGpuLan=$window.FindName("BtnPresetAllExceptGpuLan")
$BtnExit=$window.FindName("BtnExit")
$InfoOS=$window.FindName("InfoOS"); $InfoCPU=$window.FindName("InfoCPU"); $InfoGPU=$window.FindName("InfoGPU")
$InfoNET=$window.FindName("InfoNET"); $InfoRAM=$window.FindName("InfoRAM"); $InfoAdapter=$window.FindName("InfoAdapter")
$RamUsageFill=$window.FindName("RamUsageFill"); $RamUsageText=$window.FindName("RamUsageText")
$BtnTaskMgr=$window.FindName("BtnTaskMgr"); $BtnGpedit=$window.FindName("BtnGpedit"); $BtnClean=$window.FindName("BtnClean")
$LogScrollV=$window.FindName("LogScrollViewer"); $LogBox=$window.FindName("LogBox"); $CurrentTask=$window.FindName("CurrentTaskText")
$CategoryOverlay=$window.FindName("CategoryOverlay"); $CatOverlayTitle=$window.FindName("CatOverlayTitle")
$CatOverlayClipGeom=$window.FindName("CatOverlayClipGeom")
$CatOverlayBgCanvas=$window.FindName("CatOverlayBgCanvas")
Add-BackgroundParallax -TargetWindow $window -Canvas $CatOverlayBgCanvas -MaxOffset 14 -DurationX 9.5 -DurationY 7.5
$CatOverlayDesc=$window.FindName("CatOverlayDesc"); $CatOverlayItems=$window.FindName("CatOverlayItems")
$CatOverlayCloseX=$window.FindName("CatOverlayCloseX"); $CatOverlayCloseBtn=$window.FindName("CatOverlayCloseBtn")
$DockPresetScroll=$window.FindName("DockPresetScroll")
$BtnDockScrollLeft=$window.FindName("BtnDockScrollLeft")
$BtnDockScrollRight=$window.FindName("BtnDockScrollRight")
if($DockPresetScroll){
    $DockPresetScroll.Add_PreviewMouseWheel({
        param($sender,$e)
        $next = $sender.HorizontalOffset - $e.Delta
        if($next -lt 0){ $next = 0 }
        $sender.ScrollToHorizontalOffset($next)
        $e.Handled = $true
    })
}
if($BtnDockScrollLeft -and $DockPresetScroll){
    $BtnDockScrollLeft.Add_Click({
        $DockPresetScroll.ScrollToHorizontalOffset([math]::Max(0, $DockPresetScroll.HorizontalOffset - 180))
    })
}
if($BtnDockScrollRight -and $DockPresetScroll){
    $BtnDockScrollRight.Add_Click({
        $DockPresetScroll.ScrollToHorizontalOffset($DockPresetScroll.HorizontalOffset + 180)
    })
}

$InfoOS.Text=$Global:SysInfo.OS; $InfoCPU.Text=$Global:SysInfo.CPU; $InfoGPU.Text=$Global:SysInfo.GPU
$InfoNET.Text=$Global:SysInfo.NetType; $InfoRAM.Text="$($Global:SysInfo.RAM) GB"
$InfoAdapter.Text=$Global:SysInfo.Adapter

$window.Add_Loaded({
    foreach($btn in @($NetPresetLan,$NetPresetWifi,$GpuPresetAmd,$GpuPresetNvidia,$BtnPresetAllExceptGpuLan)){
        if($btn){ $btn.ApplyTemplate() | Out-Null }
    }
    Update-PresetGlowConsistency
    $maxW=$RamUsageFill.Parent.ActualWidth; if($maxW -le 0){$maxW=400}
    $pct=$Global:SysInfo.RAMUsedPct; $RamUsageFill.Width=[math]::Max(0,($pct/100.0)*$maxW); $RamUsageText.Text="$pct%"
    Play-StartupChime
})
$TopBar.Add_MouseLeftButtonDown({ $window.DragMove() })
$BtnClose.Add_Click({ $window.Close() })
$BtnMin.Add_Click({ $window.WindowState="Minimized" })
$BtnMax.Add_Click({
    if($window.Tag -eq "Maximized"){
        $window.Width=$Global:NormalW; $window.Height=$Global:NormalH
        $window.Left=$Global:NormalL; $window.Top=$Global:NormalT
        $window.Tag=$null
    } else {
        $Global:NormalW=$window.Width; $Global:NormalH=$window.Height
        $Global:NormalL=$window.Left; $Global:NormalT=$window.Top
        $wa=[System.Windows.SystemParameters]::WorkArea
        $window.Left=$wa.Left; $window.Top=$wa.Top
        $window.Width=$wa.Width; $window.Height=$wa.Height
        $window.Tag="Maximized"
    }
})
# Keep the rounded-corner clip matched to the actual window size so resizing/maximizing
# never leaves stray hairlines at the edges or a stuck/oversized render surface.
$window.Add_SizeChanged({
    if($window.ActualWidth -gt 2 -and $window.ActualHeight -gt 2){
        $RootClipGeom.Rect=[System.Windows.Rect]::new(0,0,$window.ActualWidth-2,$window.ActualHeight-2)
    }
    if($RamUsageFill -and $RamUsageFill.Parent -and $RamUsageFill.Parent.ActualWidth -gt 0){
        $pct=$Global:SysInfo.RAMUsedPct
        $RamUsageFill.Width=[math]::Max(0,($pct/100.0)*$RamUsageFill.Parent.ActualWidth)
    }
})
# The category overlay's clip geometry was hardcoded to 600x600 in XAML, but the overlay
# itself stretches to fill the whole right-hand panel (which is wider than 600px on most
# window sizes). That mismatch pushed each row's toggle switch (right-aligned "Auto" column)
# past the clipped/visible area, so the switches rendered off-screen and couldn't be clicked.
# Keep the clip synced to the overlay's actual size, the same way RootClipGeom tracks the window.
$CategoryOverlay.Add_SizeChanged({
    if($CategoryOverlay.ActualWidth -gt 2 -and $CategoryOverlay.ActualHeight -gt 2){
        $CatOverlayClipGeom.Rect=[System.Windows.Rect]::new(0,0,$CategoryOverlay.ActualWidth,$CategoryOverlay.ActualHeight)
    }
})

$Global:LogLines=[System.Collections.Generic.List[string]]::new()
function Add-Log {
    param([string]$msg,[string]$color="#6B7280")
    $Global:LogLines.Add($msg)
    $window.Dispatcher.Invoke([Action]{
        $run=New-Object System.Windows.Documents.Run; $run.Text="> $msg`n"
        try{$run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($color)}catch{}
        $LogBox.Inlines.Add($run); $LogScrollV.ScrollToEnd()
    })
}
$Global:StageCBs=@{}
$Global:CategoryInfo = @(
    @{Group="LAN NETWORK";          Icon="&#9889;"; Desc="TCP/network stack tuning and adapter-level tweaks for wired Ethernet connections."; Accent=@(0x38,0xBD,0xF8)}
    @{Group="WI-FI NETWORK";        Icon="&#9889;"; Desc="TCP/network stack tuning and adapter-level tweaks for Wi-Fi connections."; Accent=@(0x2D,0xD4,0xBF)}
    @{Group="INPUT LAG";            Icon="&#9000;"; Desc="Keyboard, mouse, and USB tweaks aimed at reducing input delay."; Accent=@(0xD4,0xAF,0x5A)}
    @{Group="SYSTEM & TIMING";      Icon="&#9632;"; Desc="Timer resolution, power throttling, and driver health checks for a steadier system."; Accent=@(0xE8,0xC9,0x7A)}
    @{Group="GAMING & MEMORY";      Icon="&#9654;"; Desc="Memory prioritization and fullscreen/overlay tweaks aimed at smoother gaming."; Accent=@(0xD4,0xAF,0x5A)}
    @{Group="INTERFACE & CLEANUP";  Icon="&#10003;"; Desc="Instant menus, disabled notifications, and background maintenance kept out of the way."; Accent=@(0xC9,0xA2,0x4A)}
    @{Group="NVIDIA GPU";           Icon="&#9670;"; Desc="NVD - Driver-level tweaks for NVIDIA (green) cards, plus the universal GPU timeout fix."; Accent=@(0x76,0xB9,0x00)}
    @{Group="AMD GPU";              Icon="&#9670;"; Desc="Driver-level tweaks for AMD (red) cards, plus the universal GPU timeout fix."; Accent=@(0xED,0x1C,0x24)}
    @{Group="GPU & CACHE";          Icon="&#128465;"; Desc="Shader cache, temp files, and game-cache cleanup, plus a quick CPU/GPU load check."; Accent=@(0xF5,0x9E,0x0B)}
)
# What each tweak actually touches under the hood, shown as a small badge in the detail view.
$Global:TagMeta = @{
    REG      = @{ Label="REGISTRY"; Bg=@(0x1E,0x2A,0x45); Fg=@(0x60,0xA5,0xFA) }
    TCP      = @{ Label="TCP/NETSH"; Bg=@(0x27,0x1E,0x45); Fg=@(0xA7,0x8B,0xFA) }
    GPEDIT   = @{ Label="GPEDIT"; Bg=@(0x40,0x2A,0x1A); Fg=@(0xF5,0x9E,0x0B) }
    SVC      = @{ Label="SERVICE"; Bg=@(0x40,0x1A,0x1A); Fg=@(0xEF,0x44,0x44) }
    POWERCFG = @{ Label="POWERCFG"; Bg=@(0x1A,0x33,0x28); Fg=@(0x10,0xB9,0x81) }
    BCD      = @{ Label="BCD/BOOT"; Bg=@(0x14,0x33,0x38); Fg=@(0x2D,0xD4,0xBF) }
    ADAPTER  = @{ Label="ADAPTER"; Bg=@(0x14,0x2E,0x3D); Fg=@(0x38,0xBD,0xF8) }
    WMI      = @{ Label="WMI"; Bg=@(0x28,0x28,0x28); Fg=@(0x9C,0xA3,0xAF) }
    PROC     = @{ Label="PROCESS"; Bg=@(0x40,0x38,0x14); Fg=@(0xEA,0xB3,0x08) }
    API      = @{ Label="WIN API"; Bg=@(0x38,0x1A,0x38); Fg=@(0xE8,0x79,0xF9) }
    TASK     = @{ Label="SCHED. TASK"; Bg=@(0x33,0x24,0x14); Fg=@(0xF9,0x9B,0x5D) }
}
function Get-LighterRgb($rgb, [double]$amt=0.55) {
    $r=[math]::Round($rgb[0] + (255-$rgb[0])*$amt); $g=[math]::Round($rgb[1] + (255-$rgb[1])*$amt); $b=[math]::Round($rgb[2] + (255-$rgb[2])*$amt)
    return @([byte]$r,[byte]$g,[byte]$b)
}
function New-IconBrush($rgb) {
    $light=Get-LighterRgb $rgb 0.55
    $brush=New-Object System.Windows.Media.LinearGradientBrush
    $brush.StartPoint=New-Object System.Windows.Point(0,0); $brush.EndPoint=New-Object System.Windows.Point(1,1)
    $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($light[0],$light[1],$light[2]),0)))
    $brush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($rgb[0],$rgb[1],$rgb[2]),1)))
    return $brush
}
function New-CategoryIconVisual([string]$GroupName, $AccentRgb, [bool]$IsActive) {
    $fgRgb= if($IsActive){$AccentRgb} else {@(0x9C,0xA3,0xAF)}
    $brush=New-IconBrush $fgRgb
    $canvas=New-Object System.Windows.Controls.Canvas; $canvas.Width=24; $canvas.Height=24
    switch($GroupName){
        "LAN NETWORK" {
            foreach($pt in @(@(12,7,6,16),@(12,7,18,16))){
                $l=New-Object System.Windows.Shapes.Line; $l.X1=$pt[0];$l.Y1=$pt[1];$l.X2=$pt[2];$l.Y2=$pt[3]
                $l.Stroke=$brush; $l.StrokeThickness=1.6; $l.StrokeStartLineCap="Round"; $l.StrokeEndLineCap="Round"
                $canvas.Children.Add($l)|Out-Null
            }
            foreach($n in @(@(9.8,2.8),@(3.8,15.8),@(15.8,15.8))){
                $e=New-Object System.Windows.Shapes.Ellipse; $e.Width=4.4; $e.Height=4.4; $e.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($e,$n[0]); [System.Windows.Controls.Canvas]::SetTop($e,$n[1])
                $canvas.Children.Add($e)|Out-Null
            }
        }
        "WI-FI NETWORK" {
            foreach($bar in @(@(3,14,6),@(10,9,11),@(17,4,16))){
                $r=New-Object System.Windows.Shapes.Rectangle; $r.Width=4; $r.Height=$bar[2]; $r.RadiusX=1; $r.RadiusY=1; $r.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($r,$bar[0]); [System.Windows.Controls.Canvas]::SetTop($r,$bar[1])
                $canvas.Children.Add($r)|Out-Null
            }
        }
        "INPUT LAG" {
            $body=New-Object System.Windows.Shapes.Rectangle; $body.Width=20; $body.Height=13; $body.RadiusX=3; $body.RadiusY=3; $body.Fill=$brush; $body.Opacity=0.28
            [System.Windows.Controls.Canvas]::SetLeft($body,2); [System.Windows.Controls.Canvas]::SetTop($body,6)
            $canvas.Children.Add($body)|Out-Null
            $keys=@(@(4.5,8.5),@(7.7,8.5),@(10.9,8.5),@(14.1,8.5),@(17.3,8.5),@(4.5,11.7),@(7.7,11.7),@(10.9,11.7),@(14.1,11.7),@(17.3,11.7),@(6,14.9),@(9.5,14.9),@(14.5,14.9),@(18,14.9))
            foreach($p in $keys){
                $k=New-Object System.Windows.Shapes.Rectangle; $k.Width=2.2; $k.Height=2.2; $k.RadiusX=0.5; $k.RadiusY=0.5; $k.Fill=$brush
                [System.Windows.Controls.Canvas]::SetLeft($k,$p[0]); [System.Windows.Controls.Canvas]::SetTop($k,$p[1])
                $canvas.Children.Add($k)|Out-Null
            }
        }
        "SYSTEM & TIMING" {
            $arc=New-Object System.Windows.Shapes.Path; $arc.Data=[System.Windows.Media.Geometry]::Parse("M4,17 A8,8 0 1 1 20,17")
            $arc.Stroke=$brush; $arc.StrokeThickness=2; $arc.StrokeStartLineCap="Round"; $arc.StrokeEndLineCap="Round"
            $canvas.Children.Add($arc)|Out-Null
            $needle=New-Object System.Windows.Shapes.Line; $needle.X1=12; $needle.Y1=17; $needle.X2=16; $needle.Y2=10
            $needle.Stroke=$brush; $needle.StrokeThickness=1.8; $needle.StrokeStartLineCap="Round"; $needle.StrokeEndLineCap="Round"
            $canvas.Children.Add($needle)|Out-Null
            $hub=New-Object System.Windows.Shapes.Ellipse; $hub.Width=3; $hub.Height=3; $hub.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($hub,10.5); [System.Windows.Controls.Canvas]::SetTop($hub,15.5)
            $canvas.Children.Add($hub)|Out-Null
        }
        "GAMING & MEMORY" {
            $bodyGeom=[System.Windows.Media.Geometry]::Parse("M6,9 L18,9 A4,4 0 0 1 22,13 L22,15 A3,3 0 0 1 17,17.5 L15,15 L9,15 L7,17.5 A3,3 0 0 1 2,15 L2,13 A4,4 0 0 1 6,9 Z")
            $bodyPath=New-Object System.Windows.Shapes.Path; $bodyPath.Data=$bodyGeom; $bodyPath.Fill=$brush
            $canvas.Children.Add($bodyPath)|Out-Null
            $dpadV=New-Object System.Windows.Shapes.Rectangle; $dpadV.Width=1.6; $dpadV.Height=5; $dpadV.Fill="#101218"
            [System.Windows.Controls.Canvas]::SetLeft($dpadV,7.2); [System.Windows.Controls.Canvas]::SetTop($dpadV,10.5)
            $dpadH=New-Object System.Windows.Shapes.Rectangle; $dpadH.Width=5; $dpadH.Height=1.6; $dpadH.Fill="#101218"
            [System.Windows.Controls.Canvas]::SetLeft($dpadH,5.5); [System.Windows.Controls.Canvas]::SetTop($dpadH,12.2)
            $canvas.Children.Add($dpadV)|Out-Null; $canvas.Children.Add($dpadH)|Out-Null
            foreach($b in @(@(16.5,10.5),@(18.5,12.5))){
                $btn=New-Object System.Windows.Shapes.Ellipse; $btn.Width=2; $btn.Height=2; $btn.Fill="#101218"
                [System.Windows.Controls.Canvas]::SetLeft($btn,$b[0]); [System.Windows.Controls.Canvas]::SetTop($btn,$b[1])
                $canvas.Children.Add($btn)|Out-Null
            }
        }
        "INTERFACE & CLEANUP" {
            $star=New-Object System.Windows.Shapes.Path; $star.Data=[System.Windows.Media.Geometry]::Parse("M12,2 L14,9 L21,11 L14,13 L12,20 L10,13 L3,11 L10,9 Z")
            $star.Fill=$brush
            $canvas.Children.Add($star)|Out-Null
        }
        {$_ -eq "NVIDIA GPU" -or $_ -eq "AMD GPU"} {
            $chip=New-Object System.Windows.Shapes.Rectangle; $chip.Width=16; $chip.Height=12; $chip.RadiusX=2; $chip.RadiusY=2; $chip.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($chip,4); [System.Windows.Controls.Canvas]::SetTop($chip,6)
            $canvas.Children.Add($chip)|Out-Null
            $fan=New-Object System.Windows.Shapes.Ellipse; $fan.Width=6; $fan.Height=6; $fan.Fill="#101218"; $fan.Opacity=0.55
            [System.Windows.Controls.Canvas]::SetLeft($fan,9); [System.Windows.Controls.Canvas]::SetTop($fan,9)
            $canvas.Children.Add($fan)|Out-Null
            foreach($p in @(@(6,3,6,6),@(10,3,10,6),@(14,3,14,6),@(6,18,6,15),@(10,18,10,15),@(14,18,14,15))){
                $pin=New-Object System.Windows.Shapes.Line; $pin.X1=$p[0]; $pin.Y1=$p[1]; $pin.X2=$p[2]; $pin.Y2=$p[3]
                $pin.Stroke=$brush; $pin.StrokeThickness=1.4
                $canvas.Children.Add($pin)|Out-Null
            }
        }
        "GPU & CACHE" {
            $lid=New-Object System.Windows.Shapes.Rectangle; $lid.Width=14; $lid.Height=2; $lid.RadiusX=1; $lid.RadiusY=1; $lid.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($lid,5); [System.Windows.Controls.Canvas]::SetTop($lid,6)
            $canvas.Children.Add($lid)|Out-Null
            $handle=New-Object System.Windows.Shapes.Rectangle; $handle.Width=5; $handle.Height=2.5; $handle.RadiusX=1; $handle.RadiusY=1; $handle.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($handle,9.5); [System.Windows.Controls.Canvas]::SetTop($handle,3.2)
            $canvas.Children.Add($handle)|Out-Null
            $bin=New-Object System.Windows.Shapes.Path; $bin.Data=[System.Windows.Media.Geometry]::Parse("M6.5,9 L17.5,9 L16.5,20 A2,2 0 0 1 14.5,22 L9.5,22 A2,2 0 0 1 7.5,20 Z")
            $bin.Fill=$brush
            $canvas.Children.Add($bin)|Out-Null
        }
        default {
            $dot=New-Object System.Windows.Shapes.Ellipse; $dot.Width=10; $dot.Height=10; $dot.Fill=$brush
            [System.Windows.Controls.Canvas]::SetLeft($dot,7); [System.Windows.Controls.Canvas]::SetTop($dot,7)
            $canvas.Children.Add($dot)|Out-Null
        }
    }
    $vb=New-Object System.Windows.Controls.Viewbox; $vb.Width=16; $vb.Height=16; $vb.Stretch="Uniform"; $vb.Child=$canvas
    $shadow=New-Object System.Windows.Media.Effects.DropShadowEffect
    $shadow.Color=[System.Windows.Media.Color]::FromRgb($fgRgb[0],$fgRgb[1],$fgRgb[2]); $shadow.BlurRadius=6; $shadow.ShadowDepth=0; $shadow.Opacity=0.55
    $vb.Effect=$shadow
    return $vb
}
function Get-GroupToggleCount([string]$groupName) {
    $items=@($Global:TweakInfo | Where-Object { $_.Group -eq $groupName })
    $on=0; foreach($it in $items){ if($Global:TweakToggles[$it.Key]){ $on++ } }
    return @{ On=$on; Total=$items.Count }
}
function Build-StageCards {
    param([string]$filter="")
    if(-not $Global:StageCountLabels){ $Global:StageCountLabels=@{} }
    $StagesPanel.Children.Clear()
    $groupOrder=@("LAN NETWORK","WI-FI NETWORK","INPUT LAG","SYSTEM & TIMING","GAMING & MEMORY","INTERFACE & CLEANUP","NVIDIA GPU","AMD GPU","GPU & CACHE")
    if ($Global:DetectedGpuVendor -eq "NVIDIA") { $groupOrder = $groupOrder | Where-Object { $_ -ne "AMD GPU" } }
    elseif ($Global:DetectedGpuVendor -eq "AMD") { $groupOrder = $groupOrder | Where-Object { $_ -ne "NVIDIA GPU" } }
    foreach ($groupName in $groupOrder) {
        $catMeta=$Global:CategoryInfo | Where-Object { $_.Group -eq $groupName }
        $itemsInGroup=$Global:TweakInfo | Where-Object { $_.Group -eq $groupName }
        $matches= -not $filter -or $groupName -like "*$filter*" -or ($itemsInGroup | Where-Object { $_.Title -like "*$filter*" -or $_.Category -like "*$filter*" })
        if(-not $matches){continue}
        $isActive = ($Global:ActiveCategory -eq $groupName)
        $accentColor= if($catMeta.Accent){$catMeta.Accent}else{@(0xD4,0xAF,0x5A)}
        $counts=Get-GroupToggleCount $groupName
        $card=New-Object System.Windows.Controls.Border
        $card.Width=268; $card.Height=158; $card.CornerRadius="18"; $card.BorderThickness="1"
        $card.Margin="0,0,12,12"; $card.Padding="16,14"; $card.Cursor="Hand"
        $bgColor= if($isActive){@(0x1C,0x18,0x12)}else{@(0x12,0x10,0x0E)}
        $borderColor= if($isActive){$accentColor}else{@(0x2C,0x28,0x1F)}
        $card.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($bgColor[0],$bgColor[1],$bgColor[2]))
        $card.BorderBrush=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($borderColor[0],$borderColor[1],$borderColor[2]))
        $root=New-Object System.Windows.Controls.DockPanel
        $top=New-Object System.Windows.Controls.Grid
        $top.Margin="0,0,0,10"
        [System.Windows.Controls.DockPanel]::SetDock($top,"Top")
        $tc1=New-Object System.Windows.Controls.ColumnDefinition; $tc1.Width="Auto"
        $tc2=New-Object System.Windows.Controls.ColumnDefinition; $tc2.Width="*"
        $top.ColumnDefinitions.Add($tc1); $top.ColumnDefinitions.Add($tc2)
        $iconBd=New-Object System.Windows.Controls.Border
        $iconBd.Width=40; $iconBd.Height=40; $iconBd.CornerRadius=14; $iconBd.VerticalAlignment="Center"
        $iconBg= if($isActive){@(0x2A,0x24,0x18)}else{@(0x1A,0x18,0x14)}
        $iconBgLight=Get-LighterRgb $iconBg 0.28
        $iconBgBrush=New-Object System.Windows.Media.RadialGradientBrush
        $iconBgBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($iconBgLight[0],$iconBgLight[1],$iconBgLight[2]),0)))
        $iconBgBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromRgb($iconBg[0],$iconBg[1],$iconBg[2]),1)))
        $iconBd.Background=$iconBgBrush
        $iconVisual=New-CategoryIconVisual -GroupName $groupName -AccentRgb $accentColor -IsActive $true
        $iconVisual.Width=22; $iconVisual.Height=22
        $iconBd.Child=$iconVisual
        [System.Windows.Controls.Grid]::SetColumn($iconBd,0)
        $countBd=New-Object System.Windows.Controls.Border
        $countBd.CornerRadius="10"; $countBd.Padding="8,4"; $countBd.HorizontalAlignment="Right"; $countBd.VerticalAlignment="Center"
        $countBd.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x1C,0x18,0x12))
        $countTxt=New-Object System.Windows.Controls.TextBlock
        $countTxt.Text="$($counts.On)/$($counts.Total)"; $countTxt.FontSize=11; $countTxt.FontWeight="Bold"
        $countTxt.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xD6,0xB2,0x5A))
        $countBd.Child=$countTxt
        [System.Windows.Controls.Grid]::SetColumn($countBd,1)
        $Global:StageCountLabels[$groupName]=$countTxt
        $top.Children.Add($iconBd)|Out-Null; $top.Children.Add($countBd)|Out-Null
        $title=New-Object System.Windows.Controls.TextBlock
        $title.Text=$groupName; $title.FontSize=14; $title.FontWeight="Black"
        $title.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xF6,0xF1,0xE8))
        $desc=New-Object System.Windows.Controls.TextBlock
        $desc.Text=$catMeta.Desc; $desc.FontSize=11; $desc.TextWrapping="Wrap"; $desc.Margin="0,6,0,0"; $desc.MaxHeight=36
        $desc.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x8A,0x84,0x78))
        $open=New-Object System.Windows.Controls.TextBlock
        $open.Text="Open room  >"; $open.FontSize=11; $open.FontWeight="SemiBold"; $open.Margin="0,10,0,0"
        $open.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xD6,0xB2,0x5A))
        $body=New-Object System.Windows.Controls.StackPanel
        $body.Children.Add($title)|Out-Null; $body.Children.Add($desc)|Out-Null; $body.Children.Add($open)|Out-Null
        $root.Children.Add($top)|Out-Null; $root.Children.Add($body)|Out-Null
        $card.Child=$root
        $capturedGroup=$groupName
        $card.Add_MouseLeftButtonUp({ Show-CategoryDetail $capturedGroup }.GetNewClosure())
        $StagesPanel.Children.Add($card)|Out-Null
    }
}
function Show-CategoryDetail {
    param([string]$groupName)
    $Global:ActiveCategory=$groupName
    $CatOverlayTitle.Text=$groupName
    $catMeta=$Global:CategoryInfo | Where-Object { $_.Group -eq $groupName }
    $CatOverlayDesc.Text=$catMeta.Desc
    $CatOverlayItems.Children.Clear()
    $itemsInGroup=$Global:TweakInfo | Where-Object { $_.Group -eq $groupName }
    if($itemsInGroup){
        $summaryWrap=New-Object System.Windows.Controls.WrapPanel
        $summaryWrap.Margin="0,0,0,14"
        $tagGroups=$itemsInGroup | Group-Object Tag | Sort-Object Count -Descending
        foreach($tg in $tagGroups){
            if(-not $tg.Name -or -not $Global:TagMeta.ContainsKey($tg.Name)){continue}
            $tm=$Global:TagMeta[$tg.Name]
            $chip=New-Object System.Windows.Controls.Border
            $chip.CornerRadius="6"; $chip.Padding="7,3"; $chip.Margin="0,0,6,6"
            $chip.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Bg[0],$tm.Bg[1],$tm.Bg[2]))
            $chipTxt=New-Object System.Windows.Controls.TextBlock
            $chipTxt.Text="$($tg.Count) $($tm.Label)"; $chipTxt.FontSize=8.5; $chipTxt.FontWeight="Bold"
            $chipTxt.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Fg[0],$tm.Fg[1],$tm.Fg[2]))
            $chip.Child=$chipTxt
            $summaryWrap.Children.Add($chip)|Out-Null
        }
        $CatOverlayItems.Children.Add($summaryWrap)|Out-Null
    }
    foreach ($t in $itemsInGroup) {
        $key=$t.Key; $isOn=$Global:TweakToggles[$key]
        $row=New-Object System.Windows.Controls.Border
        $row.CornerRadius="12"; $row.BorderThickness="1"; $row.Margin="0,0,0,8"; $row.Padding="14,12"
        $row.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x14,0x16,0x1C))
        $row.BorderBrush=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x2A,0x2C,0x34))
        $grid=New-Object System.Windows.Controls.Grid
        $c1=New-Object System.Windows.Controls.ColumnDefinition; $c1.Width="*"
        $c2=New-Object System.Windows.Controls.ColumnDefinition; $c2.Width="Auto"; $c2.MinWidth=48
        $grid.ColumnDefinitions.Add($c1); $grid.ColumnDefinitions.Add($c2)
        $sp=New-Object System.Windows.Controls.StackPanel; [System.Windows.Controls.Grid]::SetColumn($sp,0)
        $sp.Margin="0,0,16,0"
        $headerGrid=New-Object System.Windows.Controls.Grid
        $h1=New-Object System.Windows.Controls.ColumnDefinition; $h1.Width="*"
        $h2=New-Object System.Windows.Controls.ColumnDefinition; $h2.Width="Auto"
        $headerGrid.ColumnDefinitions.Add($h1); $headerGrid.ColumnDefinitions.Add($h2)
        $title=New-Object System.Windows.Controls.TextBlock
        $title.Text=$t.Title; $title.FontSize=12; $title.FontWeight="SemiBold"; $title.TextWrapping="Wrap"; $title.VerticalAlignment="Center"
        $title.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xF4,0xEF,0xE4))
        [System.Windows.Controls.Grid]::SetColumn($title,0)
        $headerGrid.Children.Add($title)|Out-Null
        if($t.Tag -and $Global:TagMeta.ContainsKey($t.Tag)){
            $tm=$Global:TagMeta[$t.Tag]
            $badge=New-Object System.Windows.Controls.Border
            $badge.CornerRadius="6"; $badge.Padding="7,2"; $badge.Margin="10,0,0,0"; $badge.VerticalAlignment="Center"
            $badge.Background=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Bg[0],$tm.Bg[1],$tm.Bg[2]))
            $badgeTxt=New-Object System.Windows.Controls.TextBlock
            $badgeTxt.Text=$tm.Label; $badgeTxt.FontSize=8; $badgeTxt.FontWeight="Bold"
            $badgeTxt.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb($tm.Fg[0],$tm.Fg[1],$tm.Fg[2]))
            $badge.Child=$badgeTxt
            [System.Windows.Controls.Grid]::SetColumn($badge,1)
            $headerGrid.Children.Add($badge)|Out-Null
        }
        $desc=New-Object System.Windows.Controls.TextBlock
        $desc.Text=$t.Desc; $desc.FontSize=10; $desc.TextWrapping="Wrap"; $desc.Margin="0,5,0,0"
        $desc.Foreground=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x8A,0x84,0x78))
        $sp.Children.Add($headerGrid)|Out-Null; $sp.Children.Add($desc)|Out-Null
        $cb=New-Object System.Windows.Controls.CheckBox
        $cb.Style=$window.Resources["ToggleStyle"]; $cb.IsChecked=$isOn
        $cb.VerticalAlignment="Center"; $cb.HorizontalAlignment="Right"; $cb.MinWidth=44
        [System.Windows.Controls.Grid]::SetColumn($cb,1)
        $capturedKey=$key
        $cb.Add_Checked({$Global:TweakToggles[$capturedKey]=$true; Update-EnabledBadge; Update-PresetGlowConsistency; Save-TweakState}.GetNewClosure())
        $cb.Add_Unchecked({$Global:TweakToggles[$capturedKey]=$false; Update-EnabledBadge; Update-PresetGlowConsistency; Save-TweakState}.GetNewClosure())
        $Global:StageCBs[$key]=$cb
        $grid.Children.Add($sp)|Out-Null; $grid.Children.Add($cb)|Out-Null; $row.Child=$grid
        $CatOverlayItems.Children.Add($row)|Out-Null
    }
    $CategoryOverlay.Visibility="Visible"
    if($CatOverlayClipGeom -and $CategoryOverlay.ActualWidth -gt 2 -and $CategoryOverlay.ActualHeight -gt 2){
        $CatOverlayClipGeom.Rect=[System.Windows.Rect]::new(0,0,$CategoryOverlay.ActualWidth,$CategoryOverlay.ActualHeight)
    }
    $searchTxt= if($SearchBox){ $SearchBox.Text.Trim() } else { "" }
    Build-StageCards -filter $searchTxt
}
function Close-CategoryDetail {
    $CategoryOverlay.Visibility="Collapsed"
    $Global:ActiveCategory=$null
    $searchTxt= if($SearchBox){ $SearchBox.Text.Trim() } else { "" }
    Build-StageCards -filter $searchTxt
}
function Set-PresetGlow {
    param($Border,[bool]$Selected,[string]$AccentColor,[string]$DefaultColor="#2A2C34")
    if(-not $Border){ return }
    $bc = New-Object System.Windows.Media.BrushConverter
    if($Selected){
        $accent = $bc.ConvertFromString($AccentColor)
        $Border.BorderBrush = $accent
        $Border.BorderThickness = [System.Windows.Thickness]::new(1.6)
        if(-not ($Border.Effect -is [System.Windows.Media.Effects.DropShadowEffect])){
            $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
            $glow.Color = $accent.Color; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0
            $Border.Effect = $glow
        }
        $Border.Effect.Color = $accent.Color
        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
        $anim.To = 0.85; $anim.Duration = [TimeSpan]::FromMilliseconds(200)
        $Border.Effect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty,$anim)
    } else {
        $Border.BorderBrush = $bc.ConvertFromString($DefaultColor)
        $Border.BorderThickness = [System.Windows.Thickness]::new(1)
        if($Border.Effect -is [System.Windows.Media.Effects.DropShadowEffect]){
            $glowEffect = $Border.Effect
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.To = 0; $anim.Duration = [TimeSpan]::FromMilliseconds(160)
            $capturedBorder = $Border
            $anim.Add_Completed({ $capturedBorder.Effect = $null }.GetNewClosure())
            $glowEffect.BeginAnimation([System.Windows.Media.Effects.DropShadowEffect]::OpacityProperty,$anim)
        }
    }
}
function Set-NetPresetGlow {
    param([string]$Selected)
    if(-not $NetPresetLan -or -not $NetPresetWifi){ return }
    $lanBd = $NetPresetLan.Template.FindName("Bd",$NetPresetLan)
    $wifiBd = $NetPresetWifi.Template.FindName("Bd",$NetPresetWifi)
    Set-PresetGlow -Border $lanBd  -Selected ($Selected -eq "LAN NETWORK")   -AccentColor "#38BDF8"
    Set-PresetGlow -Border $wifiBd -Selected ($Selected -eq "WI-FI NETWORK") -AccentColor "#2DD4BF"
}
function Set-GpuPresetGlow {
    param([string]$Selected)
    if(-not $GpuPresetAmd -or -not $GpuPresetNvidia){ return }
    $amdBd = $GpuPresetAmd.Template.FindName("Bd",$GpuPresetAmd)
    $nvBd  = $GpuPresetNvidia.Template.FindName("Bd",$GpuPresetNvidia)
    Set-PresetGlow -Border $amdBd -Selected ($Selected -eq "AMD")    -AccentColor "#ED1C24"
    Set-PresetGlow -Border $nvBd  -Selected ($Selected -eq "NVIDIA") -AccentColor "#76B900"
}
function Set-SelectAllGlow {
    param([bool]$Active)
    if(-not $BtnPresetAllExceptGpuLan){ return }
    $bd = $BtnPresetAllExceptGpuLan.Template.FindName("Bd",$BtnPresetAllExceptGpuLan)
    Set-PresetGlow -Border $bd -Selected $Active -AccentColor "#D4AF5A"
}
function Update-PresetGlowConsistency {
    # Re-checks whether the actual tweak toggle state still matches each preset, and dims
    # the glow on any preset button whose selection no longer reflects reality (e.g. the
    # user manually flipped a checkbox that the preset had set).
    if($Global:ActiveNetPreset){
        $type=$Global:ActiveNetPreset
        $other="WI-FI NETWORK"; if($type -eq "WI-FI NETWORK"){ $other="LAN NETWORK" }
        $match=$true
        foreach($t in $Global:TweakInfo){
            # Only invalidate if a tweak in the ACTIVE group is turned OFF.
            # We no longer invalidate just because a tweak in the OTHER group is turned ON (by Queen Project).
            if($t.Group -eq $type -and -not $Global:TweakToggles[$t.Key]){ $match=$false; break }
        }
        if($match){ Set-NetPresetGlow -Selected $type } else { Set-NetPresetGlow -Selected $null }
    } else { Set-NetPresetGlow -Selected $null }
    if($Global:ActiveGpuPreset){
        $vendor=$Global:ActiveGpuPreset
        $mine="AMD GPU"; $other="NVIDIA GPU"; if($vendor -eq "NVIDIA"){ $mine="NVIDIA GPU"; $other="AMD GPU" }
        $match=$true
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $mine -and -not $Global:TweakToggles[$t.Key]){ $match=$false }
            elseif($t.Group -eq $other -and $Global:TweakToggles[$t.Key]){ $match=$false }
        }
        if($match){ Set-GpuPresetGlow -Selected $vendor } else { Set-GpuPresetGlow -Selected $null }
    } else { Set-GpuPresetGlow -Selected $null }
    # Queen Project Glow: Only check keys that ARE in the recommended list.
    # If all recommended keys are true, the glow stays on, regardless of other selections.
    $match=$true
    foreach($key in $Global:RecommendedFiveMBalancedKeys){
        if(-not $Global:TweakToggles[$key]){ $match=$false; break }
    }
    Set-SelectAllGlow -Active $match
}
function Set-NetPreset {
    param([ValidateSet("LAN NETWORK","WI-FI NETWORK")][string]$Type)
    $other= if($Type -eq "LAN NETWORK"){"WI-FI NETWORK"}else{"LAN NETWORK"}
    
    # Toggle Logic: If clicking the already active preset, turn it OFF.
    if($Global:ActiveNetPreset -eq $Type){
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $Type){ $Global:TweakToggles[$t.Key]=$false }
        }
        $Global:ActiveNetPreset = $null
        Add-Log "Network preset: Deselected" "#9B7EBD"
    } else {
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $Type){ $Global:TweakToggles[$t.Key]=$true }
            elseif($t.Group -eq $other){ 
                # Only turn off if it's NOT part of the Recommended FiveM keys to avoid conflict
                if($Global:RecommendedFiveMBalancedKeys -notcontains $t.Key){
                    $Global:TweakToggles[$t.Key]=$false 
                }
            }
        }
        $Global:ActiveNetPreset = $Type
        $label= if($Type -eq "LAN NETWORK"){"LAN (wired)"}else{"Wi-Fi"}
        Add-Log "Network preset: $label tweaks enabled" "#9B7EBD"
    }
    
    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory -eq "LAN NETWORK" -or $Global:ActiveCategory -eq "WI-FI NETWORK"){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
}
function Set-GpuPreset {
    param([ValidateSet("AMD","NVIDIA")][string]$Vendor)
    $mine= if($Vendor -eq "AMD"){"AMD GPU"}else{"NVIDIA GPU"}
    $other= if($Vendor -eq "AMD"){"NVIDIA GPU"}else{"AMD GPU"}

    # Toggle Logic: If clicking the already active preset, turn it OFF.
    if($Global:ActiveGpuPreset -eq $Vendor){
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $mine){ $Global:TweakToggles[$t.Key]=$false }
        }
        $Global:ActiveGpuPreset = $null
        Add-Log "GPU preset: Deselected" "#9B7EBD"
    } else {
        $Global:DetectedGpuVendor=$Vendor
        foreach($t in $Global:TweakInfo){
            if($t.Group -eq $mine){ $Global:TweakToggles[$t.Key]=$true }
            elseif($t.Group -eq $other){ $Global:TweakToggles[$t.Key]=$false }
        }
        $Global:ActiveGpuPreset = $Vendor
        Add-Log "GPU preset: $Vendor tweaks enabled" "#9B7EBD"
    }

    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory -eq "AMD GPU" -or $Global:ActiveCategory -eq "NVIDIA GPU"){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
}
$GpuPresetAmd.Add_Click({ Set-GpuPreset -Vendor "AMD" })
$GpuPresetNvidia.Add_Click({ Set-GpuPreset -Vendor "NVIDIA" })
function Set-PresetAllExceptGpuLan {
    # Queen Project Preset: Selects all core performance tweaks.
    # Toggle Logic: If all recommended keys are already TRUE, turn them all OFF.
    $allActive = $true
    foreach($key in $Global:RecommendedFiveMBalancedKeys){
        if(-not $Global:TweakToggles[$key]){ $allActive = $false; break }
    }

    if($allActive){
        foreach($key in $Global:RecommendedFiveMBalancedKeys){
            $Global:TweakToggles[$key] = $false
        }
        Add-Log "Queen Project preset: Deselected" "#9B7EBD"
    } else {
        # Store current network selection before applying Queen Project
        $prevNet = $Global:ActiveNetPreset
        
        foreach($key in $Global:RecommendedFiveMBalancedKeys){
            $Global:TweakToggles[$key] = $true
        }
        
        # Restore network selection if it was active
        if($prevNet){
            foreach($t in $Global:TweakInfo){
                if($t.Group -eq $prevNet){ $Global:TweakToggles[$t.Key]=$true }
            }
            $Global:ActiveNetPreset = $prevNet
        }
        
        Add-Log "Queen Project preset: Applied" "#9B7EBD"
    }

    Update-PresetGlowConsistency
    Build-StageCards
    if($Global:ActiveCategory){ Show-CategoryDetail $Global:ActiveCategory }
    Save-TweakState
}
$BtnPresetAllExceptGpuLan.Add_Click({ Set-PresetAllExceptGpuLan })
function Update-EnabledBadge {
    if(-not $Global:StageCountLabels){ return }
    foreach($groupName in @($Global:StageCountLabels.Keys)){
        $lbl=$Global:StageCountLabels[$groupName]
        if(-not $lbl){ continue }
        $counts=Get-GroupToggleCount $groupName
        $lbl.Text="$($counts.On)/$($counts.Total)"
    }
}
Build-StageCards; Update-EnabledBadge
$CatOverlayCloseX.Add_Click({ Close-CategoryDetail })
$CatOverlayCloseBtn.Add_Click({ Close-CategoryDetail })
$SearchBox.Add_TextChanged({
    $txt=$SearchBox.Text.Trim()
    $SearchPH.Visibility=if($txt -eq ""){"Visible"}else{"Collapsed"}
    Build-StageCards -filter $txt
})
$BtnTaskMgr.Add_Click({Start-Process "taskmgr.exe" -EA SilentlyContinue})
$NetPresetLan.Add_Click({ Set-NetPreset -Type "LAN NETWORK" })
$NetPresetWifi.Add_Click({ Set-NetPreset -Type "WI-FI NETWORK" })
$BtnGpedit.Add_Click({Start-Process "gpedit.msc" -EA SilentlyContinue})
$BtnClean.Add_Click({Start-Process "explorer.exe" -ArgumentList "`"$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell`"" -EA SilentlyContinue})
$BtnNetTwakes.Add_Click({
    Add-Log "Net Twakes is disabled: the previous implementation downloaded and executed unverified remote code." "#F59E0B"
    [System.Windows.MessageBox]::Show("This shortcut is disabled for safety because it previously downloaded and executed code from the internet. Use a reviewed local script instead.", "Net Twakes", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
})
$BtnExit.Add_Click({$window.Close()})
function Set-RegValue{
    param($Path,$Name,$Value,$Type="DWord")
    try{
        if(-not(Test-Path $Path)){New-Item -Path $Path -Force|Out-Null}
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -EA Stop
        # Verify the write
        $check = (Get-ItemProperty -Path $Path -Name $Name -EA SilentlyContinue).$Name
        if($null -ne $check -and $check.ToString() -eq $Value.ToString()){ return $true }
        return $false
    }catch{return $false}
}
function Get-RegValue{param($Path,$Name);try{return(Get-ItemProperty -Path $Path -Name $Name -EA Stop).$Name}catch{return $null}}
function Save-Orig{param($key,$path,$name);if(-not $Global:Orig.ContainsKey($key)){$Global:Orig[$key]=@{Path=$path;Name=$name;Value=(Get-RegValue $path $name)}}}
# Several tweaks are exposed as two separate UI toggles (e.g. a LAN and a Wi-Fi checkbox, or an
# NVIDIA and an AMD checkbox) but actually change one machine-wide, non-adapter-specific setting.
# If both toggles are active at once this helper makes sure the underlying change/log only happens
# once, while still marking whichever toggle key triggered the call as applied (so restore/undo
# and the on-screen "OK" status stay consistent no matter which of the two checkboxes was used).
function Invoke-DedupedGlobalTweak{
    param([string]$BaseKey, $ToggleKey, [scriptblock]$Action)
    if(-not $Global:AppliedKeys[$BaseKey]){
        & $Action
        $Global:AppliedKeys[$BaseKey]=$true
    } else {
        Add-Log "Already applied via the other toggle sharing this setting - skipped duplicate write" "#6B7280"
    }
    if($ToggleKey -and $ToggleKey -ne $BaseKey){ $Global:AppliedKeys[$ToggleKey]=$true }
}
function Save-OrigService{
    param($key,[string]$serviceName)
    if($Global:OrigServices.ContainsKey($key)){return}
    try{
        $svc=Get-Service -Name $serviceName -EA Stop
        $startType=(Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -EA SilentlyContinue).StartMode
        $Global:OrigServices[$key]=@{ServiceName=$serviceName;Status=$svc.Status.ToString();StartType=$startType}
    } catch { $Global:OrigServices[$key]=@{ServiceName=$serviceName;Status=$null;StartType=$null} }
}
$Global:IsCancelled=$false
function Update-Progress{
    param([int]$done,[int]$total)
    $window.Dispatcher.Invoke([Action]{
        if($total -gt 0){
            $pct=[math]::Round(($done/$total)*100)
            $ProgressPct.Text="$pct%"
            $maxW=$ProgressFill.Parent.ActualWidth; if($maxW -le 0){$maxW=242}
            $ProgressFill.Width=[math]::Max(0,($pct/100.0)*$maxW)
        }
    })
    # Pump the dispatcher to keep UI responsive during long-running tweaks
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
}
function Set-StatusRunning{$window.Dispatcher.Invoke([Action]{$StatusText.Text="RUNNING";$StatusDotE.Fill=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0xF5,0x9E,0x0B));$BtnRun.IsEnabled=$false})}
function Set-StatusDone{$window.Dispatcher.Invoke([Action]{$StatusText.Text="DONE";$StatusDotE.Fill=[System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(0x10,0xB9,0x81));$BtnRun.IsEnabled=$true})}
function Set-CurrentTask{param([string]$msg);$window.Dispatcher.Invoke([Action]{$CurrentTask.Text=$msg})}

function Run-NetThrottle{
    param($ToggleKey)
    Set-CurrentTask "Network Throttling -> Absolute Max"
    Invoke-DedupedGlobalTweak "NetThrottle" $ToggleKey {
        $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        Save-Orig "NetThrottle" $p "NetworkThrottlingIndex"
        $s1 = Set-RegValue $p "NetworkThrottlingIndex" 0xFFFFFFFF
        $s2 = Set-RegValue $p "SystemResponsiveness" 0
        if($s1 -and $s2){ Add-Log "Network throttling disabled" "#9B7EBD" }
        else { Add-Log "Network throttling tweak partially failed" "#EF4444" }
    }
}
function Run-BcdTimer{Set-CurrentTask "BCD Timer Tweaks";try{bcdedit /set useplatformtick yes 2>&1|Out-Null;bcdedit /set disabledynamictick yes 2>&1|Out-Null;Add-Log "BCD timer tweaks applied (reboot)" "#9B7EBD";$Global:AppliedKeys["BcdTimer"]=$true}catch{Add-Log "BCD tweaks skipped" "#EF4444"}}
function Run-TcpGlobal{param($ToggleKey);Set-CurrentTask "TCP Global Stack Overhaul";try{Invoke-DedupedGlobalTweak "TcpGlobal" $ToggleKey {netsh int tcp set global autotuninglevel=normal rss=enabled ecncapability=enabled fastopen=enabled congestionprovider=ctcp 2>&1|Out-Null;Add-Log "TCP global stack optimized" "#9B7EBD"}}catch{Add-Log "TCP global failed" "#EF4444"}}
function Run-KbQueue{Set-CurrentTask "Keyboard Queue Size -> 10";$p="HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters";Save-Orig "KbQueue" $p "KeyboardDataQueueSize";Set-RegValue $p "KeyboardDataQueueSize" 10|Out-Null;Add-Log "Keyboard queue -> 10" "#9B7EBD";$Global:AppliedKeys["KbQueue"]=$true}
function Run-NduDisable{param($ToggleKey);Set-CurrentTask "Ndu Driver -> Disabled";Invoke-DedupedGlobalTweak "NduDisable" $ToggleKey {$p="HKLM:\SYSTEM\CurrentControlSet\Services\Ndu";Save-Orig "NduDisable" $p "Start";Set-RegValue $p "Start" 4|Out-Null;Add-Log "Ndu driver disabled" "#9B7EBD"}}
function Run-GamingMemory{Set-CurrentTask "Gaming Memory Mode";try{Save-OrigService "GamingMemory" "SysMain";Stop-Service SysMain -Force -EA SilentlyContinue;Set-Service SysMain -StartupType Disabled -EA SilentlyContinue;Add-Log "Gaming memory mode enabled" "#9B7EBD";$Global:AppliedKeys["GamingMemory"]=$true}catch{Add-Log "Gaming memory partial" "#F59E0B"}}
function Run-FiveMBooster{Set-CurrentTask "FiveM Booster";$p=Get-Process -Name "FiveM*" -EA Ignore|Select -First 1;if($p){$p.PriorityClass="High";Add-Log "FiveM boosted to High priority" "#9B7EBD"}else{Add-Log "FiveM not running - skipped" "#F59E0B"};$Global:AppliedKeys["FiveMBooster"]=$true}

function Run-FiveMPerfOptions{
    Set-CurrentTask "FiveM_GTAProcess.exe -> CpuPriorityClass 3 (IFEO)"
    $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\FiveM_GTAProcess.exe\PerfOptions"
    Save-Orig "GM_FiveMPerfOptions" $p "CpuPriorityClass"
    Set-RegValue $p "CpuPriorityClass" 6|Out-Null
    Add-Log "FiveM_GTAProcess.exe CpuPriorityClass set to 6 (AboveNormal) via IFEO" "#9B7EBD"
    $Global:AppliedKeys["GM_FiveMPerfOptions"]=$true
}
function Run-FiveMCoreAffinity{
    Set-CurrentTask "FiveM Core Affinity -> Auto-Optimized"
    try{
        $logical=[Environment]::ProcessorCount
        if($logical -le 2){
            Add-Log "Only $logical logical cores detected - skipping affinity change (not enough cores to spare)" "#F59E0B"
            $Global:AppliedKeys["GM_FiveMCoreAffinity"]=$true
            return
        }
        # Leave core 0 free for system/interrupt work, cap usable cores around 5-6 to avoid cross-core migration overhead
        $maxCores=[Math]::Min($logical-1,6)
        $mask=0
        for($i=1;$i -le $maxCores;$i++){ $mask=$mask -bor (1 -shl $i) }
        $procs=Get-Process -Name "FiveM_GTAProcess","FiveM" -EA Ignore
        if($procs){
            foreach($proc in $procs){
                try{ $proc.ProcessorAffinity=[IntPtr]$mask; Add-Log "$($proc.ProcessName) affinity set to cores 1-$maxCores (mask 0x$($mask.ToString('X')))" "#9B7EBD" }catch{ Add-Log "Could not set affinity for $($proc.ProcessName): $_" "#EF4444" }
            }
        } else {
            Add-Log "FiveM not running yet - will auto-apply as soon as it starts (watching for 10 min)" "#F59E0B"
            $affinityJob = Start-Job -ScriptBlock {
                param($mask)
                $deadline=(Get-Date).AddMinutes(10)
                while((Get-Date) -lt $deadline){
                    $proc=Get-Process -Name "FiveM_GTAProcess","FiveM" -EA Ignore|Select -First 1
                    if($proc){ try{ $proc.ProcessorAffinity=[IntPtr]$mask }catch{}; break }
                    Start-Sleep -Seconds 5
                }
            } -ArgumentList $mask
            # Track it so we can stop/reap it on app exit instead of leaving an orphaned job running.
            if(-not $Global:BackgroundJobs){ $Global:BackgroundJobs=@() }
            $Global:BackgroundJobs += $affinityJob
        }
        $Global:AppliedKeys["GM_FiveMCoreAffinity"]=$true
    } catch { Add-Log "FiveM core affinity error: $_" "#EF4444" }
}
function Run-KillerFix{
    Set-CurrentTask "Killer NIC Traffic Analysis -> Disabled"
    try{
        # Only ever touch user-mode "smart traffic" services (Win32OwnProcess/Win32ShareProcess),
        # never a Kernel/FileSystem driver - that keeps the actual NIC driver completely untouched
        # so the adapter itself can never be broken by this tweak.
        $killerSvcs=Get-CimInstance Win32_Service -Filter "Name LIKE '%Killer%'" -EA SilentlyContinue | Where-Object { $_.ServiceType -notmatch "Kernel|FileSystem" }
        if($killerSvcs){
            foreach($svc in $killerSvcs){
                Save-OrigService "NET_KillerFix_$($svc.Name)" $svc.Name
                Stop-Service -Name $svc.Name -Force -EA SilentlyContinue
                Set-Service -Name $svc.Name -StartupType Disabled -EA SilentlyContinue
                Add-Log "Killer service disabled: $($svc.DisplayName)" "#9B7EBD"
            }
        } else {
            Add-Log "No Killer NIC detected - skipped" "#6B7280"
        }
        $Global:AppliedKeys["NET_KillerFix"]=$true
    } catch { Add-Log "Killer NIC check failed: $_" "#EF4444" }
}
function Run-FiveMQos{
    Set-CurrentTask "FiveM Traffic -> QoS Priority Tag"
    try{
        # Windows only applies DSCP tagging on domain networks by default - this flips that on
        # for home/private networks too. It only permits tagging, it never blocks or throttles.
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
        Save-Orig "NET_FiveMQos_NLA" $p "DoNotUseNLA"
        Set-RegValue $p "DoNotUseNLA" 1|Out-Null

        $created=@()
        foreach($procName in @("FiveM.exe","FiveM_GTAProcess.exe")){
            $polName="QueenProject FiveM Priority - $procName"
            try{
                Get-NetQosPolicy -Name $polName -EA SilentlyContinue | Remove-NetQosPolicy -Confirm:$false -EA SilentlyContinue
                New-NetQosPolicy -Name $polName -AppPathNameMatchCondition $procName -DSCPAction 46 -NetworkProfile All -EA Stop | Out-Null
                $created+=$polName
                Add-Log "QoS priority tag applied: $procName" "#9B7EBD"
            } catch { Add-Log "QoS policy for $procName skipped: $_" "#F59E0B" }
        }
        if($created.Count -gt 0){ $Global:OrigMisc["NET_FiveMQos_Policies"]=$created }
        $Global:AppliedKeys["NET_FiveMQos"]=$true
    } catch { Add-Log "FiveM QoS setup failed: $_" "#EF4444" }
}
function Run-FiveMFirewall{
    Set-CurrentTask "FiveM -> Explicit Firewall Allow Rule"
    try{
        $procs=Get-Process -Name "FiveM","FiveM_GTAProcess" -EA Ignore | Where-Object { $_.Path }
        if(-not $procs){
            Add-Log "FiveM not running - firewall rule skipped" "#F59E0B"
            $Global:AppliedKeys["NET_FiveMFirewall"]=$true
            return
        }
        $created=@()
        $seenPaths=@{}
        foreach($proc in $procs){
            $path=$proc.Path
            if(-not $path -or $seenPaths.ContainsKey($path)){ continue }
            $seenPaths[$path]=$true
            $ruleName="QueenProject - FiveM Allow ($($proc.ProcessName))"
            if(-not (Get-NetFirewallRule -DisplayName $ruleName -EA SilentlyContinue)){
                try{
                    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Program $path -Profile Any -EA Stop | Out-Null
                    New-NetFirewallRule -DisplayName "$ruleName (Out)" -Direction Outbound -Action Allow -Program $path -Profile Any -EA Stop | Out-Null
                    $created+=$ruleName; $created+="$ruleName (Out)"
                    Add-Log "Firewall allow rule added: $($proc.ProcessName)" "#9B7EBD"
                } catch { Add-Log "Firewall rule for $($proc.ProcessName) skipped: $_" "#F59E0B" }
            }
        }
        if($created.Count -gt 0){ $Global:OrigMisc["NET_FiveMFirewall_Rules"]=$created }
        $Global:AppliedKeys["NET_FiveMFirewall"]=$true
    } catch { Add-Log "FiveM firewall rule failed: $_" "#EF4444" }
}
function Run-DriverHealth{Set-CurrentTask "Driver Health Check";try{$bad=Get-CimInstance Win32_PnPEntity -EA SilentlyContinue|Where-Object{$_.ConfigManagerErrorCode -ne 0};if($bad){foreach($d in $bad){Add-Log "Problem: $($d.Name)" "#EF4444"}}else{Add-Log "All drivers OK" "#10B981"};$Global:AppliedKeys["DriverHealth"]=$true}catch{Add-Log "Driver check skipped" "#F59E0B"}}
function Run-LanOptimize{Set-CurrentTask "LAN Optimization";try{netsh int tcp set global autotuninglevel=normal 2>&1|Out-Null;Add-Log "LAN optimized" "#9B7EBD";$Global:AppliedKeys["LanOptimize"]=$true}catch{Add-Log "LAN optimize failed" "#EF4444"}}
function Run-WifiOptimize{Set-CurrentTask "Wi-Fi Optimization";try{$wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1;if($wa){Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Preferred Band" -DisplayValue "Prefer 5GHz band" -EA SilentlyContinue};Add-Log "Wi-Fi optimized" "#9B7EBD";$Global:AppliedKeys["WifiOptimize"]=$true}catch{Add-Log "Wi-Fi optimize skipped" "#F59E0B"}}
function Run-LanJumboFrame{
    Set-CurrentTask "Jumbo Frame -> 9014 Bytes"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Jumbo Packet" -DisplayValue "9014 Bytes" -EA SilentlyContinue
            $count++
        }
        Add-Log "Jumbo frame requested on $count wired adapter(s) (skipped if unsupported)" "#9B7EBD"
        $Global:AppliedKeys["NET_LanJumboFrame"]=$true
    } catch { Add-Log "Jumbo frame tweak skipped" "#F59E0B" }
}
function Run-LanInterruptModeration{
    Set-CurrentTask "Interrupt Moderation -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -EA SilentlyContinue
            $count++
        }
        Add-Log "Interrupt moderation disabled on $count wired adapter(s)" "#9B7EBD"
        $Global:AppliedKeys["NET_LanInterruptModeration"]=$true
    } catch { Add-Log "Interrupt moderation tweak skipped" "#F59E0B" }
}
function Run-WifiPowerSaveMode{
    Set-CurrentTask "802.11 Power Saving -> Disabled"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Power Saving Mode" -DisplayValue "Disabled" -EA SilentlyContinue
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "802.11n/ac Power Save Mode" -DisplayValue "Off" -EA SilentlyContinue
            Add-Log "Wi-Fi power saving disabled" "#9B7EBD"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_WifiPowerSaveMode"]=$true
    } catch { Add-Log "Wi-Fi power save tweak skipped" "#F59E0B" }
}
function Run-WifiRoamingAggressiveness{
    Set-CurrentTask "Roaming Aggressiveness -> Lowest"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-NetAdapterAdvancedProperty -Name $wa.Name -DisplayName "Roaming Aggressiveness" -DisplayValue "Lowest" -EA SilentlyContinue
            Add-Log "Wi-Fi roaming aggressiveness set to lowest" "#9B7EBD"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_WifiRoamingAggressiveness"]=$true
    } catch { Add-Log "Wi-Fi roaming tweak skipped" "#F59E0B" }
}
function Run-DnsFastLan{
    Set-CurrentTask "DNS -> Google"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-DnsClientServerAddress -InterfaceIndex $a.IfIndex -ServerAddresses ("8.8.4.4","8.8.8.8") -EA SilentlyContinue
            $count++
        }
        if($count -gt 0){ Add-Log "DNS set to 8.8.4.4 / 8.8.8.8 on $count wired adapter(s)" "#9B7EBD" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_DnsFast"]=$true
    } catch { Add-Log "DNS tweak (LAN) skipped" "#F59E0B" }
}
function Run-DeliveryOptOff{
    Set-CurrentTask "Delivery Optimization (P2P Updates) -> Off"
    try{
        $p="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
        Save-Orig "NET_DeliveryOptOff" $p "DODownloadMode"
        Set-RegValue $p "DODownloadMode" 0|Out-Null
        try{ Set-Service dosvc -StartupType Manual -EA SilentlyContinue }catch{}
        Add-Log "Delivery Optimization P2P sharing disabled" "#9B7EBD"
        $Global:AppliedKeys["NET_DeliveryOptOff"]=$true
    } catch { Add-Log "Delivery Optimization tweak failed" "#EF4444" }
}
function Run-DnsCacheAggressive{
    Set-CurrentTask "DNS Client Cache -> Aggressive"
    try{
        $p="HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
        Save-Orig "NET_DnsCacheAggressive_MaxTtl" $p "MaxCacheTtl"
        Save-Orig "NET_DnsCacheAggressive_NegTtl" $p "MaxNegativeCacheTtl"
        Set-RegValue $p "MaxCacheTtl" 86400|Out-Null
        Set-RegValue $p "MaxNegativeCacheTtl" 5|Out-Null
        try{ Restart-Service dnscache -Force -EA SilentlyContinue }catch{}
        Add-Log "DNS client cache set to hold entries longer" "#9B7EBD"
        $Global:AppliedKeys["NET_DnsCacheAggressive"]=$true
    } catch { Add-Log "DNS cache tweak failed" "#EF4444" }
}
function Run-BottleneckCheck{
    Set-CurrentTask "CPU/GPU Bottleneck Check"
    try{
        # NOTE: previously used -SampleInterval 1 -MaxSamples 3 on BOTH counters, which
        # blocks this single-threaded UI for ~6 real seconds every run (2 x 3s), long enough
        # for Windows to flag the window as "Not Responding" and paint the ghost/frozen
        # overlay - no clicks register during that window. A single instantaneous sample
        # keeps this fast/non-blocking; it's already labeled as a rough snapshot, not a
        # precise reading, so losing the 3-sample average doesn't change its usefulness.
        $cpuSamples=(Get-Counter '\Processor(_Total)\% Processor Time' -MaxSamples 1 -EA SilentlyContinue).CounterSamples
        $gpuSamples=(Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -MaxSamples 1 -EA SilentlyContinue).CounterSamples
        $cpuAvg= if($cpuSamples){[math]::Round(($cpuSamples|Measure-Object CookedValue -Average).Average,1)}else{$null}
        $gpuAvg= if($gpuSamples){[math]::Round(($gpuSamples|Measure-Object CookedValue -Average).Average,1)}else{$null}
        if($null -ne $cpuAvg -and $null -ne $gpuAvg){
            $verdict= if($cpuAvg -gt ($gpuAvg+15)){"CPU is more loaded right now"} elseif($gpuAvg -gt ($cpuAvg+15)){"GPU is more loaded right now"} else {"CPU and GPU load are close"}
            Add-Log "CPU: $cpuAvg% | GPU: $gpuAvg% - $verdict" "#9B7EBD"
            Add-Log "This is a single instant snapshot, not in-game data - use RTSS/Afterburner while playing for a real reading" "#6B7280"
        } else { Add-Log "Bottleneck check: counters unavailable on this system - skipped" "#6B7280" }
        $Global:AppliedKeys["SYS_BottleneckCheck"]=$true
    } catch { Add-Log "Bottleneck check skipped (counters unavailable)" "#F59E0B" }
}
function Run-ClearShaderCache{
    Set-CurrentTask "Clear Shader Cache (NVIDIA/AMD)"
    try{
        $found=0
        $paths=@(
            "$env:LOCALAPPDATA\NVIDIA\DXCache","$env:LOCALAPPDATA\NVIDIA\GLCache","$env:LOCALAPPDATA\NVIDIA Corporation\NV_Cache",
            "$env:LOCALAPPDATA\AMD\DxCache","$env:LOCALAPPDATA\AMD\DxcCache","$env:LOCALAPPDATA\AMD\GLCache","$env:LOCALAPPDATA\AMD\VkCache"
        )
        foreach($p in $paths){
            if(Test-Path $p){
                # Remove-Item with a wildcard handles its own recursion internally instead of
                # building a full Get-ChildItem object list and piping it item-by-item, which is
                # much faster on large caches and keeps this from blocking the UI thread as long.
                Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
                $found++
            }
        }
        if($found -gt 0){ Add-Log "Shader cache cleared ($found folder(s) found)" "#9B7EBD" } else { Add-Log "No NVIDIA/AMD shader cache folders found - skipped" "#6B7280" }
        $Global:AppliedKeys["GPU_ClearShaderCache"]=$true
    } catch { Add-Log "Shader cache clear skipped (files in use)" "#F59E0B" }
}
function Run-ClearTempJunk{
    Set-CurrentTask "Clear Temp & Junk Files"
    try{
        $paths=@($env:TEMP,"$env:WINDIR\Temp")
        $touched=0
        foreach($p in $paths){
            if(Test-Path $p){
                # See Run-ClearShaderCache note: wildcard Remove-Item avoids the slow
                # Get-ChildItem + per-item pipeline pattern, which matters a lot here since
                # TEMP folders can accumulate tens of thousands of files over time.
                Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
                $touched++
            }
        }
        Add-Log "Temp/junk files cleared from $touched location(s) (locked files skipped)" "#9B7EBD"
        $Global:AppliedKeys["CLEAN_ClearTempJunk"]=$true
    } catch { Add-Log "Temp cleanup partial - some files in use" "#F59E0B" }
}
function Run-ClearFiveMCache{
    Set-CurrentTask "Clear FiveM Cache"
    try{
        $p="$env:LOCALAPPDATA\FiveM\FiveM.app\data\cache"
        if(Test-Path $p){
            Remove-Item -Path "$p\*" -Force -Recurse -EA SilentlyContinue
            Add-Log "FiveM cache cleared" "#9B7EBD"
        } else { Add-Log "FiveM cache folder not found - skipped" "#6B7280" }
        $Global:AppliedKeys["CLEAN_ClearFiveMCache"]=$true
    } catch { Add-Log "FiveM cache clear skipped (files in use)" "#F59E0B" }
}
function Run-RemoveBloat{
    Set-CurrentTask "Remove Unnecessary Pre-Installed Apps"
    $bloatList=$Global:BloatList
    $removed=0; $skipped=0; $removedNames=@()
    # One enumeration of all installed packages instead of calling Get-AppxPackage once per
    # name in $bloatList (~30 separate full-repository queries) - much faster, same result.
    $allPkgs = @(Get-AppxPackage -EA SilentlyContinue)
    foreach($name in $bloatList){
        try{
            $pkgs=$allPkgs | Where-Object { $_.Name -eq $name }
            if($pkgs){
                $pkgs | Remove-AppxPackage -EA SilentlyContinue
                $removed++; $removedNames+=$name
            } else { $skipped++ }
        } catch { $skipped++ }
    }
    if($removedNames.Count -gt 0){ $Global:OrigMisc["CLEAN_RemoveBloat"]=$removedNames }
    Add-Log "Pre-installed app cleanup: $removed app(s) removed, $skipped not found/skipped" "#9B7EBD"
    $Global:AppliedKeys["CLEAN_RemoveBloat"]=$true
}
function Run-KillBackgroundProcesses{
    Set-CurrentTask "Non-Essential Background Processes -> Closed"
    # Curated, deliberately conservative list of common third-party helper/updater/overlay processes.
    # Never includes Windows system processes, drivers, security software, shell (explorer.exe), or FiveM/game processes.
    $procList=$Global:KillProcList
    $closed=0; $notRunning=0
    foreach($name in $procList){
        try{
            $p=Get-Process -Name $name -EA Ignore
            if($p){ $p | Stop-Process -Force -EA SilentlyContinue; $closed += ($p|Measure-Object).Count }
            else { $notRunning++ }
        } catch { }
    }
    Add-Log "Background process cleanup: $closed process(es) closed, $notRunning not running" "#9B7EBD"
    $Global:AppliedKeys["CLEAN_KillBackgroundProcs"]=$true
}
function Run-DisableLauncherStartup{
    Set-CurrentTask "Game Launchers & Chat Apps -> Startup Disabled"
    # Matches by substring against the value NAME (usually the app's own registered name) so it catches
    # "Steam", "Discord", "EpicGamesLauncher", "Battle.net", "Origin", "Ubisoft Connect", "RiotClientServices", "GOG Galaxy", "Spotify".
    $targets=$Global:StartupDisableTargets
    $runPaths=@(
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    $backup=@(); $removed=0
    foreach($rp in $runPaths){
        try{
            if(-not (Test-Path $rp)){ continue }
            $props=Get-ItemProperty -Path $rp -EA SilentlyContinue
            if(-not $props){ continue }
            foreach($name in $props.PSObject.Properties.Name){
                if($name -in @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")){ continue }
                foreach($t in $targets){
                    if($name -match [regex]::Escape($t)){
                        $val=$props.$name
                        $backup += @{Path=$rp;Name=$name;Value=$val}
                        try{
                            Remove-ItemProperty -Path $rp -Name $name -EA Stop
                            $removed++
                            Add-Log "Startup entry disabled: $name" "#9B7EBD"
                        } catch { Add-Log "Could not remove startup entry $name (may need admin on HKLM): $_" "#F59E0B" }
                        break
                    }
                }
            }
        } catch {}
    }
    if($backup.Count -gt 0){ $Global:OrigMisc["CLEAN_DisableLauncherStartup"]=$backup }
    if($removed -gt 0){ Add-Log "Startup cleanup: $removed launcher/chat app(s) will no longer auto-start" "#9B7EBD" }
    else { Add-Log "No matching startup entries found (nothing to disable)" "#6B7280" }
    $Global:AppliedKeys["CLEAN_DisableLauncherStartup"]=$true
}
function Run-DnsFastWifi{
    Set-CurrentTask "DNS -> Google"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Set-DnsClientServerAddress -InterfaceIndex $wa.IfIndex -ServerAddresses ("8.8.4.4","8.8.8.8") -EA SilentlyContinue
            Add-Log "DNS set to 8.8.4.4 / 8.8.8.8 on Wi-Fi adapter" "#9B7EBD"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_DnsFast_WiFi"]=$true
    } catch { Add-Log "DNS tweak (Wi-Fi) skipped" "#F59E0B" }
}
function Run-Ipv6DisableLan{
    Set-CurrentTask "IPv6 -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){ Disable-NetAdapterBinding -Name $a.Name -ComponentID ms_tcpip6 -EA SilentlyContinue; $count++ }
        if($count -gt 0){ Add-Log "IPv6 disabled on $count wired adapter(s)" "#9B7EBD" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_Ipv6Disable"]=$true
    } catch { Add-Log "IPv6 disable (LAN) skipped" "#F59E0B" }
}
function Run-Ipv6DisableWifi{
    Set-CurrentTask "IPv6 -> Disabled"
    try{
        $wa=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.InterfaceDescription -match "Wi-Fi|Wireless"}|Select -First 1
        if($wa){
            Disable-NetAdapterBinding -Name $wa.Name -ComponentID ms_tcpip6 -EA SilentlyContinue
            Add-Log "IPv6 disabled on Wi-Fi adapter" "#9B7EBD"
        } else { Add-Log "No Wi-Fi adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_Ipv6Disable_WiFi"]=$true
    } catch { Add-Log "IPv6 disable (Wi-Fi) skipped" "#F59E0B" }
}
function Run-RssEnable{
    Set-CurrentTask "Receive Side Scaling -> Enabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){ Enable-NetAdapterRss -Name $a.Name -EA SilentlyContinue; $count++ }
        if($count -gt 0){ Add-Log "RSS enabled on $count wired adapter(s)" "#9B7EBD" } else { Add-Log "No wired adapter detected - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_RssEnable"]=$true
    } catch { Add-Log "RSS enable skipped" "#F59E0B" }
}
function Run-FlowControlOff{
    Set-CurrentTask "Flow Control -> Disabled"
    try{
        $la=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up" -and $_.InterfaceDescription -notmatch "Wi-Fi|Wireless"}
        $count=0
        foreach($a in $la){
            Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Flow Control" -DisplayValue "Disabled" -EA SilentlyContinue
            $count++
        }
        Add-Log "Flow control disable requested on $count wired adapter(s) (skipped if unsupported)" "#9B7EBD"
        $Global:AppliedKeys["NET_FlowControlOff"]=$true
    } catch { Add-Log "Flow control tweak skipped" "#F59E0B" }
}
function Run-Ipv6TransitionDisable{
    Set-CurrentTask "IPv6 Transition Tech -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\TCPIP6\Teredo"
    foreach($n in @("Teredo_State","6to4_State","IPHTTPS_State","ISATAP_State")){
        Save-Orig "NET_Ipv6Transition_$n" $p $n
        Set-RegValue $p $n "Disabled" "String"|Out-Null
    }
    Add-Log "IPv6 transition technologies (Teredo/6to4/ISATAP/IP-HTTPS) disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_Ipv6Transition"]=$true
}
function Run-DnsClientPolicy{
    Set-CurrentTask "DNS Client Multicast/Smart Resolution -> Off"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    Save-Orig "NET_DnsClientPolicy_Multicast" $p "EnableMulticast"
    Set-RegValue $p "EnableMulticast" 0|Out-Null
    Save-Orig "NET_DnsClientPolicy_SmartMultiHomed" $p "DisableSmartNameResolution"
    Set-RegValue $p "DisableSmartNameResolution" 1|Out-Null
    Add-Log "LLMNR multicast + smart multi-homed name resolution turned off" "#9B7EBD"
    $Global:AppliedKeys["NET_DnsClientPolicy"]=$true
}
function Run-LltdDisable{
    Set-CurrentTask "Link-Layer Topology Discovery -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    Save-Orig "NET_LltdDisable_IO" $p "EnableLLTDIO"
    Set-RegValue $p "EnableLLTDIO" 0|Out-Null
    Save-Orig "NET_LltdDisable_Rspndr" $p "EnableRspndr"
    Set-RegValue $p "EnableRspndr" 0|Out-Null
    Add-Log "LLTD mapper/responder disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_LltdDisable"]=$true
}
function Run-BitsNoLimit{
    Set-CurrentTask "BITS Bandwidth Limit -> Removed"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\BITS"
    Save-Orig "NET_BitsNoLimit" $p "EnableBITSMaxBandwidth"
    Set-RegValue $p "EnableBITSMaxBandwidth" 0|Out-Null
    Add-Log "BITS background transfer bandwidth cap removed" "#9B7EBD"
    $Global:AppliedKeys["NET_BitsNoLimit"]=$true
}
function Run-NcsiNoActiveProbe{
    Set-CurrentTask "Network Connectivity Active Probing -> Off"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\NlaSvc\Parameters\Internet"
    Save-Orig "NET_NcsiNoActiveProbe" $p "EnableActiveProbing"
    Set-RegValue $p "EnableActiveProbing" 0|Out-Null
    Add-Log "Network connectivity status active probing disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_NcsiNoActiveProbe"]=$true
}
function Run-NoAutoRootCertUpdate{
    Set-CurrentTask "Automatic Root Certificate Update -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\SystemCertificates\AuthRoot"
    Save-Orig "NET_NoAutoRootCertUpdate" $p "DisableRootAutoUpdate"
    Set-RegValue $p "DisableRootAutoUpdate" 1|Out-Null
    Add-Log "Automatic root certificate update disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_NoAutoRootCertUpdate"]=$true
}
function Run-NetbiosDisable{
    Set-CurrentTask "NetBIOS over TCP/IP -> Disabled"
    try{
        $base="HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
        $ifaces=Get-ChildItem -Path $base -EA SilentlyContinue
        $count=0
        foreach($i in $ifaces){
            $p=$i.PSPath
            Save-Orig "NET_NetbiosDisable_$($i.PSChildName)" $p "NetbiosOptions"
            Set-RegValue $p "NetbiosOptions" 2|Out-Null
            $count++
        }
        if($count -gt 0){ Add-Log "NetBIOS over TCP/IP disabled on $count adapter(s)" "#9B7EBD" } else { Add-Log "No adapters found for NetBIOS tweak - skipped" "#6B7280" }
        $Global:AppliedKeys["NET_NetbiosDisable"]=$true
    } catch { Add-Log "NetBIOS disable skipped" "#F59E0B" }
}
function Run-RemoteAssistanceOff{
    Set-CurrentTask "Solicited Remote Assistance -> Disabled"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
    Save-Orig "NET_RemoteAssistanceOff" $p "fAllowToGetHelp"
    Set-RegValue $p "fAllowToGetHelp" 0|Out-Null
    Add-Log "Solicited Remote Assistance disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_RemoteAssistanceOff"]=$true
}
function Run-GameExclusion{
    Set-CurrentTask "Defender Exclusions -> Game Folders"
    try{
        $candidates=@(
            "$env:ProgramFiles(x86)\Steam","$env:ProgramFiles\Steam","C:\Program Files (x86)\Steam",
            "$env:ProgramFiles(x86)\Epic Games","C:\Program Files\Epic Games",
            "$env:ProgramFiles(x86)\Riot Games","C:\Program Files\Riot Games",
            "$env:LOCALAPPDATA\FiveM","$env:LOCALAPPDATA\FiveM Application Data"
        )
        $added=0; $addedPaths=@()
        foreach($p in $candidates){
            if($p -and (Test-Path $p)){
                try{ Add-MpPreference -ExclusionPath $p -EA Stop; $added++; $addedPaths+=$p }catch{}
            }
        }
        if($added -gt 0){
            Add-Log "Defender exclusions added for $added game folder(s)" "#9B7EBD"
            if(-not $Global:OrigMisc.ContainsKey("DEF_GameExclusion")){ $Global:OrigMisc["DEF_GameExclusion"]=@() }
            $Global:OrigMisc["DEF_GameExclusion"]=@($Global:OrigMisc["DEF_GameExclusion"])+$addedPaths
        } else { Add-Log "No known game folders found / Defender module unavailable - skipped" "#6B7280" }
        $Global:AppliedKeys["DEF_GameExclusion"]=$true
    } catch { Add-Log "Defender exclusion tweak skipped" "#F59E0B" }
}
function Run-PageFileAuto{
    Set-CurrentTask "Page File -> System Managed"
    try{
        $cs=Get-CimInstance -ClassName Win32_ComputerSystem -EA Stop
        if(-not $cs.AutomaticManagedPagefile){
            Set-CimInstance -CimInstance $cs -Property @{AutomaticManagedPagefile=$true} -EA Stop|Out-Null
        }
        Add-Log "Page file set to system-managed" "#9B7EBD"
        $Global:AppliedKeys["SYS_PageFileAuto"]=$true
    } catch { Add-Log "Page file tweak skipped" "#F59E0B" }
}
function Run-PwrThrottling{Set-CurrentTask "Power Throttling -> Off";Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1|Out-Null;Add-Log "Power throttling disabled" "#9B7EBD";$Global:AppliedKeys["PWR_Throttling"]=$true}
function Run-FSOptim{Set-CurrentTask "Fullscreen Optimizations -> Disabled";Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2|Out-Null;Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1|Out-Null;Add-Log "Fullscreen optimizations disabled" "#9B7EBD";$Global:AppliedKeys["GM_FSOptim"]=$true}
function Run-MouseAccel{Set-CurrentTask "Mouse Acceleration -> Disabled";Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"|Out-Null;Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"|Out-Null;Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"|Out-Null;Add-Log "Mouse acceleration disabled" "#9B7EBD";$Global:AppliedKeys["GM_MouseAccel"]=$true}
function Run-MenuInstant{Set-CurrentTask "Instant Menus and Animations Off";Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"|Out-Null;Add-Log "Menu delay 0ms, animations off" "#9B7EBD";$Global:AppliedKeys["UX_MenuInstant"]=$true}
function Run-Notifications{Set-CurrentTask "Toast Notifications -> Disabled";Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0|Out-Null;Add-Log "Toast notifications disabled" "#9B7EBD";$Global:AppliedKeys["UX_Notifications"]=$true}
function Run-HPET{Set-CurrentTask "Dynamic Tick and HPET -> Disabled";try{bcdedit /set useplatformclock false 2>&1|Out-Null;bcdedit /set disabledynamictick yes 2>&1|Out-Null;Add-Log "HPET disabled (reboot)" "#9B7EBD";$Global:AppliedKeys["ADV_HPET"]=$true}catch{Add-Log "HPET tweak failed" "#EF4444"}}
function Run-MPODisable{Set-CurrentTask "Smooth Motion -> MPO Disabled";Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode" 5|Out-Null;Add-Log "MPO disabled" "#9B7EBD";$Global:AppliedKeys["GM_SmoothMotion"]=$true}
function Run-SmoothOptim{Set-CurrentTask "Smooth Background Maintenance";try{Disable-ScheduledTask -TaskName "\Microsoft\Windows\TaskScheduler\Regular Maintenance" -EA SilentlyContinue|Out-Null;Add-Log "Auto maintenance disabled" "#9B7EBD";$Global:AppliedKeys["CLEAN_SmoothOptim"]=$true}catch{Add-Log "Maintenance disable skipped" "#F59E0B"}}
function Run-NoNagle{
    param($ToggleKey)
    Set-CurrentTask "Nagle's Algorithm -> Disabled"
    try{
        Invoke-DedupedGlobalTweak "NET_NoNagle" $ToggleKey {
            $ifRoot="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            $ifaces=Get-ChildItem -Path $ifRoot -EA SilentlyContinue
            $count=0
            foreach($i in $ifaces){
                Save-Orig "NET_NoNagle_$($i.PSChildName)_Ack" $i.PSPath "TcpAckFrequency"
                Save-Orig "NET_NoNagle_$($i.PSChildName)_Delay" $i.PSPath "TCPNoDelay"
                Set-RegValue $i.PSPath "TcpAckFrequency" 1|Out-Null
                Set-RegValue $i.PSPath "TCPNoDelay" 1|Out-Null
                $count++
            }
            Add-Log "Nagle's algorithm disabled on $count adapter(s)" "#9B7EBD"
        }
    } catch { Add-Log "Nagle disable failed" "#EF4444" }
}
function Run-UltimatePlan{
    Set-CurrentTask "Ultimate Performance Power Plan"
    try{
        $srcGuid="e9a42b02-d5df-448d-aa00-03f14749eb61"
        $guid=$null
        # Reuse the scheme this app created on a previous run (if it's still present) instead of
        # matching the literal English label "Ultimate Performance" - that text is localized on
        # non-English Windows installs, which made the old check silently fail and duplicate a
        # brand-new power scheme every single time this tweak ran.
        if($Global:OrigMisc.ContainsKey("PWR_UltimatePlanGuid")){
            $savedGuid=$Global:OrigMisc["PWR_UltimatePlanGuid"]
            if((powercfg /list) -match [regex]::Escape($savedGuid)){ $guid=$savedGuid }
        }
        if(-not $guid){
            $dup=powercfg /duplicatescheme $srcGuid 2>&1
            $guid=[regex]::Match($dup,"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}").Value
            if($guid){ $Global:OrigMisc["PWR_UltimatePlanGuid"]=$guid }
        }
        if($guid){ powercfg /setactive $guid 2>&1|Out-Null; Add-Log "Ultimate Performance plan active" "#9B7EBD" }
        else { Add-Log "Ultimate Performance plan not supported on this system" "#F59E0B" }
        $Global:AppliedKeys["PWR_UltimatePlan"]=$true
    } catch { Add-Log "Ultimate Performance plan failed" "#EF4444" }
}
function Run-NoCoreParking{
    Set-CurrentTask "CPU Core Parking -> Disabled"
    try{
        powercfg /setacvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100 2>&1|Out-Null
        powercfg /setdcvalueindex scheme_current sub_processor 0cc5b647-c1df-4637-891a-dec35c318583 100 2>&1|Out-Null
        powercfg /setactive scheme_current 2>&1|Out-Null
        Add-Log "Core parking disabled (all cores active)" "#9B7EBD"
        $Global:AppliedKeys["SYS_NoCoreParking"]=$true
    } catch { Add-Log "Core parking tweak failed" "#EF4444" }
}
function Run-HAGS{
    Set-CurrentTask "Hardware-Accelerated GPU Scheduling -> On"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Save-Orig "GM_HAGS" $p "HwSchMode"
    Set-RegValue $p "HwSchMode" 2|Out-Null
    Add-Log "HAGS enabled (reboot)" "#9B7EBD"
    $Global:AppliedKeys["GM_HAGS"]=$true
}
function Get-GpuVendors{
    if($null -ne $Global:GpuVendors){return $Global:GpuVendors}
    $names=@()
    try{ $names=@(Get-CimInstance Win32_VideoController -EA SilentlyContinue|Select-Object -ExpandProperty Name) }catch{}
    $Global:GpuVendors=@{
        Nvidia=($names|Where-Object{$_ -match "NVIDIA"}).Count -gt 0
        Amd=($names|Where-Object{$_ -match "AMD|Radeon|ATI"}).Count -gt 0
    }
    return $Global:GpuVendors
}
function Get-GpuClassSubKeys{
    $classPath="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    if(-not(Test-Path $classPath)){return @()}
    return Get-ChildItem -Path $classPath -EA SilentlyContinue|Where-Object{$_.PSChildName -match '^\d{4}$'}
}
function Run-GpuTdrDelay{
    # NOTE: GPU_TdrDelay_Nvidia and GPU_TdrDelay_Amd both map to this function because TdrDelay
    # is a single system-wide registry value, not per-vendor. On hybrid (NVIDIA+AMD) systems both
    # toggles can be active at once, so we only touch the registry once and just record the extra
    # toggle key as applied - this avoids duplicate writes/log lines and keeps AppliedKeys in sync
    # with whichever toggle(s) the user actually had checked.
    param($ToggleKey)
    Set-CurrentTask "GPU Timeout Detection (TDR) -> Extended"
    if(-not $Global:AppliedKeys["GPU_TdrDelay"]){
        $p="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        Save-Orig "GPU_TdrDelay" $p "TdrDelay"
        Set-RegValue $p "TdrDelay" 8|Out-Null
        Add-Log "TDR delay extended to 8s" "#9B7EBD"
        $Global:AppliedKeys["GPU_TdrDelay"]=$true
    } else {
        Add-Log "TDR delay already extended by the other GPU toggle - shared setting, skipped duplicate write" "#6B7280"
    }
    if($ToggleKey -and $ToggleKey -ne "GPU_TdrDelay"){ $Global:AppliedKeys[$ToggleKey]=$true }
}
function Run-NvidiaPowerMode{
    Set-CurrentTask "NVIDIA Power Mode -> Prefer Max Performance"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $keys=Get-GpuClassSubKeys|Where-Object{ (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -EA SilentlyContinue).DriverDesc -match "NVIDIA" }
        $applied = 0
        foreach($k in $keys){
            $path="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($k.PSChildName)"
            Save-Orig "GPU_NvidiaPowerMode_$($k.PSChildName)" $path "PowerMizerEnable"
            $s1 = Set-RegValue $path "PowerMizerEnable" 1
            $s2 = Set-RegValue $path "PowerMizerLevel" 1
            $s3 = Set-RegValue $path "PowerMizerLevelAC" 1
            $s4 = Set-RegValue $path "PerfLevelSrc" 0x2222
            if($s1 -and $s2 -and $s3 -and $s4){ $applied++ }
        }
        if($applied -gt 0){
            Add-Log "NVIDIA power mode set to Prefer Max Performance ($applied instance(s))" "#9B7EBD"
        } else {
            Add-Log "NVIDIA power mode could not be applied to any instance" "#EF4444"
        }
        $Global:AppliedKeys["GPU_NvidiaPowerMode"]=$true
    } catch { Add-Log "NVIDIA power mode tweak failed: $_" "#EF4444" }
}
function Run-NvidiaTelemetryOff{
    Set-CurrentTask "NVIDIA Telemetry Service -> Disabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service NvTelemetryContainer -Force -EA SilentlyContinue
        Set-Service NvTelemetryContainer -StartupType Disabled -EA SilentlyContinue
        Add-Log "NVIDIA telemetry service disabled" "#9B7EBD"
        $Global:AppliedKeys["GPU_NvidiaTelemetryOff"]=$true
    } catch { Add-Log "NVIDIA telemetry disable skipped" "#F59E0B" }
}
function Get-GpuInstancePaths{
    param([string]$vendorMatch)
    try{
        $ctrls=Get-CimInstance -ClassName Win32_VideoController -EA SilentlyContinue|Where-Object{$_.Name -match $vendorMatch -or $_.PNPDeviceID -match $vendorMatch}
        $validPaths = @()
        foreach($ctrl in $ctrls){
            $p = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($ctrl.PNPDeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            if(Test-Path $p){ $validPaths += $p }
            else {
                # Try fallback path if the exact subkey is missing
                $base = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($ctrl.PNPDeviceID)\Device Parameters"
                if(Test-Path $base){ $validPaths += $base }
            }
        }
        return $validPaths
    } catch { return @() }
}
function Run-NvidiaMSIMode{
    Set-CurrentTask "NVIDIA MSI Mode -> Enabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $paths=Get-GpuInstancePaths "NVIDIA"
        $applied = 0
        foreach($path in $paths){
            Save-Orig "GPU_NvidiaMSIMode_$([math]::Abs($path.GetHashCode()))" $path "MSISupported"
            if(Set-RegValue $path "MSISupported" 1){ $applied++ }
        }
        if($applied -gt 0){
            Add-Log "NVIDIA MSI mode enabled ($applied instance(s))" "#9B7EBD"
        } else {
            Add-Log "NVIDIA MSI mode could not be enabled (hardware may not support it)" "#EF4444"
        }
        $Global:AppliedKeys["GPU_NvidiaMSIMode"]=$true
    } catch { Add-Log "NVIDIA MSI mode tweak failed: $_" "#EF4444" }
}
function Run-NvidiaOverlayOff{
    Set-CurrentTask "NVIDIA In-Game Overlay -> Disabled"
    if(-not (Get-GpuVendors).Nvidia){ Add-Log "No NVIDIA GPU detected - skipped" "#6B7280"; return }
    try{
        $path="HKCU:\SOFTWARE\NVIDIA Corporation\Global\ShadowPlay\NVSPCAPS"
        Save-Orig "GPU_NvidiaOverlayOff" $path "value"
        Set-RegValue $path "value" 0|Out-Null
        Add-Log "NVIDIA in-game overlay disabled" "#9B7EBD"
        $Global:AppliedKeys["GPU_NvidiaOverlayOff"]=$true
    } catch { Add-Log "NVIDIA overlay disable skipped" "#F59E0B" }
}
function Run-AmdUlps{
    Set-CurrentTask "AMD ULPS -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        $keys=Get-GpuClassSubKeys|Where-Object{ (Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -EA SilentlyContinue).DriverDesc -match "AMD|Radeon|ATI" }
        $applied = 0
        foreach($k in $keys){
            $path="HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\$($k.PSChildName)"
            Save-Orig "GPU_AmdUlps_$($k.PSChildName)" $path "EnableUlps"
            $s1 = Set-RegValue $path "EnableUlps" 0
            $s2 = Set-RegValue $path "EnableUlps_NA" 0
            if($s1 -and $s2){ $applied++ }
        }
        if($applied -gt 0){
            Add-Log "AMD ULPS disabled ($applied instance(s))" "#9B7EBD"
        } else {
            Add-Log "AMD ULPS could not be disabled for any instance" "#EF4444"
        }
        $Global:AppliedKeys["GPU_AmdUlps"]=$true
    } catch { Add-Log "AMD ULPS tweak failed: $_" "#EF4444" }
}
function Run-AmdEventsUtil{
    Set-CurrentTask "AMD External Events Utility -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service "AMD External Events Utility Service" -Force -EA SilentlyContinue
        Set-Service "AMD External Events Utility Service" -StartupType Disabled -EA SilentlyContinue
        Add-Log "AMD External Events Utility disabled" "#9B7EBD"
        $Global:AppliedKeys["GPU_AmdEventsUtil"]=$true
    } catch { Add-Log "AMD External Events Utility disable skipped" "#F59E0B" }
}
function Run-AmdMSIMode{
    Set-CurrentTask "AMD MSI Mode -> Enabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        $paths=Get-GpuInstancePaths "AMD|Radeon|ATI"
        $applied = 0
        foreach($path in $paths){
            Save-Orig "GPU_AmdMSIMode_$([math]::Abs($path.GetHashCode()))" $path "MSISupported"
            if(Set-RegValue $path "MSISupported" 1){ $applied++ }
        }
        if($applied -gt 0){
            Add-Log "AMD MSI mode enabled ($applied instance(s))" "#9B7EBD"
        } else {
            Add-Log "AMD MSI mode could not be enabled (hardware may not support it)" "#EF4444"
        }
        $Global:AppliedKeys["GPU_AmdMSIMode"]=$true
    } catch { Add-Log "AMD MSI mode tweak failed: $_" "#EF4444" }
}
function Run-AmdCrashDefenderOff{
    Set-CurrentTask "AMD Crash Defender -> Disabled"
    if(-not (Get-GpuVendors).Amd){ Add-Log "No AMD GPU detected - skipped" "#6B7280"; return }
    try{
        Stop-Service "AMD Crash Defender Service" -Force -EA SilentlyContinue
        Set-Service "AMD Crash Defender Service" -StartupType Disabled -EA SilentlyContinue
        Add-Log "AMD Crash Defender service disabled" "#9B7EBD"
        $Global:AppliedKeys["GPU_AmdCrashDefenderOff"]=$true
    } catch { Add-Log "AMD Crash Defender disable skipped" "#F59E0B" }
}
function Run-NetPowerSaving{
    param($ToggleKey)
    Set-CurrentTask "Adapter Power Saving -> Off"
    try{
        Invoke-DedupedGlobalTweak "NET_PowerSaving" $ToggleKey {
            $ups=Get-NetAdapter -EA SilentlyContinue|Where-Object{$_.Status -eq "Up"}
            foreach($a in $ups){
                Disable-NetAdapterPowerManagement -Name $a.Name -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $a.Name -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            Add-Log "Adapter power saving disabled" "#9B7EBD"
        }
    } catch { Add-Log "Adapter power saving skipped" "#F59E0B" }
}
function Run-UsbSelSuspend{
    Set-CurrentTask "USB Selective Suspend -> Off"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    Save-Orig "NET_USBSelSuspend" $p "DisableSelectiveSuspend"
    Set-RegValue $p "DisableSelectiveSuspend" 1|Out-Null
    Add-Log "USB selective suspend disabled" "#9B7EBD"
    $Global:AppliedKeys["NET_USBSelSuspend"]=$true
}
function Run-TimerRes{
    Set-CurrentTask "System Timer Resolution -> 0.5ms"
    try{
        if(-not ("Win32TimerResNS.Win32TimerRes" -as [type])){
            Add-Type -Namespace Win32TimerResNS -Name Win32TimerRes -MemberDefinition @"
[DllImport("ntdll.dll")] public static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, ref uint CurrentResolution);
"@
        }
        [uint32]$cur=0
        [Win32TimerResNS.Win32TimerRes]::NtSetTimerResolution(5000,$true,[ref]$cur)|Out-Null
        Add-Log "Timer resolution set to ~0.5ms (holds while app is open)" "#9B7EBD"
        $Global:AppliedKeys["SYS_TimerRes"]=$true
    } catch { Add-Log "Timer resolution tweak failed" "#EF4444" }
}
function Run-PauseUpdates{
    Set-CurrentTask "No Auto-Restart for Windows Update"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    Save-Orig "SYS_PauseUpdates" $p "NoAutoRebootWithLoggedOnUsers"
    Set-RegValue $p "NoAutoRebootWithLoggedOnUsers" 1|Out-Null
    Add-Log "Windows Update auto-restart disabled" "#9B7EBD"
    $Global:AppliedKeys["SYS_PauseUpdates"]=$true
}
function Run-GameMode{
    Set-CurrentTask "Windows Game Mode -> Forced On"
    $p="HKCU:\SOFTWARE\Microsoft\GameBar"
    Save-Orig "GM_GameMode" $p "AutoGameModeEnabled"
    Set-RegValue $p "AutoGameModeEnabled" 1|Out-Null
    Add-Log "Game Mode forced on" "#9B7EBD"
    $Global:AppliedKeys["GM_GameMode"]=$true
}
function Run-NoGameDVR{
    Set-CurrentTask "Game Bar / Game DVR -> Disabled"
    $p1="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
    Save-Orig "GM_NoGameDVR_App" $p1 "AppCaptureEnabled"
    Set-RegValue $p1 "AppCaptureEnabled" 0|Out-Null
    $p2="HKCU:\System\GameConfigStore"
    Save-Orig "GM_NoGameDVR_Cfg" $p2 "GameDVR_Enabled"
    Set-RegValue $p2 "GameDVR_Enabled" 0|Out-Null
    Add-Log "Game Bar / Game DVR disabled" "#9B7EBD"
    $Global:AppliedKeys["GM_NoGameDVR"]=$true
}
function Run-GameBarOff{
    Set-CurrentTask "Xbox Game Bar Overlay -> Disabled"
    $p="HKCU:\SOFTWARE\Microsoft\GameBar"
    Save-Orig "GM_GameBarOff_Nexus" $p "UseNexusForGameBarEnabled"
    Set-RegValue $p "UseNexusForGameBarEnabled" 0|Out-Null
    Save-Orig "GM_GameBarOff_Startup" $p "ShowStartupPanel"
    Set-RegValue $p "ShowStartupPanel" 0|Out-Null
    Add-Log "Xbox Game Bar overlay disabled" "#9B7EBD"
    $Global:AppliedKeys["GM_GameBarOff"]=$true
}
function Run-StandbyClean{
    Set-CurrentTask "Clear Standby Memory List"
    try{
        if(-not ("Win32MemPurgeNS.Win32MemPurge" -as [type])){
            Add-Type -Namespace Win32MemPurgeNS -Name Win32MemPurge -MemberDefinition @"
[DllImport("ntdll.dll")] public static extern int NtSetSystemInformation(int InfoClass, IntPtr Info, int Length);
"@
        }
        $cmd=4 # MemoryPurgeStandbyList
        $ptr=[System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        [System.Runtime.InteropServices.Marshal]::WriteInt32($ptr,$cmd)
        [Win32MemPurgeNS.Win32MemPurge]::NtSetSystemInformation(80,$ptr,4)|Out-Null
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
        Add-Log "Standby memory list cleared" "#9B7EBD"
        $Global:AppliedKeys["GM_StandbyClean"]=$true
    } catch { Add-Log "Standby list clear failed (needs admin)" "#EF4444" }
}
function Run-NoSearchIndex{
    Set-CurrentTask "Windows Search Indexing -> Disabled"
    try{
        Save-OrigService "CLEAN_NoSearchIndex" "WSearch"
        Stop-Service WSearch -Force -EA SilentlyContinue
        Set-Service WSearch -StartupType Disabled -EA SilentlyContinue
        Add-Log "Windows Search indexing disabled" "#9B7EBD"
        $Global:AppliedKeys["CLEAN_NoSearchIndex"]=$true
    } catch { Add-Log "Search indexing disable skipped" "#F59E0B" }
}
function Run-NoTelemetry{
    Set-CurrentTask "Telemetry Service -> Disabled"
    try{
        Save-OrigService "CLEAN_NoTelemetry" "DiagTrack"
        Stop-Service DiagTrack -Force -EA SilentlyContinue
        Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue
        Add-Log "Telemetry (DiagTrack) service disabled" "#9B7EBD"
        $Global:AppliedKeys["CLEAN_NoTelemetry"]=$true
    } catch { Add-Log "Telemetry disable skipped" "#F59E0B" }
}
function Run-NoStorageSense{
    Set-CurrentTask "Storage Sense -> Disabled"
    $p="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    Save-Orig "CLEAN_NoStorageSense" $p "01"
    Set-RegValue $p "01" 0|Out-Null
    Add-Log "Storage Sense disabled" "#9B7EBD"
    $Global:AppliedKeys["CLEAN_NoStorageSense"]=$true
}
function Run-OneDriveSyncOff{
    Set-CurrentTask "OneDrive Background Sync -> Off"
    try{
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
        Save-Orig "SYS_OneDriveSyncOff" $p "DisableFileSyncNGSC"
        Set-RegValue $p "DisableFileSyncNGSC" 1|Out-Null
        Get-Process -Name OneDrive -EA Ignore|Stop-Process -Force -EA SilentlyContinue
        Add-Log "OneDrive file sync policy disabled and process stopped" "#9B7EBD"
        $Global:AppliedKeys["SYS_OneDriveSyncOff"]=$true
    } catch { Add-Log "OneDrive sync tweak skipped" "#F59E0B" }
}
function Run-WidgetsOff{
    Set-CurrentTask "Windows Widgets -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
    Save-Orig "SYS_WidgetsOff" $p "AllowNewsAndInterests"
    Set-RegValue $p "AllowNewsAndInterests" 0|Out-Null
    Add-Log "Windows Widgets / News and Interests disabled" "#9B7EBD"
    $Global:AppliedKeys["SYS_WidgetsOff"]=$true
}
function Run-ConsumerFeaturesOff{
    Set-CurrentTask "Consumer Features / Suggested Apps -> Blocked"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    Save-Orig "SYS_ConsumerFeaturesOff" $p "DisableWindowsConsumerFeatures"
    Set-RegValue $p "DisableWindowsConsumerFeatures" 1|Out-Null
    Add-Log "Microsoft consumer experiences / suggested apps blocked" "#9B7EBD"
    $Global:AppliedKeys["SYS_ConsumerFeaturesOff"]=$true
}
function Run-Win32Priority{
    Set-CurrentTask "Win32PrioritySeparation -> Lowest Input Lag (40)"
    $p="HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    Save-Orig "SYS_Win32Priority" $p "Win32PrioritySeparation"
    Set-RegValue $p "Win32PrioritySeparation" 0xFA322A|Out-Null
    Add-Log "Win32PrioritySeparation set to 0xFA322A (Windows only reads the low 6 bits -> effectively 0x2A / 42)" "#9B7EBD"
    $Global:AppliedKeys["SYS_Win32Priority"]=$true
}
function Run-MMCSS{
    Set-CurrentTask "MMCSS Games Profile -> Smooth Max"
    $p="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    foreach($n in @("GPU Priority","Priority","Scheduling Category","SFIO Priority","Background Only","Clock Rate")){
        Save-Orig "GM_MMCSS_$($n -replace ' ','')" $p $n
    }
    Set-RegValue $p "GPU Priority" 8|Out-Null
    Set-RegValue $p "Priority" 6|Out-Null
    Set-RegValue $p "Scheduling Category" "High" "String"|Out-Null
    Set-RegValue $p "SFIO Priority" "High" "String"|Out-Null
    Set-RegValue $p "Background Only" "False" "String"|Out-Null
    Set-RegValue $p "Clock Rate" 10000|Out-Null
    Add-Log "MMCSS Games profile tuned for smoothest scheduling" "#9B7EBD"
    $Global:AppliedKeys["GM_MMCSS"]=$true
}
function Run-TcpTimedWait{
    param($ToggleKey)
    Set-CurrentTask "TCP TIME_WAIT Delay -> 30s"
    Invoke-DedupedGlobalTweak "NET_TcpTimedWait" $ToggleKey {
        $p="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
        Save-Orig "NET_TcpTimedWait" $p "TcpTimedWaitDelay"
        Set-RegValue $p "TcpTimedWaitDelay" 30|Out-Null
        Add-Log "TCP TIME_WAIT delay set to 30s" "#9B7EBD"
    }
}
function Run-PortRange{
    param($ToggleKey)
    Set-CurrentTask "Dynamic Port Range -> Widened"
    try{
        Invoke-DedupedGlobalTweak "NET_PortRange" $ToggleKey {
            netsh int ipv4 set dynamicport tcp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv4 set dynamicport udp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv6 set dynamicport tcp start=10000 num=55536 2>&1|Out-Null
            netsh int ipv6 set dynamicport udp start=10000 num=55536 2>&1|Out-Null
            Add-Log "Dynamic port range widened (10000-65535)" "#9B7EBD"
        }
    } catch { Add-Log "Port range widen failed" "#EF4444" }
}
function Run-QoSReserve{
    param($ToggleKey)
    Set-CurrentTask "QoS Reserved Bandwidth -> 0% (gpedit)"
    Invoke-DedupedGlobalTweak "NET_QoSReserve" $ToggleKey {
        $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        Save-Orig "NET_QoSReserve" $p "NonBestEffortLimit"
        Set-RegValue $p "NonBestEffortLimit" 0|Out-Null
        Add-Log "QoS reserved bandwidth returned to 0%" "#9B7EBD"
    }
}
function Run-MouseQueue{
    Set-CurrentTask "Mouse Data Queue Size -> 100 (Windows default)"
    $p="HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters"
    Save-Orig "GM_MouseQueue" $p "MouseDataQueueSize"
    # NOTE: 100 is Windows' own default. A high polling-rate mouse (500Hz-8000Hz)
    # can send far more reports than a queue of 10 can hold; when it overflows,
    # reports get dropped, which is exactly what causes cursor "ghosting"/skipping/
    # stutter. Keeping this at the OS default removes that risk while still
    # applying the tweak (in case it was previously shrunk by this or another tool).
    Set-RegValue $p "MouseDataQueueSize" 100|Out-Null
    Add-Log "Mouse data queue restored to safe default (100)" "#9B7EBD"
    $Global:AppliedKeys["GM_MouseQueue"]=$true
}
function Run-NoStickyKeys{
    Set-CurrentTask "Sticky/Toggle/Filter Keys -> Disabled"
    $pSK="HKCU:\Control Panel\Accessibility\StickyKeys"
    $pTK="HKCU:\Control Panel\Accessibility\ToggleKeys"
    $pFK="HKCU:\Control Panel\Accessibility\Keyboard Response"
    Save-Orig "GM_NoStickyKeys_SK" $pSK "Flags"
    Save-Orig "GM_NoStickyKeys_TK" $pTK "Flags"
    Save-Orig "GM_NoStickyKeys_FK" $pFK "Flags"
    Set-RegValue $pSK "Flags" "58" "String"|Out-Null
    Set-RegValue $pTK "Flags" "58" "String"|Out-Null
    Set-RegValue $pFK "Flags" "58" "String"|Out-Null
    Add-Log "Accessibility keyboard hotkeys disabled" "#9B7EBD"
    $Global:AppliedKeys["GM_NoStickyKeys"]=$true
}
function Run-NoBackgroundApps{
    Set-CurrentTask "UWP Background Apps -> Blocked (gpedit)"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
    Save-Orig "SYS_NoBackgroundApps" $p "LetAppsRunInBackground"
    Set-RegValue $p "LetAppsRunInBackground" 2|Out-Null
    Add-Log "UWP background apps force-denied" "#9B7EBD"
    $Global:AppliedKeys["SYS_NoBackgroundApps"]=$true
}
function Run-NoBkgndGPRefresh{
    Set-CurrentTask "Background Group Policy Refresh -> Disabled"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Save-Orig "SYS_NoBkgndGPRefresh" $p "DisableBkGndGroupPolicy"
    Set-RegValue $p "DisableBkGndGroupPolicy" 1|Out-Null
    Add-Log "Background Group Policy refresh disabled" "#9B7EBD"
    $Global:AppliedKeys["SYS_NoBkgndGPRefresh"]=$true
}
function Run-NoSmartScreenCheck{
    Set-CurrentTask "SmartScreen App Reputation Check -> Off"
    $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    Save-Orig "SYS_NoSmartScreenCheck" $p "EnableSmartScreen"
    Set-RegValue $p "EnableSmartScreen" 0|Out-Null
    Add-Log "SmartScreen app reputation check turned off" "#9B7EBD"
    $Global:AppliedKeys["SYS_NoSmartScreenCheck"]=$true
}
function Run-NoWER{
    Set-CurrentTask "Windows Error Reporting -> Disabled"
    try{
        Save-OrigService "CLEAN_NoWER" "WerSvc"
        Stop-Service WerSvc -Force -EA SilentlyContinue
        Set-Service WerSvc -StartupType Disabled -EA SilentlyContinue
        Add-Log "Windows Error Reporting service disabled" "#9B7EBD"
        $Global:AppliedKeys["CLEAN_NoWER"]=$true
    } catch { Add-Log "WER disable skipped" "#F59E0B" }
}
function Run-NoPrintSpooler{
    Set-CurrentTask "Print Spooler -> Disabled"
    try{
        Save-OrigService "CLEAN_NoPrintSpooler" "Spooler"
        Stop-Service Spooler -Force -EA SilentlyContinue
        Set-Service Spooler -StartupType Disabled -EA SilentlyContinue
        Add-Log "Print Spooler disabled (printing will not work)" "#9B7EBD"
        $Global:AppliedKeys["CLEAN_NoPrintSpooler"]=$true
    } catch { Add-Log "Print Spooler disable skipped" "#F59E0B" }
}
$BtnRun.Add_Click({
    $activeKeys=$Global:TweakToggles.Keys|Where-Object{$Global:TweakToggles[$_] -eq $true}
    $total=($activeKeys|Measure-Object).Count
    if($total -eq 0){Add-Log "No tweaks selected." "#EF4444";return}

    # FIX: AppliedKeys used to be loaded from state.json at startup and never reset before a
    # new Run. Invoke-DedupedGlobalTweak (and the GPU TdrDelay dedup block) checks AppliedKeys
    # and SKIPS the actual registry write if a key was ever marked applied in a *previous*
    # session - even if Windows/an update reverted the setting since. That made NetThrottle,
    # TcpGlobal and GPU TdrDelay permanently "stick" at whatever they were the very first time
    # you ran the tool, no matter how many times you ran it again. Reset per-run so every click
    # of Run actually re-applies the selected tweaks.
    $Global:AppliedKeys = @{}

    # --- Safety check #1: warn about the selected tweaks that change system behavior in ways the user should know about ---
    $riskyMap = [ordered]@{
        "SYS_PauseUpdates"        = "Windows Update will be paused"
        "CLEAN_NoTelemetry"       = "Telemetry / diagnostic data collection will be disabled"
        "CLEAN_NoWER"             = "Windows Error Reporting will be disabled"
        "CLEAN_NoPrintSpooler"    = "Print Spooler service will be disabled (printing will stop working)"
        "SYS_NoBackgroundApps"    = "Background apps will be restricted"
        "CLEAN_RemoveBloat"       = "Pre-installed 'bloatware' apps will be removed"
        "CLEAN_KillBackgroundProcs" = "Common background apps (OneDrive, Discord, Spotify, browser updaters, etc.) will be force-closed if running"
        "CLEAN_DisableLauncherStartup" = "Steam/Discord/Epic/Battle.net/Origin/Ubisoft/Riot/GOG/Spotify will no longer auto-start with Windows (still openable manually)"
        "SYS_ConsumerFeaturesOff" = "Windows 'suggested content' / consumer features will be disabled"
        "SYS_WidgetsOff"         = "Windows Widgets will be disabled"
        "SYS_OneDriveSyncOff"    = "OneDrive sync will be turned off"
        "NET_RemoteAssistanceOff"= "Remote Assistance will be disabled"
        "NET_NoAutoRootCertUpdate" = "Automatic root certificate updates will be disabled"
        "NduDisable"             = "Network Data Usage (Ndu) driver will be disabled"
        "NduDisable_WiFi"        = "Network Data Usage (Ndu) driver will be disabled"
        "NET_Ipv6Disable"        = "IPv6 will be unbound on the wired adapter"
        "NET_Ipv6Disable_WiFi"   = "IPv6 will be unbound on the Wi-Fi adapter"
    }
    $activeRisky=@()
    foreach($k in $riskyMap.Keys){ if($Global:TweakToggles[$k] -and ($activeRisky -notcontains $riskyMap[$k])){ $activeRisky += $riskyMap[$k] } }
    if($activeRisky.Count -gt 0){
        $riskMsg = "The tweaks you selected include changes you should know about:`n`n- " + ($activeRisky -join "`n- ") + "`n`nContinue?"
        $riskConfirm=[System.Windows.MessageBox]::Show($riskMsg,"Queen Project - Please Review",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if($riskConfirm -ne [System.Windows.MessageBoxResult]::Yes){ Add-Log "Run cancelled by user at the review step." "#F59E0B"; return }
    }

    # --- Safety check #1b: for the three tweaks that remove/kill/disable actual apps, show the
    # SPECIFIC list of what's actually installed/running on THIS machine (not a generic description)
    # and let the user opt each one out individually without cancelling the whole run. ---
    $skipKeys=@()
    if($Global:TweakToggles["CLEAN_RemoveBloat"]){
        $__installedPkgs = @(Get-AppxPackage -EA SilentlyContinue | Select-Object -ExpandProperty Name)
        $foundBloat=@($Global:BloatList | Where-Object { $__installedPkgs -contains $_ })
        if($foundBloat.Count -gt 0){
            $msg="These pre-installed apps will be REMOVED from this PC:`n`n- "+($foundBloat -join "`n- ")+"`n`nNOTE: this cannot be undone by the Restore Defaults button - to get an app back you'd need to reinstall it from the Microsoft Store.`n`nRemove them?"
            $r=[System.Windows.MessageBox]::Show($msg,"Queen Project - Confirm App Removal",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_RemoveBloat"; Add-Log "Skipped: app removal (declined by user)." "#F59E0B" }
        }
    }
    if($Global:TweakToggles["CLEAN_KillBackgroundProcs"]){
        $foundProcs=@($Global:KillProcList | Where-Object { Get-Process -Name $_ -EA Ignore } | Select-Object -Unique)
        if($foundProcs.Count -gt 0){
            $msg="These currently-running apps will be FORCE-CLOSED:`n`n- "+($foundProcs -join "`n- ")+"`n`nClose them now? (You can reopen them manually afterward.)"
            $r=[System.Windows.MessageBox]::Show($msg,"Queen Project - Confirm Force-Close",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_KillBackgroundProcs"; Add-Log "Skipped: force-close background apps (declined by user)." "#F59E0B" }
        }
    }
    if($Global:TweakToggles["CLEAN_DisableLauncherStartup"]){
        $msg="Auto-start on Windows login will be DISABLED for any installed launcher/chat app matching:`n`n- "+($Global:StartupDisableTargets -join "`n- ")+"`n`n(They'll still open fine manually - this only stops them launching automatically.) Continue?"
        $r=[System.Windows.MessageBox]::Show($msg,"Queen Project - Confirm Startup Change",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
        if($r -ne [System.Windows.MessageBoxResult]::Yes){ $skipKeys+="CLEAN_DisableLauncherStartup"; Add-Log "Skipped: disable launcher startup (declined by user)." "#F59E0B" }
    }
    if($skipKeys.Count -gt 0){
        $activeKeys=@($activeKeys | Where-Object { $skipKeys -notcontains $_ })
        $total=($activeKeys|Measure-Object).Count
        if($total -eq 0){ Add-Log "No tweaks left to run after declining the app changes above." "#EF4444"; return }
    }

    # --- Safety check #2: offer to create a System Restore Point first ---
    $rpChoice=[System.Windows.MessageBox]::Show("Create a Windows System Restore Point before applying tweaks? (Recommended, lets you undo everything from Control Panel if something goes wrong)`n`nYes = create restore point, then continue`nNo = continue without one`nCancel = don't run anything","Queen Project - Safety Check",[System.Windows.MessageBoxButton]::YesNoCancel,[System.Windows.MessageBoxImage]::Question)
    if($rpChoice -eq [System.Windows.MessageBoxResult]::Cancel){ Add-Log "Run cancelled by user." "#F59E0B"; return }
    if($rpChoice -eq [System.Windows.MessageBoxResult]::Yes){
        # FIX: Checkpoint-Computer routinely takes anywhere from ~10 seconds to over a minute.
        # It used to run directly on the UI thread inside this click handler with zero feedback,
        # which is exactly what Windows' "(Not Responding)" freeze detector flags - the window
        # looked hung the moment you clicked Run. We now run it in a background job and pump the
        # WPF dispatcher (via an empty Invoke) every 200ms while we wait, which keeps the window
        # responsive/repainting even though we're still waiting on the same click handler.
        Add-Log "Creating System Restore Point (this can take up to a minute, window will stay responsive)..." "#6B7280"
        $rpJob = Start-Job -ScriptBlock {
            try{
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -EA SilentlyContinue
                Checkpoint-Computer -Description "Queen Project - before tweaks" -RestorePointType "MODIFY_SETTINGS" -EA Stop
                "OK"
            } catch { "ERR: $_" }
        }
        while($rpJob.State -eq 'Running'){
            $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) | Out-Null
            Start-Sleep -Milliseconds 200
        }
        $rpResult = Receive-Job -Job $rpJob -Wait -AutoRemoveJob -EA SilentlyContinue
        if($rpResult -like "ERR:*"){
            Add-Log "Could not create a restore point: $rpResult" "#F59E0B"
            $cont=[System.Windows.MessageBox]::Show("Failed to create a restore point.`n`n$rpResult`n`nContinue anyway without one?","Queen Project",[System.Windows.MessageBoxButton]::YesNo,[System.Windows.MessageBoxImage]::Warning)
            if($cont -ne [System.Windows.MessageBoxResult]::Yes){ Add-Log "Run cancelled by user." "#F59E0B"; return }
        } else {
            Add-Log "Restore point created." "#10B981"
        }
    }

    Set-StatusRunning; Add-Log "--- QUEEN PROJECT STARTED ---" "#9B7EBD"
    $Global:IsCancelled=$false; $script:_done=0; Update-Progress 0 $total
    $runMap=@{
        "NetThrottle"="Run-NetThrottle";"BcdTimer"="Run-BcdTimer";"TcpGlobal"="Run-TcpGlobal"
        "KbQueue"="Run-KbQueue";"NduDisable"="Run-NduDisable";"GamingMemory"="Run-GamingMemory"
        "FiveMBooster"="Run-FiveMBooster";"GM_FiveMPerfOptions"="Run-FiveMPerfOptions";"GM_FiveMCoreAffinity"="Run-FiveMCoreAffinity";"NET_KillerFix"="Run-KillerFix";"NET_FiveMQos"="Run-FiveMQos";"NET_FiveMFirewall"="Run-FiveMFirewall";"DriverHealth"="Run-DriverHealth"
        "LanOptimize"="Run-LanOptimize";"WifiOptimize"="Run-WifiOptimize"
        "PWR_Throttling"="Run-PwrThrottling";"GM_FSOptim"="Run-FSOptim";"GM_MouseAccel"="Run-MouseAccel"
        "UX_MenuInstant"="Run-MenuInstant";"UX_Notifications"="Run-Notifications"
        "ADV_HPET"="Run-HPET";"GM_SmoothMotion"="Run-MPODisable";"CLEAN_SmoothOptim"="Run-SmoothOptim"
        "NET_NoNagle"="Run-NoNagle";"PWR_UltimatePlan"="Run-UltimatePlan";"SYS_NoCoreParking"="Run-NoCoreParking";"GM_HAGS"="Run-HAGS"
        "NET_PowerSaving"="Run-NetPowerSaving";"NET_USBSelSuspend"="Run-UsbSelSuspend"
        "SYS_TimerRes"="Run-TimerRes";"SYS_PauseUpdates"="Run-PauseUpdates"
        "GM_GameMode"="Run-GameMode";"GM_NoGameDVR"="Run-NoGameDVR";"GM_GameBarOff"="Run-GameBarOff";"GM_StandbyClean"="Run-StandbyClean"
        "CLEAN_NoSearchIndex"="Run-NoSearchIndex";"CLEAN_NoTelemetry"="Run-NoTelemetry";"CLEAN_NoStorageSense"="Run-NoStorageSense"
        "SYS_Win32Priority"="Run-Win32Priority";"GM_MMCSS"="Run-MMCSS"
        "NET_TcpTimedWait"="Run-TcpTimedWait";"NET_PortRange"="Run-PortRange";"NET_QoSReserve"="Run-QoSReserve"
        "GM_MouseQueue"="Run-MouseQueue";"GM_NoStickyKeys"="Run-NoStickyKeys"
        "SYS_NoBackgroundApps"="Run-NoBackgroundApps";"CLEAN_NoWER"="Run-NoWER";"CLEAN_NoPrintSpooler"="Run-NoPrintSpooler"
        "GPU_TdrDelay_Nvidia"="Run-GpuTdrDelay";"GPU_TdrDelay_Amd"="Run-GpuTdrDelay";"GPU_NvidiaPowerMode"="Run-NvidiaPowerMode";"GPU_NvidiaTelemetryOff"="Run-NvidiaTelemetryOff"
        "GPU_NvidiaMSIMode"="Run-NvidiaMSIMode";"GPU_NvidiaOverlayOff"="Run-NvidiaOverlayOff"
        "GPU_AmdUlps"="Run-AmdUlps";"GPU_AmdEventsUtil"="Run-AmdEventsUtil"
        "GPU_AmdMSIMode"="Run-AmdMSIMode";"GPU_AmdCrashDefenderOff"="Run-AmdCrashDefenderOff"
        "NetThrottle_WiFi"="Run-NetThrottle";"TcpGlobal_WiFi"="Run-TcpGlobal";"NduDisable_WiFi"="Run-NduDisable"
        "NET_NoNagle_WiFi"="Run-NoNagle";"NET_PowerSaving_WiFi"="Run-NetPowerSaving"
        "NET_TcpTimedWait_WiFi"="Run-TcpTimedWait";"NET_PortRange_WiFi"="Run-PortRange";"NET_QoSReserve_WiFi"="Run-QoSReserve"
        "NET_LanJumboFrame"="Run-LanJumboFrame";"NET_LanInterruptModeration"="Run-LanInterruptModeration"
        "NET_WifiPowerSaveMode"="Run-WifiPowerSaveMode";"NET_WifiRoamingAggressiveness"="Run-WifiRoamingAggressiveness"
        "NET_DnsFast"="Run-DnsFastLan";"NET_DnsFast_WiFi"="Run-DnsFastWifi"
        "NET_DeliveryOptOff"="Run-DeliveryOptOff";"NET_DnsCacheAggressive"="Run-DnsCacheAggressive"
        "SYS_BottleneckCheck"="Run-BottleneckCheck";"GPU_ClearShaderCache"="Run-ClearShaderCache"
        "CLEAN_ClearTempJunk"="Run-ClearTempJunk";"CLEAN_ClearFiveMCache"="Run-ClearFiveMCache"
        "CLEAN_RemoveBloat"="Run-RemoveBloat";"CLEAN_KillBackgroundProcs"="Run-KillBackgroundProcesses";"CLEAN_DisableLauncherStartup"="Run-DisableLauncherStartup"
        "NET_Ipv6Disable"="Run-Ipv6DisableLan";"NET_Ipv6Disable_WiFi"="Run-Ipv6DisableWifi"
        "NET_RssEnable"="Run-RssEnable";"NET_FlowControlOff"="Run-FlowControlOff"
        "DEF_GameExclusion"="Run-GameExclusion";"SYS_PageFileAuto"="Run-PageFileAuto"
        "NET_Ipv6Transition"="Run-Ipv6TransitionDisable";"NET_DnsClientPolicy"="Run-DnsClientPolicy"
        "NET_LltdDisable"="Run-LltdDisable";"NET_BitsNoLimit"="Run-BitsNoLimit";"NET_NetbiosDisable"="Run-NetbiosDisable"
        "NET_NcsiNoActiveProbe"="Run-NcsiNoActiveProbe";"NET_NoAutoRootCertUpdate"="Run-NoAutoRootCertUpdate"
        "SYS_NoBkgndGPRefresh"="Run-NoBkgndGPRefresh";"SYS_NoSmartScreenCheck"="Run-NoSmartScreenCheck"
        "NET_RemoteAssistanceOff"="Run-RemoteAssistanceOff"
        "SYS_OneDriveSyncOff"="Run-OneDriveSyncOff";"SYS_WidgetsOff"="Run-WidgetsOff";"SYS_ConsumerFeaturesOff"="Run-ConsumerFeaturesOff"
    }
    $restartRequiredKeys=@("BcdTimer","ADV_HPET","GM_HAGS","PWR_UltimatePlan","SYS_NoCoreParking")
    $restartRequired=[bool](@($activeKeys | Where-Object { $restartRequiredKeys -contains $_ }).Count -gt 0)
    $timer=New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval=[TimeSpan]::FromMilliseconds(180)
    $keyQueue=[System.Collections.Queue]::new($activeKeys)
    $script:_total = $total; $script:_done = 0
    $timer.Add_Tick({
        if($keyQueue.Count -eq 0 -or $Global:IsCancelled){
            $timer.Stop();Save-TweakState
            Add-Log "--- QUEEN PERFORMANCE PROFILE COMPLETE ---" "#10B981"
            if(-not $Global:IsCancelled){
                if($restartRequired){
                    Add-Log "At least one selected advanced tweak requires a restart to fully take effect." "#F59E0B"
                    [System.Windows.MessageBox]::Show("Your selected tweaks have been applied.`n`nAt least one advanced option needs a PC restart to fully take effect.","Queen Project - Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)|Out-Null
                    Set-CurrentTask "Complete. Restart required for selected advanced options."
                } else {
                    Add-Log "Optimize profile applied. Start or return to FiveM; no restart is required for this profile." "#10B981"
                    [System.Windows.MessageBox]::Show("Queen Project profile has been applied.`n`nNo restart is required. Priority and performance tweaks are now active via IFEO/System.","Queen Project - Complete",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Information)|Out-Null
                    Set-CurrentTask "Complete. Ready for FiveM."
                }
            }
            Set-StatusDone;Update-Progress $script:_total $script:_total;return
        }
        $k=$keyQueue.Dequeue();$script:_done++;Update-Progress $script:_done $script:_total
        if($runMap.ContainsKey($k)){
            $fnName=$runMap[$k]
            try{
                & (Get-Command $fnName -CommandType Function).ScriptBlock $k
                Add-Log "[OK] $k" "#10B981"
            } catch {
                Add-Log "[FAIL] $k`: $_" "#EF4444"
            }
        } else { Set-CurrentTask $k; Add-Log "[OK] $k applied" "#10B981" }
    }.GetNewClosure())
    $timer.Start()
})

Add-Log "> Queen Project console initialised." "#9B7EBD"
Add-Log "> Safe client-side profile selected. Server/ISP ping is not changed by local tweaks." "#6B7280"

$window.Add_KeyDown({
    param($s,$e)
    if($e.Key -eq [System.Windows.Input.Key]::Escape){
        if($CategoryOverlay.Visibility -eq "Visible"){ Close-CategoryDetail; $e.Handled=$true }
    } elseif(($e.Key -eq [System.Windows.Input.Key]::Return -or $e.Key -eq [System.Windows.Input.Key]::Enter)){
        if($CategoryOverlay.Visibility -ne "Visible" -and (-not $SearchBox.IsFocused)){
            $BtnRun.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $e.Handled=$true
        }
    }
})

$window.Add_Closing({
    if($Global:BackgroundJobs){
        foreach($j in $Global:BackgroundJobs){
            try{ Stop-Job -Job $j -EA SilentlyContinue; Remove-Job -Job $j -Force -EA SilentlyContinue }catch{}
        }
    }
})

Update-PresetGlowConsistency
$window.ShowDialog()|Out-Null








