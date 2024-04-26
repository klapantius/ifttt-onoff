. "$PSScriptRoot\logging.ps1"
. "$PSScriptRoot\battery.ps1"
. "$PSScriptRoot\trigger.ps1"

function get-violation {
  param(
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  write-log (("$currentLevel", "$lowerTreshold(l)", "$upperTreshold(u)" | sort) -join ' <= ')
  if ($currentLevel -lt $lowerTreshold) { 'lower' } elseif ($upperTreshold -lt $currentLevel) { 'upper' } else { 'no' }
}

function evaluate {
  param(
    [bool]$force = $false,
    [int]$currentLevel,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  if ($force) {
    write-log "evaluate force ==> trigger with $currentLevel%"
    return $currentLevel 
  }
  $activeLimit = get-violation -currentLevel $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
  write-log "$activeLimit limit violation detected"
  if (-not ('no' -eq $activeLimit)) {
    $lastTrigger = get-lastTrigger
    $lastLevel = $lastTrigger | get-TriggerLevel
    if ($lastLevel -gt 0) {
      # check if the last trigger was reacting to the same situation
      # - it should not be too old
      $supposedDurationToGetIntoValidRange = 30 # minutes
      $lastTriggerTime = $lastTrigger | get-TriggerTime
      $lastTriggerIsTooOld = (Get-Date) -gt $lastTriggerTime.AddMinutes($supposedDurationToGetIntoValidRange)
      # - it should react to the same situation
      write-log "last trigger was placed due to $lastLevel% at $($lastTriggerTime.ToString('HH:mm'))"
      $lastViolation = get-violation -currentLevel $lastLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold
      write-log "last trigger was due to $lastViolation limit violation $(if ($lastTriggerIsTooOld) {'but it is'} else {'and it is not'}) too old"
      $lastTriggerAssumedToBeInvalid = $lastViolation -ne $activeLimit -or $lastTriggerIsTooOld
      if ($lastTriggerAssumedToBeInvalid) {
        write-log "a new trigger must be set"
        return $currentLevel
      }
      # last trigger is still valid, check the progress made since last trigger
      $isCharging = test-charging
      $isDepleting = -not $isCharging
      #  <----- level is too low -------->  and <level is already increasing>
      if ($activeLimit -eq 'lower') {
        if ($isCharging) {
          write-log "already triggered (on) and charging"
          return $null
        }
        show-notification "based on the last trigger it should be already charging but the charger is off"
      }
      #   <---- level is too high ------->  and < level is already sinking >
      if ($activeLimit -eq 'upper') {
        if ($isDepleting) {
          write-log "already triggered (off) and depleting"
          return $null
        }
        show-notification "based on the last trigger it should be already depleting but the charger is on"
      }
    }
    write-log "evaluation decides to trigger"
    return $currentLevel
  }
  return $null
}

function trigger-ifttt {
  param(
    [parameter(ValueFromPipeline)]
    $level
  )
  if ($null -ne $level) {
    write-log "triggering with $level%"
    place_a_trigger_file $level
    synchronise-trigger
  }
}

function launch {
  param(
    [bool]$force = $false,
    [int]$lowerTreshold,
    [int]$upperTreshold
  )
  $currentLevel = get-batteryLevel
  write-log "current level is $currentLevel%"
  evaluate -force $force -currentLevel $currentLevel -lowerTreshold $lowerTreshold -upperTreshold $upperTreshold |
    trigger-ifttt
}