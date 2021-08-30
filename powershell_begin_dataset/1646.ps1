





function Release-Ref ($ref) {
    ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}


function Remove-InvalidFileNameChars ([String]$Name, [switch]$IncludeSpace) {
    if ($IncludeSpace) {
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')
    } else {
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape(-join [System.IO.Path]::GetInvalidFileNameChars())), '')
    }
}


function Get-Files {
    param (
        [string[]]$Path = $PWD,
        [string[]]$Include,
        [switch]$Recurse,
        [switch]$FoldersOnly
    )

    $params = '/L', '/NJH', '/BYTES', '/FP', '/NC', '/TS', '/XJ', '/R:0', '/W:0'
    if ($Recurse) {$params += '/E'}
    if ($Include) {$params += $Include}
    foreach ($dir in $Path) {
        foreach ($line in $(robocopy $dir NULL $params)) {
            
            if (!$Include -and $line -match '\s+\d+\s+(?<FullName>.*\\)$') {
                New-Object PSObject -Property @{
                    FullName = $matches.FullName
                    Size = $null
                    DateModified = $null
                }
            
            } elseif (!$FoldersOnly -and $line -match '(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*)') {
                New-Object PSObject -Property @{
                    FullName = $matches.FullName
                    Size = $matches.Size
                    DateModified = $matches.Date
                }
            } else {
                Write-Verbose ('{0}' -f $line)
            }
        }
    }
}

cls


$folder = Read-Host 'Drag and drop the folder you wish to process.'
$folder = $folder -replace '"' 
if (!$folder) { Throw 'No folder provided.' }


$recursive = Read-Host 'Check all subfolders? y/[N]'
if ($recursive -eq 'y') {
    $mails = Get-Files $folder -Include *.msg -Recurse | select -ExpandProperty fullname | ? {$_ -match '\.msg$'}
} else {
    $mails = Get-Files $folder -Include *.msg | select -ExpandProperty fullname | ? {$_ -match '\.msg$'}
}


Write-Host '    1: SUBJECT [A][FROM][DATE]'
Write-Host '    2: [DATE][FROM][A] SUBJECT'
$format = $null
while ($format -ne 1 -and $format -ne 2) {
    $format = Read-Host 'Choose a formatting option. [1]/2'
    if (!$format) { $format = 1 }
}



if ($format -eq 1) {
    $mails = $mails | ? {$_ -notmatch '\[.*\]\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\](?:-\d+)?\.msg$'}
} else {
    $mails = $mails | ? {$_ -notmatch '\\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\]\[.*\]'}
}


$Outlook = New-Object -ComObject Outlook.application
$user = $Outlook.Session.CurrentUser.Name



$drives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$avail = diff $drives $alpha | select -ExpandProperty inputobject
$drive = $avail[0] + ':'


$i = 1
$total = $mails.Count
foreach ($mail in $mails) {
    
    $type = 1
    
    
    $file = (Split-Path $mail -Leaf) -replace '\.msg$'

    
    $folder = Split-Path $mail
    if ($total -gt 1) {
        Write-Progress `
            -Activity 'Processing...' `
            -Status "($i of $total) [$('{0:N0}' -f (($i/$total)*100))%] FOLDER: $folder" `
            -CurrentOperation "FILE: $file" `
            -PercentComplete (($i/$total)*100)
        $i++
    }
    
    
    
    

    
    
    $null = subst $drive /d
    $subst = $false
    if ($mail.length -gt 240) {
        $path = Split-Path $mail
        subst $drive $path
        $subst = $true
        rv path
        $mail = Join-Path $drive $(Split-Path $mail -Leaf)
    }

    
    try {
        $msg = $Outlook.CreateItemFromTemplate($mail)
    } catch {
        try {
            
            

            
            
            $type = 2
            
            
            $text = $null
            $text = cmd /c "type `"$mail`" 2>&1"
            if ($text -match 'The system cannot find') { Throw 'Unable to process. Probably due to strange characters in the filename.' }
            0..$($text.count-1) | % {$text[$_] = -join([string[]]$text[$_] | % {[char[]]$_} | ? {$_})}
            
            
            $subject = $null
            $subject = @($text | ? {$_ -match '(?:subject|emne): '})[0] -replace '^.*(?:subject|emne): '
            
            
            $attachment = $false
            $attached = $text | ? {$_ -match 'X-MS-Has-Attach: yes'}
            if ($attached) {
                $attached = 'A'
                $attachment = $true
            }

            
            $from = $null
            $from = @($text | ? {$_ -match '(?:fra|from): '})[0] -replace '^.*(?:fra|from): '
            $from = $from.Trim()
            if ($from -match '^\<') {
                $from = $from -replace '\<|\>'
            } elseif ($from -match '^\[') {
                $from = $from -replace '\[|\]'
            } elseif ($from -match '\[') {
                $from = $from -replace '^([^\[]+) \[.*$', '$1' -replace '"'
            } else {
                $from = $from -replace '^([^\<]+) <.*$', '$1' -replace '"'
            }
            $from = $from -replace '\s+$'
            $from = Remove-InvalidFileNameChars $from
            $from = ($from.split() | ? {$_}) -join ' '
            
            

            
            $date = $null
            $date = ($text | ? {$_ -match 'date: '} | select -f 1) -replace '^.*date: '
            try {
                $day = Get-Date $date -f yyyy-MM-dd
                $date = ($date -replace '^.*(\d\d:\d\d:\d\d).*$', '$1').Replace(':', '.')
                $date = "$day $date"
            } catch { $date = $null }
            if (!$date) {
                Write-Host "Date Error: $file" -ForegroundColor Red
                $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
                "filename: $mail" >> "$env:temp\MTFerror.txt"
                'Could not get DATE information' >> "$env:temp\MTFerror.txt"
                '' >> "$env:temp\MTFerror.txt"
            }
        } catch {
            Write-Host "Skipping: $file" -ForegroundColor Yellow
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            $error[0] >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
            
            

            if ($subst) {
                subst $drive /d
            }

            continue
        }
    }
    
    
    if ($type -eq 1) {
        
        $subject = Remove-InvalidFileNameChars $msg.Subject

        
        
        
        $attachment = $false
        try {
            
            
            
            $attached = $msg.Attachments | % {if ($_.filename) {$_.filename} elseif ($_.displayname -eq 'Picture (Device Independent Bitmap)') {'image000.jpg'} else {'?'}}
        } catch {
            Write-Host "Attachments Error: $file" -ForegroundColor Red
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            "attached: $attached" >> "$env:temp\MTFerror.txt"
            $error[0] >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
        }
        if ($attached) {
            $attached = ($attached | % {if ($_ -match '^image[0-9]{3}.[a-zA-Z]{3,4}$') {'.img'} else {$_}} | % {if ($_ -match '\.') {$_.substring($_.lastindexof('.') + 1).ToLower()} else {'..'}} | ? {$_} | select -Unique | sort) -join ','
            $attachment = $true
        }

        
        $from = $null
        $from = Remove-InvalidFileNameChars $msg.SenderName
    
        
        
        
        
    
        
        
        $date = $null
        $date = Get-Date $msg.SentOn -f 'yyyy-MM-dd HH.mm.ss'
        if (!$date) {
            Write-Host "Date Error: $file" -ForegroundColor Red
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            'Could not get DATE information' >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
        }
    }

    
    $null = $msg | % {
        while (Release-Ref $_) {
            Release-Ref $_
        }
    }

    
    if ($format -eq 1) {
        $basename = ''
        $basename += "$subject "
        if ($attachment) { $basename += "[$attached]" }
        if ($to) {
            $basename += "[»$to][$date]"
        } else {
            $basename += "[$from][$date]"
        }
    } else {
        $basename = ''
        if ($to) {
            $basename += "[$date][»$to]"
        } else {
            $basename += "[$date][$from]"
        }
        if ($attachment) { $basename += "[$attached]" }
        $basename += " $subject"
    }

    
    
    $num = 1
    $TargetPath = Split-Path $mail
    $ext = '.msg'
    $newname = Join-Path $TargetPath ($basename + $ext)
	while (Test-Path -LiteralPath $newname) {
        $newname = Join-Path $TargetPath $($basename + "-$num" + $ext)
        $num++
	}
    rv TargetPath
    
    
    try {
        mv -LiteralPath $mail $newname
    } catch {
        Write-Host "Rename Error: $mail" -ForegroundColor Red
        $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
        "filename: $mail" >> "$env:temp\MTFerror.txt"
        "new name: $newname" >> "$env:temp\MTFerror.txt"
        $error[0] >> "$env:temp\MTFerror.txt"
        '' >> "$env:temp\MTFerror.txt"
    }

    
    if ($subst) {
        subst $drive /d
    }
}


$null = subst $drive /d


$null = $Outlook | % {
    while (Release-Ref $_) {
        Release-Ref $_
    }
}

Write-Host 'Done!'
Read-Host 'Press Enter to continue...'


