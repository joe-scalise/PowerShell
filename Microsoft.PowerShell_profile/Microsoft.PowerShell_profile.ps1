# Switch this variable to false if you want to launch an older version than 6.
$blockVersionLaunched = $true
$alwaysRunAsAdmin = $true

$ErrorActionPreference = "Stop"

# Load variable for scripts
$scriptPathError = $false
if (!(Test-Path "C:\temp\secrets\scriptspath.txt")) {
  Write-Warning "Secret not found"
  $scriptPathError = $true
} else {
  $scriptPath = Get-Content "C:\temp\secrets\scriptspath.txt"
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
      New-Item -ItemType SymbolicLink -Path (Join-Path -Path $Env:USERPROFILE -ChildPath Documents) -Name PowerShell -Target (Join-Path -Path $Env:USERPROFILE -ChildPath Documents\WindowsPowerShell)
    }

    $profileRepository = "$scriptPath\Microsoft.PowerShell_profile"
    $profileDirectory = "$env:USERPROFILE\Documents\WindowsPowerShell\"
    
    if (((Get-ChildItem "$profileDirectory\Microsoft.PowerShell_profile.ps1").LastWriteTime) -lt ((Get-ChildItem "$profileRepository\Microsoft.PowerShell_profile.ps1").LastWriteTime)) {
      try { 
        Copy-Item "$profileRepository\Microsoft.PowerShell_profile.ps1" -Destination $profileDirectory -Force 
        #Restart-Profile
      }
      catch { Write-Warning "Error copying updated profile from local repository." }
    
    }
  }
}

# Test for running as Administrator and relaunch
$isAdmin = Test-Administrator
if (-not $isAdmin -and $alwaysRunAsAdmin) { 
  Start-Process "$PSHOME\powershell.exe" -Verb runAs
  Stop-Process $pid
}

# If PowerShell version 6 was not launched, check to see if it's installed and relaunch prompt.
if ($blockVersionLaunched) {
  if ($PSVersionTable.PSVersion.Major -lt 6) {
    $Version = "6.0.0"
    $InstallFolder = "$env:ProgramFiles\PowerShell\$Version"
    If (Test-Path "$InstallFolder\pwsh.exe")
    {
      Get-UpdatedProfile
      Invoke-Item "$InstallFolder\pwsh.exe"
      Stop-Process $pid
    }
  }
}

if (!(Get-Module -Name PSReadline)) { Import-Module -Name PSReadLine }
if (!(Get-Module -Name posh-git)) { Import-Module -Name posh-git }

# Stop Windows 10 Connected User Experience and Telemetry
if ($isAdmin) {
  if ((Get-Service diagtrack | Select-Object StartType).StartType  -eq "Automatic") { Get-Service DiagTrack | Set-Service -StartupType Disabled }
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

# Temporarily add to Path to get access to Caret.exe
$env:Path += ";$env:LOCALAPPDATA\Caret"

# Reloads the PowerShell Profile in same window
function Restart-Profile {
    & $profile
}

# Shortcut for opening files, like on macOS
Set-Alias open Invoke-Item

# Shortcut for creating files, like on Linux
Set-Alias touch New-Item

# Show date and time
Get-Date

if (!(Test-Path "C:\temp\secrets\scriptspath.txt")) {
  Write-Warning "Secret not found"
  return
} else {
  $scriptPath = Get-Content "C:\temp\secrets\scriptspath.txt"
}

function Get-Weather {
  param ([Parameter(Mandatory=$False)][switch]$Clear)
  if ($Clear) { Clear-Host }
  Push-Location $scriptPath
  . .\Get-Weather\Get-Weather.ps1
  Get-Weather
  Pop-Location
  if ($Clear) { Write-Host }
}

# Show the weather forecast
Get-Weather -Clear