# most of this came from another source, which I lost track of

function Get-NewPassword {

  param (
    [Parameter()][int]$length = 50,
    [Parameter()][switch]$noSpecialCharacters
  )

  $passwordResult = ""
  $rng = new-object System.Security.Cryptography.RNGCryptoServiceProvider
  $tempBytes = new-object byte[] 4096
  $rng.GetBytes($tempBytes)
  $i = 0

  while ($passwordResult.Length -lt $length) {
    if ($noSpecialCharacters) {
      if (($tempBytes[$i] -ge 48 -and $tempBytes[$i] -le 57) -or ($tempBytes[$i] -ge 65 -and $tempBytes[$i] -le 90) -or ($tempBytes[$i] -ge 97 -and $tempBytes[$i] -le 122)) {
        $passwordResult += [char][int]$tempBytes[$i]
      }
    } else {
      if ($tempBytes[$i] -ge 33 -and $tempBytes[$i] -le 126) {
        $passwordResult += [char][int]$tempBytes[$i]
      }
    } 
    if ($i -ge 4096) {
      $i = 0
      $tempBytes = new-object byte[] 4096
      $rng.GetBytes($tempBytes)
    }
    $i++
  }
  return $passwordResult

}