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
        EnableProfile      = $false # Default off, as it modifies user profile
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
        @{
            # Zen Browser
            # https://zen-browser.app/
            Id = "Zen-Team.Zen-Browser"
        }
        @{
            # Chrome Browser
            # https://google.com/chrome/
            Id = "Google.Chrome"
        }
        @{
            # Notion
            # https://notion.com/
            Id = "Notion.Notion"
        }
        @{
            # Notion Calendar
            # https://notion.com/product/calendar
            Id = "Notion.NotionCalendar"
        }
        @{
            # Spotify
            # https://spotify.com/
            Id = "Spotify.Spotify"
        }
        @{
            # Discord
            # https://discord.com/
            Id = "Discord.Discord"
        }
        @{
            # Zoom
            # https://zoom.com/
            Id = "Zoom.Zoom"
        }
        @{
            # Proton Mail
            # https://proton.me/mail
            Id = "Proton.ProtonMail"
        }
        @{
            # Proton Drive
            # https://proton.me/drive
            Id = "Proton.ProtonDrive"
        }
        @{
            # Proton Pass
            # https://proton.me/pass
            Id = "Proton.ProtonPass"
        }
        @{
            # Proton VPN
            # https://proton.me/vpn
            Id = "Proton.ProtonVPN"
        }
        @{
            # Proton Authenticator
            # https://proton.me/authenticator
            Id = "Proton.ProtonAuthenticator"
        }
        # -────────────────────────────────────────────────────────────────────
        # Utilities
        # -────────────────────────────────────────────────────────────────────
        @{
            # 7-Zip
            # https://www.7-zip.org/
            Id = "7zip.7zip"
        }
        @{
            # VLC Media Player
            # https://www.videolan.org/vlc/
            Id = "VideoLAN.VLC"
        }
        @{
            # Microsoft PowerToys
            # https://learn.microsoft.com/en-us/windows/powertoys/
            Id = "Microsoft.PowerToys"
        }
        @{
            # qBittorrent
            # https://www.qbittorrent.org/
            Id = "qBittorrent.qBittorrent"
        }
        @{
            # Raycast
            # https://raycast.com/
            Id = "Raycast.Raycast"
        }
        @{
            # Synergy
            # https://symless.com/synergy
            Id = "Symless.Synergy"
        }
        @{
            # WizFile
            # https://antibody-software.com/wizfile/
            Id = "AntibodySoftware.WizFile"
        }
        @{
            # WizTree
            # https://antibody-software.com/wiztree/
            Id = "AntibodySoftware.WizTree"
        }
        @{
            # Autoruns
            # https://docs.microsoft.com/en-us/sysinternals/downloads/autoruns
            Id = "Microsoft.Sysinternals.Autoruns"
        }
        @{
            # HWiNFO
            # https://www.hwinfo.com/
            Id = "REALiX.HWiNFO"
        }
        @{
            # HWMonitor
            # https://www.cpuid.com/softwares/hwmonitor.html
            Id = "CPUID.HWMonitor"
        }
        @{
            # Rufus
            # https://rufus.ie/
            Id = "Rufus.Rufus"
        }
        @{
            # Revo Uninstaller
            # https://www.revouninstaller.com/
            Id = "RevoUninstaller.RevoUninstaller"
        }
        # -────────────────────────────────────────────────────────────────────
        # Development
        # -────────────────────────────────────────────────────────────────────
        @{
            # GitHub Desktop
            # https://desktop.github.com/
            Id = "GitHub.GitHubDesktop"
        }
        @{
            # Docker Desktop
            # https://docker.com/products/docker-desktop/
            Id = "Docker.DockerDesktop"
        }
        @{
            # Blender
            # https://blender.org/
            Id = "BlenderFoundation.Blender"
        }
        @{
            # Figma
            # https://figma.com/
            Id = "Figma.Figma"
        }
        @{
            # Unity Hub
            # https://unity.com/download
            Id = "Unity.UnityHub"
        }
        # -────────────────────────────────────────────────────────────────────
        # IDEs & Code Tools
        # -────────────────────────────────────────────────────────────────────
        @{
            # Visual Studio Code
            # https://code.visualstudio.com/
            Id = "Microsoft.VisualStudioCode"
        }
        @{
            # Visual Studio Community
            # https://visualstudio.microsoft.com/vs/community/
            Id = "Microsoft.VisualStudio.Community"
        }
        @{
            # SQL Server Management Studio
            # https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
            Id = "Microsoft.SQLServerManagementStudio"
        }
        @{
            # JetBrains Toolbox
            # https://jetbrains.com/toolbox-app/
            Id = "JetBrains.Toolbox"
        }
        @{
            # JetBrains DotUltimate
            # https://jetbrains.com/dotultimate/
            Id = "JetBrains.dotUltimate"
        }
        # -────────────────────────────────────────────────────────────────────
        # CLIs & Terminal
        # -────────────────────────────────────────────────────────────────────
        @{
            # Git
            # https://git-scm.com/
            Id = "Git.Git"
        }
        @{
            # GitHub CLI
            # https://cli.github.com/
            Id = "GitHub.GitHubCLI"
        }
        @{
            # Zoxide
            # https://github.com/ajeetdsouza/zoxide
            Id           = "ajeetdsouza.zoxide"
            ProfileLines = @(
                "Invoke-Expression (& { (zoxide init powershell | Out-String) })"
            )
        }
        @{
            # Oh My Posh
            # https://ohmyposh.dev/
            Id           = "JanDeDobbeleer.OhMyPosh"
            ProfileLines = @(
                'oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression'
            )
        }
        # -────────────────────────────────────────────────────────────────────
        # Package Managers & Runtimes & SDKs
        # -────────────────────────────────────────────────────────────────────
        @{
            # Bun
            # https://bun.com/
            Id = "Oven-sh.Bun"
        }
        @{
            # Node.js
            # https://nodejs.org/
            Id = "OpenJS.NodeJS"
        }
        @{
            # NuGet
            # https://nuget.org/
            Id = "NuGet.NuGet"
        }
        @{
            # .NET SDK 10
            # https://dotnet.microsoft.com/en-us/download/dotnet/10.0
            Id = "Microsoft.DotNet.SDK.10"
        }
        @{
            # .NET SDK 9
            # https://dotnet.microsoft.com/en-us/download/dotnet/9.0
            Id = "Microsoft.DotNet.SDK.9"
        }
        @{
            # Visual C++ Redistributable 2015+ (64-bit)
            # https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170
            Id = "Microsoft.VCRedist.2015+.x64"
        }
        @{
            # Visual C++ Redistributable 2015+ (32-bit)
            # https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170
            Id = "Microsoft.VCRedist.2015+.x86"
        }
        # -────────────────────────────────────────────────────────────────────
        # Gaming
        # -────────────────────────────────────────────────────────────────────
        @{
            # Steam
            # https://steampowered.com/
            Id = "Valve.Steam"
        }
        @{
            # Epic Games Launcher
            # https://epicgames.com/store/en-US/download
            Id = "EpicGames.EpicGamesLauncher"
        }
    )

    # ─────────────────────────────────────────────────────────────────────────
    # Sophia Script (Windows 11)
    # ─────────────────────────────────────────────────────────────────────────
    SophiaFunctions = @(
        "DiagTrackService"
        "ConnectedUserExperiences"
        "Telemetries"
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
