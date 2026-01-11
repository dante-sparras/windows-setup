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

# This File will run via a one-liner command to powerShell


# Download repository and run setup script
