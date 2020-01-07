<#
.SYNOPSIS 

.NOTES

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$user
)

$ver = $host | select version
if ($ver.Version.Major -gt 1)  {$Host.Runspace.ThreadOptions = "ReuseThread"}
Add-PsSnapin Microsoft.SharePoint.PowerShell

#region variables
$sw = [Diagnostics.Stopwatch]::StartNew()
# Modify for AD Domain Qualification
$userID = "i:0#.w|domain.local\$($user)"
#endregion

#region functions
function LogWrite
{
    param 
    (
        [string]$logType,
        [string]$logString
    )

    if (!$script:guid) { $script:guid = ([System.Guid]::NewGuid().toString()).Remove(8) }
    if (!$script:logFile) { $script:logFile = "LOG-Remove-CMUSharePointUser.log" }
    switch ($logType) {
        "beginscript" {
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): BEGIN]"
        }
        "endscript" {
            $sw.Stop()
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): END] Elapsed Time: $($sw.Elapsed)"
            Add-Content $logFile -value $logString
            Write-Output $logstring
            Exit
        }
        "exitscript" {
            $sw.Stop()
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): EXIT] Elapsed Time: $($sw.Elapsed)"
            Add-Content $logFile -value $logString
            Write-Output $logstring
            Exit
            }
        default { 
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): $($logType.ToUpper())] $logString"
        }
    }
    Write-Output $logstring
}
#endregion

#region Main
LogWrite BeginScript

$siteCollections = Get-SPSite -Limit All

foreach ($site in $siteCollections)
{
    $web = $site.openweb()
    $siteColUsers = $web.SiteUsers
    $SPUser = $siteColUsers | Where-Object { $_.UserLogin.ToLower() -eq $userID}
    if ($SPUser -eq $null)
    {
        continue;
    } else {
        LogWrite "User $($userID) was found in site collection $($site.URL)."
    }

    $siteCollectionGroups = Get-SPSite $site.URL | Select -ExpandProperty RootWeb | Select -ExpandProperty Groups
    
    foreach ($group in $siteCollectionGroups)
    {
        foreach ($user in $group.Users)
        {
            if ($user.LoginName -eq $userid)
            {
                LogWrite "User $($userID) was found in group $($group.Name)."
            }
        }
    }
}