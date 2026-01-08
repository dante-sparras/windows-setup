# Microsoft.PowerShell_profile.ps1
#Requires -Version 5.1

using namespace System.Collections.Generic

#region Configuration

$script:Config = @{
    NpmProvider   = 'Oven-sh.Bun'
    Tools         = [ordered]@{
        'Oven-sh.Bun'              = @{
            Type    = 'winget'
            Command = 'bun'
        }
        'Git.Git'                  = @{
            Type    = 'winget'
            Command = 'git'
        }
        'GitHub.cli'               = @{
            Type     = 'winget'
            Command  = 'gh'
            Requires = @('Git.Git')
        }
        'JanDeDobbeleer.OhMyPosh'  = @{
            Type    = 'winget'
            Command = 'oh-my-posh'
            Init    = { oh-my-posh init pwsh | Invoke-Expression }
        }
        'ajeetdsouza.zoxide'       = @{
            Type    = 'winget'
            Command = 'zoxide'
            Init    = { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
        }
        'Terminal-Icons'           = @{
            Type = 'module'
            Init = { Import-Module Terminal-Icons }
        }
        '@microsoft/inshellisense' = @{
            Type    = 'npm'
            Command = 'is'
            Init    = { if (-not $env:INSHELLISENSE_SESSION) { is -s pwsh } }
        }
    }
    WinUtilConfig = @{
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
}

$script:MissingTools = [List[string]]::new()
$script:ToolCache = @{} # Cache installation status during init

#endregion

#region Private Helpers

function Get-ToolConfig([string]$Name) {
    $script:Config.Tools[$Name]
}

function Get-NpmCommand {
    (Get-ToolConfig $script:Config.NpmProvider)?.Command ?? 'npm'
}

function Get-ToolRequirements([string]$Name) {
    $tool = Get-ToolConfig $Name
    if (-not $tool) { return @() }

    $reqs = [List[string]]::new()

    if ($tool.Type -eq 'npm' -and $Name -ne $script:Config.NpmProvider) {
        $reqs.Add($script:Config.NpmProvider)
    }

    if ($tool.Requires) {
        $reqs.AddRange([string[]]$tool.Requires)
    }

    return $reqs
}

function Test-ToolInstalled {
    param(
        [string]$Name,
        [switch]$NoCache
    )

    if (-not $NoCache -and $script:ToolCache.ContainsKey($Name)) {
        return $script:ToolCache[$Name]
    }

    $tool = Get-ToolConfig $Name
    if (-not $tool) { return $false }

    $result = if ($tool.Command) {
        [bool](Get-Command $tool.Command -ErrorAction Ignore)
    }
    elseif ($tool.Type -eq 'module') {
        [bool](Get-Module -ListAvailable $Name)
    }
    elseif ($tool.Type -eq 'npm') {
        # @scope/package -> package
        [bool](Get-Command ($Name -split '/')[-1] -ErrorAction Ignore)
    }
    else {
        $false
    }

    $script:ToolCache[$Name] = $result
    return $result
}

function Clear-ToolCache {
    $script:ToolCache.Clear()
}

function Resolve-ToolDependencies {
    param(
        [string[]]$Tools,
        [switch]$IncludeInstalled
    )

    $resolved = [List[string]]::new()
    $visiting = [HashSet[string]]::new()

    $resolveRecursive = {
        param([string]$Name)

        $tool = Get-ToolConfig $Name
        if (-not $tool -or $resolved.Contains($Name)) { return }

        if (-not $visiting.Add($Name)) {
            throw "Circular dependency detected: $Name"
        }

        foreach ($dep in (Get-ToolRequirements $Name)) {
            if ($IncludeInstalled -or -not (Test-ToolInstalled $dep)) {
                & $resolveRecursive $dep
            }
        }

        $null = $visiting.Remove($Name)
        $resolved.Add($Name)
    }

    foreach ($name in $Tools) {
        & $resolveRecursive $name
    }

    return $resolved
}

function Update-EnvironmentPath {
    $env:Path = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
    ) -join ';'
}

function Get-ToolInstaller([string]$Name) {
    $tool = Get-ToolConfig $Name
    if (-not $tool) { return $null }
    if ($tool.Install) { return $tool.Install }

    # Capture $Name for closure
    $n = $Name

    switch ($tool.Type) {
        'winget' {
            { winget install $n -e --accept-package-agreements --accept-source-agreements --silent }.GetNewClosure()
        }
        'module' {
            { Install-Module $n -Scope CurrentUser -Force -SkipPublisherCheck }.GetNewClosure()
        }
        'npm' {
            $cmd = Get-NpmCommand
            { & $cmd install -g $n }.GetNewClosure()
        }
    }
}

function Get-ToolUpdater([string]$Name) {
    $tool = Get-ToolConfig $Name
    if (-not $tool) { return $null }
    if ($tool.Update) { return $tool.Update }

    $n = $Name

    switch ($tool.Type) {
        'winget' {
            { winget upgrade $n --accept-package-agreements --accept-source-agreements }.GetNewClosure()
        }
        'module' {
            { Update-Module $n -Force -ErrorAction SilentlyContinue }.GetNewClosure()
        }
        'npm' {
            $cmd = Get-NpmCommand
            { & $cmd update -g $n }.GetNewClosure()
        }
    }
}

function Get-ToolUninstaller([string]$Name) {
    $tool = Get-ToolConfig $Name
    if (-not $tool) { return $null }
    if ($tool.Uninstall) { return $tool.Uninstall }

    $n = $Name

    switch ($tool.Type) {
        'winget' {
            { winget uninstall $n --silent }.GetNewClosure()
        }
        'module' {
            { Uninstall-Module $n -Force -AllVersions -ErrorAction SilentlyContinue }.GetNewClosure()
        }
        'npm' {
            $cmd = Get-NpmCommand
            { & $cmd uninstall -g $n }.GetNewClosure()
        }
    }
}

function Initialize-Tools {
    foreach ($name in $script:Config.Tools.Keys) {
        $tool = Get-ToolConfig $name

        if (-not (Test-ToolInstalled $name)) {
            $script:MissingTools.Add($name)
            continue
        }

        if ($tool.Init) {
            try {
                & $tool.Init
            }
            catch {
                Write-Warning "Failed to initialize ${name}: $_"
            }
        }

        # Register aliases and functions
        if ($tool.Aliases) {
            $tool.Aliases.GetEnumerator() | ForEach-Object {
                Set-Alias -Name $_.Key -Value $_.Value -Scope Global -Force
            }
        }
        if ($tool.Functions) {
            $tool.Functions.GetEnumerator() | ForEach-Object {
                Set-Item "function:global:$($_.Key)" -Value $_.Value -Force
            }
        }
    }
}

function Initialize-PSReadLine {
    $psrl = Get-Module PSReadLine
    if (-not $psrl) { return }

    $opts = @{
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        PredictionViewStyle           = 'ListView'
        BellStyle                     = 'None'
    }

    if ($psrl.Version -ge [version]'2.2.0') {
        $opts.PredictionSource = 'HistoryAndPlugin'
    }

    Set-PSReadLineOption @opts
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
}

#endregion

#region User Functions

function ~ { Set-Location $HOME }
function dev { Set-Location "$HOME\Dev" }
function reload {
    Clear-ToolCache
    $script:MissingTools.Clear()
    . $PROFILE
}

function mkcd([Parameter(Mandatory)][string]$Path) {
    New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
    Set-Location $Path
}

function touch([Parameter(Mandatory)][string[]]$Path) {
    foreach ($p in $Path) {
        if (Test-Path $p) {
            (Get-Item $p).LastWriteTime = Get-Date
        }
        else {
            New-Item -ItemType File -Path $p -Force | Out-Null
        }
    }
}

function path {
    $seen = [HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $env:Path -split ';' | Where-Object { $_ -and $seen.Add($_) }
}

#endregion

#region Tool Management Commands

function Initialize-WinUtil {
    $config = $script:Config.WinUtilConfig
    $configJson = $config | ConvertTo-Json -Depth 5
    $tempFile = [System.IO.Path]::GetTempFileName()

    Set-Content -Path $tempFile -Value $configJson -Encoding UTF8

    try {
        Invoke-Expression "& { $(Invoke-RestMethod https://christitus.com/win) } -Config `"$tempFile`" -Run"
    }
    catch {
        Write-Error "Failed to initialize WinUtil: $_"
    }
    finally {
        Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
    }
}

function Show-MissingTools {
    <#
    .SYNOPSIS
        Shows tools that are configured but not installed.
    #>
    if ($script:MissingTools.Count -eq 0) {
        Write-Host 'All tools are installed!' -ForegroundColor Green
        return
    }

    Write-Host "`nMissing Tools:" -ForegroundColor Yellow
    foreach ($name in $script:MissingTools) {
        $reqs = Get-ToolRequirements $name
        $status = ''
        if ($reqs) {
            $missing = @($reqs | Where-Object { -not (Test-ToolInstalled $_) })
            $status = if ($missing) { " (needs: $($missing -join ', '))" } else { ' (ready)' }
        }
        Write-Host "  • $name$status" -ForegroundColor DarkGray
    }
    Write-Host ''
}

function Install-MissingTools {
    <#
    .SYNOPSIS
        Installs missing tools with dependency resolution.
    .PARAMETER Name
        Specific tool(s) to install. If omitted, installs all missing tools.
    .PARAMETER Force
        Skip confirmation prompt.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ArgumentCompleter({
                param($cmd, $param, $word)
                $script:MissingTools | Where-Object { $_ -like "$word*" }
            })]
        [string[]]$Name,
        [switch]$Force
    )

    $allTools = @($script:Config.Tools.Keys)
    $requested = if ($Name) {
        $invalid = @($Name | Where-Object { $_ -notin $allTools })
        if ($invalid) { Write-Warning "Unknown: $($invalid -join ', ')" }
        @($Name | Where-Object { $_ -in $allTools })
    }
    else {
        @($script:MissingTools)
    }

    if (-not $requested) {
        Write-Host 'Nothing to install!' -ForegroundColor Green
        return
    }

    try {
        $installOrder = Resolve-ToolDependencies -Tools $requested
    }
    catch {
        Write-Error "Dependency resolution failed: $_"
        return
    }

    Clear-ToolCache
    $toInstall = @($installOrder | Where-Object { -not (Test-ToolInstalled $_ -NoCache) })

    if (-not $toInstall) {
        Write-Host 'All requested tools are already installed!' -ForegroundColor Green
        return
    }

    Write-Host "`nInstall plan:" -ForegroundColor Cyan
    $toInstall | ForEach-Object -Begin { $i = 0 } -Process {
        $note = if ($_ -notin $requested) { ' (dependency)' } else { '' }
        Write-Host "  $((++$i)). $_$note" -ForegroundColor DarkGray
    }
    Write-Host ''

    if (-not $Force -and -not $WhatIfPreference) {
        $confirm = Read-Host "Install $($toInstall.Count) tool(s)? [y/N]"
        if ($confirm -notmatch '^y(es)?$') {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
    }

    $results = @{ Success = [List[string]]::new(); Failed = [List[string]]::new() }

    for ($i = 0; $i -lt $toInstall.Count; $i++) {
        $toolName = $toInstall[$i]
        $installer = Get-ToolInstaller $toolName

        if (-not $installer) {
            Write-Warning "No installer for $toolName"
            $results.Failed.Add($toolName)
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($toolName, 'Install')) { continue }

        Write-Host "[$($i + 1)/$($toInstall.Count)] Installing $toolName..." -ForegroundColor Cyan
        try {
            & $installer
            Update-EnvironmentPath
            Clear-ToolCache

            if (Test-ToolInstalled $toolName -NoCache) {
                $results.Success.Add($toolName)
                Write-Host '  ✓ Installed' -ForegroundColor Green
            }
            else {
                $results.Failed.Add($toolName)
                Write-Host '  ✗ Not found after install' -ForegroundColor Red
            }
        }
        catch {
            $results.Failed.Add($toolName)
            Write-Host "  ✗ $_" -ForegroundColor Red
        }
    }

    Show-OperationSummary $results
    Write-Host "`nRun 'reload' to apply changes." -ForegroundColor Yellow
}

function Update-Tools {
    <#
    .SYNOPSIS
        Updates installed tools.
    .PARAMETER Name
        Specific tool(s) to update. If omitted, updates all installed tools.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ArgumentCompleter({
                param($cmd, $param, $word)
                $script:Config.Tools.Keys | Where-Object { $_ -like "$word*" }
            })]
        [string[]]$Name
    )

    $targets = if ($Name) {
        $invalid = @($Name | Where-Object { $_ -notin $script:Config.Tools.Keys })
        if ($invalid) { Write-Warning "Unknown: $($invalid -join ', ')" }
        @($Name | Where-Object { $_ -in $script:Config.Tools.Keys })
    }
    else {
        @($script:Config.Tools.Keys)
    }

    if (-not $targets) {
        Write-Host 'No tools to update!' -ForegroundColor Yellow
        return
    }

    $results = @{
        Success = [List[string]]::new()
        Skipped = [List[string]]::new()
        Failed  = [List[string]]::new()
    }

    foreach ($toolName in $targets) {
        if (-not (Test-ToolInstalled $toolName -NoCache)) {
            $results.Skipped.Add($toolName)
            continue
        }

        $updater = Get-ToolUpdater $toolName
        if (-not $updater) {
            $results.Skipped.Add($toolName)
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($toolName, 'Update')) { continue }

        Write-Host "Updating $toolName..." -ForegroundColor Cyan
        try {
            & $updater
            $results.Success.Add($toolName)
            Write-Host '  ✓ Updated' -ForegroundColor Green
        }
        catch {
            $results.Failed.Add($toolName)
            Write-Host "  ✗ $_" -ForegroundColor Red
        }
    }

    Show-OperationSummary $results
}

function Uninstall-Tools {
    <#
    .SYNOPSIS
        Uninstalls tools.
    .PARAMETER Name
        Tool(s) to uninstall.
    .PARAMETER Force
        Skip confirmation prompt.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({
                param($cmd, $param, $word)
                $script:Config.Tools.Keys | Where-Object {
                    $_ -like "$word*" -and (Test-ToolInstalled $_ -NoCache)
                }
            })]
        [string[]]$Name,
        [switch]$Force
    )

    $valid = @($Name | Where-Object { $_ -in $script:Config.Tools.Keys })
    $invalid = @($Name | Where-Object { $_ -notin $script:Config.Tools.Keys })
    if ($invalid) { Write-Warning "Unknown: $($invalid -join ', ')" }

    Clear-ToolCache
    $toUninstall = @($valid | Where-Object { Test-ToolInstalled $_ -NoCache })

    if (-not $toUninstall) {
        Write-Host 'Nothing to uninstall!' -ForegroundColor Yellow
        return
    }

    # Warn about dependents
    foreach ($tool in $toUninstall) {
        $dependents = @($script:Config.Tools.Keys | Where-Object {
                $_ -ne $tool -and (Get-ToolRequirements $_) -contains $tool -and
                (Test-ToolInstalled $_ -NoCache)
            })
        if ($dependents) {
            Write-Warning "$tool is required by: $($dependents -join ', ')"
        }
    }

    if (-not $Force -and -not $WhatIfPreference) {
        $confirm = Read-Host "Uninstall $($toUninstall -join ', ')? [y/N]"
        if ($confirm -notmatch '^y(es)?$') {
            Write-Host 'Cancelled.' -ForegroundColor Yellow
            return
        }
    }

    $results = @{ Success = [List[string]]::new(); Failed = [List[string]]::new() }

    foreach ($toolName in $toUninstall) {
        $uninstaller = Get-ToolUninstaller $toolName
        if (-not $uninstaller) {
            Write-Warning "No uninstaller for $toolName"
            $results.Failed.Add($toolName)
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($toolName, 'Uninstall')) { continue }

        Write-Host "Uninstalling $toolName..." -ForegroundColor Cyan
        try {
            & $uninstaller
            $results.Success.Add($toolName)
            Write-Host '  ✓ Uninstalled' -ForegroundColor Green
        }
        catch {
            $results.Failed.Add($toolName)
            Write-Host "  ✗ $_" -ForegroundColor Red
        }
    }

    Show-OperationSummary $results
    Write-Host "`nRun 'reload' to refresh status." -ForegroundColor Yellow
}

function Get-ToolStatus {
    <#
    .SYNOPSIS
        Shows status of all configured tools.
    #>
    $script:Config.Tools.Keys | ForEach-Object {
        $tool = Get-ToolConfig $_
        $reqs = Get-ToolRequirements $_
        [PSCustomObject]@{
            Name         = $_
            Type         = $tool.Type
            Installed    = Test-ToolInstalled $_ -NoCache
            Command      = $tool.Command ?? '-'
            Dependencies = ($reqs -join ', ') ?? '-'
        }
    } | Format-Table -AutoSize
}

function Show-OperationSummary([hashtable]$Results) {
    Write-Host "`n────────────────────────────────" -ForegroundColor DarkGray
    if ($Results.Success.Count) {
        Write-Host '✓ Success: ' -ForegroundColor Green -NoNewline
        Write-Host ($Results.Success -join ', ')
    }
    if ($Results.Skipped.Count) {
        Write-Host '○ Skipped: ' -ForegroundColor DarkGray -NoNewline
        Write-Host ($Results.Skipped -join ', ')
    }
    if ($Results.Failed.Count) {
        Write-Host '✗ Failed: ' -ForegroundColor Red -NoNewline
        Write-Host ($Results.Failed -join ', ')
    }
}

#endregion

#region Startup

$script:ProfileLoadTime = Measure-Command {
    Initialize-Tools
    Initialize-PSReadLine
}

if ($script:MissingTools.Count -gt 0) {
    Write-Host "Missing: $($script:MissingTools -join ', ')" -ForegroundColor DarkYellow
    Write-Host "Run 'Install-MissingTools' to install" -ForegroundColor DarkGray
}

if ($script:ProfileLoadTime.TotalMilliseconds -gt 500) {
    Write-Host "Profile loaded in $([int]$script:ProfileLoadTime.TotalMilliseconds)ms" -ForegroundColor DarkGray
}

#endregion
