#requires -RunAsAdministrator
#requires -Version 5.1

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
    [switch]$SkipProfile,
    [switch]$KeepTemp
)

# ─────────────────────────────────────────────────────────────────────────────
# Preferences
# ─────────────────────────────────────────────────────────────────────────────
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ─────────────────────────────────────────────────────────────────────────────
# Globals
# ─────────────────────────────────────────────────────────────────────────────
$Script:LogDir = Join-Path $PSScriptRoot 'logs'
$Script:LogFile = $null
$Script:TempDir = $null

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,

        [Parameter(Position = 1)]
        [ValidateSet('INFO', 'SUCCESS', 'WARN', 'ERROR')]
        [string]$Level = 'INFO',

        [string]$LogFilePath = $Script:LogFile
    )

    $ColorMap = @{
        'INFO'    = 'Cyan';
        'SUCCESS' = 'Green';
        'WARN'    = 'Yellow';
        'ERROR'   = 'Red'
    }

    # Create the formatted string
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogLine = "[$Timestamp] [$Level] $Message"

    Write-Host $LogLine -ForegroundColor $ColorMap[$Level]

    # Output to file only if a valid log file path is provided
    if ($LogFilePath) {
        Add-Content -Path $LogFilePath -Value $LogLine -Encoding UTF8
    }
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)

    Write-Log ("-" * 60)
    Write-Log $Title
    Write-Log ("-" * 60)
}

function Initialize-RunContext {
    # Ensure the base log directory exists (creates it if missing, does nothing if present)
    $null = New-Item -Path $Script:LogDir -ItemType Directory -Force

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

    # Define paths
    $Script:LogFile = Join-Path -Path $Script:LogDir -ChildPath "Setup_$timestamp.log"
    $Script:TempDir = Join-Path -Path $env:TEMP -ChildPath "WinSetup_$timestamp"

    # Create the unique temp directory
    $null = New-Item -Path $Script:TempDir -ItemType Directory -Force

    # Output details
    Write-Log "Log:  $Script:LogFile"
    Write-Log "Temp: $Script:TempDir"
}

function Update-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')

    # Join non-empty paths using the correct OS separator
    $env:Path = ($machinePath, $userPath) -ne '' -join [IO.Path]::PathSeparator

    Write-Log -Level SUCCESS "PATH refreshed for current session."
}

function Restart-InPowerShell7IfNeeded {
    # Exit early if already running Core/6+
    if ($PSVersionTable.PSEdition -ne 'Desktop') { return }

    Write-Section 'BOOTSTRAP: PowerShell 7'
    Write-Log -Level WARN 'Windows PowerShell 5.1 detected. Switching to PowerShell 7...'

    # Check for existence; Install if missing
    if (-not (Get-Command 'pwsh' -ErrorAction SilentlyContinue)) {
        Write-Log 'pwsh not found. Installing PowerShell 7 via winget...'

        $installArgs = @('install', '--id', 'Microsoft.PowerShell', '--silent', '--accept-package-agreements', '--accept-source-agreements')
        $output = & winget $installArgs 2>&1

        if ($LASTEXITCODE -ne 0) {
            Write-Log -Level ERROR "PowerShell 7 install failed (Exit Code: $LASTEXITCODE)."
            if ($Script:LogFile) {
                $output | Out-String | Add-Content -Path $Script:LogFile -Encoding UTF8
            }
            throw "Failed to install PowerShell 7."
        }
    }

    # Resolve Executable Path
    # We prefer the standard path because PATH env var might not be updated in the current session after install.
    $pwshPath = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (-not (Test-Path -LiteralPath $pwshPath)) {
        $pwshPath = 'pwsh' # Fallback to system PATH lookup
    }

    # Reconstruct Arguments
    # We rebuild the arguments to pass the exact same parameters to the new process.
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)

    foreach ($param in $PSBoundParameters.GetEnumerator()) {
        if ($param.Value -is [switch]) {
            if ($param.Value) { $argList += "-$($param.Key)" }
        }
        else {
            # Note: This assumes parameters are simple strings/ints.
            # Arrays or objects may need JSON serialization if this script uses complex types.
            $argList += "-$($param.Key)", ([string]$param.Value)
        }
    }

    # Restart
    Write-Log -Level SUCCESS 'Restarting process in PowerShell 7...'
    $process = Start-Process -FilePath $pwshPath -ArgumentList $argList -PassThru -Wait

    exit $process.ExitCode
}

function Update-ProfileLines {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Lines,

        [Parameter(Mandatory)]
        [string]$Source
    )

    # Return early if the global skip flag is set or input is empty
    if ($global:SkipProfile -or -not $Lines) { return }

    # Clean input: Filter out empty strings/whitespace
    $cleanLines = $Lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if (-not $cleanLines) { return }

    # Ensure Profile File and Directory exist
    if (-not (Test-Path -LiteralPath $PROFILE)) {
        $null = New-Item -Path $PROFILE -ItemType File -Force
    }

    # Get existing content (HashSets are faster for lookups, but array is fine here)
    $existingContent = @(Get-Content -LiteralPath $PROFILE -ErrorAction SilentlyContinue)

    # Filter: Only keep lines that are NOT in the existing content
    $linesToAdd = $cleanLines | Where-Object { $_ -notin $existingContent }

    # Batch Append: Write only if there are new lines
    if ($linesToAdd) {
        $linesToAdd | Add-Content -LiteralPath $PROFILE -Encoding UTF8

        # Assuming Write-Log is a custom function available in your session
        Write-Log -Level SUCCESS "Profile updated ($Source): +$($linesToAdd.Count) lines"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Tasks
# ─────────────────────────────────────────────────────────────────────────────

function New-RestorePoint {
    [CmdletBinding()]
    param (
        [string]$Description = "Setup_$(Get-Date -Format 'yyyyMMdd')",
        [string]$Drive = 'C:\'
    )

    Write-Section 'TASK: Restore Point'

    try {
        # Enable System Restore on the target drive
        Enable-ComputerRestore -Drive $Drive -ErrorAction SilentlyContinue

        # Bypass the 24-hour limit
        # This forces the frequency limit to 0 minutes, allowing immediate creation.
        $RegPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        New-ItemProperty -Path $RegPath -Name "SystemRestorePointCreationFrequency" -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

        # Create the checkpoint
        Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS -ErrorAction Stop

        Write-Log -Level SUCCESS "Restore point '$Description' created."
    }
    catch {
        Write-Log -Level WARN "Restore point failed: $($_.Exception.Message)"
    }
}

function Set-WingetSettings {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [object]$Settings
    )

    process {
        $wingetDir = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState"
        $settingsPath = Join-Path -Path $wingetDir -ChildPath 'settings.json'

        # Log action using standard verbose stream (run with -Verbose to see)
        Write-Verbose "TARGET: $settingsPath"

        try {
            # Ensure the directory exists
            if (-not (Test-Path -Path $wingetDir)) {
                $null = New-Item -Path $wingetDir -ItemType Directory -Force -ErrorAction Stop
            }

            # Convert and Write Settings
            if ($PSCmdlet.ShouldProcess($settingsPath, "Write Winget Settings")) {
                $Settings | ConvertTo-Json -Depth 20 | Set-Content -Path $settingsPath -Encoding UTF8 -Force -ErrorAction Stop
                Write-Verbose "SUCCESS: Winget settings updated successfully."
            }
        }
        catch {
            Write-Error "FAILED: Could not write Winget settings. Details: $_"
        }
    }
}

function Install-WingetPackages {
    param(
        [Parameter(Mandatory)]
        [array]$Packages
    )

    # Fast exit if list is empty
    if ($Packages.Count -eq 0) { return }

    Write-Section 'TASK: Winget Packages'

    foreach ($pkg in $Packages) {
        if (-not $pkg.Id) { continue }

        # Prepare Winget Arguments
        $wingetArgs = @(
            'install'
            '--id', $pkg.Id
            '--exact'
            '--silent'
            '--disable-interactivity'
            '--accept-package-agreements'
            '--accept-source-agreements'
        )

        if ($pkg.Args) { $wingetArgs += $pkg.Args }

        # Execute Installation
        Write-Log "Installing: $($pkg.Id)"

        # Capture both StdOut and StdErr
        $output = & winget @wingetArgs 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log -Level SUCCESS "Installed: $($pkg.Id)"
        }
        else {
            Write-Log -Level WARN "Failed: $($pkg.Id) (Exit: $LASTEXITCODE)"
            if ($output) {
                Add-Content -Path $Script:LogFile -Value ($output | Out-String) -Encoding UTF8
            }
        }

        # Update Profile Logic
        if ($pkg.ProfileLines) {
            Update-ProfileLines -Lines $pkg.ProfileLines -Source $pkg.Id
        }

        # Handle Dotfiles
        if ($pkg.Dotfiles -and -not $SkipDotfiles) {
            foreach ($df in @($pkg.Dotfiles)) {
                if (-not $df.Url -or -not $df.Destination) { continue }

                # Expand variables (e.g., converts $env:APPDATA\config.xml -> C:\Users\...\config.xml)
                $destPath = $ExecutionContext.InvokeCommand.ExpandString($df.Destination)
                $destDir = Split-Path -Path $destPath

                # Ensure directory exists (Standard PowerShell approach)
                if (-not (Test-Path -Path $destDir)) {
                    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                }

                Invoke-WebRequest -Uri $df.Url -OutFile $destPath
                Write-Log -Level SUCCESS "Dotfile: $(Split-Path $destPath -Leaf)"
            }
        }
    }
}

function Invoke-Sophia {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Functions,

        [Parameter()]
        [string]$TempDir = $Script:TempDir
    )

    Write-Section 'TASK: Sophia Script'

    # Fetch Latest Release Info
    $githubUri = 'https://api.github.com/repos/farag2/Sophia-Script-for-Windows/releases/latest'
    $headers = @{ 'User-Agent' = 'WinSetupScript' } # Header required to avoid rate-limiting

    try {
        $releaseData = Invoke-RestMethod -Uri $githubUri -Headers $headers -ErrorAction Stop
    }
    catch {
        throw "Failed to fetch Sophia release info: $_"
    }

    # Find the correct asset (Windows 11, Non-LTSC)
    $downloadUrl = $releaseData.assets |
    Where-Object { $_.name -match 'Windows\.11' -and $_.name -notlike '*LTSC*' } |
    Select-Object -First 1 -ExpandProperty browser_download_url

    if (-not $downloadUrl) {
        throw 'Could not locate a compatible Windows 11 Sophia release asset.'
    }

    # Prepare Paths
    $zipPath = Join-Path -Path $TempDir -ChildPath 'Sophia.zip'
    $destPath = Join-Path -Path $TempDir -ChildPath 'Sophia'

    # Download and Extract
    Write-Verbose "Downloading from: $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -ErrorAction Stop

    # Clean previous extraction if exists to ensure fresh run
    if (Test-Path $destPath) { Remove-Item $destPath -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $destPath -Force

    # Unblock downloaded files
    Get-ChildItem -Path $destPath -Recurse | Unblock-File

    # Locate the main script
    $scriptPath = Get-ChildItem -Path $destPath -Filter 'Sophia.ps1' -Recurse |
    Select-Object -First 1 -ExpandProperty FullName

    if (-not $scriptPath) {
        throw 'Sophia.ps1 not found after extraction.'
    }

    # Execute
    Write-Log "Running Sophia: $scriptPath"

    # Define arguments for the external process
    $pwshArgs = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $scriptPath,
        '-Functions', ($Functions -join ',')
    )

    # Capture output and redirect stderr to stdout (2>&1)
    $output = & pwsh $pwshArgs 2>&1

    # Handle Result
    if ($LASTEXITCODE -ne 0) {
        Write-Log -Level WARN "Sophia exited with code $LASTEXITCODE"
        if ($output) {
            $output | Out-String | Add-Content -Path $Script:LogFile -Encoding UTF8
        }
    }
    else {
        Write-Log -Level SUCCESS 'Sophia completed.'
    }
}

function Install-NerdFonts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Fonts
    )

    Write-Section 'TASK: Nerd Fonts'

    # Ensure Module Exists
    if (-not (Get-Module -ListAvailable -Name NerdFonts)) {
        try {
            # Check for NuGet provider specifically to avoid prompts
            if (-not (Get-PackageProvider -ListAvailable -Name NuGet)) {
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            }
            Install-Module -Name NerdFonts -Scope CurrentUser -Force -ErrorAction Stop
            Write-Log -Level SUCCESS 'Installed module: NerdFonts'
        }
        catch {
            Write-Log -Level ERROR "Failed to install NerdFonts module: $($_.Exception.Message)"
            return # Stop execution if the module is missing
        }
    }

    # Install Fonts
    foreach ($Name in $Fonts) {
        if ([string]::IsNullOrWhiteSpace($Name)) { continue }

        try {
            # Note: You might want to add a check here if the font is already installed
            # to speed up subsequent runs, e.g., if (-not (Test-Path ...))
            Install-NerdFont -Name $Name -Scope CurrentUser -ErrorAction Stop
            Write-Log -Level SUCCESS "Font installed: $Name"
        }
        catch {
            Write-Log -Level ERROR "Font failed: $Name ($($_.Exception.Message))"
        }
    }
}

function Install-PSModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject[]]$Modules
    )

    if ($Modules.Count -eq 0) { return }
    Write-Section 'TASK: PowerShell Modules'

    foreach ($Module in $Modules) {
        # Skip invalid entries
        if ([string]::IsNullOrWhiteSpace($Module.Name)) { continue }

        # Check if module exists
        if (-not (Get-Module -ListAvailable -Name $Module.Name)) {
            try {
                Install-Module -Name $Module.Name -Scope CurrentUser -Force -ErrorAction Stop
                Write-Log -Level SUCCESS "Installed module: $($Module.Name)"
            }
            catch {
                Write-Log -Level ERROR "Failed to install module '$($Module.Name)': $_"
                continue # Skip profile update if install failed
            }
        }

        # Update profile lines (Runs whether installed newly or previously)
        if ($Module.ProfileLines) {
            Update-ProfileLines -Lines $Module.ProfileLines -Source $Module.Name
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

try {
    Initialize-RunContext
    Restart-InPowerShell7IfNeeded

    Write-Section 'WINDOWS 11 SETUP'
    $Config = Import-PowerShellDataFile -Path $ConfigPath

    if (-not $SkipRestore) { New-RestorePoint }
    if (-not $SkipSophia) { Invoke-Sophia -Funcs $Config.SophiaFunctions }

    if (-not $SkipWinget) {
        Set-WingetSettings    -Settings $Config.WingetSettings
        Install-WingetPackages -Packages $Config.WingetPackages
    }

    if (-not $SkipFonts) { Install-NerdFonts -Fonts $Config.NerdFonts }
    if (-not $SkipModules) { Install-PSModules -Modules $Config.PSModules }

    # Make newly-installed CLIs available in this session without reopening the shell.
    Update-Path

    Write-Log -Level SUCCESS 'Execution complete.'
}
catch {
    Write-Log -Level ERROR "Critical failure: $($_.Exception.Message)"
    throw
}
finally {
    if (-not $KeepTemp -and $Script:TempDir) {
        Remove-Item -Path $Script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
