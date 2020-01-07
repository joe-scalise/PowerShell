#region Variables
$varLogFile = "LOG-$($myinvocation.mycommand.name)_$($env:computername).log"
#end region

#region functions
function LogWrite {
    param 
    (
        [string]$logstring
    )
    $logstring = "$(get-date -f u)`t"+$logstring
    Add-Content $varLogFile -value $logstring
    Write-Host $logstring
}

function ConnectToSQL {
    param
    (
        [string]$SQLServer          = $(throw "SQL Server must be specified"), 
        [string]$SQLDBName          = $(throw "DB Name must be specified") 
    )
    #Create the SQL Connection Object  
    $SQLConn=New-Object System.Data.SQLClient.SQLConnection  
    #Create the SQL Command Ojbect (otherwise all we can do is admire our connection)  
    $SQLCmd=New-Object System.Data.SQLClient.SQLCommand  
    #Set our connection string property on the SQL Connection Object and tell it to use integrated auth, hopefully kerberos  
    $SQLConn.ConnectionString="Server=$SQLServer;Database=$SQLDBName;Integrated Security=SSPI"  
    #Open the connection  
    $SQLConn.Open() 
}

function QuerySQL {
    #Define our Command with a parameter (we will cover this below)  
    $SQLCmd.CommandText="SELECT * FROM NewWorkRequests"
    #Provide the open connection to the Command Object as a property  
    $SQLCmd.Connection=$SQLConn  
    #Set the WHERE clause in a variable to be referenced in the parameter (See section below)
    $WhereClause="smalls"
    #Prepare parameters  
    $SQLCmd.Parameters.Clear()
    $SQLcmd.Parameters.Add("@smalls",$WhereClause)  
    #Execute this thing  
    $SQLReturn=$SQLcmd.ExecuteReader()  
    #Init arrays to handle multiple returns
    $TheFooReturn=@()
    $TheBarReturn=@()
    #Parse it out  
    while ($SQLReturn.Read())  
    {  
        $TheFooReturn+=$SQLReturn["FOO"]  
        $TheBarReturn+=$SQLReturn["BAR"]  
    }  
    #Clean it up  
    $SQLReturn.Close()  
    $SQLConn.Close()
}

function CreateNewSPSite {
    param
    (
        [string]$SPSiteName         = $(throw "SharePoint site name must be specified"),
        [string]$SPSiteCaption      = $(throw "SharePoint site name must be specified"),
        [string]$SPSiteDesc         = $(throw "SharePoint site description must be specified"),
        [string]$SPSiteTemplate     = $(throw "SharePoint site template must be specified")

    )
    $WebApplicationPath = "https://sharepoint.url"
    $SitesServicePath = "/_vti_bin/Sites.asmx"
    $SitesWS = New-WebServiceProxy -Uri ($WebApplicationPath + $SitesServicePath) -UseDefaultCredential
    $SitesWS.CreateWeb($SPSiteName, $SPSiteCaption, $SPSiteDesc, $SPSiteTemplate, 1033, $true, 1033, $true, 1033, $true, $false, $false, $false, $false, $false, $false)
}
#end region

#region Main
Clear-Host
LogWrite "--- START ---"
LogWrite "Executing $($myinvocation.mycommand.name) on $($env:computername) by user $($env:USERNAME)"
LogWrite "Connecting to SQL Server..."
ConnectToSQL -SQLServer "localhost" -SQLDBName "PowerShellTest"
LogWrite "Looking for new SharePoint site requests."
QuerySQL 
#end region