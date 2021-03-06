[cmdletbinding()]
param(
  [bool]$force = $false,
  [int]$lowerTreshold = 30, #22
  [int]$upperTreshold = 80, #82
  [int]$iterationDelay = 0
)

Import-Module '.\onoff-functions.ps1' -force

function Start-Once {
  launch -force $force -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
}

if ($iterationDelay -gt 0) {
  do {
    write-log "-------- new iteration starts"
    Start-Once
    Start-Sleep -Seconds $(60 * $iterationDelay)
  } while ($true) 
}
else { 
  write-log "-------- single execution starts"
  Start-Once 
}