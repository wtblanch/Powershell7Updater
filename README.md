# PowerShell 7 Updater Runbook

This repository contains an Azure Automation Runbook and a standalone PowerShell script for ensuring PowerShell 7 is installed and up-to-date on Windows systems.

## Files

### 🔧 powershell7updater.ps1

This script:

- Checks the installed version of PowerShell 7.
- Retrieves the latest release from GitHub.
- Installs or updates PowerShell 7 silently if needed.

You can run this locally or in a scheduled task.

### ☁️ powershell7updaterrunbook.ps1

This script is designed to be used as an **Azure Automation Runbook**.
It:

- Logs output to **Log Analytics** (if configured).
- Supports deployment via Bicep or ARM templates.
- Can be scheduled to run weekly.

> You can use the raw URL of `powershell7updaterrunbook.ps1` in your Bicep template to publish it automatically.

## Example

You can deploy the runbook using a Bicep file like:

```bicep
publishContentLink: {
  uri: 'https://raw.githubusercontent.com/wtblanch/Powershell7Updater/main/powershellupdaterrunbook.ps1'
}
