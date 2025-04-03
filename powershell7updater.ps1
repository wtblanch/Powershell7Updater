# Check for admin and re-launch if needed
function Ensure-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host "Not running as administrator. Attempting to relaunch with elevation..."
        
        $scriptPath = $MyInvocation.MyCommand.Definition

        # Ensure the path is absolute
        if (-not (Test-Path $scriptPath)) {
            Write-Error "Cannot determine script path for elevation."
            exit 1
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
        $psi.Verb = "runas"
        $psi.UseShellExecute = $true

        try {
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        } catch {
            Write-Error "User canceled the UAC prompt or elevation failed: $_"
        }

        exit 0
    }
}

function Get-LatestPowerShellDownloadUrl {
    try {
        $releasesApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $response = Invoke-RestMethod -Uri $releasesApiUrl -UseBasicParsing
        $asset = $response.assets | Where-Object {
            $_.name -like "PowerShell-*-win-x64.msi"
        } | Select-Object -First 1
        return $asset.browser_download_url
    } catch {
        Write-Error "Failed to get latest PowerShell release: $_"
        exit 1
    }
}

function Get-InstalledPowerShell7Version {
    $pwshPath = "${env:ProgramFiles}\PowerShell\7\pwsh.exe"
    if (Test-Path $pwshPath) {
        try {
            return & $pwshPath -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
        } catch {
            return $null
        }
    }
    return $null
}

function Install-PowerShell7 {
    param ([string]$InstallerUrl)

    $tempInstaller = "$env:TEMP\PowerShell7Setup.msi"
    Write-Host "Downloading PowerShell installer..."
    
    try {
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $tempInstaller -UseBasicParsing
    } catch {
        Write-Error "Failed to download installer: $_"
        exit 1
    }

    Write-Host "Running installer silently..."
    $exitCode = Start-Process msiexec.exe -Wait -PassThru -ArgumentList "/i `"$tempInstaller`" /quiet /norestart" | Select-Object -ExpandProperty ExitCode

    if ($exitCode -eq 0) {
        Write-Host "PowerShell 7 installed successfully."
    } else {
        Write-Error "Installer exited with code $exitCode"
    }

    Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue
}

# === MAIN ===
Ensure-Admin

$latestUrl = Get-LatestPowerShellDownloadUrl
$latestVersion = ($latestUrl -split '-|\.msi')[1]
$currentVersion = Get-InstalledPowerShell7Version

Write-Host "Current PowerShell 7 version: $currentVersion"
Write-Host "Latest available version: $latestVersion"

if ($currentVersion -ne $latestVersion) {
    Install-PowerShell7 -InstallerUrl $latestUrl
} else {
    Write-Host "PowerShell 7 is already up-to-date."
}
