function place_a_trigger_file {
    $fileName = "$triggerFolder\$(get-date -Format yyMMdd_HHmm)_$proc"
    write-log "place a trigger file: $fileName"
    "switch" | out-file $fileName
    # remove older triggers
    $recently = (Get-Date).AddHours(-1)
    dir $triggerFolder -File | where { $_.CreationTime -lt $recently} | foreach { del $_ -ErrorAction SilentlyContinue }
}

function get-lastTrigger {
    $result = Get-ChildItem -file $triggerFolder | Sort-Object LastWriteTime | Select-Object -First 1 -ExpandProperty Name
    return $result
}

function get-level {
    param(
        [parameter(ValueFromPipeline)]
        [string]$trigger
    )
    if ([string]::IsNullOrEmpty($trigger)) { return -1 }
    return [int]$($trigger -split '_' | Select-Object -Last 1)
}