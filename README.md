# Windows 11 Setup Script

A powerful, data-driven bootstrapping script for setting up a fresh Windows 11 installation. This script handles everything from creating a System Restore point to installing software via Winget, applying system tweaks (Sophia), and configuring your PowerShell environment.

## Features

- **Automated**: Fully automated setup process.
- **Bootstrapping**: Auto-elevates to Administrator and ensures PowerShell 7 is installed.
- **Configurable**: All behavior is driven by `config.psd1`.
- **Winget Integration**: Installs packages defined in your config.
- **Sophia Script**: Integrates the Sophia Script for Windows 11 tweaks.
- **Nerd Fonts**: Installs specified Nerd Fonts.
- **Dotfiles**: Downloads and places configuration files from URLs.

## Usage

### Basic Run
Run the script from an Administrator PowerShell prompt (it will elevate if not).

```powershell
.\script.ps1
```

### Web Install (One-Liner)
You can run this script directly from memory without downloading it first (requires hosting the script/config or using the repo raw links).

```powershell
iex (irm https://raw.githubusercontent.com/dante-sparras/windows-setup/main/script.ps1)
```

### Specifying Configuration
By default, the script looks for `config.psd1` in the same directory. You can specify a custom path:

```powershell
.\script.ps1 -ConfigPath "C:\MyConfigs\dev-gaming.psd1"
```

## Configuration (`config.psd1`)

The configuration file is a standard PowerShell Data File. You can enable/disable major features in the `Settings` block.

```powershell
@{
    Settings = @{
        EnableRestorePoint = $true
        EnableSophia       = $true
        EnableWinget       = $true
        EnableDotfiles     = $true
        EnableFonts        = $true
        EnableModule       = $true
        EnableProfile      = $false
    }

    WingetPackages = @(
        @{ Id = "Google.Chrome" }
        @{ Id = "Microsoft.VisualStudioCode" }
    )

    # ... more settings
}
```

## Flags

Command-line flags override the configuration settings. This is useful for one-off runs where you want to skip a specific step enabled in your config.

| Flag | Description |
| :--- | :--- |
| `-SkipRestore` | Skip creating a System Restore Point. |
| `-SkipSophia` | Skip running the Sophia Script. |
| `-SkipWinget` | Skip Winget package installation. |
| `-SkipDotfiles` | Skip downloading dotfiles. |
| `-SkipFonts` | Skip font installation. |
| `-SkipModules` | Skip PowerShell module installation. |
| `-SkipProfile` | Skip profile modifications (implicit if EnableProfile is false). |
| `-KeepTemp` | Keep the temporary directory (`%TEMP%\WinSetup_...`) after execution. |

## License
MIT
