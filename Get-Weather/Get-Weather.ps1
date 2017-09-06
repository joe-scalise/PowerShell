function Get-Weather {
<#
  .SYNOPSIS
  Returns a string of the current weather forecast from DarkSky.

  .NOTES
  Accepts ZIP Code for location (requires Google Maps API key), or tries Windows Location Service, or uses free IP Address information web service.  Weather query requires DarkSky API key.

  .NOTES
  https://darksky.net/poweredby/
  https://privacy.microsoft.com/en-us/windows-10-location-and-privacy
  https://developers.google.com/maps/
  http://ipinfo.io/json

  .PARAMETER ZipCode
  Optionally, you can pass a ZIP Code.

  .EXAMPLE
  Show weather for the current location based on the location service in Windows or by IP address registration information.
  Get-Weather
  
  .EXAMPLE
  Show weather for a specific ZIP Code
  Get-Weather -ZipCode "15213"
#>

[cmdletbinding()]
param(
  [Parameter(Mandatory=$false)]
  [string]$ZipCode
)

if ($ZipCode) {

  try {
    if (!(Test-Path "C:\temp\secrets\google.sec")) {
      Write-Warning "Google Geo Code API key not found."
    }

    [string]$googleAPI = Get-Content -Path "C:\temp\secrets\google.sec"
    $googleRequest = Invoke-RestMethod "https://maps.googleapis.com/maps/api/geocode/json?address=$($ZipCode)&key=$($googleAPI)"
    $lat = $googleData.results.geometry.location.lat
    $long = $googleData.results.geometry.location.lng
  }
  catch {
    Write-Information "Unable to use ZIP Code to determine location; $($_.Exception.Message)."
    $errorZipCode = $true
  }

}

if ($errorZipCode -or !$ZipCode) {

  try {
    Add-Type -AssemblyName "System.Device"
    $watcher = New-Object -TypeName System.Device.Location.GeoCoordinateWatcher -ArgumentList "High"
    if (!$watcher.Permission -ne "Granted") {
      Write-Information "Please verify the location service in Windows is enabled."
      $errorLocService = $true
    }
  }
  catch {
    Write-Information "Unable to load the necessary assembly System.Device; $($_.Exception.Message)."
    $errorLocService = $true
  }

  if (-not $errorLocService) {

    [void]$watcher.TryStart($true, [TimeSpan]::FromMilliseconds(1000))

    $count = 1
    do {
      $count++
      Start-Sleep -Milliseconds 1000
    } while (($watcher.Position.Location.IsUnknown) -and ($count -le 3))

    if ($watcher.Position.Location.IsUnknown) {
      Write-Information "Unable to gather coordinates."
      $errorLocService= $true
    } else {
      $lat = $watcher.Position.Location.Latitude
      $long = $watcher.Position.Location.Longitude
    }

  }

}

if ($errorLocService) {

  try {
    $ipInfoRequest = Invoke-RestMethod http://ipinfo.io/json
    $lat = ($ipInfoRequest | Select-Object -ExpandProperty loc).Split(",")[0]
    $long = ($ipInfoRequest | Select-Object -ExpandProperty loc).Split(",")[1]
  }
  catch {
    Write-Warning "All attempts to gather coordinates for weather request failed; $($_.Exception.Message)."
    return
  }

}

if ($lat -and $long) {

  if (!(Test-Path "C:\temp\secrets\darksky.sec")) {
    Write-Warning "DarkSky API key not found."
    return
  }

  try {
    [string]$darkskyAPI = Get-Content -Path "C:\temp\secrets\darksky.sec" 
    $darkskyRequest = Invoke-RestMethod "https://api.darksky.net/forecast/$($darkskyAPI)/$($lat),$($long)"
  } 
  catch {
    Write-Warning "DarkSky API request failed; $($_.Exception)."
    return
  }

  return "$([math]::Round($darkskyRequest.currently.temperature))$([char]176) $($darkskyRequest.currently.summary). $($darkskyRequest.hourly.summary)"

} else {
  Write-Warning "There's a problem.  I still do not have latitude and/or longitude information."
  return
}

}