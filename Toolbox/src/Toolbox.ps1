$ToolboxConfig = @{
    Version = "1.0.0"
    Author = "FixOs Development Team - © 2026 Devspace. All rights reserved"
}

. "$PSScriptRoot\Core\Utilities.ps1"

function Center-Text($text) {
    $width = $host.UI.RawUI.WindowSize.Width
    $textLength = $text.Length
    $padding = [math]::Max(0, ($width - $textLength) / 2)
    return (" " * [math]::Floor($padding)) + $text
}

function Show-FixOsLogo {
    $logoLines = @(
        " ███████╗██╗██╗  ██╗  ██████╗ ███████╗ ",
        " ██╔════╝██║╚██╗██╔╝ ██╔═══██╗██╔════╝ ",
        " █████╗  ██║ ╚███╔╝  ██║   ██║███████╗ ",
        " ██╔══╝  ██║ ██╔██╗  ██║   ██║╚════██║ ",
        " ██║     ██║██╔╝ ██╗ ╚██████╔╝███████║ ",
        " ╚═╝     ╚═╝╚═╝  ╚═╝  ╚═════╝ ╚══════╝ ",
        "",
        "          TOOLBOX v$($ToolboxConfig.Version)          "
    )
    
    foreach ($line in $logoLines) {
        Write-Host (Center-Text $line) -ForegroundColor White
    }
    Write-Host ""
}

function Initialize-Toolbox {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Toolbox requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
        Exit 1
    }
    
    Clear-Host
    Show-FixOsLogo
    Write-Host (Center-Text "Initialized successfully at $(Get-Date)") -ForegroundColor Yellow
    Write-Host ""
}

function Show-MainMenu {
    Clear-Host
    Show-FixOsLogo
    
    $menuOptions = @(
        "╔════════════════════════════════════════════════╗",
        "║                SELECT AN OPTION                ║",
        "╠════════════════════════════════════════════════╣",
        "║  ┌──────────────────────────────────────────┐  ║",
        "║  │           [1] APPS INSTALLER             │  ║",
        "║  │           [2] RUN FIXOS PRESET           │  ║",
        "║  │           [3] EXIT TOOLBOX               │  ║",
        "║  └──────────────────────────────────────────┘  ║",
        "╚════════════════════════════════════════════════╝"
    )
    
    foreach ($line in $menuOptions) {
        Write-Host (Center-Text $line) -ForegroundColor White
    }
    Write-Host ""
}

function Install-App($appId, $appName) {
    try {
        Write-Host ""
        Write-Host (Center-Text "Installing $appName...") -ForegroundColor Yellow
        Write-Host ""
        
        $job = Start-Job -ScriptBlock {
            param($appId)
            winget install --id $appId --exact --silent --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1
        } -ArgumentList $appId
        
        $frames = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
        $i = 0
        $startTime = Get-Date
        
        while ($job.State -eq 'Running') {
            $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
            Write-Host (Center-Text "  $($frames[$i % 10]) Installing... $elapsed seconds") -ForegroundColor White -NoNewline
            Start-Sleep -Milliseconds 100
            Write-Host "`r" -NoNewline
            $i++
        }
        
        $result = Receive-Job -Job $job
        Remove-Job -Job $job -Force
        
        Write-Host ""
        Write-Host (Center-Text "  ╔══════════════════════════════╗") -ForegroundColor Green
        Write-Host (Center-Text "  ║  ✓ $appName installed!      ║") -ForegroundColor Green
        Write-Host (Center-Text "  ╚══════════════════════════════╝") -ForegroundColor Green
        
    } catch {
        Write-Host ""
        Write-Host (Center-Text "  ╔══════════════════════════════╗") -ForegroundColor Red
        Write-Host (Center-Text "  ║  ✗ Error installing $appName ║") -ForegroundColor Red
        Write-Host (Center-Text "  ╚══════════════════════════════╝") -ForegroundColor Red
    }
    Write-Host ""
    Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-GridMenu($title, $options, $gridColumns = 3) {
    Clear-Host
    Show-FixOsLogo
    
    Write-Host (Center-Text "==============================================") -ForegroundColor Yellow
    Write-Host (Center-Text "  $title  ") -ForegroundColor White
    Write-Host (Center-Text "==============================================") -ForegroundColor Yellow
    Write-Host ""
    
    $maxLength = ($options | Measure-Object -Property Length -Maximum).Maximum + 6
    $colWidth = $maxLength + 4
    
    for ($i = 0; $i -lt $options.Count; $i += $gridColumns) {
        $line = ""
        for ($j = 0; $j -lt $gridColumns; $j++) {
            $index = $i + $j
            if ($index -lt $options.Count) {
                $optionNum = $index + 1
                $optionText = "[$optionNum] $($options[$index])"
                $line += $optionText.PadRight($colWidth)
            }
        }
        Write-Host (Center-Text $line.Trim()) -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host (Center-Text "[A] Install All") -ForegroundColor Magenta
    Write-Host (Center-Text "[0] Back") -ForegroundColor Gray
    Write-Host ""
}

function Invoke-BrowsersInstaller {
    $browsers = @(
        "Google Chrome", "Brave Browser", "Mozilla Firefox",
        "Microsoft Edge", "Thorium Browser", "Waterfox",
        "LibreWolf", "Floorp Browser"
    )
    
    $browserIds = @(
        "Google.Chrome", "Brave.Brave", "Mozilla.Firefox",
        "Microsoft.Edge", "Alex313031.Thorium", "Waterfox.Waterfox",
        "LibreWolf.LibreWolf", "Floorp.Floorp"
    )
    
    while ($true) {
        Show-GridMenu "BROWSERS SELECTION" $browsers 4
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all browsers...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $browsers.Count; $i++) {
                Install-App $browserIds[$i] $browsers[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $browsers.Count) {
            Install-App $browserIds[$index] $browsers[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-FileToolsInstaller {
    $tools = @("WinRAR", "7-Zip")
    $toolIds = @("RARLab.WinRAR", "7zip.7zip")
    
    while ($true) {
        Show-GridMenu "FILE TOOLS" $tools 3
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all file tools...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $tools.Count; $i++) {
                Install-App $toolIds[$i] $tools[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Install-App $toolIds[$index] $tools[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-DevToolsInstaller {
    $tools = @(
        "VS Code", "Notepad++", "Sublime Text",
        "Git", "GitHub Desktop", "PowerShell 7", "Docker"
    )
    
    $toolIds = @(
        "Microsoft.VisualStudioCode", "Notepad++.Notepad++", "SublimeHQ.SublimeText",
        "Git.Git", "GitHub.GitHubDesktop", "Microsoft.PowerShell", "Docker.DockerDesktop"
    )
    
    while ($true) {
        Show-GridMenu "DEV TOOLS" $tools 4
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all dev tools...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $tools.Count; $i++) {
                Install-App $toolIds[$i] $tools[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Install-App $toolIds[$index] $tools[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-DotNetInstaller {
    $tools = @(".NET SDK 8", ".NET Runtime 8", ".NET Desktop 8", ".NET SDK 7", ".NET Runtime 7")
    $toolIds = @(
        "Microsoft.DotNet.SDK.8", "Microsoft.DotNet.Runtime.8", "Microsoft.DotNet.DesktopRuntime.8",
        "Microsoft.DotNet.SDK.7", "Microsoft.DotNet.Runtime.7"
    )
    
    while ($true) {
        Show-GridMenu ".NET TOOLS" $tools 3
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all .NET tools...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $tools.Count; $i++) {
                Install-App $toolIds[$i] $tools[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Install-App $toolIds[$index] $tools[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-CommunicationInstaller {
    $apps = @("Telegram", "Discord", "WhatsApp", "Slack", "Zoom")
    $appIds = @(
        "Telegram.TelegramDesktop", "Discord.Discord", "WhatsApp.WhatsApp",
        "SlackTechnologies.Slack", "Zoom.Zoom"
    )
    
    while ($true) {
        Show-GridMenu "COMMUNICATION APPS" $apps 3
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all communication apps...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $apps.Count; $i++) {
                Install-App $appIds[$i] $apps[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $apps.Count) {
            Install-App $appIds[$index] $apps[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-GamingInstaller {
    $apps = @("Steam", "Epic Games", "Ubisoft", "EA Desktop")
    $appIds = @(
        "Valve.Steam", "EpicGames.EpicGamesLauncher",
        "Ubisoft.Connect", "ElectronicArts.EADesktop"
    )
    
    while ($true) {
        Show-GridMenu "GAMING APPS" $apps 2
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all gaming apps...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $apps.Count; $i++) {
                Install-App $appIds[$i] $apps[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $apps.Count) {
            Install-App $appIds[$index] $apps[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-MicrosoftInstaller {
    $apps = @("Windows Terminal", "PowerToys", "Microsoft Office", "Microsoft Store")
    $appIds = @(
        "Microsoft.WindowsTerminal", "Microsoft.PowerToys",
        "Microsoft.Office", "Microsoft.Store"
    )
    
    while ($true) {
        Show-GridMenu "MICROSOFT APPS" $apps 2
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all Microsoft apps...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $apps.Count; $i++) {
                Install-App $appIds[$i] $apps[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $apps.Count) {
            Install-App $appIds[$index] $apps[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-MediaInstaller {
    $apps = @("VLC Player", "OBS Studio", "Handbrake")
    $appIds = @("VideoLAN.VLC", "OBSProject.OBSStudio", "Handbrake.Handbrake")
    
    while ($true) {
        Show-GridMenu "MEDIA APPS" $apps 3
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all media apps...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $apps.Count; $i++) {
                Install-App $appIds[$i] $apps[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $apps.Count) {
            Install-App $appIds[$index] $apps[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Invoke-ProductivityInstaller {
    $tools = @("Obsidian", "Notion", "AnyDesk", "TeamViewer")
    $toolIds = @(
        "Obsidian.Obsidian", "Notion.Notion",
        "AnyDeskSoftwareGmbH.AnyDesk", "TeamViewer.TeamViewer"
    )
    
    while ($true) {
        Show-GridMenu "PRODUCTIVITY TOOLS" $tools 2
        
        Write-Host (Center-Text "Enter selection: ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        if ($choice -eq "0") { return }
        if ($choice -eq "A" -or $choice -eq "a") {
            Write-Host ""
            Write-Host (Center-Text "Installing all productivity tools...") -ForegroundColor Yellow
            for ($i = 0; $i -lt $tools.Count; $i++) {
                Install-App $toolIds[$i] $tools[$i]
            }
            continue
        }
        
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $tools.Count) {
            Install-App $toolIds[$index] $tools[$index]
        } else {
            Write-Host ""
            Write-Host (Center-Text "Invalid selection!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

function Show-CategoriesMenu {
    Clear-Host
    Show-FixOsLogo
    
    Write-Host (Center-Text "==================================================================") -ForegroundColor DarkCyan
    Write-Host (Center-Text "                       APP CATEGORIES MENU                        ") -ForegroundColor DarkCyan
    Write-Host (Center-Text "==================================================================") -ForegroundColor DarkCyan
    
    $categories = @(
        "  [1] Browsers         [2] File Tools      [3] Dev Tools",
        "  [4] .NET Tools       [5] Communication   [6] Gaming Apps",
        "  [7] Microsoft Apps   [8] Media Apps      [9] Productivity"
    )
    
    foreach ($line in $categories) {
        Write-Host (Center-Text $line) -ForegroundColor White
    }
    Write-Host ""
    Write-Host (Center-Text "              Enter number (1-9) or [0] to go back                ") -ForegroundColor Gray 
    Write-Host ""
}

function Invoke-AppsInstaller {
    while ($true) {
        Show-CategoriesMenu
        
        Write-Host (Center-Text "Select category (1-9): ") -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Invoke-BrowsersInstaller }
            "2" { Invoke-FileToolsInstaller }
            "3" { Invoke-DevToolsInstaller }
            "4" { Invoke-DotNetInstaller }
            "5" { Invoke-CommunicationInstaller }
            "6" { Invoke-GamingInstaller }
            "7" { Invoke-MicrosoftInstaller }
            "8" { Invoke-MediaInstaller }
            "9" { Invoke-ProductivityInstaller }
            "0" { return }
            default {
                Write-Host ""
                Write-Host (Center-Text "Invalid option!") -ForegroundColor Red
                Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
    }
}

function Invoke-FullFixOsPreset {
    Clear-Host
    Show-FixOsLogo

    Write-Host (Center-Text "  This will run FixOs installer ") -ForegroundColor White
    
    Write-Host (Center-Text "Continue? [Y/N]: ") -NoNewline -ForegroundColor Magenta
    $confirm = Read-Host
    
    if ($confirm -ne "Y" -and $confirm -ne "y") { return }
    
    Write-Host ""
    Write-Host (Center-Text "Running FixOs...") -ForegroundColor Yellow
    
    try {
        irm "DevelopmentSpace.pages.dev/FixOs.ps1" | iex
        Write-Host ""
        Write-Host (Center-Text "FixOs executed successfully!") -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host (Center-Text "Error running FixOs") -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host (Center-Text "FixOs preset completed") -ForegroundColor Green
    Write-Host ""
    Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Initialize-Toolbox

while ($true) {
    Show-MainMenu
    
    Write-Host (Center-Text "Enter choice (1-3): ") -NoNewline -ForegroundColor Cyan
    $choice = Read-Host
    
    switch ($choice) {
        "1" { Invoke-AppsInstaller }
        "2" { Invoke-FullFixOsPreset }
        "3" { 
            Clear-Host
            Show-FixOsLogo
            Write-Host ""
            Write-Host (Center-Text "FixOs Toolbox!") -ForegroundColor Green
            Write-Host ""
            Exit 0
        }
        default {
            Write-Host ""
            Write-Host (Center-Text "Invalid option!") -ForegroundColor Red
            Write-Host (Center-Text "Press any key to continue...") -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}