


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






