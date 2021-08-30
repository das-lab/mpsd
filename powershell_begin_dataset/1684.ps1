



















$source = 'C:\temp\music'
$dest = 'C:\temp\new'


$exclude = '\\my (?:music|pictures)\\'


$files = (Get-ChildItem $source -Recurse -File).where{$_.FullName -notmatch $exclude}

$index = 0
$total = $files.Count
$starttime = $lasttime = Get-Date
$results = $files | % {
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "Copying files $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "File: $_"
        PercentComplete = ($index/$total)*100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    
    $destdir = Join-Path $dest $($(Split-Path $_.fullname) -replace [regex]::Escape($source))

    
    if (!(Test-Path $destdir)) {
        $null = md $destdir
    }

    
    $num = 1
    $base = $_.basename
    $ext = $_.extension
    $newname = Join-Path $destdir "$base$ext"
    while (Test-Path $newname) {
        $newname = Join-Path $destdir "$base-$num$ext"
        $num++
    }

    
    New-Object psobject -Property @{
        SourceFile = $_.fullname
        DestFile = $newname
    }

    
    copy $_.fullname $newname
}
