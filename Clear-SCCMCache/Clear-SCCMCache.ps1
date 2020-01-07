<#   
.SYNOPSIS Performs cache clearing operations for specified systems.
.NOTES Clears SCCM client cache and system servicing cache.  Some hosts might need FQDN and some hosts might have issues with WinRM.
.EXAMPLE .\Clear-CacheTempFiles.ps1 "SRV-MAN-01"
.EXAMPLE .\Clear-CacheTempFiles.ps1 "SRV-MAN-01", "SRV-DUDE-02", "SRV-THING-03"
#> 

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
        ValueFromPipeline=$true)]
    [string[]]$computername
)

#region functions
function LogWrite
{
    param 
    (
        [string]$logstring
    )
    $logstring = "$(get-date -f u)`t"+$logstring
    Add-Content $LogFile -value $logstring
    Write-Host $logstring
}
#endregion

#region variables
$LogFile = "LOG-$($myinvocation.mycommand.name)_$($env:computername).log"
if ([Environment]::UserName -like "*-admin") {
    $CurrUser = [Environment]::UserDomainName + "\" + [Environment]::UserName
} else {
    $CurrUser = [Environment]::UserDomainName + "\" + [Environment]::UserName + "-admin"
}
#$tempdir = "%windir%\Temp"
#endregion

#region main
foreach ($n in $computername) {

    try {
        LogWrite "Creating New-PSSession with host $n..."
        $s = New-PSSession -computername $n -credential $CurrUser
    }
    catch {
        LogWrite "Error: unsuccessful creating New-PSSession with host $n."
    }

    if ($s) {
        LogWrite "Successfully connected to host $n..."
        try {
            LogWrite "Attempting command to clear SCCM client cache from host $n..."
            Invoke-Command -Session $s -ScriptBlock {
                $CMObject = New-Object -ComObject "UIResource.UIResourceMgr"
                $CMCacheObjects = $CMObject.GetCacheInfo()
                $CMCacheElements = $CMCacheObjects.GetCacheElements()
                foreach ($ce in $CMCacheElements) {
                    $CacheElementID = $ce.CacheElementID
                    $CMCacheObjects.DeleteCacheElement($CacheElementID)
                }
            }
        }
        catch {
            LogWrite "Error: unsuccessful executing SCCM cache clear ScriptBlock for host $n."
        }

        try {
            LogWrite "Attempting command to clear space with DISM tool..."
            Invoke-Command -Session $s -ScriptBlock { DISM /online /Cleanup-Image /SpSuperseded } | Out-Null
        }    
        catch { 
            LogWrite "Error: unsuccessful executing DISM tool ScriptBlock for host $n."
        }

        try { 
            $ds = Disconnect-PSSession $s
            LogWrite "PSSession state with node $n is $($ds.State)."
        } catch { 
            LogWrite "Error: unsuccessful disconnecting PSSession with node $n, exiting."
            Exit
        }
    }
}
#endregion