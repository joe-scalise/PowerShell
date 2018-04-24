<#
.SYNOPSIS
  Calculates the nth week day of the month and also a specific day after this date.
.DESCRIPTION
  Currently configured to calculate a certain day after the second Teusday of the month.  Used to schedule Microsoft updates based off of 'Patch Tuesday'.
.NOTES
  VBScript https://msdn.microsoft.com/en-us/library/aa387102(VS.85).aspx
#>

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

# Variables
$vFindNthDay = 2
$vWeekDay='Tuesday'
$vAction = $null
# Number of days AFTER Patch Tuesday.  2 would be Thursday, 3 would be Friday etc.
$vPatchDay = 2

# Log file info
$sLogPath = "C:\scripts\logs"
$sLogName = "$($MyInvocation.MyCommand.Name).log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName
if (!(Test-Path -Path $sLogFile)) {
 if (!(Test-Path -Path $sLogPath)) {
  New-Item $sLogPath -type directory | Out-Null
 }
 New-Item -Path $sLogPath -Value $sLogName -ItemType File | Out-Null
}

# Get today's date
[System.DateTime]$vToday=[System.DateTime]::Now.ToString("dddd, MMMM d, yyyy")
Add-Content -Path $sLogFile -Value "$(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") > Today's date is $($vToday)"

# Extract the current month and year
$vCurrentM=$vToday.Month.ToString()
$vCurrentY=$vToday.Year.ToString()

# Build a datetime variable for the first day of current month
[datetime]$vCurrentStart=$vCurrentM+'/1/'+$vCurrentY

# Find first Day defined above
while ($vCurrentStart.DayofWeek -ine $vWeekDay ) { $vCurrentStart=$vCurrentStart.AddDays(1) }

# Find nth day defined above
$vPatchRelease = $vCurrentStart.AddDays(7*($vFindNthDay-1))

Add-Content -Path $sLogFile -Value "$(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") > Current Patch Tuesday date was calculated to be $($vPatchRelease)"

# Here's where you will add days to get to desired execution day.
if ($vToday -eq $vPatchRelease.AddDays($vPatchDay)) { 
    Add-Content -Path $sLogFile -Value "$(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") > Determined to be a patch day, $($vPatchRelease.AddDays(2))"
    $vAction="patch"
}
else {
    Add-Content -Path $sLogFile -Value "$(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") > Not patch day, script exiting"
    return "not a patch day"
}
if ($vAction) {
    Add-Content -Path $sLogFile -Value "$(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") > Executing InstallWindowsUpdate.vbs"
    $command = "cscript C:\scripts\WUA_SearchDownloadInstall.vbs //Nologo"
    Invoke-Expression -Command $command
    return "patch day; command executed"
}