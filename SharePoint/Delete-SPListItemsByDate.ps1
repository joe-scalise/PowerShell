<# .SYNOPSIS Script automatically purges SharePoint lists from SharePoint site https://sharepoint.url of items older than 14 days. #>

#region variables
$sw = [Diagnostics.Stopwatch]::StartNew()
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
    if (!$script:logFile) { $script:logFile = "LOG-DeleteSPListItemsByDate.log" }
    switch ($logType) {
        "beginscript" {
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): BEGIN]"
        }
        "endscript" {
            $sw.Stop()
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): END] Elapsed Time: $($sw.Elapsed)"
            Add-Content $logFile -value $logString
            Write-Host $logstring
            Exit
        }
        "exitscript" {
            $sw.Stop()
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): EXIT] Elapsed Time: $($sw.Elapsed)"
            Add-Content $logFile -value $logString
            Write-Host $logstring
            Exit
            }
        default { 
            $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid): $($logType.ToUpper())] $logString"
        }
    }
    Add-Content $logFile -value $logString
    Write-Host $logstring
}

function SendMail
{ 
    param([string]$Body = "Email body not passed to function." )

    $smtpServer   = "relay.example.com" 
    $MailAddress  = "noreply@example.com"  
    $mail = New-Object System.Net.Mail.MailMessage 
    $mail.From = New-Object System.Net.Mail.MailAddress($MailAddress) 
    $mail.To.Add("user@example.com")
    $mail.Subject = "Delete-SPListItemsByDate" 
    $mail.Priority  = "High" 
    $mail.Body = $Body 
    $smtp = New-Object System.Net.Mail.SmtpClient -argumentList $smtpServer 
    try{ 
        $smtp.Send($mail) 
        LogWrite Info "Mail sent successfully."
    } 
    catch [system.exception] { 
        LogWrite Error "SMTP send error. Error: $($_.Exception.Message)"
    }
}

function DeleteListItems {

    param 
    (
        [string]$SPsite,
        [string]$SPlist,
        [int]$days
    )

    LogWrite Info "Attempting to connect to site $($SPsite)..."
    try { $varWeb = Get-SPWeb "$SPsite" }
    catch [system.exception] { LogWrite Error "Error connecting to SharePoint site $($SPsite); ERROR: $($_.Exception)"; return }

    LogWrite Info "Performing list query and purge..."
    try {
        $varList = $varWeb.Lists["$SPlist"]
        $varDeleteBeforeDate = [Microsoft.SharePoint.Utilities.SPUtility]::CreateISO8601DateTimeFromSystemDateTime([DateTime]::Now.AddDays(-$($days))) 
        $SPcaml = "<Where> <Lt> <FieldRef Name=""Created"" /><Value Type=""DateTime"">$($varDeleteBeforeDate)</Value> </Lt> </Where>" 
        $SPquery = New-Object Microsoft.SharePoint.SPquery 
        $SPquery.Query = $SPcaml
        $col = $varList.GetItems($SPquery) 
        LogWrite Info "List $($SPlist) has $($col.Count) list items older than $($days) days and will now be purged..."
        try { 
            $col | % {$varList.GetItemById($_.Id).Delete()} 
            $finalEmail = $finalEmail + "`nList $($SPlist) had $($col.Count) list items older than $($days) days and was purged successfully."
        }
        catch [system.exception] { LogWrite Error "Error deleting list items for list $($SPlist); ERROR: $($_.Exception)"; return }
    }
    catch [system.exception] { LogWrite Error "Error with query and purge of list $($SPlist); ERROR: $($_.Exception)"; return }
    LogWrite Info "Closing web connection."
    $varWeb.Dispose()
}
#endregion

#region Main
LogWrite beginscript

try { Add-PsSnapin Microsoft.SharePoint.PowerShell }
catch [system.exception] { 
    LogWrite Error "Error adding SharePoint PsSnapin; ERROR: $($_.Exception.Message)"
    SendMail "Error adding Sharepint PsSnapin; Error: $($_.Exception.Message); script will exit."
    LogWrite exitscript
}

LogWrite Info "Calling delete function for LIST NAME list..."
try { DeleteListItems "https://sharepoint.url/site" "LIST NAME" 14 }
catch [system.exception] { LogWrite Error "Error processing DeleteListItems function; ERROR: $($_.Exception.Message)" }

if ($finalEmail) { SendMail "$finalEmail" }

LogWrite endscript