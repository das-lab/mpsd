
































function Get-FolderAccess {
    [CmdletBinding()]
    param (
        [string]$Path = $PWD,
        [int]$Depth = 1,
        [switch]$ExpandGroups = $false,
        [switch]$ShowAllAccounts = $false,
        [switch]$DontOpen = $false,
        [ValidateSet('Console','HTML','Excel')]
        $ReportFormat = 'Console'
    )

function Get-FolderACL ([string]$Path, [string]$Domain) {
    
    
    try {
        $CurrentACL = Get-Acl -Path $Path
    } catch {
        Write-Warning "Could not Get-Acl for $Path"
        continue
    }

    
    
    
    

    
    
    






    $CurrentACL.Access |
        Where-Object {
            
            $_.FileSystemRights.ToString() -notmatch '^-?\d{5}'
        } |
        ForEach-Object {
            
            $UserAccount = $_.IdentityReference.ToString().Substring($_.IdentityReference.ToString().IndexOf('\') + 1)
            $IdentityReference = $_.IdentityReference.ToString()
            $FileSystemRights  = $_.FileSystemRights.ToString() 
            $InheritanceFlags  = $_.InheritanceFlags.ToString() 
            $PropagationFlags  = $_.PropagationFlags.ToString() 
            $AccessControlType = $_.AccessControlType.ToString() 
            
            

            
            
            
            if ($UserAccount -match '(domain )?administrators') {
                $CurrentACL.AddAccessRule($_)
            } else {
                try {
                    $dn = ([adsisearcher]"samaccountname=$($UserAccount)").FindOne().Path.Substring(7)
                } catch {
                    $dn = $null
                }
                Get-Member $dn |
                    Where-Object { 
                        $_ -notmatch 'S-\d-\d-\d{1,}'
                    } |
                    ForEach-Object {
                        $IdentityReference = ([adsi]"LDAP://$_").samaccountname.ToString()
                        $CurrentACLPermission = $IdentityReference, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType
                        
                        try {
                            $CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission
                            $CurrentACL.AddAccessRule($CurrentAccessRule)
                        } catch {
                            Write-Host "Error: `$CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission" -ForegroundColor Red
                            "Error: `$CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission" >> $logFile
                        }
                    }
            }
        }
    Write-Output $CurrentACL | select * -Unique
}

function Get-Member ($GroupName) {
    $Grouppath = "LDAP://" + $GroupName
    $GroupObj = [ADSI]$Grouppath





    $users = foreach ($member in $GroupObj.Member) {
        $UserPath = "LDAP://" + $member
        $UserObj = [ADSI]$UserPath

        if ($UserObj.groupType.Value -eq $null) { 





            $member
        } else { 
            Get-Member -GroupName $member
        }
    }
    $users | select -Unique
}

function acltohtml ($Path, $colACLs, $ShowAllAccounts, $Domain) {
$saveDir = "$env:TEMP\Network Access"
if (!(Test-Path $saveDir)) {
    $null = mkdir "$saveDir\Logs"
}
$time = Get-Date -Format 'yyyyMMddHHmmss'
$saveName = "Network Access $time"
$report = "$saveDir\$saveName.html"
'' > $report
$result = New-Object System.Text.StringBuilder


function drawDirectory ($directory, $Domain) {
    $dirHTML = New-Object System.Text.StringBuilder

    $null = $dirHTML.Append('
        <div class="')

    if ($directory.level -eq 0) {
        $null = $dirHTML.Append('he0_expanded')
    } else {
        $null = $dirHTML.Append('he' + $directory.level)
    }

    $null = $dirHTML.Append('"><span class="sectionTitle" tabindex="0">Folder ' + $directory.Folder + '</span></div>
        <div class="container">
        <div class="he4i">
        <div class="heACL">
        <table class="info3" cellpadding="0" cellspacing="0">
        <thead>
        <th scope="col"><b>Owner</b></th>
        </thead>
        <tbody>')

    $null = $dirHTML.Append('<tr><td>' + $itemACL.Owner + '</td></tr>
        <tr>
        <td>
        <table>
        <thead>
        <th>User</th>
        <th>Control</th>
        <th>Privilege</th>
        </thead>
        <tbody>')

    $itemACL = $directory.ACL
    if ($itemACL.AccessToString -ne $null) {
        
        $acls = $itemACL.AccessToString.split("`n") | select -Unique | ? {$_ -notmatch '  -\d{9}$'} | sort
    }
    
    if (!$ShowAllAccounts) {
        $acls = $acls -match "^$domain\\" -notmatch '\\MAM-|\\\w{2}-\w{3}\d-\w{3}|\\a-|\\-svc-'
    }
    
    $index = 0
    $total = $acls.Count
    $starttime = $lasttime = Get-Date
    foreach ($acl in $acls) {
        
        $temp = [regex]::split($acl, '\s+(?=Allow|Deny)|(?<=Allow|Deny)\s+')  

        if ($debug) {
            Write-Host "ACL(" $temp.gettype().name ")[" $temp.length "]: " $temp
        }

        if ($temp.count -eq 1) {
            continue
        }

        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "Check if account is disabled $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "USER: $($temp[0])"
            PercentComplete = $index / $total * 100
            id = 2
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        if ($temp[0] -match "^$domain\\") {
            if ((([adsi]([adsisearcher]"samaccountname=$($temp[0] -replace "^$domain\\")").findone().path).useraccountcontrol[0] -band 2) -ne 0) {
                
                $temp[0] += ' - DISABLED'
            }
        }

        $null = $dirHTML.Append('<tr><td>' + $temp[0] + '</td><td>' + $temp[1] + '</td><td>' + $temp[2] + '</td></tr>')
    }

    $null = $dirHTML.Append('</tbody>
        </table>
        </td>
        </tr>
        </tbody>
        </table>
        </div>
        </div>
        <div class="filler"></div>
        </div>')

    return $dirHTML.ToString()
}


$null = $result.Append(@"
<html dir="ltr" xmlns:v="urn:schemas-microsoft-com:vml" gpmc_reportInitialized="false">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-16" />
<title>Access Control List for $Path</title>
<!-- Styles -->
<style type="text/css">
    body    { background-color:
    table   { font-size:100%; table-layout:fixed; width:100%; }
    td,th   { overflow:visible; text-align:left; vertical-align:top; white-space:normal; }
    .title  { background:
    .he0_expanded    { background-color:
    .he1_expanded    { background-color:
    .he1h_expanded   { background-color: 
    .he1    { background-color:
    .he2    { background-color:
    .he3    { background-color:
    .he4    { background-color:
    .he4h   { background-color:
    .he4i   { background-color:
    .he5    { background-color:
    .he5h   { background-color:
    .he5i   { background-color:
    DIV .expando { color:
    .he0 .expando { font-size:100%; }
    .info, .info3, .info4, .disalign  { line-height:1.6em; padding:0px,0px,0px,0px; margin:0px,0px,0px,0px; }
    .disalign TD                      { padding-bottom:5px; padding-right:10px; }
    .info TD                          { padding-right:10px; width:50%; }
    .info3 TD                         { padding-right:10px; width:33%; }
    .info4 TD, .info4 TH              { padding-right:10px; width:25%; }
    .info TH, .info3 TH, .info4 TH, .disalign TH { border-bottom:1px solid 
    .subtable, .subtable3             { border:1px solid 
    .subtable TD, .subtable3 TD       { padding-left:10px; padding-right:5px; padding-top:3px; padding-bottom:3px; line-height:1.1em; width:10%; }
    .subtable TH, .subtable3 TH       { border-bottom:1px solid 
    .subtable .footnote               { border-top:1px solid 
    .subtable3 .footnote, .subtable .footnote { border-top:1px solid 
    .subtable_frame     { background:
    .subtable_frame TD  { line-height:1.1em; padding-bottom:3px; padding-left:10px; padding-right:15px; padding-top:3px; }
    .subtable_frame TH  { border-bottom:1px solid 
    .subtableInnerHead { border-bottom:1px solid 
    .explainlink            { color:
    .explainlink:hover      { color:
    .spacer { background:transparent; border:1px solid 
    .filler { background:transparent; border:none; color:
    .container { display:block; position:relative; }
    .rsopheader { background-color:
    .rsopname { color:
    .gponame{ color:
    .gpotype{ color:
    
    
    
    
    
    @media print {
        
        body    { color:
        .title  { color:
        .he0_expanded    { color:
        .he1h_expanded   { color:
        .he1_expanded    { color:
        .he1    { color:
        .he2    { color:
        .he3    { color:
        .he4    { color:
        .he4h   { color:
        .he4i   { color:
        .he5    { color:
        .he5h   { color:
        .he5i   { color:
        }
        v\:* {behavior:url(
</style>
</head>
<body>
<table class="title" cellpadding="0" cellspacing="0">
<tr><td colspan="2" class="gponame">Access Control List for $Path</td></tr>
<tr>
<td id="dtstamp">Data obtained on: $(Get-Date)</td>
<td><div id="objshowhide" tabindex="0"></div></td>
</tr>
</table>
<div class="filler"></div>
'<div class="gposummary">'
"@)


    $index = 0
    $total = $colACLs.Count
    $starttime = $lasttime = Get-Date
    foreach ($acl in $colACLs) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "acltohtml $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $($acl.folder)"
            PercentComplete = $index / $total * 100
            id = 1
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        $null = $result.Append((drawDirectory -directory $acl -domain $Domain))
    }

    $null = $result.Append('</div></body></html>')

    $result.ToString() > $report

    if (!$DontOpen) {
        . $report
    }

    $report
}

function acltovariable ($colACLs, $ShowAllAccounts, [string]$Domain) {
    $index = 0
    $total = $colACLs.Count
    $starttime = $lasttime = Get-Date
    foreach ($directory in $colACLs) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "acltovariable $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $($directory.folder)"
            PercentComplete = $index / $total * 100
            id = 1
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        $itemACL = $directory.ACL
        $acls = $null

        if ($itemACL.AccessToString -ne $null) {
            
            $acls = $itemACL.AccessToString.split("`n") | select -Unique |  sort
        }
        
        if (!$ShowAllAccounts) {
            $acls = $acls -match "^$domain\\" -notmatch '\\MAM-|\\\w{2}-\w{3}\d-\w{3}|\\a-|\\-svc-'
        }

        $index2 = 0
        $total2 = $acls.Count
        $starttime2 = $lasttime2 = Get-Date
        foreach ($acl in $acls) {
            
            $temp = [regex]::split($acl, '\s+(?=Allow|Deny)|(?<=Allow|Deny)\s+')

            if ($temp.count -eq 1) {
                continue
            }

            $index2++
            $currtime2 = (Get-Date) - $starttime2
            $avg2 = $currtime2.TotalSeconds / $index2
            $last2 = ((Get-Date) - $lasttime2).TotalSeconds
            $left2 = $total2 - $index2
            $WrPrgParam2 = @{
                Activity = (
                    "Check if account is disabled $(Get-Date -f s)",
                    "Total: $($currtime2 -replace '\..*')",
                    "Avg: $('{0:N2}' -f $avg2)",
                    "Last: $('{0:N2}' -f $last2)",
                    "ETA: $('{0:N2}' -f ($avg2 * $left2 / 60))",
                    "min ($([string](Get-Date).AddSeconds($avg2*$left2) -replace '^.* '))"
                ) -join ' '
                Status = "$index2 of $total2 ($left2 left) [$('{0:N2}' -f ($index2 / $total2 * 100))%]"
                CurrentOperation = "USER: $($temp[0])"
                PercentComplete = $index2 / $total2 * 100
                id = 2
            }
            Write-Progress @WrPrgParam2
            $lasttime2 = Get-Date

            
            if ($temp[0] -match "^$domain\\") {
                if ((([adsi]([adsisearcher]"samaccountname=$($temp[0] -replace "^$domain\\")").findone().path).useraccountcontrol[0] -band 2) -ne 0) {
                    $temp[0] += ' - DISABLED'
                }
            }

            New-Object psobject -Property @{
                Folder = $directory.Folder
                Name   = $temp[0]
                Access = $temp[1]
                Rights = $temp[2]
            }
        }
    }
}

function acltoexcel ($colACLs, $ShowAllAccounts) {
    $saveDir = "$env:TEMP\Network Access"
    if (!(Test-Path $saveDir)) {$null = mkdir "$saveDir\Logs"}
    $time = Get-Date -Format 'yyyyMMddHHmmss'
    $saveName = "Network Access $time"
    $report = "$saveDir\$saveName.csv"
    '' > $report

    acltovariable $colACLs $ShowAllAccounts | epcsv $report -NoTypeInformation

    $xl = New-Object -ComObject 'Excel.Application'
    $wb = $xl.workbooks.open($report)
    $xlOut = $report.Replace('.csv', '')
    $ws = $wb.Worksheets.Item(1)
    $range = $ws.UsedRange 
    [void]$range.EntireColumn.Autofit()
    $wb.SaveAs($xlOut, 51)
    $xl.Quit()
    
    function Release-Ref ($ref) {
        ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    
    $null = $ws, $wb, $xl | % {Release-Ref $_}

    del $report

    if (!$DontOpen) {
        . ($report -replace '\.csv$', '.xlsx')
    }

    $report -replace '\.csv$', '.xlsx'
}

function SIDtoName ([string]$SID) {
    ([System.Security.Principal.SecurityIdentifier]($SID)).Translate([System.Security.Principal.NTAccount]).Value
}



    
    $domain = $env:USERDOMAIN

    if ($Path.EndsWith('\')) {
        $Path = $Path.TrimEnd('\')
    }

    $allowedLevels = 6

    if ($Depth -gt $allowedLevels -or $Depth -lt -1) {
        throw 'Level out of range.'
    }
    
    if (!$ExpandGroups) {
        $ShowAllAccounts = $true
    }

    $colFolders = New-Object System.Collections.ArrayList

    if ($Depth -eq 0) {
        
        
    } elseif ($Depth -ne -1) {
        1..$Depth | % {
            
            Get-ChildItem -Path ($Path + ('\*' * $_)) -ErrorVariable GciError -ErrorAction SilentlyContinue | ? {$_.psiscontainer} | sort FullName | % {
                $null = $colFolders.Add($_.FullName)
            }
        }
    }

    if ($GciError) {
        $GciError | % {Write-Warning $_.exception.message}
    }
    
    
    $colACLs = New-Object System.Collections.ArrayList

    $myobj = New-Object psobject -Property @{
        Folder = $Path
        ACL = ''
        Level = 0
    }

    if (!$ExpandGroups) {
        $ShowAllAccounts = $true
        $myobj.ACL = Get-Acl -Path $Path
    } else {
        $myobj.ACL = Get-FolderACL -Path $Path -Domain $domain
    }

    $null = $colACLs.Add($myobj)

    $index = 0
    $total = $colFolders.Count
    $starttime = $lasttime = Get-Date
    
    foreach ($folder in $colFolders) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "Get-FolderAccess $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $folder"
            PercentComplete = $index / $total * 100
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        
        $matches = (([regex]'\\').matches($folder.substring($Path.length, $folder.length - $Path.length))).count

        $myobj = New-Object psobject -Property @{
            Folder = $folder
            ACL = ''
            Level = $matches - 1
        }
        
        if (!$ExpandGroups) {
            $myobj.ACL = Get-Acl -Path $folder
        } else {
            $myobj.ACL = Get-FolderAcl -Path $folder -Domain $domain 
        }

        $null = $colACLs.Add($myobj)
    }

    
    
    $colACLs = $colACLs | sort folder

    
    switch ($ReportFormat) {
        'Console' {acltovariable -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts -Domain $domain}
        'HTML'    {acltohtml -Path $Path -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts -Domain $domain}
        'Excel'   {acltoexcel -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts}
    }
}
