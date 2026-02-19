    # ======================================================== #
    #                    Main optimization                     #
    # ======================================================== #
function Disable-AllAnimations {
    try {
        $animKeys = @(
            @{Path="HKCU:\Control Panel\Desktop"; Name="UserPreferencesMask"; Type="Binary"; Value=([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))}
            @{Path="HKCU:\Control Panel\Desktop"; Name="MenuShowDelay"; Type="String"; Value="0"}
            @{Path="HKCU:\Control Panel\Desktop"; Name="AutoEndTasks"; Type="String"; Value="1"}
            @{Path="HKCU:\Control Panel\Desktop"; Name="HungAppTimeout"; Type="String"; Value="1000"}
            @{Path="HKCU:\Control Panel\Desktop"; Name="WaitToKillAppTimeout"; Type="String"; Value="1000"}
            @{Path="HKCU:\Control Panel\Desktop"; Name="LowLevelHooksTimeout"; Type="String"; Value="1000"}
            @{Path="HKCU:\Control Panel\Desktop"; Name="ForegroundLockTimeout"; Type="DWord"; Value=0}
            @{Path="HKCU:\Control Panel\Desktop\WindowMetrics"; Name="MinAnimate"; Type="String"; Value="0"}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="TaskbarAnimations"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ListviewAlphaSelect"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="ListviewShadow"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="IconsOnly"; Type="DWord"; Value=1}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="DisallowShaking"; Type="DWord"; Value=1}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name="EnableBalloonTips"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"; Name="VisualFXSetting"; Type="DWord"; Value=2}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Name="EnableAeroPeek"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Name="AlwaysHibernateThumbnails"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Name="AnimationAttributionEnabled"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Name="EnableWindowColorization"; Type="DWord"; Value=0}
            @{Path="HKCU:\SOFTWARE\Microsoft\Windows\DWM"; Name="Composition"; Type="DWord"; Value=0}
        )
        
        foreach ($anim in $animKeys) {
            try {
                if (-not (Test-Path $anim.Path)) {
                    New-Item -Path $anim.Path -Force | Out-Null
                }
                if ($anim.Type -eq "Binary") {
                    Set-ItemProperty -Path $anim.Path -Name $anim.Name -Value $anim.Value -Force
                } elseif ($anim.Type -eq "String") {
                    Set-ItemProperty -Path $anim.Path -Name $anim.Name -Value $anim.Value -Type String -Force
                } else {
                    Set-ItemProperty -Path $anim.Path -Name $anim.Name -Value $anim.Value -Type DWord -Force
                }
            } catch {}
        }
    } catch {}
}

function Optimize-NTFS {
    try {
        fsutil behavior set disablelastaccess 1 | Out-Null
        fsutil behavior set disable8dot3 1 | Out-Null
    } catch {}
}

function Disable-BackgroundApps {
    try {
        $key1 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
        if (-not (Test-Path $key1)) { New-Item -Path $key1 -Force | Out-Null }
        Set-ItemProperty -Path $key1 -Name "GlobalUserDisabled" -Type DWord -Value 1 -Force
        
        $key2 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        Set-ItemProperty -Path $key2 -Name "BackgroundAppGlobalToggle" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-GameBar {
    try {
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowStartupPanel" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "GamePanelStartupTipIndex" -Type DWord -Value 3 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "AllowGameDVR" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "value" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Disable-SleepStudy {
    try {
        wevtutil.exe set-log "Microsoft-Windows-SleepStudy/Diagnostic" /e:false 2>$null
        wevtutil.exe set-log "Microsoft-Windows-Kernel-Processor-Power/Diagnostic" /e:false 2>$null
        wevtutil.exe set-log "Microsoft-Windows-UserModePowerService/Diagnostic" /e:false 2>$null
        schtasks /Change /TN "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable 2>$null
    } catch {}
}

function Disable-AdvertisingID {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "Enabled" -Type DWord -Value 0 -Force
        
        $path = "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "DisabledByGroupPolicy" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-SyncProviderNotifications {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-NvidiaTelemetry {
    try {
        $path = "HKCU:\Software\NVIDIA Corporation\NVControlPanel2\Client"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "OptInOrOutPreference" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-OfficeTelemetry {
    try {
        $path = "HKCU:\Software\Policies\Microsoft\office\16.0\common"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "sendcustomerdata" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path $path -Name "qmenable" -Type DWord -Value 0 -Force
        
        $path = "HKCU:\Software\Policies\Microsoft\office\common\clienttelemetry"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "sendtelemetry" -Type DWord -Value 3 -Force
    } catch {}
}

function Disable-DeviceSetupSuggestions {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "ScoobeSystemSettingEnabled" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-NETCLITelemetry {
    try {
        [Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT", "1", "User")
        [Environment]::SetEnvironmentVariable("DOTNET_CLI_TELEMETRY_OPTOUT", "1", "Machine")
    } catch {}
}

function Disable-InputTelemetry {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Type DWord -Value 1 -Force
    } catch {}
}

function Set-WindowsMediaPlayer {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "AcceptedPrivacyStatement" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-AppLaunchTracking {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-OnlineSpeechRecognition {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "HasAccepted" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-RecallSnapshots {
    if ($isWindows11) {
        try {
            $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisableAIDataAnalysis" -Type DWord -Value 1 -Force
            
            $path = "HKCU:\Software\Policies\Microsoft\Windows\Windows AI"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TurnOffSavingSnapshots" -Type DWord -Value 1 -Force
        } catch {}
    }
}

function Disable-TailoredExperiences {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type DWord -Value 0 -Force
        
        $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-FrequentApps {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "NoInstrumentation" -Type DWord -Value 1 -Force
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "NoStartMenuMFUprogramsList" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-LanguageListAccess {
    try {
        $path = "HKCU:\Control Panel\International\User Profile"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "HttpAcceptLanguageOptOut" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-ErrorReporting {
    try {
        $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "Disabled" -Type DWord -Value 1 -Force
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "Disabled" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DontSendAdditionalData" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DontShowUI" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "LoggingDisabled" -Type DWord -Value 1 -Force
    } catch {}
}

function Set-SearchPrivacy {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0 -Force
    } catch {}
}

function Disable-UserActivityUpload {
    try {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path $path -Name "PublishUserActivities" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path $path -Name "UploadUserActivities" -Type DWord -Value 0 -Force
    } catch {}
}

function Hide-RecentItems {
    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Type DWord -Value 0 -Force
        
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "ClearRecentDocsOnExit" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "NoRecentDocsHistory" -Type DWord -Value 1 -Force
        
        $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "NoRemoteDestinations" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-MenuHoverDelay {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0" -Force
    } catch {}
}

function Disable-StartMenuRecommendations {
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_IrisRecommendations" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_AccountNotifications" -Type DWord -Value 0 -Force
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "HideRecentlyAddedApps" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "HideRecommendedPersonalizedSites" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "ShowOrHideMostUsedApps" -Type DWord -Value 2 -Force
        
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideRecommendedPersonalizedSites" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Show-MorePinsInStartMenu {
    try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_Layout" -Type DWord -Value 1 -Force
    } catch {}
}

function Set-ShutdownTime {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Type String -Value "2000" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeOut" -Type String -Value "2000" -Force
        
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type String -Value "2000" -Force
    } catch {}
}

function Disable-StartupDelay {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "StartupDelayInMSec" -Type DWord -Value 0 -Force
    } catch {}
}

function Add-EndTaskToTaskbar {
    if ($isWindows11) {
        try {
            $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
            if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "TaskbarEndTask" -Type DWord -Value 1 -Force
        } catch {}
    }
}

function Disable-MouseAcceleration {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value "0" -Force
    } catch {}
}

function Disable-WindowsFeedback {
    try {
        $path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0 -Force
        Remove-ItemProperty -Path $path -Name "PeriodInNanoSeconds" -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        Set-ItemProperty -Path $path -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1 -Force
    } catch {}
}

function Disable-WindowsSpotlight {
    try {
        $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "DisableWindowsSpotlightFeatures" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DisableWindowsSpotlightWindowsWelcomeExperience" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DisableWindowsSpotlightOnActionCenter" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DisableWindowsSpotlightOnSettings" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path $path -Name "DisableThirdPartySuggestions" -Type DWord -Value 1 -Force
        
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type DWord -Value 1 -Force
    } catch {}
}

function Set-VisualEffects {
    try {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Type String -Value "2" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value "1" -Force
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0" -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 0 -Force
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\DWM" -Name "AlwaysHibernateThumbnails" -Type DWord -Value 0 -Force
    } catch {}
}

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

function Remove-RegistryKey {
    param([string]$Path)
    try {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

function Create-ToolboxShortcut {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "Toolbox.lnk"
        
        $toolboxUrl = "https://raw.githubusercontent.com/DeveIopmentSpace/FixOs/dev/Toolbox/src/Toolbox.ps1"
        
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
        "Microsoft.MicrosoftStickyNotes"
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
        "Microsoft.GamingApp"
        "Microsoft.Family"
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
            'AJRouter', 'AssignedAccessManagerSvc', 'AppIDSvc', 'BDESVC', 'DiagTrack', 'DPS', 'Fax', 'FontCache', 
            'InventorySvc', 'PcaSvc', 'RmSvc', 'TabletInputService', 'WSearch', 'WbioSrvc', 'webthreatdefsvc', 'lfsvc',
            'dmwappushservice', 'XboxGipSvc', 'XblAuthManager', 'XblGameSave', 'XboxNetApiSvc', 'OneSyncSvc',
            'WpcMonSvc', 'wisvc', 'RetailDemo', 'MessagingService', 'MapsBroker', 'PimIndexMaintenanceSvc',
            'UnistoreSvc', 'UserDataSvc', 'WpnService', 'WpnUserService', 'WdNisSvc', 'Sense', 'wscsvc', 'SysMain',
            'edgeupdate', 'edgeupdatem', 'MicrosoftEdgeElevationService', 'BcastDVRUserService', 'CaptureService',
            'cbdhsvc', 'ConsentUxUserSvc', 'CredentialEnrollmentManagerUserSvc', 'DeviceAssociationBrokerSvc',
            'DevicePickerUserSvc', 'DevicesFlowUserSvc', 'NPSMSvc', 'P9RdrService', 'PrintWorkflowUserSvc',
            'UdkUserSvc', 'autotimesvc', 'tzautoupdate', 'shpamsvc', 'PhoneSvc', 'RemoteRegistry', 'RemoteAccess',
            'SessionEnv', 'TermService', 'UmRdpService', 'SharedAccess', 'FrameServer', 'StiSvc', 'WiaRpc', 'icssvc',
            'WlanSvc', 'WwanSvc'
        )
        
        $servicesToManual = @(
            'BITS', 'CDPSvc', 'DusmSvc', 'LanmanServer', 'LanmanWorkstation', 'Spooler', 'StateRepository',
            'StorSvc', 'TokenBroker', 'TrkWks', 'UsoSvc', 'iphlpsvc', 'sppsvc', 'DoSvc', 'W32Time', 'Themes',
            'Schedule', 'TrustedInstaller', 'AudioEndpointBuilder', 'Audiosrv', 'CoreMessagingRegistrar',
            'TimeBrokerSvc', 'UserManager', 'VaultSvc', 'WinHttpAutoProxySvc', 'Winmgmt', 'Wcmsvc', 'nsi',
            'Dnscache', 'Dhcp', 'EventLog', 'EventSystem', 'gpsvc', 'ProfSvc', 'Power', 'DcomLaunch', 'RpcSs',
            'RpcEptMapper', 'SamSs', 'PlugPlay', 'SENS', 'ShellHWDetection', 'tiledatamodelsvc',
            'BrokerInfrastructure', 'SystemEventsBroker', 'CryptSvc', 'MpsSvc', 'mpssvc', 'BFE', 'KeyIso',
            'Netlogon', 'NlaSvc', 'PolicyAgent', 'SgrmBroker', 'WinDefend', 'SecurityHealthService'
        )
        
        foreach ($service in $servicesToDisable) {
            try {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                    if ($svc.Status -eq 'Running') {
                        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {}
        }
        
        foreach ($service in $servicesToManual) {
            try {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    } catch {}
}

function Disable-WindowsDefenderStartup {
    try {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend"
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name "WindowsDefender" -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $path -Name "SecurityHealth" -Force -ErrorAction SilentlyContinue
        }
        
        schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable 2>$null
        schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable 2>$null
        schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable 2>$null
        schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable 2>$null
        
        if ($isWindows10) {
            schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable 2>$null
            schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable 2>$null
            schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable 2>$null
            schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable 2>$null
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

function Remove-OneDrive {
    try {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        $OneDriveSetup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
        $OneDriveSetup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        if (Test-Path $OneDriveSetup32) { Start-Process $OneDriveSetup32 "/uninstall" -Wait -ErrorAction SilentlyContinue }
        if (Test-Path $OneDriveSetup64) { Start-Process $OneDriveSetup64 "/uninstall" -Wait -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2
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
        foreach ($dir in $oneDriveDirs) { if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue } }
        
        Remove-RegistryKey -Path "HKCU:\Software\Microsoft\OneDrive"
        Remove-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\OneDrive"
        Remove-RegistryKey -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
        Get-ScheduledTask | Where-Object {$_.TaskName -like "*OneDrive*"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
}

function Remove-Teams {
    try {
        Stop-Process -Name "Teams" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
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
        foreach ($dir in $teamsDirs) { if (Test-Path $dir) { Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue } }
    } catch {}
}

function Remove-Xbox {
    try {
        $xboxApps = @(
            "Microsoft.Xbox.TCUI"
            "Microsoft.XboxApp"
            "Microsoft.XboxGameCallableUI"
            "Microsoft.XboxGamingOverlay"
            "Microsoft.XboxIdentityProvider"
            "Microsoft.XboxSpeechToTextOverlay"
            "Microsoft.GamingApp"
        )
        foreach ($app in $xboxApps) { Remove-AppxSafe -AppName $app }
        
        Remove-RegistryKey -Path "HKCU:\Software\Microsoft\XboxApp"
        Remove-RegistryKey -Path "HKLM:\Software\Microsoft\Xbox"
        Remove-RegistryKey -Path "HKLM:\Software\Microsoft\GamingServices"
    } catch {}
}

function Remove-LinkedIn {
    try {
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*LinkedIn*" } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like "*LinkedIn*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        $profiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '^(Default|Public|All Users)$' }
        foreach ($profile in $profiles) {
            $desktop = Join-Path $profile.FullName "Desktop"
            if (Test-Path $desktop) {
                Get-ChildItem -Path $desktop -Filter "*LinkedIn*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

function Disable-Telemetry {
    try {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "AllowTelemetry" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "SubmitSamplesConsent" -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Set-Wallpaper {
    $wallUrl = 'https://github.com/DeveIopmentSpace/FixOs/blob/dev/assets/wallpaper-dev.png?raw=true'
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

function Add-AdditionalRegistryTweaks {
    try {
        $path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "SubmitSamplesConsent" -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "VerifiedAndReputablePolicyState" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "ShippedWithReserves" -Type DWord -Value 0 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Device performance and health"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "UILockdown" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Family options"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "UILockdown" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Account protection"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "UILockdown" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\MRT"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "DontOfferThroughWUAU" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "AUOptions" -Type DWord -Value 2 -Force -ErrorAction SilentlyContinue
        
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "DeferFeatureUpdates" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $path -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 180 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $path -Name "DeferQualityUpdates" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $path -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 7 -Force -ErrorAction SilentlyContinue
        
        $path = "HKCU:\Software\Classes\CLSID\{645FF040-5081-101B-9F08-00AA002F954E}"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "System.IsPinnedToNameSpaceTree" -Type DWord -Value 1 -Force -ErrorAction SilentlyContinue
    } catch {}
}

function Start-WindowsOptimization {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Please run as Administrator"
        return $false
    }

    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue

    Remove-CrapApps
    Optimize-Services
    Disable-Telemetry
    Optimize-NTFS
    Disable-BackgroundApps
    Disable-GameBar
    Disable-SleepStudy
    Disable-AdvertisingID
    Disable-SyncProviderNotifications
    Disable-NvidiaTelemetry
    Disable-OfficeTelemetry
    Disable-DeviceSetupSuggestions
    Disable-NETCLITelemetry
    Disable-InputTelemetry
    Set-WindowsMediaPlayer
    Disable-AppLaunchTracking
    Disable-OnlineSpeechRecognition
    Disable-RecallSnapshots
    Disable-TailoredExperiences
    Disable-FrequentApps
    Disable-LanguageListAccess
    Disable-ErrorReporting
    Set-SearchPrivacy
    Disable-UserActivityUpload
    Hide-RecentItems
    Disable-MenuHoverDelay
    Disable-StartMenuRecommendations
    Show-MorePinsInStartMenu
    Set-ShutdownTime
    Disable-StartupDelay
    Add-EndTaskToTaskbar
    Disable-MouseAcceleration
    Disable-WindowsFeedback
    Disable-WindowsSpotlight
    Set-VisualEffects
    Disable-AllAnimations
    Remove-EdgeCompletely
    Remove-OneDrive
    Remove-Teams
    Remove-Xbox
    Remove-LinkedIn
    Disable-WindowsDefenderStartup
    Add-AdditionalRegistryTweaks
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

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisableWindowsSpotlightOnLockScreen" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DisableWindowsSpotlightActiveUser" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"

    Set-RegistryForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" -Name "ConfigureChatAutoInstall" -Type "DWord" -Value 0
    
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ChatIcon" -Type "DWord" -Value 3

    $path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path $path -Name "ConfigureStartPins_ProviderSet" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "ConfigureStartPins_WinningProvider" -Type "String" -Value "B5292708-1619-419B-9923-E5D9F3925E71"
    
    $path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\providers\B5292708-1619-419B-9923-E5D9F3925E71\default\Device\Start"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ConfigureStartPins" -Type "String" -Value '{ "pinnedList": [] }'
    Set-RegistryForce -Path $path -Name "ConfigureStartPins_LastWrite" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AllowNewsAndInterests" -Type "DWord" -Value 0

    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "PreventDeviceEncryption" -Type "DWord" -Value 1
    
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EnhancedStorageDevices"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "TCGSecurityActivationDisabled" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DeferFeatureUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DeferFeatureUpdatesPeriodInDays" -Type "DWord" -Value 365
    Set-RegistryForce -Path $path -Name "DeferQualityUpdates" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DeferQualityUpdatesPeriodInDays" -Type "DWord" -Value 365
    Set-RegistryForce -Path $path -Name "TargetReleaseVersion" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "TargetReleaseVersionInfo" -Type "String" -Value "22H2"
    Set-RegistryForce -Path $path -Name "ProductVersion" -Type "String" -Value "Windows 10"

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AllowCortana" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "EnableActivityFeed" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "PublishUserActivities" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "UploadUserActivities" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Value" -Type "String" -Value "Deny"
    
    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "SensorPermissionState" -Type "DWord" -Value 0
    
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Status" -Type "DWord" -Value 0
    
    $path = "HKLM:\SYSTEM\Maps"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AutoUpdateEnabled" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AllowWindowsInkWorkspace" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DoNotShowFeedbackNotifications" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisabledByGroupPolicy" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Disabled" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DODownloadMode" -Type "DWord" -Value 0

    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "fAllowToGetHelp" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "SearchOrderConfig" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "SystemResponsiveness" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "NetworkThrottlingIndex" -Type "DWord" -Value 10

    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "IRPStackSize" -Type "DWord" -Value 30

    $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "GPU Priority" -Type "DWord" -Value 8
    Set-RegistryForce -Path $path -Name "Priority" -Type "DWord" -Value 6
    Set-RegistryForce -Path $path -Name "Scheduling Category" -Type "String" -Value "High"

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    $path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Value" -Type "DWord" -Value 0
    
    $path = "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Value" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "01" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AllowGameDVR" -Type "DWord" -Value 0

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisableAutomaticRestartSignOn" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "KFMBlockOptIn" -Type "DWord" -Value 1
    
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisableFileSyncNGSC" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\PushToInstall"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisablePushToInstall" -Type "DWord" -Value 1

    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisableConsumerAccountStateContent" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DisableCloudOptimizedContent" -Type "DWord" -Value 1

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ContentDeliveryAllowed" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "FeatureManagementEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "OEMPreInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "PreInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "PreInstalledAppsEverEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SilentInstalledAppsEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "RotatingLockScreenEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "RotatingLockScreenOverlayEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SoftLandingEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContentEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-310093Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-338387Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-338388Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-338389Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-353698Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-353694Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SubscribedContent-353696Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "SystemPaneSuggestionsEnabled" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "IsMiEnabled" -Type "DWord" -Value 0

    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions"
    Remove-RegistryKeyForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps"

    $path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "HasAccepted" -Type "DWord" -Value 0

    if ($isWindows11) {
        $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-RegistryForce -Path $path -Name "TurnOffWindowsCopilot" -Type "DWord" -Value 1
    }

    $path = "HKCU:\SOFTWARE\Microsoft\Notepad"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ShowStoreBanner" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" -Action "Delete"

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "TaskbarAl" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "Start_IrisRecommendations" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "Start_AccountNotifications" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
    Set-RegistryForce -Path $path -Name "SearchboxTaskbarMode" -Type "DWord" -Value 0

    $path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "HideRecentlyAddedApps" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DisableNotificationCenter" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "DisableSearchBoxSuggestions" -Type "DWord" -Value 1

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "PeopleBand" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ShellFeedsTaskbarViewMode" -Type "DWord" -Value 2
    Set-RegistryForce -Path $path -Name "ShellFeedsEnabled" -Type "DWord" -Value 0
    
    $path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "EnableFeeds" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "ToastEnabled" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy"
    Set-RegistryForce -Path $path -Name "SettingSyncEnabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "LocationServicesEnabled" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AcceptedPrivacyPolicy" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feedback"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AutoSample" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "ServiceEnabled" -Type "DWord" -Value 0

    $path = "HKCU:\Control Panel\International\User Profile"
    Set-RegistryForce -Path $path -Name "HttpAcceptLanguageOptOut" -Type "DWord" -Value 1

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    Set-RegistryForce -Path $path -Name "GlobalUserDisabled" -Type "DWord" -Value 1

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppDiagnostics"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AppDiagnosticsEnabled" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DODownloadMode" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "UseSignInInfo" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Maps"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "AutoDownload" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Siuf\Rules"
    Set-RegistryForce -Path $path -Name "NumberOfSIUFInPeriod" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    Set-RegistryForce -Path $path -Name "Enabled" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "HarvestContacts" -Type "DWord" -Value 0

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "EnthusiastMode" -Type "DWord" -Value 1
    
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type "DWord" -Value 1
    Set-RegistryForce -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    Set-RegistryForce -Path $path -Name "HideSCAMeetNow" -Type "DWord" -Value 1

    if ($isWindows11) {
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
        Set-RegistryForce -Path $path -Name "TaskbarEndTask" -Type "DWord" -Value 1
    }

    $path = "HKCU:\System\GameConfigStore"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "GameDVR_FSEBehavior" -Type "DWord" -Value 2
    Set-RegistryForce -Path $path -Name "GameDVR_Enabled" -Type "DWord" -Value 0
    Set-RegistryForce -Path $path -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "GameDVR_HonorUserFSEBehaviorMode" -Type "DWord" -Value 1
    Set-RegistryForce -Path $path -Name "GameDVR_EFSEFeatureFlags" -Type "DWord" -Value 0

    Set-RegistryForce -Path "HKCU:\Control Panel\Keyboard" -Name "InitialKeyboardIndicators" -Type "String" -Value "2"

    $path = "HKCU:\Control Panel\Accessibility\StickyKeys"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "Flags" -Type "String" -Value "506"
    Set-RegistryForce -Path $path -Name "HotkeyFlags" -Type "String" -Value "58"

    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAcrylicOpacity" -Type "DWord" -Value 0
    Set-RegistryForce -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type "DWord" -Value 1

    $photoExtensions = @(".bmp",".cr2",".dib",".gif",".ico",".jfif",".jpe",".jpeg",".jpg",".jxr",".png",".tif",".tiff",".wdp")

    foreach ($ext in $photoExtensions) {
        $path = "HKCU:\SOFTWARE\Classes\$ext"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-RegistryForce -Path $path -Name "(default)" -Type "String" -Value "PhotoViewer.FileAssoc.Tiff"
        
        $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$ext\OpenWithProgids"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-RegistryForce -Path $path -Name "PhotoViewer.FileAssoc.Tiff" -Type "None" -Value $null
    }

    $path = "HKCU:\Software\Policies\Microsoft\Windows\WindowsAI"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "DisableAIDataAnalysis" -Type "DWord" -Value 1
    
    $path = "HKCU:\Software\Policies\Microsoft\Windows\Windows AI"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "TurnOffSavingSnapshots" -Type "DWord" -Value 1

    $path = "HKCU:\Software\Microsoft\Multimedia\Audio"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-RegistryForce -Path $path -Name "UserDuckingPreference" -Type "DWord" -Value 3

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-RegistryForce -Path $path -Name "EnableLUA" -Type "DWord" -Value 3

    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
    Remove-RegistryKeyForce -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"

    $path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    Set-RegistryForce -Path $path -Name "SettingsPageVisibility" -Type "String" -Value "hide:home"

    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" -Name "LinkedIn" -Force -ErrorAction SilentlyContinue | Out-Null
    
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "Hostname" -Value "FixOs" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "NV Hostname" -Value "FixOs" -Force | Out-Null

    $quickLaunchDir = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    if (Test-Path $quickLaunchDir) {
        Get-ChildItem -Path $quickLaunchDir -Include *.lnk -Force -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne 'File Explorer.lnk' -and
            $_.Name -ne 'Windows Explorer.lnk' -and
            $_.Name -ne 'explorer.lnk'
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    $SearchRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"
    if (-not (Test-Path $SearchRegPath)) { New-Item -Path $SearchRegPath -Force | Out-Null }
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

    if (Test-Path $winget) {
        $commonFlags = @("--exact","--silent","--accept-package-agreements","--accept-source-agreements","--source","winget")
        & $winget install --id Nilesoft.Shell @commonFlags
    }

    return $true
}