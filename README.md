# Windows Setup

## How to Run

1. Open PowerShell as Administrator.
2. Run the following command to execute the setup script:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force; `
   iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/dante-sparras/windows-setup/main/setup.ps1'))
   ```
