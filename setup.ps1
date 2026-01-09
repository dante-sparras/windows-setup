#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Modular System Setup Script.

.DESCRIPTION
    Runs specific setup tasks based on flags provided.

.EXAMPLE
    .\Setup.ps1 -All
.EXAMPLE
    .\Setup.ps1 -Apps -Profile
#>

[CmdletBinding()]
param (
    [switch]$All,
    [switch]$Apps,
    [switch]$Modules,
    [switch]$Profile,
    [switch]$Fonts
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# --- Logic Configuration ---

if ($All) {
    $Apps = $Modules = $Profile = $Fonts = $true
}

if (-not ($Apps -or $Modules -or $Profile -or $Fonts)) {
    Write-Warning "No actions selected."
    Write-Host "Usage: .\Setup.ps1 [-Apps] [-Modules] [-Profile] [-Fonts] [-All]" -ForegroundColor Gray
    exit
}

# --- Helper Functions ---

function Write-Log {
    param(
        [string]$Message,
        [string]$Color = 'Cyan',
        [switch]$TimeStamp
    )
    $prefix = if ($TimeStamp) { "[$((Get-Date).ToString('HH:mm:ss'))] " } else { "" }
    Write-Host "$prefix$Message" -ForegroundColor $Color
}

function Update-EnvironmentPath {
    Write-Log "Refreshing Environment Variables..." -Color DarkGray
    $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Add-ProfileLine {
    param([Parameter(Mandatory)][string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) { return }

    # Prefer CurrentUserAllHosts, fallback to standard profile path
    $targetPath = if ($PROFILE.CurrentUserAllHosts) { $PROFILE.CurrentUserAllHosts } else { $PROFILE }

    # Ensure directory exists
    $parentDir = Split-Path -Path $targetPath -Parent
    if (-not (Test-Path -Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Ensure file exists
    if (-not (Test-Path -Path $targetPath)) {
        New-Item -ItemType File -Path $targetPath -Force | Out-Null
        Write-Log "Created new profile: $targetPath" -Color Gray
    }

    # Check content safely
    try {
        $content = Get-Content -Path $targetPath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content -or $content -notmatch [regex]::Escape($Line)) {
            Add-Content -Path $targetPath -Value "`n$Line"
            Write-Log "Profile updated: Added '$Line'" -Color Green
        }
        else {
            Write-Verbose "Skipping '$Line' (Already in profile)"
        }
    }
    catch {
        Write-Log "Failed to read/write profile: $_" -Color Red
    }
}

function Install-PSGalleryModule {
    param([string[]]$Modules)

    foreach ($module in $Modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Log "Skipping Module: $module (Installed)" -Color Yellow
            continue
        }

        Write-Log "Installing Module: $module..." -Color Cyan -TimeStamp
        try {
            # Scope CurrentUser is safer; remove -Scope if AllUsers is desired
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
            Write-Log "Successfully Installed: $module" -Color Green
        }
        catch {
            Write-Log "Failed to install $module`: $_" -Color Red
        }
    }
}

function Install-WingetApp {
    param([string[]]$Apps)

    foreach ($app in $Apps) {
        Write-Verbose "Checking status for $app..."

        # 'winget list' is slow; -e ensures exact ID match
        $isInstalled = winget list --id $app --exact --source winget 2>$null

        if ($isInstalled) {
            Write-Log "Skipping App: $app (Installed)" -Color Yellow
            continue
        }

        Write-Log "Installing App: $app..." -Color Cyan -TimeStamp
        $args = @('install', '--id', $app, '-e', '--silent', '--accept-package-agreements', '--accept-source-agreements')

        $process = Start-Process 'winget' -ArgumentList $args -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Log "Installed: $app" -Color Green
        }
        else {
            Write-Log "Installation Failed: $app (Exit Code: $($process.ExitCode))" -Color Red
        }
    }
    # Refresh Path once after all apps are processed
    Update-EnvironmentPath
}

function Install-TerminalFont {
    param([string]$Font = 'GeistMono')

    if (-not (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue)) {
        Write-Warning "Oh-My-Posh not found. Cannot auto-install fonts."
        return
    }

    Write-Log "Installing Font via Oh-My-Posh..." -TimeStamp
    oh-my-posh font install $Font

    $termSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (Test-Path $termSettingsPath) {
        try {
            $jsonContent = Get-Content $termSettingsPath -Raw
            $json = $jsonContent | ConvertFrom-Json

            # Ensure object structure exists
            if (-not $json.profiles.defaults.PSObject.Properties.Match('font')) {
                $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name 'font' -Value @{}
            }

            # Update Font Face
            $fontName = "$Font Nerd Font"
            if ($json.profiles.defaults.font.face -ne $fontName) {
                $json.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name 'face' -Value $fontName -Force

                # CRITICAL: Depth 100 prevents nested JSON (like color schemes) from being deleted
                $json | ConvertTo-Json -Depth 100 | Set-Content $termSettingsPath
                Write-Log "Windows Terminal Configured to use $fontName" -Color Green
            }
            else {
                Write-Log "Terminal already using $fontName" -Color Yellow
            }
        }
        catch {
            Write-Log "Error updating Terminal settings: $_" -Color Red
        }
    }
    else {
        Write-Warning "Windows Terminal settings.json not found."
    }
}

# --- Data Definitions ---

$appList = @(
    # General
    "Zen-Team.Zen-Browser",
    "Notion.Notion",
    "Notion.NotionCalendar",
    "Spotify.Spotify",
    "Discord.Discord",
    "Zoom.Zoom",
    "Proton.ProtonDrive",
    "Proton.ProtonMail",
    # Dev Core
    "Oven-sh.Bun",
    "OpenJS.NodeJS",
    "Git.Git",
    "GitHub.cli",
    "GitHub.GitHubDesktop",
    "Docker.DockerDesktop",
    "Microsoft.VisualStudioCode",
    "Microsoft.VisualStudio.Community",
    "BlenderFoundation.Blender",
    "Figma.Figma",
    "JetBrains.Toolbox",
    "JetBrains.dotUltimate",
    "Unity.UnityHub",
    "Microsoft.AzureDataStudio",
    # Runtimes & Frameworks
    "Microsoft.DotNet.DesktopRuntime.3_1",
    "Microsoft.DotNet.DesktopRuntime.5",
    "Microsoft.DotNet.DesktopRuntime.6",
    "Microsoft.DotNet.DesktopRuntime.7",
    "Microsoft.DotNet.DesktopRuntime.8",
    "Microsoft.DotNet.DesktopRuntime.9",
    "Microsoft.NuGet",
    "Microsoft.SQLServerManagementStudio",
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86",
    # Shell Enhancements
    "ajeetdsouza.zoxide",
    "JanDeDobbeleer.OhMyPosh",
    # Gaming
    "Valve.Steam",
    "EpicGames.EpicGamesLauncher",
    # Utility & System
    "7zip.7zip",
    "VideoLAN.VLC",
    "Microsoft.PowerToys",
    "Proton.ProtonAuthenticator",
    "Proton.ProtonPass",
    "Proton.ProtonVPN",
    "qBittorrent.qBittorrent",
    "Raycast.Raycast",
    "Symless.Synergy",
    "AntibodySoftware.WizFile",
    "AntibodySoftware.WizTree",
    "Microsoft.Sysinternals.Autoruns",
    "REALiX.HWiNFO",
    "CPUID.HWMonitor",
    "Rufus.Rufus",
    "RevoUninstaller.RevoUninstaller"
)

$moduleList = @(
    "Terminal-Icons"
)

# --- Execution Flow ---

if ($Apps) {
    Install-WingetApp -Apps $appList
}

if ($Modules) {
    Install-PSGalleryModule -Modules $moduleList
}

if ($Profile) {
    Add-ProfileLine "Import-Module Terminal-Icons"
    Add-ProfileLine "Set-PSReadLineOption -PredictionSource History"
    Add-ProfileLine 'Invoke-Expression (& { (zoxide init powershell | Out-String) })'
    Add-ProfileLine 'oh-my-posh init pwsh | Invoke-Expression'
}

if ($Fonts) {
    Install-TerminalFont -Font "GeistMono"
}

Write-Log "Setup Complete." -Color Green -TimeStamp
