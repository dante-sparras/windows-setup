#requires -Version 5.1

<#
.SYNOPSIS
    Windows 11 Setup & Configuration Script (Refactored)

.DESCRIPTION
    A comprehensive bootstrapping and configuration script for Windows 11.
    Driven by 'config.psd1', it handles elevation, PowerShell 7, Winget,
    system tweaks (Sophia), and more.

.PARAMETER ConfigPath
    Path to the configuration data file (psd1). Defaults to 'config.psd1'.

.PARAMETER SkipRestore
    Overrides config to skip System Restore point creation.

.PARAMETER SkipSophia
    Overrides config to skip Sophia Script tweaks.

.PARAMETER SkipWinget
    Overrides config to skip Winget operations.

.PARAMETER SkipDotfiles
    Overrides config to skip dotfile downloads.

.PARAMETER SkipFonts
    Overrides config to skip font installation.

.PARAMETER SkipModules
    Overrides config to skip PowerShell module installation.

.PARAMETER KeepTemp
    Preserves the temporary directory used during execution for debugging.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config.psd1'),

    [switch]$SkipRestore,
    [switch]$SkipSophia,
    [switch]$SkipWinget,
    [switch]$SkipDotfiles,
    [switch]$SkipFonts,
    [switch]$SkipModules,
    [switch]$KeepTemp
)

#region Globals
$Script:LogFile = $null
$Script:TempDir = $null
$ErrorActionPreference = 'Stop'
#endregion

#region Logging
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $ColorMap = @{ 'INFO' = 'Cyan'; 'SUCCESS' = 'Green'; 'WARN' = 'Yellow'; 'ERROR' = 'Red' }
    $LogLine = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Write-Host $LogLine -ForegroundColor $ColorMap[$Level]
    if ($Script:LogFile) { Add-Content -Path $Script:LogFile -Value $LogLine -Encoding UTF8 }
}

function Write-Section {
    param([string]$Title)
    Write-Log ("-" * 60)
    Write-Log $Title
    Write-Log ("-" * 60)
}
#endregion

#region Bootstrap (Admin + PWSH)
function Initialize-Bootstrap {
    # 1. Web / Memory Execution Handling
    if (-not $PSScriptRoot) {
        $tempDir = New-Item -Path (Join-Path $env:TEMP "WinSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss')") -ItemType Directory -Force
        $scriptPath = Join-Path $tempDir 'setup.ps1'
        $MyInvocation.MyCommand.ScriptBlock.ToString() | Set-Content -Path $scriptPath -Encoding UTF8

        # Handle Config
        if (-not (Test-Path $ConfigPath)) {
            Write-Host "Downloading default config..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/dante-sparras/windows-setup/main/config.psd1" -OutFile (Join-Path $tempDir 'config.psd1') -ErrorAction Stop
                $ConfigPath = Join-Path $tempDir 'config.psd1'
            }
            catch { Write-Warning "Failed to download config."; exit 1 }
        }

        # Build Args
        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath, '-ConfigPath', $ConfigPath)
        $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -ne 'ConfigPath' } | ForEach-Object {
            if ($_.Value -is [switch] -and $_.Value) { $argsList += "-$($_.Key)" }
            elseif ($_.Value -isnot [switch]) { $argsList += "-$($_.Key)", $_.Value }
        }
        $argsList += '-KeepTemp'

        Start-Process 'powershell' -ArgumentList $argsList -Wait
        exit
    }

    # 2. Elevation
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Host "Elevating..." -ForegroundColor Yellow
        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-ConfigPath', $ConfigPath)
        $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -ne 'ConfigPath' } | ForEach-Object {
            if ($_.Value -is [switch] -and $_.Value) { $argsList += "-$($_.Key)" }
            elseif ($_.Value -isnot [switch]) { $argsList += "-$($_.Key)", $_.Value }
        }
        Start-Process 'powershell' -ArgumentList $argsList -Verb RunAs -Wait
        exit
    }

    # 3. PowerShell 7
    if ($PSVersionTable.PSEdition -ne 'Core') {
        Write-Host "Switching to PowerShell 7..." -ForegroundColor Cyan
        if (-not (Get-Command 'pwsh' -ErrorAction SilentlyContinue)) {
            Write-Host "Installing PowerShell 7..."
            winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements
        }
        $pwshPath = (Get-Command 'pwsh').Source
        $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-ConfigPath', $ConfigPath)
        $PSBoundParameters.GetEnumerator() | Where-Object { $_.Key -ne 'ConfigPath' } | ForEach-Object {
            if ($_.Value -is [switch] -and $_.Value) { $argsList += "-$($_.Key)" }
            elseif ($_.Value -isnot [switch]) { $argsList += "-$($_.Key)", $_.Value }
        }
        Start-Process $pwshPath -ArgumentList $argsList -Wait
        exit
    }
}
#endregion

#region Tasks
function New-RestorePoint {
    Write-Section 'Create Restore Point'
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Setup_$(Get-Date -Format 'yyyyMMdd')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log -Level SUCCESS "Restore point created."
    }
    catch { Write-Log -Level WARN "Failed to create restore point: $_" }
}

function Invoke-Sophia {
    param($Config)
    Write-Section 'Sophia Script'
    try {
        $url = $Config.Resources.SophiaReleaseApi
        $release = Invoke-RestMethod $url
        $zipUrl = $release.assets | Where-Object { $_.name -match 'Windows\.11' -and $_.name -notlike '*LTSC*' } | Select-Object -First 1 -ExpandProperty browser_download_url

        $zipPath = Join-Path $Script:TempDir 'Sophia.zip'
        $dest = Join-Path $Script:TempDir 'Sophia'

        Invoke-WebRequest $zipUrl -OutFile $zipPath
        Expand-Archive $zipPath -DestinationPath $dest -Force

        $script = Get-ChildItem $dest -Filter 'Sophia.ps1' -Recurse | Select-Object -First 1 -ExpandProperty FullName
        $funcs = $Config.SophiaFunctions -join ','

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $script -Functions $funcs
        Write-Log -Level SUCCESS "Sophia Script applied."
    }
    catch { Write-Log -Level ERROR "Sophia failed: $_" }
}

function Install-Winget {
    param($Config)
    Write-Section 'Winget Packages'

    # Settings
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path (Split-Path $settingsPath)) {
        $Config.WingetSettings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Force
    }

    # Packages
    foreach ($pkg in $Config.WingetPackages) {
        if (-not $pkg.Id) { continue }
        Write-Log "Installing: $($pkg.Id)"
        $wingetArgs = @('install', '--id', $pkg.Id, '--exact', '--silent', '--accept-package-agreements', '--accept-source-agreements')
        if ($pkg.Args) { $wingetArgs += $pkg.Args }

        $output = & winget @wingetArgs 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Log -Level SUCCESS "Installed $($pkg.Id)" }
        else {
            Write-Log -Level WARN "Failed $($pkg.Id)"
            if ($Script:LogFile -and $output) { $output | Out-String | Add-Content -Path $Script:LogFile }
        }

        # Dotfiles & Profile Extras
        if ($pkg.Dotfiles -and $Config.Settings.EnableDotfiles -and -not $SkipDotfiles) {
            foreach ($df in $pkg.Dotfiles) {
                try {
                    $p = $ExecutionContext.InvokeCommand.ExpandString($df.Destination)
                    New-Item -Path (Split-Path $p) -ItemType Directory -Force | Out-Null
                    Invoke-WebRequest $df.Url -OutFile $p
                    Write-Log -Level SUCCESS "Fetched: $(Split-Path $p -Leaf)"
                }
                catch { Write-Log -Level ERROR "Dotfile error: $_" }
            }
        }

        if ($pkg.ProfileLines -and $Config.Settings.EnableProfile -and -not $SkipProfile) {
            Update-Profile $pkg.ProfileLines
        }
    }
}

function Install-Fonts {
    param($Fonts)
    Write-Section 'Nerd Fonts'
    if (-not (Get-Module -ListAvailable NerdFonts)) {
        Install-Module NerdFonts -Scope CurrentUser -Force -AllowClobber
    }
    foreach ($f in $Fonts) {
        try { Install-NerdFont -Name $f -Scope CurrentUser -ErrorAction Stop; Write-Log -Level SUCCESS "$f" }
        catch { Write-Log -Level WARN "$f failed" }
    }
}

function Install-Modules {
    param($Modules)
    Write-Section 'PowerShell Modules'
    foreach ($m in $Modules) {
        try { Install-Module $m.Name -Scope CurrentUser -Force -AllowClobber; Write-Log -Level SUCCESS "$($m.Name)" }
        catch { Write-Log -Level WARN "$($m.Name) failed" }

        if ($m.ProfileLines) { Update-Profile $m.ProfileLines }
    }
}

function Update-Profile {
    param($Lines)
    if (-not (Test-Path $PROFILE)) { New-Item $PROFILE -Force | Out-Null }

    $existing = @(Get-Content $PROFILE -ErrorAction SilentlyContinue)
    $toAdd = $Lines | Where-Object { $_ -notin $existing }

    if ($toAdd) {
        Add-Content $PROFILE -Value $toAdd -Force
        Write-Log -Level SUCCESS "Updated Profile (+$($toAdd.Count) lines)"
    }
}
#endregion

#region Main
try {
    Initialize-Bootstrap

    # Setup Context
    $Script:TempDir = New-Item -Path (Join-Path $env:TEMP "WinSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss')") -ItemType Directory -Force
    $Script:LogDir = Join-Path $PSScriptRoot 'logs'; New-Item $Script:LogDir -ItemType Directory -Force | Out-Null
    $Script:LogFile = Join-Path $Script:LogDir "Setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

    Write-Section "STARTING SETUP"
    Write-Log "Config: $ConfigPath"

    $Config = Import-PowerShellDataFile -Path $ConfigPath

    # Execution Logic (Config + Flags)
    if ($Config.Settings.EnableRestorePoint -and -not $SkipRestore) { New-RestorePoint }
    if ($Config.Settings.EnableSophia -and -not $SkipSophia) { Invoke-Sophia -Config $Config }
    if ($Config.Settings.EnableWinget -and -not $SkipWinget) { Install-Winget -Config $Config }
    if ($Config.Settings.EnableFonts -and -not $SkipFonts) { Install-Fonts -Fonts $Config.NerdFonts }
    if ($Config.Settings.EnableModules -and -not $SkipModules) { Install-Modules -Modules $Config.PSModules }

    Write-Section "COMPLETE"
    Write-Log -Level SUCCESS "Setup finished successfully."

}
catch {
    Write-Log -Level ERROR "CRITICAL: $_"
    exit 1
}
finally {
    if (-not $KeepTemp -and $Script:TempDir) { Remove-Item $Script:TempDir -Recurse -Force -ErrorAction SilentlyContinue }
}
#endregion
