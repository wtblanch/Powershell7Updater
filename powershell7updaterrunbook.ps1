param()

function Get-LatestPowerShellDownloadUrl {
    try {
        $releasesApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $response = Invoke-RestMethod -Uri $releasesApiUrl -UseBasicParsing
        $asset = $response.assets | Where-Object {
            $_.name -like "PowerShell-*-win-x64.msi"
        } | Select-Object -First 1
        return $asset.browser_download_url
    } catch {
        Write-Error "Failed to retrieve latest PowerShell release: $_"
        throw
    }
}

function Get-InstalledPowerShell7Version {
    $pwshPath = "${env:ProgramFiles}\PowerShell\7\pwsh.exe"
    if (Test-Path $pwshPath) {
        try {
            return & $pwshPath -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        } catch {
            Write-Warning "PowerShell 7 executable exists but failed to run: $_"
            return $null
        }
    }
    return $null
}

function Install-PowerShell7 {
    param ([string]$InstallerUrl)

    $tempInstaller = "$env:TEMP\PowerShell7Setup.msi"
    Write-Output "Downloading PowerShell installer from $InstallerUrl..."

    try {
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $tempInstaller -UseBasicParsing
    } catch {
        Write-Error "Download failed: $_"
        throw
    }

    Write-Output "Running PowerShell 7 installer silently..."
    $proc = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/i `"$tempInstaller`" /quiet /norestart"

    if ($proc.ExitCode -eq 0) {
        Write-Output "Installation completed successfully."
    } else {
        Write-Error "Installer exited with code $($proc.ExitCode)"
    }

    Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
}

# === MAIN ===
Write-Output "PowerShell 7 updater runbook started on: $(Get-Date -Format u)"
$currentVersion = Get-InstalledPowerShell7Version
Write-Output "Current PowerShell 7 version: $currentVersion"

$latestUrl = Get-LatestPowerShellDownloadUrl
$latestVersion = ($latestUrl -split '-|\.msi')[1]
Write-Output "Latest PowerShell 7 version available: $latestVersion"

if ($currentVersion -ne $latestVersion) {
    Write-Output "Updating PowerShell 7 to version $latestVersion..."
    Install-PowerShell7 -InstallerUrl $latestUrl
} else {
    Write-Output "PowerShell 7 is already up-to-date."
}

Write-Output "Runbook completed at: $(Get-Date -Format u)"
