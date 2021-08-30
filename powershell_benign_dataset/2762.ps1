



function GetBase64GzippedStream {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [System.IO.FileInfo]$File
)
    
    $memFile = New-Object System.IO.MemoryStream (,[System.IO.File]::ReadAllBytes($File))
        
    
    $memStrm = New-Object System.IO.MemoryStream

    
    $gzStrm  = New-Object System.IO.Compression.GZipStream $memStrm, ([System.IO.Compression.CompressionMode]::Compress)

    
    $gzStrm.Write($memFile.ToArray(), 0, $File.Length)
    $gzStrm.Close()
    $gzStrm.Dispose()

    
    [System.Convert]::ToBase64String($memStrm.ToArray())   
}

function GetName {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$LocalPath
)
    $Start = $LocalPath.LastIndexOf("\") + 1
    $End   = $LocalPath.Length - $Start
    $LocalPath.Substring($Start, $End)    
}

$obj = "" | Select-Object ProfilePath,SID,Name,Script

Get-WmiObject win32_userprofile | ForEach-Object {
    $obj.ProfilePath,$obj.SID,$obj.Script,$obj.Name = $null

    $obj.ProfilePath = $_.LocalPath + "\Documents\WindowsPowershell\Microsoft.Powershell_profile.ps1"
    $obj.SID  = $_.SID
    $obj.Name = GetName $_.LocalPath
    
    if (Test-Path $obj.ProfilePath) {
        
        $obj.Script = GetBase64GzippedStream (Get-Item -Force $obj.ProfilePath)
    }
    $obj
}

"AllUsersAllHosts", "AllUsersCurrentHost", "CurrentUserAllHosts", "CurrentUserCurrentHost" | ForEach-Object {
    $obj.ProfilePath,$obj.SID,$obj.Script,$obj.Name = $null

    $obj.ProfilePath = ($profile.$_)
    $obj.SID  = $null
    $obj.Name = $_
    if (Test-Path $obj.ProfilePath) {
        $obj.Script = GetBase64GzippedStream (Get-Item -Force $obj.ProfilePath)
    }
    $obj
}