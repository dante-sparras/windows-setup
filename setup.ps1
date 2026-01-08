#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Utilities

function Update-Path {
    <#
    .SYNOPSIS
        Updates the PATH environment variable from the registry.
    #>
    $env:PATH = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Test-WingetPackageInstalled {
    <#
    .SYNOPSIS
        Checks if a specific winget package is installed.

    .PARAMETER PackageId
        The exact package ID to check (e.g., "Mozilla.Firefox")

    .OUTPUTS
        Boolean - $true if package is installed, $false otherwise
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $result = winget list --id $PackageId --exact 2>$null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackage {
    <#
    .SYNOPSIS
        Installs a winget package silently, accepting agreements.

    .PARAMETER PackageId
        The exact package ID to install.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    if (Test-WingetPackageInstalled $PackageId) {
        Write-Host "Package '$PackageId' is already installed. Skipping." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Installing package '$PackageId'..." -ForegroundColor Cyan
        winget install --id $PackageId --exact --silent --accept-source-agreements --accept-package-agreements --disable-interactivity |
        Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "Winget exited with code $LASTEXITCODE"
        }

        Update-Path
        Write-Host "Package '$PackageId' installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install package '$PackageId': $_"
    }
}

function Test-PowershellGalleryModuleInstalled {
    <#
    .SYNOPSIS
        Checks if a PowerShell Gallery module is installed.

    .PARAMETER ModuleName
        The name of the module to check.

    .OUTPUTS
        Boolean - $true if module is installed, $false otherwise
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $module = Get-Module -ListAvailable -Name $ModuleName
    return $null -ne $module
}

function Install-PowershellGalleryModule {
    <#
    .SYNOPSIS
        Installs a PowerShell Gallery module if not already installed.

    .PARAMETER ModuleName
        The name of the module to install.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if (Test-PowershellGalleryModuleInstalled -ModuleName $ModuleName) {
        Write-Host "Module '$ModuleName' is already installed. Skipping." -ForegroundColor Yellow
        return
    }

    try {
        Write-Host "Installing module '$ModuleName'..." -ForegroundColor Cyan
        Install-Module -Name $ModuleName -Repository PSGallery -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "Module '$ModuleName' installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install module '$ModuleName': $_"
    }
}

function New-PowerShellProfile {
    <#
    .SYNOPSIS
        Creates a PowerShell profile file if it does not exist.

    .OUTPUTS
        Void
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if (-not (Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Write-Host "PowerShell profile created at '$PROFILE'." -ForegroundColor Green
    }
}

function Add-ContentToPowerShellProfile {
    <#
    .SYNOPSIS
        Adds content to the PowerShell profile if it does not already exist.

    .PARAMETER Content
        The content to add to the profile.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    if (-not (Test-Path -Path $PROFILE)) {
        New-PowerShellProfile
    }

    $profileContent = Get-Content -Path $PROFILE -Raw

    if (-not $profileContent -or $profileContent -notmatch [regex]::Escape($Content)) {
        Add-Content -Path $PROFILE -Value "`n$Content"
        Write-Host "Added to profile: $Content" -ForegroundColor Green
    }
    else {
        Write-Host "Profile already contains: $Content" -ForegroundColor Yellow
    }
}

function Invoke-WinUtilWithConfig {
    <#
    .SYNOPSIS
        Invokes WinUtil with the provided configuration.

    .PARAMETER Config
        The configuration object to pass to WinUtil.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSObject]$Config
    )

    $configJson = $Config | ConvertTo-Json -Depth 5
    $tempFile = [System.IO.Path]::GetTempFileName()

    Set-Content -Path $tempFile -Value $configJson -Encoding UTF8

    try {
        Write-Host "Invoking WinUtil with configuration..." -ForegroundColor Cyan
        Invoke-Expression "& { $(Invoke-RestMethod https://christitus.com/win) } -Config `"$tempFile`" -Run"
    }
    catch {
        Write-Error "Failed to initialize WinUtil: $_"
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

function Update-WtDefaultsFontFace {
    <#
    .SYNOPSIS
        Updates the default font face in Windows Terminal settings.
    .PARAMETER Face
        The font face to set as default.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Face
    )

    $possiblePaths = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )

    $path = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $path) {
        Write-Warning "Windows Terminal settings file not found."
        return
    }

    try {
        # Read file
        $content = Get-Content $path -Raw

        # Windows Terminal JSON often contains comments which ConvertFrom-Json can't handle.
        # We strip them out just in case, though usually WT settings are clean.
        $content = $content -replace '(?m)^\s*//.*$', ''

        # Convert to Hashtable for easier manipulation
        # If on PS7+, -AsHashtable works. For PS5, we use a different approach.
        if ($PSVersionTable.PSVersion.Major -ge 6) {
            $settings = $content | ConvertFrom-Json -AsHashtable
        }
        else {
            # Legacy PS5.1 logic to ensure we have a modifiable object
            $settings = $content | ConvertFrom-Json
        }

        # 1. Ensure 'profiles' exists and is a container
        if ($null -eq $settings.profiles) {
            $settings | Add-Member -Name "profiles" -Value @{} -MemberType NoteProperty -Force
        }

        # 2. Ensure 'defaults' exists inside 'profiles'
        if ($null -eq $settings.profiles.defaults) {
            if ($settings.profiles -is [hashtable]) {
                $settings.profiles["defaults"] = @{}
            }
            else {
                $settings.profiles | Add-Member -Name "defaults" -Value @{} -MemberType NoteProperty -Force
            }
        }

        # 3. Ensure 'font' exists inside 'defaults'
        # If it's a string (old style), we overwrite it with an object
        if ($null -eq $settings.profiles.defaults.font -or $settings.profiles.defaults.font -is [string]) {
            if ($settings.profiles.defaults -is [hashtable]) {
                $settings.profiles.defaults["font"] = @{}
            }
            else {
                $settings.profiles.defaults | Add-Member -Name "font" -Value @{} -MemberType NoteProperty -Force
            }
        }

        # 4. Set the face property using the most compatible method
        if ($settings.profiles.defaults.font -is [hashtable]) {
            $settings.profiles.defaults.font["face"] = $Face
        }
        else {
            # Use Add-Member to bypass the "property not found" assignment error
            $settings.profiles.defaults.font | Add-Member -Name "face" -Value $Face -MemberType NoteProperty -Force
        }

        # Convert back to JSON
        $jsonOutput = $settings | ConvertTo-Json -Depth 20
        $jsonOutput | Set-Content $path -Encoding UTF8

        Write-Host "Windows Terminal font set to '$Face' successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update Windows Terminal settings: $($_.Exception.Message)"
    }
}

function Test-CommandExists {
    <#
    .SYNOPSIS
        Checks if a command exists in the current PATH.

    .PARAMETER Command
        The command to check.

    .OUTPUTS
        Boolean - $true if command exists, $false otherwise
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$Command
    )

    return $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

#endregion

#region Main

# =====================================
# PowerShell Environment
# =====================================

# Create Powershell Profile
New-PowerShellProfile

# zoxide
Install-WingetPackage "ajeetdsouza.zoxide"
Add-ContentToPowerShellProfile -Content 'Invoke-Expression (& { (zoxide init powershell | Out-String) })'

# Oh My Posh
Install-WingetPackage "JanDeDobbeleer.OhMyPosh"
Add-ContentToPowerShellProfile -Content "oh-my-posh init pwsh | Invoke-Expression"

# Terminal Icons
Install-PowershellGalleryModule -ModuleName "Terminal-Icons"
Add-ContentToPowerShellProfile -Content "Import-Module Terminal-Icons"

# Geist Mono Nerd Font (only if oh-my-posh is available)
if (Test-CommandExists -Command "oh-my-posh") {
    Write-Host "Installing Geist Mono Nerd Font..." -ForegroundColor Cyan
    oh-my-posh font install GeistMono
}
else {
    Write-Warning "oh-my-posh not found in PATH. Skipping font installation. You may need to restart your terminal and run 'oh-my-posh font install geist-mono' manually."
}

# Change Windows terminal font to Geist Mono Nerd Font
Update-WtDefaultsFontFace -Face "GeistMono Nerd Font"

# =====================================
# Developer Packages
# =====================================

# Bun
Install-WingetPackage "Oven-sh.Bun"

# NodeJS
Install-WingetPackage "OpenJS.NodeJS"

# Git
Install-WingetPackage  "Git.Git"

# GitHub CLI
Install-WingetPackage "GitHub.cli"

# GitHub Desktop
Install-WingetPackage "GitHub.GitHubDesktop"

# Docker Desktop
Install-WingetPackage "Docker.DockerDesktop"

# Visual Studio Code
Install-WingetPackage "Microsoft.VisualStudioCode"

# Visual Studio
Install-WingetPackage "Microsoft.VisualStudio.Community"

# Blender
Install-WingetPackage "BlenderFoundation.Blender"

# Figma
Install-WingetPackage "Figma.Figma"

# Claude Code
Install-WingetPackage "Anthropic.ClaudeCode"

# JetBrains Toolbox
Install-WingetPackage "JetBrains.Toolbox"

# JetBrains dotUltimate
Install-WingetPackage "JetBrains.dotUltimate"

# Unity Hub
Install-WingetPackage "Unity.UnityHub"

# Azure Data Studio
Install-WingetPackage "Microsoft.AzureDataStudio"

# .NET Desktop Runtime 3.1 / 5 / 6 / 7 / 8 / 9
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.3_1"
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.5"
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.6"
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.7"
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.8"
Install-WingetPackage "Microsoft.DotNet.DesktopRuntime.9"

# Nuget
Install-WingetPackage "Microsoft.NuGet"

# SQL Server Management Studio
Install-WingetPackage "Microsoft.SQLServerManagementStudio"

# Visual C++ 2015-2022 32-bit and 64-bit
Install-WingetPackage "Microsoft.VCRedist.2015+.x64"
Install-WingetPackage "Microsoft.VCRedist.2015+.x86"

# =====================================
# General Packages
# =====================================

# Zen Browser
Install-WingetPackage "Zen-Team.Zen-Browser"

# Notion
Install-WingetPackage "Notion.Notion"

# Notion Calendar
Install-WingetPackage "Notion.NotionCalendar"

# Spotify
Install-WingetPackage "Spotify.Spotify"

# Discord
Install-WingetPackage "Discord.Discord"

# Zoom
Install-WingetPackage "Zoom.Zoom"

# Proton Drive
Install-WingetPackage "Proton.ProtonDrive"

# Proton Mail
Install-WingetPackage "Proton.ProtonMail"

# =====================================
# Gaming Packages
# =====================================

# Steam
Install-WingetPackage "Valve.Steam"

# Epic Games Launcher
Install-WingetPackage "EpicGames.EpicGamesLauncher"

# =====================================
# Utility Packages
# =====================================

# 7zip
Install-WingetPackage "7zip.7zip"

# VLC
Install-WingetPackage "VideoLAN.VLC"

# Microsoft PowerToys
Install-WingetPackage "Microsoft.PowerToys"

# Proton Authenticator
Install-WingetPackage "Proton.ProtonAuthenticator"

# Proton Pass
Install-WingetPackage "Proton.ProtonPass"

# Proton VPN
Install-WingetPackage "Proton.ProtonVPN"

# qBittorrent
Install-WingetPackage "qBittorrent.qBittorrent"

# Raycast (Microsoft Store)
Install-WingetPackage "Raycast.Raycast"

# Synergy
Install-WingetPackage "Symless.Synergy"

# WizFile
Install-WingetPackage "AntibodySoftware.WizFile"

# WizTree
Install-WingetPackage "AntibodySoftware.WizTree"

# Autoruns
Install-WingetPackage "Microsoft.Sysinternals.Autoruns"

# HWInfo
Install-WingetPackage "REALiX.HWiNFO"

# HWMonitor
Install-WingetPackage "CPUID.HWMonitor"

# Rufus Imager
Install-WingetPackage "Rufus.Rufus"

# Revo Uninstaller
Install-WingetPackage "RevoUninstaller.RevoUninstaller"

# =====================================
# Windows Tweaks and Features
# =====================================

Invoke-WinUtilWithConfig -Config @{
    WPFTweaks  = @(
        "WPFTweaksRestorePoint",
        "WPFTweaksRemoveGallery",
        "WPFTweaksTele",
        "WPFTweaksServices",
        "WPFTweaksPowershell7",
        "WPFTweaksActivity",
        "WPFTweaksRemoveCopilot",
        "WPFTweaksDVR",
        "WPFTweaksDisableExplorerAutoDiscovery",
        "WPFTweaksConsumerFeatures",
        "WPFTweaksRemoveHome",
        "WPFTweaksDisplay",
        "WPFTweaksRightClickMenu",
        "WPFTweaksDiskCleanup",
        "WPFTweaksDeleteTempFiles",
        "WPFTweaksLocation",
        "WPFTweaksEndTaskOnTaskbar",
        "WPFTweaksPowershell7Tele"
    )
    WPFInstall = @()
    WPFFeature = @(
        "WPFFeaturesSandbox",
        "WPFFeatureshyperv",
        "WPFFeaturesdotnet",
        "WPFFeaturewsl"
    )
    Install    = @()
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "Please restart your terminal for all changes to take effect." -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Cyan

#endregion
