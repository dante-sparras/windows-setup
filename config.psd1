@{
    Repository      = "https://github.com/dante-sparras/windows-setup"
    # ─────────────────────────────────────────────────────────────────────────
    # Global Settings (Default Behavior)
    # These can be overridden by command-line switches (e.g. -SkipRestore)
    # ─────────────────────────────────────────────────────────────────────────
    Settings        = @{
        EnableRestorePoint = $true
        EnableSophia       = $true
        EnableWinget       = $true
        EnableDotfiles     = $true
        EnableFonts        = $true
        EnableModules      = $true
        EnableProfile      = $true
    }

    # ─────────────────────────────────────────────────────────────────────────
    # External Resources & URLs
    # ─────────────────────────────────────────────────────────────────────────
    Resources       = @{
        SophiaReleaseApi = "https://api.github.com/repos/farag2/Sophia-Script-for-Windows/releases/latest"
    }

    # ─────────────────────────────────────────────────────────────────────────
    # Winget Settings
    # https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md
    # ─────────────────────────────────────────────────────────────────────────
    WingetSettings  = @{
        "visual" = @{
            "progressBar" = "rainbow"
        }
        "source" = @{
            "autoUpdateIntervalInMinutes" = 5
        }
    }
    # ─────────────────────────────────────────────────────────────────────────
    # Winget Packages & Dotfiles
    #
    # Dotfiles Property:
    #   Url         : Direct raw download link
    #   Destination : Local path (Environment variables like $env:USERPROFILE are supported)
    # ─────────────────────────────────────────────────────────────────────────
    WingetPackages  = @(
        # -────────────────────────────────────────────────────────────────────
        # General
        # -────────────────────────────────────────────────────────────────────
        # Zen Browser
        # https://zen-browser.app/
        "Zen-Team.Zen-Browser"
        # Chrome Browser
        # https://google.com/chrome/
        "Google.Chrome"
        # Notion
        # https://notion.com/
        "Notion.Notion"
        # Notion Calendar
        # https://notion.com/product/calendar
        "Notion.NotionCalendar"
        # Spotify
        # https://spotify.com/
        "Spotify.Spotify"
        # Discord
        # https://discord.com/
        "Discord.Discord"
        # Zoom
        # https://zoom.com/
        "Zoom.Zoom"
        # Proton Mail
        # https://proton.me/mail
        "Proton.ProtonMail"
        # Proton Drive
        # https://proton.me/drive
        "Proton.ProtonDrive"
        # Proton Pass
        # https://proton.me/pass
        "Proton.ProtonPass"
        # Proton VPN
        # https://proton.me/vpn
        "Proton.ProtonVPN"
        # Proton Authenticator
        # https://proton.me/authenticator
        "Proton.ProtonAuthenticator"
        # -────────────────────────────────────────────────────────────────────
        # Utilities
        # -────────────────────────────────────────────────────────────────────
        # 7-Zip
        # https://www.7-zip.org/
        "7zip.7zip"
        # VLC Media Player
        # https://www.videolan.org/vlc/
        "VideoLAN.VLC"
        # Microsoft PowerToys
        # https://learn.microsoft.com/en-us/windows/powertoys/
        "Microsoft.PowerToys"
        # qBittorrent
        # https://www.qbittorrent.org/
        "qBittorrent.qBittorrent"
        # Raycast
        # https://raycast.com/
        "Raycast.Raycast"
        # Synergy
        # https://symless.com/synergy
        "Symless.Synergy"
        # WizFile
        # https://antibody-software.com/wizfile/
        "AntibodySoftware.WizFile"
        # WizTree
        # https://antibody-software.com/wiztree/
        "AntibodySoftware.WizTree"
        # Autoruns
        # https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns
        "Microsoft.Sysinternals.Autoruns"
        # HWiNFO
        # https://www.hwinfo.com/
        "REALiX.HWiNFO"
        # HWMonitor
        # https://www.cpuid.com/softwares/hwmonitor.html
        "CPUID.HWMonitor"
        # Rufus
        # https://rufus.ie/
        "Rufus.Rufus"
        # Revo Uninstaller
        # https://www.revouninstaller.com/
        "RevoUninstaller.RevoUninstaller"
        # -────────────────────────────────────────────────────────────────────
        # Development
        # -────────────────────────────────────────────────────────────────────
        # GitHub Desktop
        # https://desktop.github.com/
        "GitHub.GitHubDesktop"
        # Docker Desktop
        # https://docker.com/products/docker-desktop/
        "Docker.DockerDesktop"
        # Blender
        # https://blender.org/
        "BlenderFoundation.Blender"
        # Figma
        # https://figma.com/
        "Figma.Figma"
        # Unity Hub
        # https://unity.com/download
        "Unity.UnityHub"
        # -────────────────────────────────────────────────────────────────────
        # IDEs & Code Tools
        # -────────────────────────────────────────────────────────────────────
        # Visual Studio Code
        # https://code.visualstudio.com/
        "Microsoft.VisualStudioCode"
        # Visual Studio Community
        # https://visualstudio.microsoft.com/vs/community/
        "Microsoft.VisualStudio.Community"
        # SQL Server Management Studio
        # https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
        "Microsoft.SQLServerManagementStudio"
        # JetBrains Toolbox
        # https://jetbrains.com/toolbox-app/
        "JetBrains.Toolbox"
        # JetBrains DotUltimate
        # https://jetbrains.com/dotultimate/
        "JetBrains.dotUltimate"
        # -────────────────────────────────────────────────────────────────────
        # CLIs & Terminal
        # -────────────────────────────────────────────────────────────────────
        # Git
        # https://git-scm.com/
        "Git.Git"
        # GitHub CLI
        # https://cli.github.com/
        "GitHub.GitHubCLI"
        # Zoxide
        # https://github.com/ajeetdsouza/zoxide
        @{
            Id           = "ajeetdsouza.zoxide"
            ProfileLines = @(
                "Invoke-Expression (& { (zoxide init powershell | Out-String) })"
            )
        }
        # Oh My Posh
        # https://ohmyposh.dev/
        @{
            Id           = "JanDeDobbeleer.OhMyPosh"
            ProfileLines = @(
                'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'
            )
        }
        # -────────────────────────────────────────────────────────────────────
        # Package Managers
        # -────────────────────────────────────────────────────────────────────
        # Bun
        # https://bun.com/
        "Oven-sh.Bun"
        # Node.js
        # https://nodejs.org/
        "OpenJS.NodeJS"
        # NuGet
        # https://nuget.org/
        "NuGet.NuGet"
        # -────────────────────────────────────────────────────────────────────
        # Gaming
        # -────────────────────────────────────────────────────────────────────
        # Steam
        # https://steampowered.com/
        "Valve.Steam"
        # Epic Games Launcher
        # https://epicgames.com/store/en-US/download
        "EpicGames.EpicGamesLauncher"
    )

    # ─────────────────────────────────────────────────────────────────────────
    # Sophia Script (Windows 11)
    # All Function:
    # https://github.com/farag2/Sophia-Script-for-Windows/blob/master/src/Sophia_Script_for_Windows_11_PowerShell_7/Sophia.ps1
    # ─────────────────────────────────────────────────────────────────────────
    SophiaFunctions = @(
        # Protection
        "CreateRestorePoint"
        # Privacy & Telemetry
        "DiagTrackService -Disable"
        "DiagnosticDataLevel -Minimal"
        "ErrorReporting -Disable"
        "FeedbackFrequency -Never",
        "ScheduledTasks -Disable",
        "SigninInfo -Disable",
        "LanguageListAccess -Disable",
        "AdvertisingID -Disable",
        "WindowsWelcomeExperience -Hide",
        "WindowsTips -Disable",
        "SettingsSuggestedContent -Hide",
        "AppsSilentInstalling -Disable",
        "WhatsNewInWindows -Disable",
        "TailoredExperiences -Disable",
        "BingSearch -Disable",
        # UI & Personalization
        "ThisPC -Show",
        "CheckBoxes -Disable",
        "HiddenItems -Enable",
        "FileExtensions -Show",
        "MergeConflicts -Show",
        "OpenFileExplorerTo -ThisPC",
        "FileExplorerCompactMode -Disable",
        "OneDriveFileExplorerAd -Hide",
        "SnapAssist -Enable",
        "FileTransferDialog -Detailed",
        "RecycleBinDeleteConfirmation -Enable",
        "QuickAccessRecentFiles -Hide",
        "QuickAccessFrequentFolders -Hide",
        "TaskbarAlignment -Center",
        "TaskbarWidgets -Hide",
        "TaskbarSearch -Hide",
        "SearchHighlights -Hide",
        "TaskViewButton -Hide",
        "SecondsInSystemClock -Show",
        "ClockInNotificationCenter -Show",
        "TaskbarCombine -Always",
        "UnpinTaskbarShortcuts -Shortcuts Edge, Store, Outlook",
        "TaskbarEndTask -Enable",
        "ControlPanelView -LargeIcons",
        "WindowsColorMode -Dark",
        "AppColorMode -Dark",
        "FirstLogonAnimation -Disable",
        "JPEGWallpapersQuality -Max",
        "ShortcutsSuffix -Disable",
        "PrtScnSnippingTool -Enable",
        "AppsLanguageSwitch -Enable",
        "AeroShaking -Disable",
        "Install-Cursors -Dark",
        "FolderGroupBy -None",
        "NavigationPaneExpand -Disable",
        "RecentlyAddedStartApps -Hide",
        "MostUsedStartApps -Hide",
        "StartRecommendedSection -Hide",
        "StartRecommendationsTips -Hide",
        "StartAccountNotifications -Hide",
        "StartLayout -ShowMorePins",
        # OneDrive
        "OneDrive -Uninstall",
        # System
        "StorageSense -Enable",
        "Hibernation -Disable",
        "Win32LongPathsSupport -Enable",
        "BSoDStopError -Enable",
        "AdminApprovalMode -Never",
        "DeliveryOptimization -Disable",
        "WindowsManageDefaultPrinter -Disable",
        "UpdateMicrosoftProducts -Disable",
        "RestartNotification -Show",
        "RestartDeviceAfterUpdate -Enable",
        "ActiveHours -Automatically",
        "WindowsLatestUpdate -Disable",
        "PowerPlan -High",
        "NetworkAdaptersSavePower -Disable",
        "InputMethod -Default",
        "Set-UserShellFolderLocation -Root",
        "WinPrtScrFolder -Desktop",
        "RecommendedTroubleshooting -Automatically",
        "ReservedStorage -Disable",
        "F1HelpPage -Disable",
        "NumLock -Enable",
        "StickyShift -Disable",
        "Autoplay -Disable",
        "ThumbnailCacheRemoval -Disable",
        "SaveRestartableApps -Enable",
        "NetworkDiscovery -Enable",
        "DefaultTerminalApp -WindowsTerminal",
        "Install-VCRedist -Redistributables 2015_2026_x86, 2015_2026_x64",
        "Install-DotNetRuntimes -Runtimes NET8, NET9, NET10",
        "PreventEdgeShortcutCreation -Channels Stable, Beta, Dev, Canary",
        "RegistryBackup -Enable",
        # WSL
        "Install-WSL",
        # UWP Apps
        "Uninstall-UWPApps",
        # Gaming
        "XboxGameBar -Disable",
        "XboxGameTips -Disable",
        "GPUScheduling -Enable",
        # Scheduled tasks
        "CleanupTask -Register",
        "SoftwareDistributionTask -Register",
        "TempTask -Register",
        # Microsoft Defender & Security
        "NetworkProtection -Enable",
        "PUAppsDetection -Enable",
        "DefenderSandbox -Enable",
        "DismissMSAccount",
        "DismissSmartScreenFilter",
        "EventViewerCustomView -Enable",
        "PowerShellModulesLogging -Enable",
        "PowerShellScriptsLogging -Enable",
        "AppsSmartScreen -Enable",
        "SaveZoneInformation -Disable",
        "WindowsSandbox -Enable",
        "DNSoverHTTPS -Enable -PrimaryDNS 1.0.0.1 -SecondaryDNS 1.1.1.1",
        "LocalSecurityAuthority -Enable",
        # Context menu
        "MSIExtractContext -Show",
        "CABInstallContext -Show",
        "EditWithClipchampContext -Hide",
        "EditWithPhotosContext -Hide",
        "EditWithPaintContext -Hide",
        "PrintCMDContext -Hide",
        "CompressedFolderNewContext -Hide",
        "MultipleInvokeContext -Enable",
        "UseStoreOpenWith -Hide",
        "OpenWindowsTerminalContext -Show",
        "OpenWindowsTerminalAdminContext -Enable",
        # Environment refresh
        "PostActions"
    )

    # ─────────────────────────────────────────────────────────────────────────
    # Nerd Fonts
    # ─────────────────────────────────────────────────────────────────────────
    NerdFonts       = @(
        "CaskaydiaCove"
        "JetBrainsMono"
    )

    # ─────────────────────────────────────────────────────────────────────────
    # PowerShell Modules
    # ─────────────────────────────────────────────────────────────────────────
    PSModules       = @(
        @{
            Name         = "Terminal-Icons"
            ProfileLines = "Import-Module -Name Terminal-Icons"
        }
        @{
            Name         = "PSReadLine"
            ProfileLines = "Set-PSReadLineOption -PredictionSource History"
        }
    )
}
