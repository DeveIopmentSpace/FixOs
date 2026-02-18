function Start-WindowsOptimization {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Please run as Administrator"
        return $false
    }

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

    function Remove-CrapApps {
        $appsToRemove = @(
        "Microsoft.549981C3F5F10"
        "Microsoft.BingNews"
        "Microsoft.BingWeather"
        "Microsoft.BingSports"
        "Microsoft.BingFinance"
        "Microsoft.BingFoodAndDrink"
        "Microsoft.BingHealthAndFitness"
        "Microsoft.BingTravel"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.Messaging"
        "Microsoft.Microsoft3DViewer"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.MixedReality.Portal"
        "Microsoft.Office.OneNote"
        "Microsoft.OneConnect"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.SkypeApp"
        "Microsoft.Wallet"
        "Microsoft.WindowsAlarms"
        "Microsoft.WindowsCamera"
        "Microsoft.WindowsCommunicationsApps"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameCallableUI"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.YourPhone"
        "Microsoft.ZuneMusic"
        "Microsoft.ZuneVideo"
        "Microsoft.Advertising.Xaml"
        "Microsoft.Todos"
        "Microsoft.PowerAutomateDesktop"
        "Microsoft.Windows.DevHome"
        "Clipchamp.Clipchamp"
        "Microsoft.Copilot"
        "Microsoft.WindowsCopilot"
        "Microsoft.LinkedIn"
        "Microsoft.Teams"
        "Microsoft.People"
        "Microsoft.MixedReality"
        "MicrosoftCorporationII.QuickAssist"
        "Microsoft.OutlookForWindows"
        "microsoft.windowscommunicationsapps"
        "Microsoft.WindowsStore"
        "Microsoft.StorePurchaseApp"
        "Microsoft.Widgets"
        "Microsoft.Windows.Photos"
        "Microsoft.Paint"
        "Microsoft.MSPaint"
        "Microsoft.WindowsCalculator"
        "Microsoft.WindowsNotepad"
        "Microsoft.MicrosoftStickyNotes"
        "Microsoft.People"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.Getstarted"
        "Microsoft.MicrosoftEdge"
        "Microsoft.MicrosoftEdge.Stable"
        "MicrosoftEdge"
        "Microsoft.WebMediaExtensions"
        "Microsoft.WebpImageExtension"
        "Microsoft.HEIFImageExtension"
        "Microsoft.VP9VideoExtensions"
        "Microsoft.RawImageExtension"
        "Microsoft.HEVCVideoExtension"
        "Microsoft.DolbyAudioExtensions"
        "Microsoft.DolbyVisionExtensions"
        "Microsoft.MPEG2VideoExtension"
        )

        foreach ($app in $appsToRemove) {
            try {
                Remove-AppxSafe -AppName $app
            } catch {}
        }
    }

    function Optimize-Services {
        try {
            $servicesToDisable = @(
                @{Name = 'DiagTrack'; StartupType = 'Disabled'}
                @{Name = 'dmwappushservice'; StartupType = 'Disabled'}
                @{Name = 'WSearch'; StartupType = 'Disabled'}
                @{Name = 'XboxGipSvc'; StartupType = 'Disabled'}
                @{Name = 'XblAuthManager'; StartupType = 'Disabled'}
                @{Name = 'XblGameSave'; StartupType = 'Disabled'}
                @{Name = 'XboxNetApiSvc'; StartupType = 'Disabled'}
                @{Name = 'OneSyncSvc'; StartupType = 'Disabled'}
                @{Name = 'PcaSvc'; StartupType = 'Disabled'}
                @{Name = 'WpcMonSvc'; StartupType = 'Disabled'}
                @{Name = 'wisvc'; StartupType = 'Disabled'}
                @{Name = 'RetailDemo'; StartupType = 'Disabled'}
                @{Name = 'MessagingService'; StartupType = 'Disabled'}
                @{Name = 'lfsvc'; StartupType = 'Disabled'}
                @{Name = 'MapsBroker'; StartupType = 'Disabled'}
                @{Name = 'PimIndexMaintenanceSvc'; StartupType = 'Disabled'}
                @{Name = 'UnistoreSvc'; StartupType = 'Disabled'}
                @{Name = 'UserDataSvc'; StartupType = 'Disabled'}
                @{Name = 'WpnService'; StartupType = 'Disabled'}
                @{Name = 'WpnUserService'; StartupType = 'Disabled'}
                @{Name = 'WdNisSvc'; StartupType = 'Disabled'}
                @{Name = 'Sense'; StartupType = 'Disabled'}
                @{Name = 'wscsvc'; StartupType = 'Disabled'}
                @{Name = 'SysMain'; StartupType = 'Disabled'}
                @{Name = 'edgeupdate'; StartupType = 'Disabled'}
                @{Name = 'edgeupdatem'; StartupType = 'Disabled'}
                @{Name = 'MicrosoftEdgeElevationService'; StartupType = 'Disabled'}
                @{Name = 'BcastDVRUserService'; StartupType = 'Disabled'}
                @{Name = 'CaptureService'; StartupType = 'Disabled'}
                @{Name = 'cbdhsvc'; StartupType = 'Disabled'}
                @{Name = 'ConsentUxUserSvc'; StartupType = 'Disabled'}
                @{Name = 'CredentialEnrollmentManagerUserSvc'; StartupType = 'Disabled'}
                @{Name = 'DeviceAssociationBrokerSvc'; StartupType = 'Disabled'}
                @{Name = 'DevicePickerUserSvc'; StartupType = 'Disabled'}
                @{Name = 'DevicesFlowUserSvc'; StartupType = 'Disabled'}
                @{Name = 'MessagingService'; StartupType = 'Disabled'}
                @{Name = 'NPSMSvc'; StartupType = 'Disabled'}
                @{Name = 'P9RdrService'; StartupType = 'Disabled'}
                @{Name = 'PenService'; StartupType = 'Disabled'}
                @{Name = 'PrintWorkflowUserSvc'; StartupType = 'Disabled'}
                @{Name = 'UdkUserSvc'; StartupType = 'Disabled'}
                @{Name = 'WpnUserService'; StartupType = 'Disabled'}
                @{Name = 'autotimesvc'; StartupType = 'Disabled'}
                @{Name = 'tzautoupdate'; StartupType = 'Disabled'}
                @{Name = 'shpamsvc'; StartupType = 'Disabled'}
                @{Name = 'PhoneSvc'; StartupType = 'Disabled'}
                @{Name = 'RemoteRegistry'; StartupType = 'Disabled'}
                @{Name = 'RemoteAccess'; StartupType = 'Disabled'}
                @{Name = 'SessionEnv'; StartupType = 'Disabled'}
                @{Name = 'TermService'; StartupType = 'Disabled'}
                @{Name = 'UmRdpService'; StartupType = 'Disabled'}
                @{Name = 'SharedAccess'; StartupType = 'Disabled'}
                @{Name = 'hidserv'; StartupType = 'Disabled'}
                @{Name = 'WbioSrvc'; StartupType = 'Disabled'}
                @{Name = 'FrameServer'; StartupType = 'Disabled'}
                @{Name = 'StiSvc'; StartupType = 'Disabled'}
                @{Name = 'WiaRpc'; StartupType = 'Disabled'}
                @{Name = 'icssvc'; StartupType = 'Disabled'}
                @{Name = 'WlanSvc'; StartupType = 'Disabled'}
                @{Name = 'WwanSvc'; StartupType = 'Disabled'}
            )
            
            $servicesToManual = @(
                @{Name = 'BITS'; StartupType = 'Manual'}
                @{Name = 'wuauserv'; StartupType = 'Manual'}
                @{Name = 'DoSvc'; StartupType = 'Manual'}
                @{Name = 'UsoSvc'; StartupType = 'Manual'}
                @{Name = 'Spooler'; StartupType = 'Manual'}
                @{Name = 'W32Time'; StartupType = 'Manual'}
                @{Name = 'FontCache'; StartupType = 'Manual'}
                @{Name = 'Themes'; StartupType = 'Manual'}
                @{Name = 'Schedule'; StartupType = 'Manual'}
                @{Name = 'TrustedInstaller'; StartupType = 'Manual'}
                @{Name = 'TabletInputService'; StartupType = 'Manual'}
                @{Name = 'TextInputManagementService'; StartupType = 'Manual'}
                @{Name = 'AudioEndpointBuilder'; StartupType = 'Manual'}
                @{Name = 'Audiosrv'; StartupType = 'Manual'}
                @{Name = 'CDPSvc'; StartupType = 'Manual'}
                @{Name = 'CDPUserSvc'; StartupType = 'Manual'}
                @{Name = 'CoreMessagingRegistrar'; StartupType = 'Manual'}
                @{Name = 'StateRepository'; StartupType = 'Manual'}
                @{Name = 'StorSvc'; StartupType = 'Manual'}
                @{Name = 'TimeBrokerSvc'; StartupType = 'Manual'}
                @{Name = 'TokenBroker'; StartupType = 'Manual'}
                @{Name = 'UserManager'; StartupType = 'Manual'}
                @{Name = 'VaultSvc'; StartupType = 'Manual'}
                @{Name = 'WinHttpAutoProxySvc'; StartupType = 'Manual'}
                @{Name = 'Winmgmt'; StartupType = 'Manual'}
                @{Name = 'Wcmsvc'; StartupType = 'Manual'}
                @{Name = 'nsi'; StartupType = 'Manual'}
                @{Name = 'iphlpsvc'; StartupType = 'Manual'}
                @{Name = 'Dnscache'; StartupType = 'Manual'}
                @{Name = 'Dhcp'; StartupType = 'Manual'}
                @{Name = 'EventLog'; StartupType = 'Manual'}
                @{Name = 'EventSystem'; StartupType = 'Manual'}
                @{Name = 'gpsvc'; StartupType = 'Manual'}
                @{Name = 'ProfSvc'; StartupType = 'Manual'}
                @{Name = 'Power'; StartupType = 'Manual'}
                @{Name = 'DcomLaunch'; StartupType = 'Manual'}
                @{Name = 'RpcSs'; StartupType = 'Manual'}
                @{Name = 'RpcEptMapper'; StartupType = 'Manual'}
                @{Name = 'SamSs'; StartupType = 'Manual'}
                @{Name = 'LanmanServer'; StartupType = 'Manual'}
                @{Name = 'LanmanWorkstation'; StartupType = 'Manual'}
                @{Name = 'PlugPlay'; StartupType = 'Manual'}
                @{Name = 'SENS'; StartupType = 'Manual'}
                @{Name = 'ShellHWDetection'; StartupType = 'Manual'}
                @{Name = 'TrkWks'; StartupType = 'Manual'}
                @{Name = 'tiledatamodelsvc'; StartupType = 'Manual'}
                @{Name = 'BrokerInfrastructure'; StartupType = 'Manual'}
                @{Name = 'SystemEventsBroker'; StartupType = 'Manual'}
                @{Name = 'CryptSvc'; StartupType = 'Manual'}
                @{Name = 'DPS'; StartupType = 'Manual'}
                @{Name = 'MpsSvc'; StartupType = 'Manual'}
                @{Name = 'mpssvc'; StartupType = 'Manual'}
                @{Name = 'BFE'; StartupType = 'Manual'}
                @{Name = 'KeyIso'; StartupType = 'Manual'}
                @{Name = 'Netlogon'; StartupType = 'Manual'}
                @{Name = 'NlaSvc'; StartupType = 'Manual'}
                @{Name = 'PolicyAgent'; StartupType = 'Manual'}
                @{Name = 'SgrmBroker'; StartupType = 'Manual'}
                @{Name = 'WinDefend'; StartupType = 'Manual'}
                @{Name = 'SecurityHealthService'; StartupType = 'Manual'}
            )
            
            foreach ($service in $servicesToDisable) {
                try {
                    $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                    if ($svc) {
                        Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
                        if ($svc.Status -eq 'Running') {
                            Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                        }
                    }
                } catch {}
            }
            
            foreach ($service in $servicesToManual) {
                try {
                    $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                    if ($svc) {
                        Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
        } catch {}
    }

    function Remove-EdgeCompletely {
        try {
            Get-Process -Name "*edge*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            $edgePaths = @(
                "C:\Program Files (x86)\Microsoft\Edge"
                "C:\Program Files (x86)\Microsoft\EdgeWebView"
                "C:\Program Files (x86)\Microsoft\EdgeUpdate"
                "C:\Program Files (x86)\Microsoft\EdgeCore"
                "C:\Windows\System32\Microsoft-Edge-Webview"
                "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
                "C:\Windows\SystemApps\Microsoft.MicrosoftEdgeDevToolsClient_8wekyb3d8bbwe"
                "$env:LOCALAPPDATA\Microsoft\Edge"
                "$env:ProgramData\Microsoft\Edge"
            )
            foreach ($path in $edgePaths) { if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue } }
            
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Edge"
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge"
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
            Remove-RegistryKey -Path "HKCU:\SOFTWARE\Microsoft\Edge"
            Remove-RegistryKey -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
        } catch {}
    }

    function Disable-Telemetry {
        try {
            $telemetryRegistries = @(
                @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0}
                @{Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0}
                @{Path = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0}
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

    Remove-CrapApps
    Optimize-Services
    Disable-Telemetry
    Set-Wallpaper
    Create-ToolboxShortcut
    
    return $true
}

function Apply-RegistryTweaks {
    
    function Set-RegistryForce {
        param([string]$Path,[string]$Name,[string]$Type,[string]$Value,[string]$Action = "Add")
        
        try {
            if ($Action -eq "Add") {
                if (-not (Test-Path $Path)) {
                    New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
                }
                New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force -ErrorAction SilentlyContinue | Out-Null
            } elseif ($Action -eq "Delete") {
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
    }

    function Remove-RegistryKeyForce {
        param([string]$Path)
        
        try {
            if (Test-Path $Path) {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } catch {}
    }

    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue | Out-Null

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightOnLockScreen" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightActiveUser" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -Name "ConfigureChatAutoInstall" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon" -Type "DWord" -Value 3

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins_ProviderSet" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start" -Name "ConfigureStartPins_WinningProvider" -Type "String" -Value "B5292708-1619-419B-9923-E5D9F3925E71"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start" -Name "ConfigureStartPins_LastWrite" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EnhancedStorageDevices" -Name "TCGSecurityActivationDisabled" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type "DWord" -Value 3
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Type "DWord" -Value 365
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferQualityUpdatesPeriodInDays" -Type "DWord" -Value 365
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersion" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersionInfo" -Type "String" -Value "22H2"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ProductVersion" -Type "String" -Value "Windows 10"

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type "String" -Value "Deny"
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace" -Name "AllowWindowsInkWorkspace" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" -Name "SearchOrderConfig" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Type "DWord" -Value 10
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type "DWord" -Value 30

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Type "DWord" -Value 8
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Type "DWord" -Value 6
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Type "String" -Value "High"

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    Set-RegistryForce -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableAutomaticRestartSignOn" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptIn" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall" -Name "DisablePushToInstall" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerAccountStateContent" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableCloudOptimizedContent" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "FeatureManagementEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OEMPreInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContentEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-310093Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "IsMiEnabled" -Type "DWord" -Value 0

    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions"
    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps"

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Notepad" -Name "ShowStoreBanner" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" -Action "Delete"

    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "HideRecentlyAddedApps" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type "DWord" -Value 2
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "SettingSyncEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "LocationServicesEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feedback" -Name "AutoSample" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feedback" -Name "ServiceEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppDiagnostics" -Name "AppDiagnosticsEnabled" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization" -Name "DODownloadMode" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication" -Name "UseSignInInfo" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Maps" -Name "AutoDownload" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    Set-RegistryForce -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDeveloperSettings" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarEndTask" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Type "DWord" -Value 2
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_EFSEFeatureFlags" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type "String" -Value "2"

    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type "String" -Value "0"
    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type "String" -Value "0"
    Set-RegistryForce -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type "String" -Value "0"

    Set-RegistryForce -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type "String" -Value "506"
    Set-RegistryForce -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "HotkeyFlags" -Type "String" -Value "58"

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAcrylicOpacity" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type "DWord" -Value 1

    $photoExtensions = @(".bmp",".cr2",".dib",".gif",".ico",".jfif",".jpe",".jpeg",".jpg",".jxr",".png",".tif",".tiff",".wdp")

    foreach ($ext in $photoExtensions) {
        Set-RegistryForce -Path "HKCU:\SOFTWARE\Classes\$ext" -Name "(default)" -Type "String" -Value "PhotoViewer.FileAssoc.Tiff"
        Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\OpenWithProgids" -Name "PhotoViewer.FileAssoc.Tiff" -Type "None" -Value $null
    }

    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Policies\Microsoft\Windows\Windows AI" -Name "TurnOffSavingSnapshots" -Type "DWord" -Value 1

    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Multimedia\Audio" -Name "UserDuckingPreference" -Type "DWord" -Value 3

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Type "DWord" -Value 3

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "LinkedIn" -Force -ErrorAction SilentlyContinue | Out-Null
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value "FixOs" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "NV Hostname" -Value "FixOs" -Force | Out-Null

    Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $OneDriveSetup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $OneDriveSetup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
    if (Test-Path $OneDriveSetup32) { Start-Process $OneDriveSetup32 "/uninstall" -Wait -ErrorAction SilentlyContinue }
    if (Test-Path $OneDriveSetup64) { Start-Process $OneDriveSetup64 "/uninstall" -Wait -ErrorAction SilentlyContinue }

    $oneDriveDirs = @(
        "$env:SystemDrive\OneDriveTemp"
        "$env:USERPROFILE\OneDrive"
        "$env:USERPROFILE\AppData\Local\Microsoft\OneDrive"
        "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
        "$env:ProgramData\Microsoft OneDrive"
        "$env:LOCALAPPDATA\Microsoft\OneDrive"
        "$env:ProgramFiles\Microsoft OneDrive"
        "$env:ProgramFiles(x86)\Microsoft OneDrive"
        "$env:SystemDrive\ProgramData\Microsoft OneDrive"
        "$env:USERPROFILE\AppData\Roaming\Microsoft\OneDrive"
    )
    foreach ($dir in $oneDriveDirs) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Force -ErrorAction SilentlyContinue
    Remove-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name '{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -ErrorAction SilentlyContinue

    Get-ScheduledTask | Where-Object {$_.TaskName -like "*OneDrive*"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

    Remove-Item -Path "HKCU:\Software\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

    Get-Process -Name "Teams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    Get-AppxPackage -AllUsers -Name "*Teams*" | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*Teams*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue

    $teamsDirs = @(
        "$env:LOCALAPPDATA\Microsoft\Teams"
        "$env:APPDATA\Microsoft\Teams"
        "$env:APPDATA\Teams"
        "$env:ProgramData\Microsoft Teams"
        "$env:USERPROFILE\AppData\Local\Microsoft\Teams"
        "$env:USERPROFILE\AppData\Roaming\Microsoft\Teams"
        "$env:ProgramFiles\Teams Installer"
        "$env:ProgramFiles(x86)\Teams Installer"
    )
    foreach ($dir in $teamsDirs) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue }
    }

    $quickLaunchDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    if (Test-Path $quickLaunchDir) {
        Get-ChildItem -Path $quickLaunchDir -Include *.lnk -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne 'File Explorer.lnk' -and
            $_.Name -ne 'Windows Explorer.lnk' -and
            $_.Name -ne 'explorer.lnk'
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    $SearchRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
    New-Item -Path $SearchRegPath -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsDeviceSearchHistoryEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsCloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsMSACloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path $SearchRegPath -Name "IsAADCloudSearchEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null

    $appsToRemove = @(
        "Microsoft.Xbox.TCUI"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.GamingApp"
        "Microsoft.Family"
        "Microsoft.DevHome"
        "Microsoft.LinkedIn"
    )

    foreach ($app in $appsToRemove) {
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "$app*" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "$app*" } | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue
    }

    $regPaths = @(
        "HKCU:\Software\Microsoft\XboxApp"
        "HKLM:\Software\Microsoft\Xbox"
        "HKLM:\Software\Microsoft\GamingServices"
        "HKCU:\Software\Microsoft\Family"
        "HKCU:\Software\Microsoft\DevHome"
        "HKCU:\Software\Microsoft\LinkedIn"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $shortcutPatterns = @("*Teams*.lnk","*LinkedIn*.lnk","*Family*.lnk","*Dev Home*.lnk","*Xbox*.lnk")

    $startMenuDirs = @(
        "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs"
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
        "C:\Users\Public\Desktop"
    )

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
            $matches = Get-ChildItem -Path (Join-Path $dir $pattern) -ErrorAction SilentlyContinue
            foreach ($match in $matches) {
                try {
                    Remove-Item $match.FullName -Force -ErrorAction SilentlyContinue
                } catch { }
            }
        }
    }

    $familyProv = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match 'MicrosoftFamily|LinkedIn' }
    foreach ($prov in $familyProv) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
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
    Remove-AppxRegex 'LinkedIn|MicrosoftFamily|CFQ7TTC0HHRK'

    $provPkgs = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -match 'LinkedIn|MicrosoftFamily' }
    foreach ($prov in $provPkgs) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue
        } catch {}
    }

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

    $regFamily = "HKCU:\Software\Microsoft\MicrosoftFamily"
    $regLinkedIn = "HKCU:\Software\Microsoft\Office\16.0\Common\Internet\LinkedIn"
    foreach ($regKey in @($regFamily, $regLinkedIn)) {
        if (Test-Path $regKey) {
            try {
                Remove-Item -Path $regKey -Recurse -Force -ErrorAction SilentlyContinue
            } catch { }
        }
    }

    try {
        $dismArgs = "/Online /Cleanup-Image /RestoreHealth"
        $dismOut = "$env:TEMP\dism_silent.txt"
        $dismErr = "$env:TEMP\dism_silent_err.txt"
        Dism.exe $dismArgs *>$dismOut 2>$dismErr
    } catch {}

    try {
        $sfcOut = "$env:TEMP\sfc_silent.txt"
        $sfcErr = "$env:TEMP\sfc_silent_err.txt"
        sfc /scannow *>$sfcOut 2>$sfcErr
    } catch {}

    $winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

    if (-not (Test-Path $winget)) {
        $installerUrl = "https://aka.ms/getwinget"
        $tempFile = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"

        Invoke-WebRequest -Uri $installerUrl -OutFile $tempFile
        Add-AppxPackage -Path $tempFile
        Start-Sleep -Seconds 5
    }

    if (-not (Test-Path $winget)) {
        Write-Error "winget not available"
        exit 1
    }

    $commonFlags = @("--exact","--silent","--accept-package-agreements","--accept-source-agreements","--source","winget")

    & $winget install --id Brave.Brave @commonFlags
    & $winget install --id Nilesoft.Shell @commonFlags

    return $true
}