



return





$srcRoot = "C:\temp\news"
$dstRoot = "C:\temp\new"

$logDir = "C:\temp\log"

if (!(Test-Path $srcRoot)) {
    throw "Source path '$srcRoot' does not exist!"
}

if (!(Test-Path $logDir)) {
    Write-Warning "Path '$logDir' does not exist! Creating..."
    try {
        md $logDir | Out-Null
    } catch {
        throw $_
    }
}

if (!(Test-Path $dstRoot)) {
    Write-Warning "Path '$dstRoot' does not exist! Creating..."
    try {
        md $dstRoot | Out-Null
    } catch {
        throw $_
    }
}


Write-Host "$(date -f yyyyMMdd-HHmmss) Getting all the source files..."
$srcFiles =  Get-Files $srcRoot -Recurse -Method AlphaFS 

$date = Get-Date -f yyyyMMdd-HHmmss

$usedDrives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$availDrives = (diff $usedDrives $alpha).inputobject
if (@($availDrives).Count -lt 2) { Throw 'subst needs at least two drive letters available - one for source and one for destination. just in case' }
$srcSubstDrive = $availDrives[0] + ':'
$dstSubstDrive = $availDrives[1] + ':'


$index = 0
$total = @($srcFiles).Count
$starttime = $lasttime = Get-Date


$results = foreach ($file in $srcFiles) {
    
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "working $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "item: $($file.fullpath)"
        PercentComplete = $index / $total * 100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    
    subst $srcSubstDrive /d | Out-Null
    subst $dstSubstDrive /d | Out-Null


    


    $srcpath = $srcfile = $srcdir = $srcend = $srcsplit = $srcextra = $srcstop = $null

    
    if ($file.fullpath.length -gt 240)
    {
        
        $srcpath = Split-Path $file.fullpath

        
        $srcextra = $null
        if ($srcpath.length -gt 240)
        {
            $srcextra = New-Object System.Collections.ArrayList
            $srcsplit = $srcpath.Split('\')
            $srcstop = 2
            while ($srcpath.length -gt 240)
            {
                $srcend = $srcsplit.count - $srcstop
                $srcpath = [string]::Join('\', $srcsplit[0..$srcend])
                $srcstop++
            }
            $srcextra = [string]::Join('\', $srcsplit[($srcend + 1)..($srcend + $srcstop)])
        }

        
        subst $srcSubstDrive $srcpath

        
        if ($srcextra)
        {
            $srcfile = Join-Path (Join-Path $srcSubstDrive $srcextra) $file.filename
        }
        else
        {
            $srcfile = Join-Path $srcSubstDrive $file.filename
        }
    }
    else
    {
        $srcfile = $file.fullpath
    }

    $srcdir = Split-Path $srcfile


    


    $dstdir = $dstfile = $dstpath = $dstend = $dstsplit = $dstextra = $dststop = $null
    
    
    $dstdir = Join-Path $dstRoot $($(Split-Path $file.fullpath) -replace [regex]::Escape($srcRoot))
    $dstfile = Join-Path $dstdir $file.FileName

    
    if ($dstfile.length -gt 240)
    {
        
        $dstpath = Split-Path $dstfile

        
        $dstextra = $null
        if ($dstpath.length -gt 240)
        {
            $dstextra = New-Object System.Collections.ArrayList
            $dstsplit = $dstpath.Split('\')
            $dststop = 2
            while ($dstpath.length -gt 240)
            {
                $dstend = $dstsplit.count - $dststop
                $dstpath = [string]::Join('\', $dstsplit[0..$dstend])
                $dststop++
            }
            $dstextra = [string]::Join('\', $dstsplit[($dstend + 1)..($dstend + $dststop)])
        }

        
        if (!(Test-Path $dstpath)) {
            Write-Warning "Path '$dstpath' does not exist! Creating..."
            try {
                md $dstpath | Out-Null
            } catch {
                throw $_
            }
        }

        
        subst $dstSubstDrive $dstpath

        
        if ($dstextra)
        {
            $dstfile = Join-Path (Join-Path $dstSubstDrive $dstextra) $file.filename
        }
        else
        {
            $dstfile = Join-Path $dstSubstDrive $file.filename
        }
    }
    else
    {
        
    }

    $dstdir = Split-Path $dstfile

    if (!(Test-Path $dstdir)) {
        Write-Warning "Path '$dstdir' does not exist! Creating..."
        try {
            md $dstdir | Out-Null
        } catch {
            throw $_
        }
    }


    


    $err     = 'N/A'
    $exists  = 'N/A'
    $srcsize = $file.FileSize
    $srcdate = date $file.LastModified
    $dstsize = 'N/A'
    $dstinfo = 'N/A'
    $dstsize = 'N/A'
    $dstdate = 'N/A'
    $newer   = 'N/A'

    try
    {
        
        
        
        if (!(Test-Path $dstfile)) {
            
            if (($srcsize/1mb) -gt (200mb/1mb)) {
                
                
            } else {
                copy $srcfile $dstfile
            }

            $exists = $false
        } else {
            $dstinfo = gi $dstfile
            $dstsize = $dstinfo.length
            $dstdate = $dstinfo.LastWriteTime

            
            if ($srcdate -eq $dstdate) {
                $newer = 'Same'
            } else {
                
                
                if ($srcdate -gt $dstdate) {
                    if (($srcsize/1mb) -gt (200mb/1mb)) {
                        
                        
                    } else {
                        
                        
                        
                        

                        

                        copy $srcfile $dstfile
                    }
                    $newer = $true
                } else {
                    
                    
                    
                    
                    $newer = $false
                }
            }
            $exists = $true
        }
    }
    catch
    {
        write-host $_
        $err = $_
    }


    

    
    $obj = [pscustomobject]@{
        FullPath = $file.fullpath
        SrcFile  = $srcfile
        SrcDrive = $srcSubstDrive
        SrcPath  = $srcpath
        SrcExtra = $srcextra
        SrcDir   = $srcdir
        DstFile  = $dstfile
        DstDrive = $dstSubstDrive
        DstPath  = $dstpath
        DstExtra = $dstextra
        DstDir   = $dstdir
        Error    = $err
        Exists   = $exists
        SrcSize  = $srcsize
        DstSize  = $dstsize
        Newer    = $newer
        SrcWrite = $srcdate
        DstWrite = $dstdate
    }

    $obj

    Write-Object $obj
    Write-Host ''

    
    $obj | Export-Csv $(Join-Path $logDir "$date-Copy.csv") -NoTypeInformation -Append
    

    
    subst $srcSubstDrive /d | Out-Null
    subst $dstSubstDrive /d | Out-Null
}


$results | ? {($_.error -ne 'n/a') -or ($_.srcsize -gt 0 -and $_.dstsize -eq 0)} | Export-Csv $(Join-Path $logDir "$date-Error.csv") -NoTypeInformation
