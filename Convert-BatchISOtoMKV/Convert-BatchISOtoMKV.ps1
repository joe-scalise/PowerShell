<#   
.SYNOPSIS   Batch processing of ISO files with MakeMKV command line.
.NOTES      Requires MakeMKV http://www.makemkv.com/
.NOTES      Currently breaks if period used in file title other than file extension. 
.NOTES      Tested with MakeMKV v1.9.1 Windows 8.1 
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string[]]$fileDirs,
    [Parameter()][string]$saveDir,
    [Parameter()][switch]$delete = $false

)
#region vars
$LogFile = "LOG-ConvertBatchISOtoMKV.log"
if ([System.Environment]::Is64BitProcess) {
    $prog = "C:\Program Files (x86)\MakeMKV\makemkvcon64.exe"
} else {
    $prog = "C:\Program Files (x86)\MakeMKV\makemkvcon.exe"
}
#endregion

#region functions
function LogWrite
{
    param([string]$logstring)

    if (!$script:guid) { $script:guid = ([System.Guid]::NewGuid().toString()).Remove(8) }

    $logString = $(get-date -f "[MM/dd/yyy hh:mm:ss.$((get-date).millisecond)") + " > $($guid)] $logstring"
    Add-Content $LogFile -value $logstring
    Write-Host $logstring
}

function GetISOInfo
{
    param([string]$dir, [string]$file)

    LogWrite "command: ""$($prog)"" -r info iso:""$($dir)\$($file)"""
    try { $info = & "$($prog)" -r info iso:"$($dir)\$($file)" }
    catch [system.exception] { LogWrite "Error with ISO info command for file $($file). $_.Exception." }
    LogWrite "$($info)."
    foreach ($line in $info) {
        if ($line -like "*TINFO*.mkv*") {
            $returnInfo = $line.split("""")[1]
        }
    }
    return $returnInfo
}

function RenameMKV
{
    param([string]$dir, [string]$saveDir, [string]$titleInfo, [string]$title)
    try {
        LogWrite "command: $($dir)\$(if($saveDir){"$($saveDir)\"})$titleInfo"" -NewName ""$($dir)\$(if($saveDir){"$($saveDir)\"})$($title).mkv"
        Rename-Item "$($dir)\$(if($saveDir){"$($saveDir)\"})$titleInfo" -NewName "$($dir)\$(if($saveDir){"$($saveDir)\"})$($title).mkv"
    }
    catch [system.exception] { LogWrite "Error with renaming file $($file). $_.Exception." }
}

function DeleteISO
{
    param([string]$dir, [string]$file)
    LogWrite "Deleting original ISO file: $($file)."
    try { Remove-Item "$($dir)\$($file)" }
    catch [system.exception] { LogWrite "Error with removing file $($file). $_.Exception." }

}
#endregion

#region main
foreach ($dir in $fileDirs) {

    if (!(test-path -path $dir)) { LogWrite "Invalid file directory, please enter complete path."; return }

    if ($saveDir) {
        if ($saveDir -match '\w:\\' ) { 
            if (!(test-path -path $saveDir)) { New-Item -ItemType directory -path $saveDir | out-null }
        } else {
            if (!(test-path -path "$dir\$saveDir")) { New-Item -ItemType directory -path "$dir\$saveDir" | out-null }
        }
    }

    if (Test-Path "$($dir)$(if($saveDir){"$($saveDir)\"})\title00.mkv") {
        LogWrite "File name title00.mkv in save directory will be overwritten by MakeMKV.  Please rename or delete. EXITING!"
        Exit
    }

    $files = gci $dir *.iso
    if (-not $files) {
        LogWrite "No ISO files found in directory $dir."
    } else {
        foreach ($file in $files) {
            $title = $file.Name.Split(".")[0]
            if (Test-Path "$($dir)\$($title).mkv") {
                LogWrite "MKV file already exists with name $($title).mkv."
            } else {
                LogWrite "Converting $file to MKV."
                try {
                    $titleInfo = GetISOInfo $dir $file.Name
                    if ($titleInfo) {
                        LogWrite "Title info returned: $($titleInfo)."
                        LogWrite "command: ""$($prog)"" mkv iso:""$($dir)\$($file.Name)"" all  ""$($dir)\$($saveDir)"""
                        try {
                            & "$($prog)" mkv iso:"$($dir)\$($file.Name)" all "$($dir)\$($saveDir)"
                            RenameMKV $dir $saveDir $titleInfo $title
                        }
                        catch [system.exception] { LogWrite "Error with command converting file $($file). $_.Exception." }
                        if ($delete) {
                            DeleteISO $dir $file
                        }
                    } else {
                        LogWrite "Error extracting title info. Title will be skipped."
                    }
                }
                catch [system.exception] { LogWrite "Error with info command for file $($file). $_.Exception." }
            }
        }
    }
}