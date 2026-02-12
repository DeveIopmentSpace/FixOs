<#
- MORE INFO = https://github.com/DeveIopmentSpace/FixOs
- NOTES
    Version: 2.0.0
    Author: Project/Development Space
    Requires: Administrator privileges
#>

param(
    [switch]$Install,
    [switch]$Silent
)

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please right-click PowerShell and select 'Run as Administrator', then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to exit..." -ForegroundColor Gray
    $null = Read-Host
    exit
}

$fullscreenCode = @'
[DllImport("user32.dll")]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, int dwExtraInfo);

[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);

public const byte VK_F11 = 0x7A;
public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
public const uint KEYEVENTF_KEYUP = 0x0002;
'@

try {
    Add-Type -MemberDefinition $fullscreenCode -Name KeyboardAPI -Namespace Win32
} catch {}

try {
    Start-Sleep -Milliseconds 500
    
    $windowHandle = [Win32.KeyboardAPI]::GetForegroundWindow()
    
    if ($windowHandle -ne [IntPtr]::Zero) {
        [Win32.KeyboardAPI]::SetForegroundWindow($windowHandle)
        Start-Sleep -Milliseconds 100
        
        [Win32.KeyboardAPI]::keybd_event([Win32.KeyboardAPI]::VK_F11, 0, [Win32.KeyboardAPI]::KEYEVENTF_EXTENDEDKEY, 0)
        Start-Sleep -Milliseconds 50
        [Win32.KeyboardAPI]::keybd_event([Win32.KeyboardAPI]::VK_F11, 0, [Win32.KeyboardAPI]::KEYEVENTF_KEYUP, 0)
        
        Start-Sleep -Milliseconds 500
    }
} catch {}

try {
    $maxWidth = $Host.UI.RawUI.MaxWindowSize.Width
    $maxHeight = $Host.UI.RawUI.MaxWindowSize.Height
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($maxWidth, $maxHeight)
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($maxWidth, 9999)
} catch {
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(120, 50)
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(120, 9999)
}

function Show-Menu {
    Clear-Host

    $bannerLines = @(
        " ███████╗██╗██╗  ██╗  ██████╗ ███████╗ ",
        " ██╔════╝██║╚██╗██╔╝ ██╔═══██╗██╔════╝ ", 
        " █████╗  ██║ ╚███╔╝  ██║   ██║███████╗ ",
        " ██╔══╝  ██║ ██╔██╗  ██║   ██║╚════██║ ",
        " ██║     ██║██╔╝ ██╗ ╚██████╔╝███████║ ",
        " ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═════╝ ╚══════╝ ",
        "                                       ",
        "                                       ",
        " © 2026 Devspace. All rights reserved. ",
        "                                       "
    )

    function Write-CenteredLine {
        param (
            [string]$Text,
            [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor
        )
        try {
            $width = $Host.UI.RawUI.WindowSize.Width
            if ($width -eq 0) { $width = 80 }
            $padded = $Text.PadLeft(([int](($width + $Text.Length)/2)))
            Write-Host $padded -ForegroundColor $ForegroundColor
        } catch {
            Write-Host $Text -ForegroundColor $ForegroundColor
        }
    }

    Write-Host ""

    foreach ($line in $bannerLines) {
        Write-CenteredLine -Text $line
    }

    Write-CenteredLine -Text ""
    Write-CenteredLine -Text ""
    Write-CenteredLine -Text "[1] Install FixOS    [2] Learn More"
    Write-CenteredLine -Text ""
    Write-CenteredLine -Text "[3] Exit"
    Write-CenteredLine -Text ""

    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" { Install-FixOS }
        "2" { Start-Process "https://github.com/DeveIopmentSpace/FixOs"; Show-Menu }
        "3" { exit }
        default { Write-Host "Invalid selection..."; Start-Sleep -Seconds 2; Show-Menu }
    }
}

    # ======================================================== #
    #                    Main optimization                     #
    # ======================================================== #
function Start-WindowsOptimization {
    # Check if running as Administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Please run as Administrator"
        return $false
    }

    # Set execution policy for current process
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue

    function Remove-AppxSafe {
        param([string]$AppName)
        try {
            Get-AppxPackage -Name $AppName -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxPackage -Name $AppName -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$AppName*" } | ForEach-Object {
                Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
            }
            return $true
        } catch { return $false }
    }

    function Set-RegistrySafe {
        param([string]$Path, [string]$Name, [object]$Value, [string]$Type = "DWord")
        try {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
            }
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
            return $true
        } catch { return $false }
    }

    function Create-ToolboxShortcut {
        try {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "Toolbox.lnk"
            
            $toolboxUrl = "https://raw.githubusercontent.com/DeveIopmentSpace/FixOs/main/Toolbox/src/Toolbox.ps1"
            
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($shortcutPath)
            $Shortcut.TargetPath = "wt.exe"
            $Shortcut.Arguments = "-p `"Windows PowerShell`" -d `"$env:USERPROFILE`" powershell -Command `"irm '$toolboxUrl' | iex`""
            $Shortcut.WorkingDirectory = "$env:USERPROFILE"
            $Shortcut.Description = "FixOs Toolbox"
            $Shortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
            $Shortcut.Save()
            
            return $true
        } catch {
            return $false
        }
    }

    # Main optimization functions
    function Force-Remove-Apps {
        $appsToRemove = @(
            "Microsoft.MicrosoftEdge",
            "Microsoft.MicrosoftEdgeDevToolsClient", 
            "Microsoft.549981C3F5F10",
            "Microsoft.XboxApp",
            "Microsoft.XboxGamingOverlay", 
            "Microsoft.XboxIdentityProvider",
            "Microsoft.XboxSpeechToTextOverlay",
            "Microsoft.GamingApp",
            "Clipchamp.Clipchamp",
            "Microsoft.BingNews", 
            "Microsoft.BingWeather",
            "Microsoft.BingFinance",
            "Microsoft.BingSports",
            "Microsoft.BingFoodAndDrink",
            "Microsoft.BingHealthAndFitness",
            "Microsoft.BingTravel",
            "Microsoft.GetHelp",
            "Microsoft.Getstarted",
            "Microsoft.MicrosoftOfficeHub",
            "Microsoft.MicrosoftSolitaireCollection",
            "Microsoft.People",
            "Microsoft.WindowsAlarms",
            "Microsoft.WindowsCamera", 
            "Microsoft.WindowsMaps",
            "Microsoft.WindowsSoundRecorder",
            "Microsoft.YourPhone",
            "Microsoft.ScreenSketch",
            "Microsoft.WindowsCalculator",
            "Microsoft.WindowsFeedbackHub",
            "Microsoft.WindowsStore",
            "Microsoft.ZuneMusic",
            "Microsoft.ZuneVideo",
            "Microsoft.Windows.Photos",
            "Microsoft.MSPaint",
            "Microsoft.Paint",
            "Microsoft.MicrosoftStickyNotes",
            "Microsoft.Todos",
            "Microsoft.Widgets",
            "Microsoft.Windows.Copilot",
            "Microsoft.WindowsNotepad",
            "Microsoft.Copilot",
            "MicrosoftWindows.Client.WebExperience",
            "Microsoft.SkypeApp",
            "microsoft.windowscommunicationsapps",
            "Microsoft.OutlookForWindows",
            "Microsoft.MixedReality.Portal",
            "Microsoft.MicrosoftWhiteboard",
            "Microsoft.PowerAutomateDesktop",
            "Microsoft.QuickAssist",
            "Microsoft.LinkedIn",
            "Microsoft.Cortana",
            "Microsoft.HEIFImageExtension",
            "Microsoft.Advertising.Xaml",
            "Print.Fax.Scan",
            "Language.Handwriting", 
            "Browser.InternetExplorer",
            "MathRecognizer",
            "OneCoreUAP.OneSync",
            "OpenSSH.Client",
            "App.Support.QuickAssist",
            "Language.Speech",
            "Language.TextToSpeech", 
            "App.StepsRecorder",
            "Hello.Face*",
            "Media.WindowsMediaPlayer",
            "Microsoft.Windows.WordPad",
            "Microsoft.QuickAssist",
            "Microsoft.Teams",
            "Microsoft.BingSearch",
            "Microsoft.XboxApp",
            "Microsoft.ParentalControls",
            "MicrosoftCorporationII.QuickAssist"
        )

        foreach ($app in $appsToRemove) {
            try {
                Remove-AppxSafe -AppName $app
            } catch {}
        }
    }

    function Remove-Edge-Completely {
        try {
            # Stop Edge processes
            Get-Process -Name "*edge*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            # Remove Edge directories
            $edgePaths = @(
                "C:\Program Files (x86)\Microsoft\Edge",
                "C:\Program Files (x86)\Microsoft\EdgeWebView",
                "C:\Program Files (x86)\Microsoft\EdgeUpdate",
                "C:\Program Files (x86)\Microsoft\EdgeCore",
                "C:\Windows\System32\Microsoft-Edge-Webview",
                "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe",
                "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe"
            )
            
            foreach ($path in $edgePaths) {
                if (Test-Path $path) {
                    try {
                        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    } catch {}
                }
            }
        } catch {}
    }

    function Optimize-Services {
        try {
            $services = @(
                @{Name = 'XboxGipSvc'; StartupType = 'Disabled'},
                @{Name = 'ALG'; StartupType = 'Manual'},
                @{Name = 'AJRouter'; StartupType = 'Disabled'},
                @{Name = 'AppIDSvc'; StartupType = 'Manual'},
                @{Name = 'AppMgmt'; StartupType = 'Manual'},
                @{Name = 'AppReadiness'; StartupType = 'Manual'},
                @{Name = 'AppVClient'; StartupType = 'Disabled'},
                @{Name = 'AppXSvc'; StartupType = 'Manual'},
                @{Name = 'Appinfo'; StartupType = 'Manual'},
                @{Name = 'AssignedAccessManagerSvc'; StartupType = 'Disabled'},
                @{Name = 'AudioEndpointBuilder'; StartupType = 'Automatic'},
                @{Name = 'AudioSrv'; StartupType = 'Automatic'},
                @{Name = 'Audiosrv'; StartupType = 'Automatic'},
                @{Name = 'AxInstSV'; StartupType = 'Manual'},
                @{Name = 'BDESVC'; StartupType = 'Manual'},
                @{Name = 'BFE'; StartupType = 'Automatic'},
                @{Name = 'BITS'; StartupType = 'Manual'},
                @{Name = 'BTAGService'; StartupType = 'Manual'},
                @{Name = 'BcastDVRUserService_*'; StartupType = 'Manual'},
                @{Name = 'BrokerInfrastructure'; StartupType = 'Automatic'},
                @{Name = 'Browser'; StartupType = 'Manual'},
                @{Name = 'BthAvctpSvc'; StartupType = 'Automatic'},
                @{Name = 'BthHFSrv'; StartupType = 'Automatic'},
                @{Name = 'CDPSvc'; StartupType = 'Manual'},
                @{Name = 'CDPUserSvc_*'; StartupType = 'Automatic'},
                @{Name = 'COMSysApp'; StartupType = 'Manual'},
                @{Name = 'CaptureService_*'; StartupType = 'Manual'},
                @{Name = 'CertPropSvc'; StartupType = 'Manual'},
                @{Name = 'ClipSVC'; StartupType = 'Manual'},
                @{Name = 'ConsentUxUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'CoreMessagingRegistrar'; StartupType = 'Automatic'},
                @{Name = 'CredentialEnrollmentManagerUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'CryptSvc'; StartupType = 'Automatic'},
                @{Name = 'CscService'; StartupType = 'Manual'},
                @{Name = 'DPS'; StartupType = 'Automatic'},
                @{Name = 'DcomLaunch'; StartupType = 'Automatic'},
                @{Name = 'DcpSvc'; StartupType = 'Manual'},
                @{Name = 'DevQueryBroker'; StartupType = 'Manual'},
                @{Name = 'DeviceAssociationBrokerSvc_*'; StartupType = 'Manual'},
                @{Name = 'DeviceAssociationService'; StartupType = 'Manual'},
                @{Name = 'DeviceInstall'; StartupType = 'Manual'},
                @{Name = 'DevicePickerUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'DevicesFlowUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'Dhcp'; StartupType = 'Automatic'},
                @{Name = 'DialogBlockingService'; StartupType = 'Disabled'},
                @{Name = 'DispBrokerDesktopSvc'; StartupType = 'Automatic'},
                @{Name = 'DisplayEnhancementService'; StartupType = 'Manual'},
                @{Name = 'DmEnrollmentSvc'; StartupType = 'Manual'},
                @{Name = 'Dnscache'; StartupType = 'Automatic'},
                @{Name = 'DoSvc'; StartupType = 'Manual'},
                @{Name = 'DsSvc'; StartupType = 'Manual'},
                @{Name = 'DsmSvc'; StartupType = 'Manual'},
                @{Name = 'DusmSvc'; StartupType = 'Automatic'},
                @{Name = 'EFS'; StartupType = 'Manual'},
                @{Name = 'EapHost'; StartupType = 'Manual'},
                @{Name = 'EntAppSvc'; StartupType = 'Manual'},
                @{Name = 'EventLog'; StartupType = 'Automatic'},
                @{Name = 'EventSystem'; StartupType = 'Automatic'},
                @{Name = 'FDResPub'; StartupType = 'Manual'},
                @{Name = 'Fax'; StartupType = 'Manual'},
                @{Name = 'FontCache'; StartupType = 'Automatic'},
                @{Name = 'FrameServer'; StartupType = 'Manual'},
                @{Name = 'FrameServerMonitor'; StartupType = 'Manual'},
                @{Name = 'GraphicsPerfSvc'; StartupType = 'Manual'},
                @{Name = 'HomeGroupListener'; StartupType = 'Manual'},
                @{Name = 'HomeGroupProvider'; StartupType = 'Manual'},
                @{Name = 'HvHost'; StartupType = 'Manual'},
                @{Name = 'IEEtwCollectorService'; StartupType = 'Manual'},
                @{Name = 'IKEEXT'; StartupType = 'Manual'},
                @{Name = 'InstallService'; StartupType = 'Manual'},
                @{Name = 'InventorySvc'; StartupType = 'Manual'},
                @{Name = 'IpxlatCfgSvc'; StartupType = 'Manual'},
                @{Name = 'KeyIso'; StartupType = 'Automatic'},
                @{Name = 'KtmRm'; StartupType = 'Manual'},
                @{Name = 'LSM'; StartupType = 'Automatic'},
                @{Name = 'LanmanServer'; StartupType = 'Automatic'},
                @{Name = 'LanmanWorkstation'; StartupType = 'Automatic'},
                @{Name = 'LicenseManager'; StartupType = 'Manual'},
                @{Name = 'LxpSvc'; StartupType = 'Manual'},
                @{Name = 'MSDTC'; StartupType = 'Manual'},
                @{Name = 'MSiSCSI'; StartupType = 'Manual'},
                @{Name = 'MapsBroker'; StartupType = 'Manual'},
                @{Name = 'McpManagementService'; StartupType = 'Manual'},
                @{Name = 'MessagingService_*'; StartupType = 'Manual'},
                @{Name = 'MicrosoftEdgeElevationService'; StartupType = 'Manual'},
                @{Name = 'MixedRealityOpenXRSvc'; StartupType = 'Manual'},
                @{Name = 'MpsSvc'; StartupType = 'Automatic'},
                @{Name = 'MsKeyboardFilter'; StartupType = 'Manual'},
                @{Name = 'NPSMSvc_*'; StartupType = 'Manual'},
                @{Name = 'NaturalAuthentication'; StartupType = 'Manual'},
                @{Name = 'NcaSvc'; StartupType = 'Manual'},
                @{Name = 'NcbService'; StartupType = 'Manual'},
                @{Name = 'NcdAutoSetup'; StartupType = 'Manual'},
                @{Name = 'NetSetupSvc'; StartupType = 'Manual'},
                @{Name = 'NetTcpPortSharing'; StartupType = 'Disabled'},
                @{Name = 'Netlogon'; StartupType = 'Automatic'},
                @{Name = 'Netman'; StartupType = 'Manual'},
                @{Name = 'NgcCtnrSvc'; StartupType = 'Manual'},
                @{Name = 'NgcSvc'; StartupType = 'Manual'},
                @{Name = 'NlaSvc'; StartupType = 'Manual'},
                @{Name = 'OneSyncSvc_*'; StartupType = 'Automatic'},
                @{Name = 'P9RdrService_*'; StartupType = 'Manual'},
                @{Name = 'PNRPAutoReg'; StartupType = 'Manual'},
                @{Name = 'PNRPsvc'; StartupType = 'Manual'},
                @{Name = 'PcaSvc'; StartupType = 'Manual'},
                @{Name = 'PeerDistSvc'; StartupType = 'Manual'},
                @{Name = 'PenService_*'; StartupType = 'Manual'},
                @{Name = 'PerfHost'; StartupType = 'Manual'},
                @{Name = 'PhoneSvc'; StartupType = 'Manual'},
                @{Name = 'PimIndexMaintenanceSvc_*'; StartupType = 'Manual'},
                @{Name = 'PlugPlay'; StartupType = 'Manual'},
                @{Name = 'PolicyAgent'; StartupType = 'Manual'},
                @{Name = 'Power'; StartupType = 'Automatic'},
                @{Name = 'PrintNotify'; StartupType = 'Manual'},
                @{Name = 'PrintWorkflowUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'ProfSvc'; StartupType = 'Automatic'},
                @{Name = 'PushToInstall'; StartupType = 'Manual'},
                @{Name = 'QWAVE'; StartupType = 'Manual'},
                @{Name = 'RasAuto'; StartupType = 'Manual'},
                @{Name = 'RasMan'; StartupType = 'Manual'},
                @{Name = 'RemoteAccess'; StartupType = 'Disabled'},
                @{Name = 'RemoteRegistry'; StartupType = 'Disabled'},
                @{Name = 'RetailDemo'; StartupType = 'Manual'},
                @{Name = 'RmSvc'; StartupType = 'Manual'},
                @{Name = 'RpcEptMapper'; StartupType = 'Automatic'},
                @{Name = 'RpcLocator'; StartupType = 'Manual'},
                @{Name = 'RpcSs'; StartupType = 'Automatic'},
                @{Name = 'SCPolicySvc'; StartupType = 'Manual'},
                @{Name = 'SCardSvr'; StartupType = 'Manual'},
                @{Name = 'SDRSVC'; StartupType = 'Manual'},
                @{Name = 'SEMgrSvc'; StartupType = 'Manual'},
                @{Name = 'SENS'; StartupType = 'Automatic'},
                @{Name = 'SNMPTRAP'; StartupType = 'Manual'},
                @{Name = 'SNMPTrap'; StartupType = 'Manual'},
                @{Name = 'SSDPSRV'; StartupType = 'Manual'},
                @{Name = 'SamSs'; StartupType = 'Automatic'},
                @{Name = 'ScDeviceEnum'; StartupType = 'Manual'},
                @{Name = 'Schedule'; StartupType = 'Automatic'},
                @{Name = 'SecurityHealthService'; StartupType = 'Manual'},
                @{Name = 'Sense'; StartupType = 'Manual'},
                @{Name = 'SensorDataService'; StartupType = 'Manual'},
                @{Name = 'SensorService'; StartupType = 'Manual'},
                @{Name = 'SensrSvc'; StartupType = 'Manual'},
                @{Name = 'SessionEnv'; StartupType = 'Manual'},
                @{Name = 'SgrmBroker'; StartupType = 'Automatic'},
                @{Name = 'SharedAccess'; StartupType = 'Manual'},
                @{Name = 'SharedRealitySvc'; StartupType = 'Manual'},
                @{Name = 'ShellHWDetection'; StartupType = 'Automatic'},
                @{Name = 'SmsRouter'; StartupType = 'Manual'},
                @{Name = 'Spooler'; StartupType = 'Automatic'},
                @{Name = 'SstpSvc'; StartupType = 'Manual'},
                @{Name = 'StateRepository'; StartupType = 'Manual'},
                @{Name = 'StiSvc'; StartupType = 'Manual'},
                @{Name = 'StorSvc'; StartupType = 'Manual'},
                @{Name = 'SysMain'; StartupType = 'Automatic'},
                @{Name = 'SystemEventsBroker'; StartupType = 'Automatic'},
                @{Name = 'TabletInputService'; StartupType = 'Manual'},
                @{Name = 'TapiSrv'; StartupType = 'Manual'},
                @{Name = 'TermService'; StartupType = 'Automatic'},
                @{Name = 'TextInputManagementService'; StartupType = 'Manual'},
                @{Name = 'Themes'; StartupType = 'Automatic'},
                @{Name = 'TieringEngineService'; StartupType = 'Manual'},
                @{Name = 'TimeBroker'; StartupType = 'Manual'},
                @{Name = 'TimeBrokerSvc'; StartupType = 'Manual'},
                @{Name = 'TokenBroker'; StartupType = 'Manual'},
                @{Name = 'TrkWks'; StartupType = 'Automatic'},
                @{Name = 'TroubleshootingSvc'; StartupType = 'Manual'},
                @{Name = 'TrustedInstaller'; StartupType = 'Manual'},
                @{Name = 'UI0Detect'; StartupType = 'Manual'},
                @{Name = 'UdkUserSvc_*'; StartupType = 'Manual'},
                @{Name = 'UevAgentService'; StartupType = 'Disabled'},
                @{Name = 'UmRdpService'; StartupType = 'Manual'},
                @{Name = 'UnistoreSvc_*'; StartupType = 'Manual'},
                @{Name = 'UserDataSvc_*'; StartupType = 'Manual'},
                @{Name = 'UserManager'; StartupType = 'Automatic'},
                @{Name = 'UsoSvc'; StartupType = 'Manual'},
                @{Name = 'VGAuthService'; StartupType = 'Automatic'},
                @{Name = 'VMTools'; StartupType = 'Automatic'},
                @{Name = 'VSS'; StartupType = 'Manual'},
                @{Name = 'VacSvc'; StartupType = 'Manual'},
                @{Name = 'VaultSvc'; StartupType = 'Automatic'},
                @{Name = 'W32Time'; StartupType = 'Manual'},
                @{Name = 'WEPHOSTSVC'; StartupType = 'Manual'},
                @{Name = 'WFDSConMgrSvc'; StartupType = 'Manual'},
                @{Name = 'WMPNetworkSvc'; StartupType = 'Manual'},
                @{Name = 'WManSvc'; StartupType = 'Manual'},
                @{Name = 'WPDBusEnum'; StartupType = 'Manual'},
                @{Name = 'WSService'; StartupType = 'Manual'},
                @{Name = 'WSearch'; StartupType = 'Manual'},
                @{Name = 'WaaSMedicSvc'; StartupType = 'Manual'},
                @{Name = 'WalletService'; StartupType = 'Manual'},
                @{Name = 'WarpJITSvc'; StartupType = 'Manual'},
                @{Name = 'WbioSrvc'; StartupType = 'Manual'},
                @{Name = 'Wcmsvc'; StartupType = 'Automatic'},
                @{Name = 'WcsPlugInService'; StartupType = 'Manual'},
                @{Name = 'WdNisSvc'; StartupType = 'Manual'},
                @{Name = 'WdiServiceHost'; StartupType = 'Manual'},
                @{Name = 'WdiSystemHost'; StartupType = 'Manual'},
                @{Name = 'WebClient'; StartupType = 'Manual'},
                @{Name = 'Wecsvc'; StartupType = 'Manual'},
                @{Name = 'WerSvc'; StartupType = 'Manual'},
                @{Name = 'WiaRpc'; StartupType = 'Manual'},
                @{Name = 'WinDefend'; StartupType = 'Automatic'},
                @{Name = 'WinHttpAutoProxySvc'; StartupType = 'Manual'},
                @{Name = 'WinRM'; StartupType = 'Manual'},
                @{Name = 'Winmgmt'; StartupType = 'Automatic'},
                @{Name = 'WlanSvc'; StartupType = 'Automatic'},
                @{Name = 'WpcMonSvc'; StartupType = 'Manual'},
                @{Name = 'WpnService'; StartupType = 'Manual'},
                @{Name = 'WpnUserService_*'; StartupType = 'Automatic'},
                @{Name = 'WwanSvc'; StartupType = 'Manual'},
                @{Name = 'XblAuthManager'; StartupType = 'Manual'},
                @{Name = 'XblGameSave'; StartupType = 'Manual'},
                @{Name = 'XboxGipSvc'; StartupType = 'Manual'},
                @{Name = 'XboxNetApiSvc'; StartupType = 'Manual'},
                @{Name = 'autotimesvc'; StartupType = 'Manual'},
                @{Name = 'bthserv'; StartupType = 'Manual'},
                @{Name = 'camsvc'; StartupType = 'Manual'},
                @{Name = 'cbdhsvc_*'; StartupType = 'Manual'},
                @{Name = 'cloudidsvc'; StartupType = 'Manual'},
                @{Name = 'dcsvc'; StartupType = 'Manual'},
                @{Name = 'defragsvc'; StartupType = 'Manual'},
                @{Name = 'diagnosticshub.standardcollector.service'; StartupType = 'Manual'},
                @{Name = 'diagsvc'; StartupType = 'Manual'},
                @{Name = 'dmwappushservice'; StartupType = 'Manual'},
                @{Name = 'dot3svc'; StartupType = 'Manual'},
                @{Name = 'edgeupdate'; StartupType = 'Manual'},
                @{Name = 'edgeupdatem'; StartupType = 'Manual'},
                @{Name = 'embeddedmode'; StartupType = 'Manual'},
                @{Name = 'fdPHost'; StartupType = 'Manual'},
                @{Name = 'fhsvc'; StartupType = 'Manual'},
                @{Name = 'gpsvc'; StartupType = 'Automatic'},
                @{Name = 'hidserv'; StartupType = 'Manual'},
                @{Name = 'icssvc'; StartupType = 'Manual'},
                @{Name = 'iphlpsvc'; StartupType = 'Automatic'},
                @{Name = 'lfsvc'; StartupType = 'Manual'},
                @{Name = 'lltdsvc'; StartupType = 'Manual'},
                @{Name = 'lmhosts'; StartupType = 'Manual'},
                @{Name = 'mpssvc'; StartupType = 'Automatic'},
                @{Name = 'netprofm'; StartupType = 'Manual'},
                @{Name = 'nsi'; StartupType = 'Automatic'},
                @{Name = 'p2pimsvc'; StartupType = 'Manual'},
                @{Name = 'p2psvc'; StartupType = 'Manual'},
                @{Name = 'perceptionsimulation'; StartupType = 'Manual'},
                @{Name = 'pla'; StartupType = 'Manual'},
                @{Name = 'seclogon'; StartupType = 'Manual'},
                @{Name = 'shpamsvc'; StartupType = 'Disabled'},
                @{Name = 'smphost'; StartupType = 'Manual'},
                @{Name = 'spectrum'; StartupType = 'Manual'},
                @{Name = 'sppsvc'; StartupType = 'Manual'},
                @{Name = 'ssh-agent'; StartupType = 'Disabled'},
                @{Name = 'svsvc'; StartupType = 'Manual'},
                @{Name = 'swprv'; StartupType = 'Manual'},
                @{Name = 'tiledatamodelsvc'; StartupType = 'Automatic'},
                @{Name = 'tzautoupdate'; StartupType = 'Disabled'},
                @{Name = 'uhssvc'; StartupType = 'Disabled'},
                @{Name = 'upnphost'; StartupType = 'Manual'},
                @{Name = 'vds'; StartupType = 'Manual'},
                @{Name = 'vm3dservice'; StartupType = 'Manual'},
                @{Name = 'vmicguestinterface'; StartupType = 'Manual'},
                @{Name = 'vmicheartbeat'; StartupType = 'Manual'},
                @{Name = 'vmickvpexchange'; StartupType = 'Manual'},
                @{Name = 'vmicrdv'; StartupType = 'Manual'},
                @{Name = 'vmicshutdown'; StartupType = 'Manual'},
                @{Name = 'vmictimesync'; StartupType = 'Manual'},
                @{Name = 'vmicvmsession'; StartupType = 'Manual'},
                @{Name = 'DiagTrack'; StartupType = 'Disabled'},
                @{Name = 'vmicvss'; StartupType = 'Manual'}
            )
            
            foreach ($service in $services) {
                try {
                    if (Get-Service -Name $service.Name -ErrorAction SilentlyContinue) {
                        Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        } catch {}
    }

    function Disable-Telemetry {
        try {
            $telemetryRegistries = @(
                @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0},
                @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0}
            )
            
            foreach ($reg in $telemetryRegistries) {
                Set-RegistrySafe -Path $reg.Path -Name $reg.Name -Value $reg.Value
            }
        } catch {}
    }

    function Set-Wallpaper {
        $wallUrl = 'https://github.com/DeveIopmentSpace/FixOs/blob/main/assets/wallpaper.png?raw=true'
        $wallPath = Join-Path $env:PUBLIC 'FixOs-Wallpaper.png'
        
        try {
            Invoke-WebRequest -Uri $wallUrl -OutFile $wallPath -ErrorAction SilentlyContinue
            
            if (Test-Path $wallPath) {
                Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@ -ErrorAction SilentlyContinue
                [Wallpaper]::SystemParametersInfo(20, 0, $wallPath, 0x01 -bor 0x02)
            }
        } catch {}
    }

    # Execute
    Force-Remove-Apps
    Remove-Edge-Completely
    Optimize-Services
    Disable-Telemetry
    Set-Wallpaper
    Create-ToolboxShortcut
    
    return $true
}

function Apply-RegistryTweaks {
    
    function Set-RegistryForce {
        param(
            [string]$Path,
            [string]$Name,
            [string]$Type,
            [string]$Value,
            [string]$Action = "Add"
        )
        
        try {
            if ($Action -eq "Add") {
                if (-not (Test-Path $Path)) {
                    New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
                }
                New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force -ErrorAction SilentlyContinue | Out-Null
            } elseif ($Action -eq "Delete") {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
            
        }
    }

    function Remove-RegistryKeyForce {
        param([string]$Path)
        
        try {
            if (Test-Path $Path) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {
        
        }
    }

    # Set execution policy for this session
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue | Out-Null

    # Disable Windows Spotlight and set the normal Windows Picture as the desktop background
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnLockScreen" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightActiveUser" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "Wallpaper" -Type "String" -Value "C:\Windows\Web\Wallpaper\Windows\img19.jpg"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "WallpaperStyle" -Type "String" -Value "2"

    # Prevent unwanted application installations
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"

    # Prevent Chat Auto Installation and Remove Chat Icon
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -Name "ConfigureChatAutoInstall" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon" -Type "DWord" -Value 3

    # Start Menu Customization
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins_ProviderSet" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins_WinningProvider" -Type "String" -Value "B5292708-1619-419B-9923-E5D9F3925E71"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" -Name "ConfigureStartPins_LastWrite" -Type "DWord" -Value 1

    # Enable Long File Paths
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type "DWord" -Value 1

    # Disable News and Interests
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type "DWord" -Value 0

    # Disable Windows Consumer Features
    Set-RegistryForce -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1

    # Disable Bitlocker Auto Encryption
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EnhancedStorageDevices" -Name "TCGSecurityActivationDisabled" -Type "DWord" -Value 1

    # Configure Windows Update for Security Updates Only
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type "DWord" -Value 3
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Type "DWord" -Value 365
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Type "DWord" -Value 365

    # Disable Cortana
    Set-RegistryForce -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type "DWord" -Value 0

    # Disable Activity History
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type "DWord" -Value 0

    # Disable Location Tracking
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "String" -Value "Deny"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type "DWord" -Value 0

    # Disable Telemetry
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type "DWord" -Value 0

    # Disable Windows Ink Workspace
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Name "AllowWindowsInkWorkspace" -Type "DWord" -Value 0

    # Disable Feedback Notifications
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type "DWord" -Value 1

    # Disable Advertising ID
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type "DWord" -Value 1

    # Disable Windows Error Reporting
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type "DWord" -Value 1

    # Disable Delivery Optimization
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type "DWord" -Value 0

    # Disable Remote Assistance
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type "DWord" -Value 0

    # Search Windows Update for Drivers First
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type "DWord" -Value 1

    # Performance Optimizations
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value 10
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\ControlSet001\Services\Ndu" -Name "Start" -Type "DWord" -Value 2
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type "DWord" -Value 30

    # Gaming Optimizations
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Type "DWord" -Value 8
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Type "DWord" -Value 6
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type "String" -Value "High"

    # Hide Meet Now Button
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    # Fix Managed by your organization in Edge
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    # Disable Wifi-Sense
    Set-RegistryForce -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type "DWord" -Value 0

    # Disable Storage Sense
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Type "DWord" -Value 0

    # Disable Xbox GameDVR
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type "DWord" -Value 0

    # Disable Tablet Mode
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" -Name "TabletMode" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" -Name "SignInMode" -Type "DWord" -Value 1

    # Disable Automatic Restart Sign On
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableAutomaticRestartSignOn" -Type "DWord" -Value 1

    # Disable OneDrive Automatic Backups
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptIn" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type "DWord" -Value 1

    # Disable Push To Install
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall" -Name "DisablePushToInstall" -Type "DWord" -Value 1

    # Disable Consumer Account State Content
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Type "DWord" -Value 1

    # Disable Cloud Optimized Content
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Type "DWord" -Value 1

    # Delete Microsoft Edge Registry Entries
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Applications\Microsoft.MicrosoftEdge.Stable_124.0.2478.105_neutral__8wekyb3d8bbwe"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications\Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\InboxApplications\Microsoft.MicrosoftEdgeDevToolsClient_10.0.19041.1023_neutral__8wekyb3d8bbwe"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\S-1-5-21-2466455740-832722602-188176761-1001\Microsoft.MicrosoftEdge.Stable_124.0.2478.105_neutral__8wekyb3d8bbwe"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\S-1-5-21-2466455740-832722602-188176761-1001\Microsoft.MicrosoftEdge_44.19041.1266.0_neutral__8wekyb3d8bbwe"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\S-1-5-21-2466455740-832722602-188176761-1001\Microsoft.MicrosoftEdgeDevToolsClient_10.0.19041.1023_neutral__8wekyb3d8bbwe"

    # Delete Scheduled Tasks Registry Keys
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0600DD45-FAF2-4131-A006-0B17509B9F78}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{4738DE7A-BCC1-4E2D-B1B0-CADB044BFA81}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{6FAC31FA-4A85-4E64-BFD5-2154FF4594B3}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FC931F16-B50A-472E-B061-B6F79A71EF59}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0671EB05-7D95-4153-A32B-1426B9FE61DB}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{87BF85F4-2CE1-4160-96EA-52F554AA28A2}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{8A9C643C-3D74-4099-B6BD-9C6D170898B1}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{E3176A65-4E44-4ED3-AA73-3283660ACB9C}"

    # Block Automatic Upgrade from Windows 10 22H2 to Windows 11
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersion" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersionInfo" -Type "String" -Value "22H2"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ProductVersion" -Type "String" -Value "Windows 10"

    # Block Workplace Join
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -Name "BlockAADWorkplaceJoin" -Type "DWord" -Value 1

    # Disable Personalized Content
    $contentDeliveryKeys = @(
        "ContentDeliveryAllowed",
        "FeatureManagementEnabled",
        "OEMPreInstalledAppsEnabled",
        "PreInstalledAppsEnabled",
        "PreInstalledAppsEverEnabled",
        "SilentInstalledAppsEnabled",
        "RotatingLockScreenEnabled",
        "RotatingLockScreenOverlayEnabled",
        "SoftLandingEnabled",
        "SubscribedContentEnabled",
        "SubscribedContent-310093Enabled",
        "SubscribedContent-338387Enabled",
        "SubscribedContent-338388Enabled",
        "SubscribedContent-338389Enabled",
        "SubscribedContent-338393Enabled",
        "SubscribedContent-353698Enabled",
        "SubscribedContent-353694Enabled",
        "SubscribedContent-353696Enabled",
        "SystemPaneSuggestionsEnabled"
    )

    foreach ($key in $contentDeliveryKeys) {
        Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name $key -Type "DWord" -Value 0
    }

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "IsMiEnabled" -Type "DWord" -Value 0
    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions"
    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps"
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Type "DWord" -Value 0

    # Remove Copilot
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Runonce" -Name "UninstallCopilot" -Type "String" -Value ""
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1

    # Remove Store Banner in Notepad
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Notepad" -Name "ShowStoreBanner" -Type "DWord" -Value 0

    # Remove OneDrive
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" -Action "Delete"

    # Taskbar Customizations
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type "DWord" -Value 0

    # Start Menu Customizations
    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Type "DWord" -Value 0

    # Hide People from Taskbar
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type "DWord" -Value 0

    # Hide Task View Button
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "DWord" -Value 0

    # Hide News and Interests
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type "DWord" -Value 2
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type "DWord" -Value 0

    # Disable Notifications
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 0

    # Disable Sync and Location Services
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "SettingSyncEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "LocationServicesEnabled" -Type "DWord" -Value 0

    # Disable Input Personalization
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type "DWord" -Value 1

    # Disable Feedback
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feedback" -Name "AutoSample" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feedback" -Name "ServiceEnabled" -Type "DWord" -Value 0

    # Disable Recent Documents Tracking
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Type "DWord" -Value 0

    # Disable Language List Access
    Set-RegistryForce -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Type "DWord" -Value 1

    # Disable App Launch Tracking
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type "DWord" -Value 0

    # Disable Background Apps
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type "DWord" -Value 1

    # Disable App Diagnostics
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppDiagnostics" -Name "AppDiagnosticsEnabled" -Type "DWord" -Value 0

    # Disable Delivery Optimization (Current User)
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "DODownloadMode" -Type "DWord" -Value 0

    # Disable Tablet Mode (Current User)
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ImmersiveShell" -Name "TabletMode" -Type "DWord" -Value 0

    # Disable Use Sign-In Info
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication" -Name "UseSignInInfo" -Type "DWord" -Value 0

    # Disable Maps Auto Download
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Maps" -Name "AutoDownload" -Type "DWord" -Value 0

    # Disable Telemetry and Ads (Current User)
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type "DWord" -Value 0

    # File Explorer Settings
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    # Auto End Tasks on Shutdown
    Set-RegistryForce -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "DWord" -Value 1

    # Hide Meet Now Button (Current User)
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    # Enable End Task With Right Click
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDeveloperSettings" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarEndTask" -Type "DWord" -Value 1

    # Disable Notification Center
    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type "DWord" -Value 1

    # Disable Xbox GameDVR (Current User)
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type "DWord" -Value 2
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type "DWord" -Value 0

    # Disable Bing Search in Start Menu
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type "DWord" -Value 1

    # Enable NumLock on Startup
    Set-RegistryForce -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type "String" -Value "2"

    # Disable Mouse Acceleration
    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type "String" -Value "0"
    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type "String" -Value "0"
    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type "String" -Value "0"

    # Disable Sticky Keys
    Set-RegistryForce -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type "String" -Value "506"
    Set-RegistryForce -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "HotkeyFlags" -Type "String" -Value "58"

    # Windows 10 Taskbar Customizations
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAcrylicOpacity" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type "DWord" -Value 1

    # Restore Windows Photo Viewer and Set as Default
    $photoExtensions = @(".bmp", ".cr2", ".dib", ".gif", ".ico", ".jfif", ".jpe", ".jpeg", ".jpg", ".jxr", ".png", ".tif", ".tiff", ".wdp")

    foreach ($ext in $photoExtensions) {
        Set-RegistryForce -Path "HKCU:\SOFTWARE\Classes\$ext" -Name "(default)" -Type "String" -Value "PhotoViewer.FileAssoc.Tiff"
        Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\OpenWithProgids" -Name "PhotoViewer.FileAssoc.Tiff" -Type "None" -Value $null
    }

    # Disable Windows Recall on Copilot+ PC
    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Windows AI" -Name "TurnOffSavingSnapshots" -Type "DWord" -Value 1

    # Set Communication Activity to "Do Nothing"
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Type "DWord" -Value 3

    # Enable User Account Control
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Type "DWord" -Value 3

    # Hide Task View button (duplicate removal)
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "DWord" -Value 0

    # Delete namespace keys
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"

    # Hide Home page in Settings
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    # Remove Teams and LinkedIn registry traces
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "LinkedIn" -Force -ErrorAction SilentlyContinue | Out-Null
    
    # Update Hostname and NV Hostname 
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value "FixOs" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "NV Hostname" -Value "FixOs" -Force | Out-Null
    
    # ======================================================== #
    #                     Additional tweaks                    #
    # ======================================================== #


    # Kill any OneDrive processes
    Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # Attempt to uninstall OneDrive via system uninstaller (both 32-bit and 64-bit)
    $OneDriveSetup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $OneDriveSetup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (Test-Path $OneDriveSetup32) { Start-Process $OneDriveSetup32 "/uninstall" -Wait -ErrorAction SilentlyContinue }
    if (Test-Path $OneDriveSetup64) { Start-Process $OneDriveSetup64 "/uninstall" -Wait -ErrorAction SilentlyContinue }

    # Remove leftover OneDrive files and folders
    $oneDriveDirs = @(
        "$env:SystemDrive\OneDriveTemp",
        "$env:USERPROFILE\OneDrive",
        "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive",
        "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk",
        "$env:ProgramData\Microsoft OneDrive",
        "$env:LOCALAPPDATA\Microsoft\OneDrive",
        "$env:ProgramFiles\Microsoft OneDrive",
        "$env:ProgramFiles(x86)\Microsoft OneDrive",
        "$env:SystemDrive\ProgramData\Microsoft OneDrive",
        "$env:USERPROFILE\AppData\Roaming\Microsoft\OneDrive"
    )
    foreach ($dir in $oneDriveDirs) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # Remove OneDrive from Explorer navigation pane (registry)
    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -ErrorAction SilentlyContinue

    # Remove OneDrive scheduled tasks and services
    Get-ScheduledTask | Where-Object {$_.TaskName -like "*OneDrive*"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    if (Get-Service -Name "OneSyncSvc*" -ErrorAction SilentlyContinue) {
        Get-Service -Name "OneSyncSvc*" | Stop-Service -Force -ErrorAction SilentlyContinue
        Get-Service -Name "OneSyncSvc*" | Set-Service -StartupType Disabled -ErrorAction SilentlyContinue
    }

    # Remove OneDrive registry traces (major hives)
    Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

        # Remove OneDrive registry traces (major hives)
    Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    # BLOCK OneDriveSetup from running again by denying execution permissions and renaming/removing

    $oneDriveSetups = @($OneDriveSetup32, $OneDriveSetup64) | Where-Object { Test-Path $_ }
    foreach ($setup in $oneDriveSetups) {
        # Try to rename the file (if running as admin)
        try {
            Rename-Item -Path $setup -NewName ($setup + ".bak") -ErrorAction Stop
        } catch {
            # If rename fails (probably in use or not permitted) try to deny execution
            try {
                # Remove all permissions
                icacls $setup /inheritance:r /deny Everyone:RX 2>&1 | Out-Null
            } catch {}
        }
    }

    # Additionally, block OneDriveSetup via Image File Execution Options "Debugger" (using silent PowerShell stub)
    $ifepPath32 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\OneDriveSetup.exe"
    $ifepPath64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\OneDriveSetup.exe"
    $silentPSCmd = 'powershell.exe -WindowStyle Hidden -NoProfile -Command "exit"'
    New-Item -Path $ifepPath32 -Force | Out-Null
    Set-ItemProperty -Path $ifepPath32 -Name "Debugger" -Value $silentPSCmd -Force
    New-Item -Path $ifepPath64 -Force | Out-Null
    Set-ItemProperty -Path $ifepPath64 -Name "Debugger" -Value $silentPSCmd -Force

    # Kill any Teams processes
    Get-Process -Name "Teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    # Uninstall Teams for all users (Store app version)
    Get-AppxPackage -AllUsers -Name "*Teams*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Teams*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

    # Uninstall Teams Machine-Wide Installer (per-machine)
    $teamsUninstallers = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
        Where-Object { $_.GetValue('DisplayName') -like "*Teams*" -or $_.GetValue('DisplayName') -like "*Teams Machine-Wide Installer*" }
    foreach ($u in $teamsUninstallers) {
        $uninstPath = $u.GetValue('UninstallString')
        if ($uninstPath) {
            try { Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "$uninstPath /uninstall /quiet /norestart" -WindowStyle Hidden -Wait } catch {}
        }
    }

    # Remove Teams leftovers from common install locations
    $teamsDirs = @(
        "$env:LOCALAPPDATA\Microsoft\Teams",
        "$env:APPDATA\Microsoft\Teams",
        "$env:APPDATA\Teams",
        "$env:ProgramData\Microsoft Teams",
        "$env:USERPROFILE\AppData\Local\Microsoft\Teams",
        "$env:USERPROFILE\AppData\Roaming\Microsoft\Teams",
        "$env:ProgramFiles\Teams Installer",
        "$env:ProgramFiles(x86)\Teams Installer"
    )
    foreach ($dir in $teamsDirs) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # Remove Teams shortcuts from Start Menu & Taskbar
    $teamsShortcuts = @(
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Teams.lnk",
        "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Teams.lnk",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Microsoft Teams.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Teams.lnk"
    )
    foreach ($shortcut in $teamsShortcuts) {
        if (Test-Path $shortcut) { Remove-Item $shortcut -Force -ErrorAction SilentlyContinue }
    }

    # Remove Teams registry traces (major hives)
    Remove-Item -Path "HKCU:\Software\Microsoft\Office\Teams" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Teams" -Recurse -Force -ErrorAction SilentlyContinue

    # Unpin all Taskbar shortcuts except Windows Explorer 
    $quickLaunchDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    if (Test-Path $quickLaunchDir) {
        Get-ChildItem -Path $quickLaunchDir -Include *.lnk -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne 'File Explorer.lnk' -and
            $_.Name -ne 'Windows Explorer.lnk' -and
            $_.Name -ne 'explorer.lnk'
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }


    # Remove all possible Start Menu and Taskbar shortcuts
    $shortcuts = @(
        "$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Teams.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\LinkedIn.lnk",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs\Microsoft Teams.lnk",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs\LinkedIn.lnk"
    )
    foreach ($shortcut in $shortcuts) {
        if (Test-Path $shortcut) { Remove-Item $shortcut -Force -ErrorAction SilentlyContinue | Out-Null }
    }

    # Disable search history and account-based search integration
    $SearchRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
    New-Item -Path $SearchRegPath -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsDeviceSearchHistoryEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsCloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsMSACloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsAADCloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null


    # --- Remove provisioned packages and installed appx for all users ---
    $appsToRemove = @(
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.GamingApp",
        "Microsoft.Family",
        "Microsoft.DevHome",
        "Microsoft.LinkedIn"
    )

    foreach ($app in $appsToRemove) {
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "$app*" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "$app*" } | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue
    }

    # --- Remove related registry keys using PowerShell ---
    $regPaths = @(
        "HKCU:\Software\Microsoft\XboxApp",
        "HKLM:\Software\Microsoft\Xbox",
        "HKLM:\Software\Microsoft\GamingServices",
        "HKCU:\Software\Microsoft\Family",
        "HKCU:\Software\Microsoft\DevHome",
        "HKCU:\Software\Microsoft\LinkedIn"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Remove Start Menu shortcuts (Teams, LinkedIn, Family, Dev Home, Xbox) 

    $shortcutPatterns = @(
        "*Teams*.lnk",
        "*LinkedIn*.lnk",
        "*Family*.lnk",
        "*Dev Home*.lnk",
        "*Xbox*.lnk"
    )

    $startMenuDirs = @(
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        "C:\Users\Public\Desktop"
    )

    # Enumerate all user profiles, except Default, Public, All Users
    $profiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(Default|Public|All Users)$' }
    foreach ($profile in $profiles) {
        $userStartMenu = Join-Path $profile.FullName "AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
        if (Test-Path $userStartMenu) {
            $startMenuDirs += $userStartMenu
        }
        $userDesktop = Join-Path $profile.FullName "Desktop"
        if (Test-Path $userDesktop) {
            $startMenuDirs += $userDesktop
        }
    }

    $startMenuDirs = $startMenuDirs | Select-Object -Unique

    foreach ($dir in $startMenuDirs) {
        foreach ($pattern in $shortcutPatterns) {
            $fullPattern = Join-Path $dir $pattern
            $matches = Get-ChildItem -Path $fullPattern -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                try {
                    Remove-Item $match.FullName -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }


    # Remove provisioned Microsoft Family and LinkedIn apps
    $familyProv = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match 'MicrosoftFamily|LinkedIn' }
    foreach ($prov in $familyProv) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
        } catch {

        }
    }


    # Remove installed Microsoft Family and LinkedIn for all users
    $linkedInPackages = @(
        "LinkedIn.LinkedIn_{*}",            
        "CFQ7TTC0HHRK"                      
    )
    $familyPackages = @(
        "MicrosoftCorporationII.MicrosoftFamily_{*}",
        "MicrosoftFamily"
    )

    # Remove for all users by querying full package family names and installed names
    $allUsers = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | ForEach-Object {
        $sid = $_.PSChildName
        try {
            $user = (Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.SID -eq $sid })
            if ($user) { $sid }
        } catch {}
    }

    function Remove-AppxRegex {
        param ($regex)
        $pkgs = Get-AppxPackage -AllUsers | Where-Object { $_.Name -match $regex }
        foreach ($pkg in $pkgs) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            } catch { }
        }
    }
    # Use patterns covering real LinkedIn app names
    Remove-AppxRegex 'LinkedIn|MicrosoftFamily|CFQ7TTC0HHRK'

    # Remove provisioned (preinstalled for new users) LinkedIn and Family
    $provPkgs = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match 'LinkedIn|MicrosoftFamily' }
    foreach ($prov in $provPkgs) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
        } catch {}
    }

    # Remove leftover Start Menu entries, folders, and known installed folders for Microsoft Family and LinkedIn
    $appRelatedPatterns = @("*Microsoft Family*", "*LinkedIn*")
    foreach ($dir in $startMenuDirs) {
        foreach ($pattern in $appRelatedPatterns) {
            $matches = Get-ChildItem -Path $dir -Filter $pattern -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                try {
                    Remove-Item $match.FullName -Recurse -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }

    # Scan for LinkedIn shortcuts on all users' desktops (handles your image: LinkedIn.lnk icon is still on Desktop)
    $userProfileDirs = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(Default|Public|All Users)$' }
    foreach ($profile in $userProfileDirs) {
        $desktop = Join-Path $profile.FullName "Desktop"
        if (Test-Path $desktop) {
            $lnkMatches = Get-ChildItem -Path $desktop -Filter "*LinkedIn*.lnk" -ErrorAction SilentlyContinue
            foreach ($lnk in $lnkMatches) {
                try {
                    Remove-Item $lnk.FullName -Force -ErrorAction SilentlyContinue
                } catch {}
            }
        }
    }

    # Additional cleanup: registry traces 
    $regFamily = "HKCU:\Software\Microsoft\MicrosoftFamily"
    $regLinkedIn = "HKCU:\Software\Microsoft\Office\16.0\Common\Internet\LinkedIn"
    foreach ($regKey in @($regFamily, $regLinkedIn)) {
        if (Test-Path $regKey) {
            try {
                Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue
            } catch { }
        }
    }

    # DISM & SFC 

    try {
        $dismArgs = "/Online /Cleanup-Image /RestoreHealth"
        $dismOut = "$env:TEMP\dism_silent.txt"
        $dismErr = "$env:TEMP\dism_silent_err.txt"
        Dism.exe $dismArgs *>$dismOut 2>$dismErr
    } catch {

    }

    try {
        $sfcOut = "$env:TEMP\sfc_silent.txt"
        $sfcErr = "$env:TEMP\sfc_silent_err.txt"
        sfc /scannow *>$sfcOut 2>$sfcErr
    } catch {

    }

    # ======================================================== #
    #                          Programs                        #
    # ======================================================== #

    $ErrorActionPreference = "Stop"

    # Explicit winget path (more reliable in scripts)
    $winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

    # Ensure winget exists
    if (-not (Test-Path $winget)) {
        $installerUrl = "https://aka.ms/getwinget"
        $tempFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"

        Invoke-WebRequest -Uri $installerUrl -OutFile $tempFile
        Add-AppxPackage -Path $tempFile
        Start-Sleep -Seconds 5
    }

    # Verify winget again
    if (-not (Test-Path $winget)) {
        Write-Error "winget not available"
        exit 1
    }

    # Common silent flags
    $commonFlags = @(
        "--exact",
        "--silent",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--source", "winget"
    )

    # Install Brave
    winget install --id Brave.Brave @commonFlags

    # Install VLC Media Player
    winget install --id VideoLAN.VLC @commonFlags

    # Install Nilesoft Shell
    winget install --id Nilesoft.Shell @commonFlags

    # Install Notepads
    winget install JackieLiu.NotepadsApp @commonFlags

    # Install Flow Launcher
    winget install "Flow Launcher" @commonFlags

    return $true
}

function Install-FixOS {
    Write-Host "[                    ] 0%" -NoNewline
    
    Start-Sleep -Milliseconds 100
    $optimizationResult = Start-WindowsOptimization
    Write-Host "`r[####                ] 25%" -NoNewline
    
    Start-Sleep -Milliseconds 100
    $registryResult = Apply-RegistryTweaks
    Write-Host "`r[##########          ] 50%" -NoNewline
    
    Start-Sleep -Milliseconds 100
    
    $finalRegKeys = @(
        "HKCU:\Software\Microsoft\OneDrive",
        "HKCU:\Software\Microsoft\Teams",
        "HKCU:\Software\Microsoft\XboxApp",
        "HKLM:\Software\Microsoft\Xbox",
        "HKLM:\Software\Microsoft\GamingServices",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudExperienceHost",
        "HKCU:\Software\Microsoft\LinkedIn",
        "HKCU:\Software\Microsoft\Family"
    )
    
    foreach ($regKey in $finalRegKeys) {
        if (Test-Path $regKey) {
            Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    Write-Host "`r[###############     ] 75%" -NoNewline
    Start-Sleep -Milliseconds 100
    
    Write-Host "`r[####################] 100%"
    Write-Host "Installation finished"
    Write-Host "Press any key to return to the Menu"
    
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Show-Menu
}


try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
    
    if ($Install) {
        Install-FixOS
    } else {
        Show-Menu
    }
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}