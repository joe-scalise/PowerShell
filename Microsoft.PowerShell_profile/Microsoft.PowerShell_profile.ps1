if (!(Get-Module -Name PSReadline)) { Import-Module -Name PSReadLine }
if (!(Get-Module -Name posh-git)) { Import-Module -Name posh-git }

# Stop Windows 10 Connected User Experience and Telemetry
 if ((Get-Service diagtrack | select StartType).StartType  -eq "Automatic") { Get-Service DiagTrack | Set-Service -StartupType Disabled }
 if ((Get-Service diagtrack | Select Status).Status -ne "Stopped") { Stop-Service diagtrack }

# Increase history
$MaximumHistoryCount = 10000

# Quick way to lock screen, same as Ctrl-Alt-Delete + Enter
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

# Simple shortcut for opening files, like on macOS
Set-Alias open Invoke-Item

# Simple shortcut for creating files, like on Linux
Set-Alias touch New-Item

Get-Date

if (!(Test-Path "C:\temp\secrets\scriptpath.sec")) {
  Write-Warning "Secret not found"
  return
} else {
  $scriptPath = Get-Content "C:\temp\secrets\scriptpath.sec"
}

function Get-Weather {
  param ([Parameter(Mandatory=$False)][switch]$NoSpace)
  if (!$NoSpace) { Clear-Host }
  Push-Location $scriptPath
  . .\Get-Weather\Get-Weather.ps1
  Get-Weather
  Pop-Location
  if (!$NoSpace) { Write-Host }
}

Get-Weather -NoSpace