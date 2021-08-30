




$source = 'c:\temp\new'





$files = Get-Files $source -Recurse -Method AlphaFS 



$drives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$avail = (diff $drives $alpha).inputobject
$sourcedrive = $avail[0] + ':'
$destdrive = $avail[1] + ':' 

$result = foreach ($file in $files)
{
    
    
    
    
    subst $sourcedrive /d | Out-Null

    
    
    $path = $newfile = $null

    
    if ($file.fullpath.length -gt 240)
    {
        
        $path = Split-Path $file.fullpath

        
        $extra = $null
        if ($path.length -gt 240)
        {
            $extra = New-Object System.Collections.ArrayList
            $split = $path.Split('\')
            $stop = 2
            while ($path.length -gt 240)
            {
                $end = $split.count - $stop
                $path = [string]::Join('\', $split[0..$end])
                $stop++
            }
            $extra = [string]::Join('\', $split[($end + 1)..($end + $stop)])
        }

        
        subst $sourcedrive $path

        
        if ($extra)
        {
            $newfile = Join-Path (Join-Path $sourcedrive $extra) $file.filename
        }
        else
        {
            $newfile = Join-Path $sourcedrive $file.filename
        }
    }
    else
    {
        $newfile = $file.fullpath
    }

    [pscustomobject]@{
        FullPath = $file.fullpath
        NewFile = $newfile
        SourceDrive = $sourcedrive
        Path = $path
        ExtraSubs = $extra
    }

    
    subst $sourcedrive /d | Out-Null
}

$result







