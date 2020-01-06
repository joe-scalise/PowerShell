<#
.SYNOPSIS Concatenates log files for the previous day.
.NOTES Keeps going back a day until no more log files are in the directory.
#>

#region variables
$LogFile = "LOG-$($myinvocation.mycommand.name)_$($env:computername).log"
$exGUID = [System.Guid]::NewGuid().toString()
#$LogPath = "C:\logs\"
$LogPath = "C:\scripts\dev\Log Concatenation"
$count = 1
$newEmailContent = @()
[datetime]$ExecutionDate = get-date -format d
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

function SendMail
{ 
    param
    (
        [string]$Body                  = $(throw "body must be set") 
    )
    $smtpServer = "relay.example.com" 
    $MailAddress = "user@example.com"  
    $mail = New-Object System.Net.Mail.MailMessage 
    $mail.From = New-Object System.Net.Mail.MailAddress($MailAddress) 
    $mail.To.Add("user@example.com")
    $mail.Subject = "Log Cleanup Report" 
    $mail.Priority = "High" 
    $mail.Body = $Body
    $smtp = New-Object System.Net.Mail.SmtpClient -argumentList $smtpServer 
    try{ 
        $smtp.Send($mail) 
        LogWrite "Mail sent successfully."
    } 
    catch  
    { 
        LogWrite "SMTP Send Error!"
    } 
}
#endregion

#region main
LogWrite "Script START: [$($exGUID)]"

#while((gci -Recurse -Path $LogPath -Include log*.txt).count -gt 0)
while(gci -Recurse -Path $LogPath -Include log*.txt | where {$_.lastwritetime -lt $ExecutionDate})
{
    $curLogDate = $LogDate.ToString("MMddyyy")
    $MergeFile = "LOG--$($curLogDate).log"
    $foundFiles = gci -Recurse -Path $LogPath -Include log*.txt | where {($_.lastwritetime -lt $TodaysDate) -and ($_.lastwritetime -ge ($TodaysDate).adddays(-1))}
    if ($foundFiles) {
        LogWrite "$($foundFiles.count) files found for $($TodaysDate.adddays(-1)), performing merge next."
        foreach ($file in $foundFiles){
            try {
                $curContent = get-content $file
                Add-Content $MergeFile -value $curContent
                LogWrite "Writing file: $($file)."
                try {
                    Remove-Item $file
                    LogWrite "Removing file: $($file)."
                }
                catch [Exception]{
                    LogWrite "Issue removing file: $($file), continuing."
                }
            }
            catch {
                LogWrite "Issue adding content to file. Exiting."
                LogWrite "Script EXIT: [$($exGUID)]"
                exit
            }
        }
        LogWrite "Completed writing files for $($TodaysDate.adddays(-1)). Looking for more logs..."
    } else {
        LogWrite "No log files found for $(($TodaysDate).adddays(-1))."
    }
    $LogDate = $LogDate.adddays(-1)
    $TodaysDate = $TodaysDate.adddays(-1)
}

LogWrite "Sending email of current actions (script completes reguardless)."
LogWrite "Script COMPLETED: [$($exGUID)]"
$EmailContent = Get-Content $LogFile
$lines = $EmailContent | select-string $exGUID | select LineNumber
foreach ($line in $EmailContent) { 
    if (($count -ge $lines[0].LineNumber) -and ($count -le $lines[1].LineNumber)) { $newEmailContent = $newEmailContent + $line + "`n" }
    $count++
}
SendMail $newEmailContent
#endregion