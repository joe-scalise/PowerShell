<#
.SYNOPSIS Concatenates log files for the previous day.
.NOTES Only processes previous day.
#>

#region variables
$LogFile = "Logs\LOG-Merge.log"
$exGUID = [System.Guid]::NewGuid().toString()
$LogPath = "Logs\"
$count = 1
$newEmailContent = @()
[datetime]$TodaysDate = get-date -format d
[datetime]$LogDate = $TodaysDate.adddays(-1)
#endregion

#region functions
function LogWrite
{
    param 
    ([string]$logstring)
    $logstring = "$(get-date -f u)`t"+$logstring
    Add-Content $LogFile -value $logstring
}
#endregion

#region main
LogWrite "Script START: [$($exGUID)]"

# Pick one $foundFiles declaration:
# Yesterday's Logs
$foundFiles = gci -Path $LogPath -Filter LOG*.log | where {($_.lastwritetime -lt $TodaysDate) -and ($_.lastwritetime -ge ($TodaysDate).adddays(-1))}

# Today's Logs
#$foundFiles = gci -Path $LogPath -Filter LOG-*.log | where {($_.lastwritetime -ge ($TodaysDate).adddays(-1))}

if ($foundFiles) {
    LogWrite "$($foundFiles.count) files found, performing merge next."
    $curLogDate = $LogDate.ToString("MMddyyy")
    $MergeFile = "Logs\MergeLog-$($curLogDate).log"
    foreach ($file in $foundFiles){
        try {
            $curContent = Get-Content ($LogPath + $file)
            Add-Content $MergeFile -value $curContent
            try {
                LogWrite "Removing file: $($LogPath)$($file)."
                Remove-Item ($LogPath + $file)
            }
            catch [Exception]{
                LogWrite "Issue removing file: $($LogPath)$($file), continuing."
            }
        }
        catch {
            LogWrite "Issue adding content to file. Exiting."
            LogWrite "Script EXIT: [$($exGUID)]"
            exit
        }
    }
} else {
    LogWrite "No log files found for $(($TodaysDate).adddays(-1)). Exiting."
    LogWrite "Script EXIT: [$($exGUID)]"
    exit
}

LogWrite "Script COMPLETED: [$($exGUID)]"
#endregion