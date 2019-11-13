Write-Host "Loading personal profile...`n"

# These booleans force a few things on every launch of PowerShell on a system
$blockVersionLaunched = $false 
$alwaysRunAsAdmin = $false

$ErrorActionPreference = "Stop"

# Load variable for scripts
$scriptPathError = $false
if (!(Test-Path "C:\temp\secrets\scriptpath.sec")) {
  Write-Warning "Secret file not found"
  $scriptPathError = $true
} else {
  $scriptPath = Get-Content "C:\temp\secrets\scriptpath.sec"
}

# Reloads the PowerShell Profile in same window
function Restart-Profile {
  Write-Host "A profile reload was called.`n"
  & $profile
}

function Test-Administrator  
{  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

# Keep updated copy of PowerShell profile from Github local repository
function Get-UpdatedProfile {
  if (-not $scriptPathError) {
    if ($PSVersionTable.PSVersion.Major -ge 6) {
      # Place a symbolic link to the location of the PowerShell profile < PowerShell Core
      # Check if it exists first, as it should persist
      try {
        $dirTest = Get-Item "$Env:USERPROFILE\Documents\PowerShell"
        if (-not [bool]($dirTest.Attributes -band [IO.FileAttributes]::ReparsePoint)){
          New-Item -ItemType SymbolicLink -Path (Join-Path -Path $Env:USERPROFILE -ChildPath Documents) -Name PowerShell -Target (Join-Path -Path $Env:USERPROFILE -ChildPath Documents\WindowsPowerShell)
        }
      }
      catch { Write-Warning "Error with symbolic link for profile path. $Error[0]" }
    }

    $profileRepository = "$scriptPath\Microsoft.PowerShell_profile"
    $profileDirectory = "$env:USERPROFILE\Documents\WindowsPowerShell\"
    
    if (((Get-ChildItem "$profileDirectory\Microsoft.PowerShell_profile.ps1").LastWriteTime) -lt ((Get-ChildItem "$profileRepository\Microsoft.PowerShell_profile.ps1").LastWriteTime)) {
      try { 
        Copy-Item "$profileRepository\Microsoft.PowerShell_profile.ps1" -Destination $profileDirectory -Force 
        Restart-Profile
        Exit
      }
      catch { Write-Warning "Error copying updated profile from local repository. $Error[0]" }
    }

    if (((Get-ChildItem "$profileDirectory\Microsoft.PowerShell_profile.ps1").LastWriteTime) -gt ((Get-ChildItem "$profileRepository\Microsoft.PowerShell_profile.ps1").LastWriteTime)) {
      try { 
        Copy-Item "$profileDirectory\Microsoft.PowerShell_profile.ps1" -Destination $profileRepository -Force 
        Restart-Profile
        Exit
      }
      catch { Write-Warning "Error copying updated profile to local repository. $Error[0]" }
    }
  }
}

function RunAsAdmin {
  $isAdmin = Test-Administrator
  if (-not $isAdmin) { 
    if ($PSVersionTable.PSVersion.Major -lt 6) {
      Start-Process "$PSHOME\powershell.exe" -Verb runAs
    } else {
      Start-Process "$PSHOME\pwsh.exe" -Verb runAs
    }
    Stop-Process $pid
  } else {
    Write-Warning "Already elevated."
  }
}

# Make sure we're using the latest copy of this file.
Get-UpdatedProfile

# Test for running as Administrator and relaunch
if ($alwaysRunAsAdmin)
{
  $isAdmin = Test-Administrator
  if (-not $isAdmin) { 
    Start-Process "$PSHOME\powershell.exe" -Verb runAs
    Stop-Process $pid
  }
}

# If PowerShell version 6 was not launched, check to see if it's installed and relaunch prompt.
if ($blockVersionLaunched) {
  if ($PSVersionTable.PSVersion.Major -lt 6) {
    $Version = "6.0.0"
    $InstallFolder = "$env:ProgramFiles\PowerShell\$Version"
    If (Test-Path "$InstallFolder\pwsh.exe")
    {
      Invoke-Item "$InstallFolder\pwsh.exe"
      Stop-Process $pid
    }
  }
}

if (!(Get-Module -Name PSReadline)) { Import-Module -Name PSReadLine }

# Stop Windows 10 Connected User Experience and Telemetry
if ($isAdmin) {
  if ((Get-Service diagtrack | Select-Object StartType).StartType  -eq "Automatic") { Write-Host "Stopping telemetry..."; Get-Service DiagTrack | Set-Service -StartupType Disabled }
  if ((Get-Service diagtrack | Select-Object Status).Status -ne "Stopped") { Stop-Service diagtrack }
}

# Increase history
$MaximumHistoryCount = 10000

# Shortcut to screen lock
function Lock 
{
    $signature = @"  
    [DllImport("user32.dll", SetLastError = true)]  
    public static extern bool LockWorkStation();  
"@  
    $LockWorkStation = Add-Type -memberDefinition $signature -name "Win32LockWorkStation" -namespace Win32Functions -passthru  
    $LockWorkStation::LockWorkStation()|Out-Null
}

# Just an extra line from top of console after cls
function Add-HostSpace {
    Clear-Host
    Write-Host
}
Set-Alias cls 'Add-HostSpace' -option AllScope -Force

# Temporarily add to Path to get access to subl.exe
# http://docs.sublimetext.info/en/latest/command_line/command_line.html
$env:Path += ";C:\Program Files\Sublime Text 3"

$env:Path += ";C:\Program Files (x86)\PuTTY"
Set-Alias ssh plink.exe

# Temporarily add to Path to get access to Caret.exe
$env:Path += ";$env:LOCALAPPDATA\Caret"

# Shortcut for opening files, like on macOS
Set-Alias open Invoke-Item

# Shortcut for creating files, like on Linux
Set-Alias touch New-Item

# Show date and time
Get-Date; Write-Host

# Shortcut for opening Everything
Set-Alias everything "C:\Program Files\Everything\Everything.exe"

function Get-Weather {
  param ([Parameter(Mandatory=$False)][switch]$Clear)
  if ($Clear) { Clear-Host }
  Push-Location $scriptPath
  . .\Get-Weather\Get-Weather.ps1
  Get-Weather
  Pop-Location
  if ($Clear) { Write-Host }
}

Add-HostSpace

# Change console colors
if (Test-Path "C:\temp\ColorTool\ColorTool.exe") {
  Set-Location 'C:\temp\ColorTool'
  .\ColorTool.exe --quiet Nord.itermcolors
}

# Show the date
Get-Date

# Show the weather forecast
Get-Weather

Write-Host "---"

try { $awscli = aws --version } catch {}
if ($awscli) { Write-Host "AWS CLI: $($awscli)" }

try { $python = python --version } catch {}
if ($python) { Write-Host "Python: $($python)" }

try { $powershell = ($PSVersionTable | Select-Object PSVersion).PSVersion.ToString() } catch {}
if ($powershell) {Write-Host "Powershell: $($powershell)`n" }

# Move to working directory
Set-Location ~

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
