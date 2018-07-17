function Export-SecureString {
<#
    .SYNOPSIS
    Takes a plain text password and saves it as a secure string in a file on your hard drive for importing later.

    .NOTES
    
    .PARAMETER password
    Your plain text password

    .PARAMETER description
    You must include the description, which will end up being the file name.
    
    .EXAMPLE
    Export-SecureString -pwd "P4ssW0rd" -desc "Plex"

    .EXAMPLE
    Here's how you would consume the file this function creates:

    $pwdTxt = Get-Content "C:\temp\plex.txt"
    $securePwd = $pwdTxt | ConvertTo-SecureString
    
    And then maybe:
    $username = "bobby.fletcher@domain.com"
    $credObject = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securePwd
#>
    
    [cmdletbinding()]
    param(
      [Parameter(Mandatory=$true)]
      [alias("pwd")]
      [string]$password,

      [Parameter(Mandatory=$true)]
      [alias("desc")]
      [string]$description
    )
    
    Begin{}
    Process{

        $description = $description -replace '\s',''
        $description = $description.ToLower()
        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $secureStringText = $securePassword | ConvertFrom-SecureString

        if (!(Test-Path "C:\temp\secrets")) {
            Write-Warning "Creating temporary secrets directory C:\temp\secrets"
            New-Item -Path "C:\temp\secrets" -ItemType Directory
        }

        Set-Content "C:\temp\secrets\$description.txt" $secureStringText
    }
    End{}    
}