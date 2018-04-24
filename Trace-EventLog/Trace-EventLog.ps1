
$latest = (get-eventlog -LogName Application -Source 'CS Gold Importer Service' -Newest 1).Index
while ($true)
{
  Start-Sleep -m 5000
  $tail = (get-eventlog -LogName Application -Source 'CS Gold Importer Service' -Newest 1).Index
  [int]$grab = $tail - $latest
  if ($grab -gt 0) {
    get-eventlog -LogName Application -Source 'CS Gold Importer Service' -newest $grab | sort index | select Index, TimeGenerated, Message
    $latest = $tail
  }
}