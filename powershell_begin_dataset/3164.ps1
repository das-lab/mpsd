







if (-not (Get-Module -Name Microsoft.Lync.Model)) 
{
    try 
        {
            Import-Module -Name (Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Microsoft Office 2013\LyncSDK\Assemblies\Desktop\Microsoft.Lync.Model.dll") -ErrorAction Stop
        }
    catch 
        {
            Write-Warning "Microsoft.Lync.Model not available, download and install the Lync 2013 SDK http://www.microsoft.com/en-us/download/details.aspx?id=36824"
            break
        }
}

Function Get-SkypeStatus{



    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Email address to verify the status of.")]
        [string]$email,

        [Parameter(Mandatory=$false,
        HelpMessage="Input file to read email addresses from.")]
        [string]$inputFile,

        [Parameter(Mandatory=$false,
        HelpMessage="Output file to write valid emails to.")]
        [string]$outputFile,

        [Parameter(Mandatory=$false,
        HelpMessage="The number of times to check for an email's status - Default:1")]
        [string]$attempts,

        [Parameter(Mandatory=$false,
        HelpMessage="Delay to use - Helpful with large lists")]
        [string]$delay
    )

    
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()
    }
    catch
    {
        Write-Host "`nYou need to have Skype open and signed in first"
        break
    }

    
    if(($email.Length -eq 0) -and ($inputFile.Length -eq 0))
    {
        Get-Help Get-SkypeStatus
        break
    }

    
    $TempTblUsers = New-Object System.Data.DataTable 
    $TempTblUsers.Columns.Add("Email") | Out-Null
    $TempTblUsers.Columns.Add("Title") | Out-Null
    $TempTblUsers.Columns.Add("Full Name") | Out-Null
    $TempTblUsers.Columns.Add("Status") | Out-Null
    $TempTblUsers.Columns.Add("Out Of Office") | Out-Null
    $TempTblUsers.Columns.Add("Endpoints") | Out-Null

    
    if ($attempts.Length -eq 0){$attempts = 1}

    
    if($inputFile)
        {
           foreach($line in (Get-Content $inputFile))
           {
            Get-SkypeStatus -email $line -attempts $attempts
            if ($delay -ne $null){sleep $delay}
           }
        }

    
    for ($i=1; $i -le $attempts; $i++)
    {
        
        if ($email.Length -gt 0){
            try
            {
                $contact = $client.ContactManager.GetContactByUri($email)                
            }
            catch
            {
                Write-Verbose "Failed to find Contact $email"
                break
            }
        }
        else{break}

        
        $convo = $client.ConversationManager.AddConversation()
        if($contact)
        {
            $convo.AddParticipant($contact) | Out-Null
        }
        else{break}

        
        if(($contact.GetContactInformation('Availability') -gt '0') -or ([string]$contact.GetContactInformation('Title')))
        {
            
            $numbers = ""
            $phones = $contact.GetContactInformation('ContactEndpoints')
            $phones | foreach {if ($_.Uri -like "tel:*") {if ($_.Type -eq "WorkPhone"){$numbers += "Work: "+$_.Uri+" "} elseif ($_.Type -eq "MobilePhone"){$numbers += "Mobile: "+$_.Uri+" "}}}
            
            
            $TempTblUsers.Rows.Add([string]$email,[string]$contact.GetContactInformation('Title'),[string]$contact.GetContactInformation('DisplayName'),$contact.GetContactInformation('Activity'),[string]$contact.GetContactInformation('IsOutOfOffice'),$numbers) | Out-Null

        }
        
        $convo.End() | Out-Null
        
        
        if($outputFile)
        {
         $TempTblUsers | Export-Csv -Path $outputFile -Append
        }
    }
    return $TempTblUsers
}

Function Get-SkypeLoginURL{


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
        HelpMessage="The domain name to lookup.")]
        [string]$domain
    )

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    

    $discoDomain = 'lyncdiscover.'+$domain
    $accessDomain = 'access.'+$domain
    $meetDomain = 'meet.'+$domain
    $dialinDomain = 'dialin.'+$domain

    try{($disco = Resolve-DnsName $discoDomain -ErrorAction Stop -Verbose:$false | select Name | Select-Object -First 1)|Out-Null}catch{}
    try{($access = Resolve-DnsName $accessDomain -ErrorAction Stop -Verbose:$false | select Name | Select-Object -First 1)|Out-Null}catch{}
    try{($meet = Resolve-DnsName $meetDomain -ErrorAction Stop -Verbose:$false | select Name | Select-Object -First 1)|Out-Null}catch{}
    try{($dialin = (Resolve-DnsName $dialinDomain -ErrorAction Stop -Verbose:$false | select Name | Select-Object -First 1))|Out-Null}catch{}


    

    if($disco.length -eq 0){Write-Verbose -Message "Lyncdiscover record not found"}
    else{
        $lyncURL = "https://lyncdiscover."+$domain
        $webclient = new-object System.Net.WebClient
        try{
            $webpage = $webclient.DownloadString($lyncURL)
            $FullLyncServer = "https://"+($webpage.Split('{')[3].Split('"')[3].Split("/")[2])+"/WebTicket/WebTicketService.svc/Auth"
            Write-Verbose -Message ("Lyncdiscover Authentication Endpoint Identified - "+$FullLyncServer)
            return $FullLyncServer
        }
        catch {Write-Verbose -Message "The AutoDiscover URL doesn't appear to work"}
    }
    
    if($dialin.length -eq 0){Write-Verbose -Message "Dialin record not found"}
    else{Write-Verbose -Message ("Dialin Authentication Endpoint Identified - https://dialin."+$domain+"/abs/"); return "https://dialin."+$domain+"/abs/"}
    

    
    if($meet.length -eq 0){Write-Verbose -Message "Meet record not found"}
    
    else{Write-Verbose -Message "Meet Authentication Endpoint Identified"; return "https://meet."+$domain+""}

    if($access.length -eq 0){Write-Verbose -Message "Access record not found"}
    
    else{Write-Verbose -Message "Access Authentication Endpoint Identified"; return "https://access."+$domain+""}
            
    Write-Host "`nThe domain does not appear to support any external Skype/Lync authentication endpoints" -ForegroundColor Red; break


    return $Returnurl
        
}

Function Invoke-SkypeLogin{


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
        HelpMessage="Email address to login as.")]
        [string]$email,

        [Parameter(Mandatory=$false,
        HelpMessage="Username to login as.")]
        [string]$username,

        [Parameter(Mandatory=$true,
        HelpMessage="Password to use.")]
        [string]$password,

        [Parameter(Mandatory=$false,
        HelpMessage="Domain name to login with.")]
        [string]$domain,

        [Parameter(Mandatory=$false,
        HelpMessage="The url to authenticate against.")]
        [string]$url
    )

    if ($domain.Length -eq 0){$domain = $email.Split("@")[1]}
    
    if($url.Length -eq 0){
        $emailDomain = $email.Split("@")[1]
        $url = Get-SkypeLoginURL -domain $emailDomain
    }

    if($url -like '*lync.com*'){Write-Host 'Microsoft Managed Skype for Business instance - HTTP NTLM Auth currently not supported' -ForegroundColor Red; break}

    if($username.Length -eq 0){$username = $email.Split("@")[0]}


    
    


    


    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

    
    

    $req = [system.Net.WebRequest]::Create($url)
    $req.Credentials = new-object System.Net.NetworkCredential($username, $password, $domain)
    try {
        $res = $req.GetResponse()
        } catch [System.Net.WebException] {
        $res = $_.Exception.Response
        }
    if ([int]$res.StatusCode -eq '403'){Write-Host 'Authentication Successful: '$domain\$username' - '$password -ForegroundColor Green}
    else{Write-Host 'Authentication Failure: '$domain\$username' - '$password -ForegroundColor Red}

    
      

    

}

Function Invoke-SendSkypeMessage{


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Email address to send the message to.")]
        [string]$email,

        [Parameter(Mandatory=$true,
        HelpMessage="Message to send.")]
        [string]$message,

        [Parameter(Mandatory=$false,
        HelpMessage="File of email addresses to send the message to.")]
        [string]$inputFile
    )
    
    
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()
    }
    catch
    {
        Write-Host "`nYou need to have Skype open and signed in first"
        break
    }

    
    if(($email.Length -eq 0) -and ($inputFile.Length -eq 0))
    {
        
        Get-Help Invoke-SendSkypeMessage
        break
    }

    
    if($inputFile)
    {
        foreach($line in (Get-Content $inputFile))
        {
            if ($line.Length -ne $null){Invoke-SendSkypeMessage -email $line -message $message}
        }
        break
    }
        
    
    $msg = New-Object "System.Collections.Generic.Dictionary[Microsoft.Lync.Model.Conversation.InstantMessageContentType, String]"

    
    $msg.Add(1,$message)

    
    try 
    {
        $contact = $client.ContactManager.GetContactByUri($email) 
    }
    catch
    {
        Write-Host "`nFailed to lookup Contact"$email
        break
    }

    
    $convo = $client.ConversationManager.AddConversation()
    $convo.AddParticipant($contact) | Out-Null

    
    $imModality = $convo.Modalities[1]
    
    $imModality.BeginSendMessage($msg, $null, $imModality) | Out-Null
    
    $convo.End() | Out-Null

    Write-Host "Sent the following message to "$email":`n"$message
}


Function Invoke-SendGroupSkypeMessage{


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Email addresses to send the message to.")]
        [string]$emails,

        [Parameter(Mandatory=$false,
        HelpMessage="Input file to read email addresses from.")]
        [string]$inputFile,

        [Parameter(Mandatory=$true,
        HelpMessage="Message to send.")]
        [string]$message
    )

    
    if (($emails -eq $null) -and ($inputFile -eq $null)){break}
    
    
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()        
    }
    catch
    {
        Write-Host "`nYou need to have Skype open and signed in first"
        break
    }
        
    
    $msg = New-Object "System.Collections.Generic.Dictionary[Microsoft.Lync.Model.Conversation.InstantMessageContentType, String]"

    
    $msg.Add(1,$message)

    
    $count = 0

    if($inputFile)
    {
        
        $convo = $client.ConversationManager.AddConversation()
        foreach($email in (Get-Content $inputFile))
        {
            
            try 
            {
                $contact = $client.ContactManager.GetContactByUri($email.Replace(" ",""))
                $convo.AddParticipant($contact) | Out-Null
                $count += 1
            }
            catch
            {
                Write-Host "`nFailed to lookup Contact"$email
            }            
        }
    }
    else
    {
        
        $convo = $client.ConversationManager.AddConversation()
        
        $emailSplit = $emails.Split(',')
        foreach ($email in $emailSplit)
        {
            try 
            {
                $contact = $client.ContactManager.GetContactByUri($email.Replace(" ",""))
                $convo.AddParticipant($contact) | Out-Null
                $count += 1
            }
            catch
            {
                Write-Host "`nFailed to lookup Contact"$email
            }
            
        }        
     }

    
    $imModality = $convo.Modalities[1]
    
    $imModality.BeginSendMessage($msg, $null, $imModality) | Out-Null
    $convo.End() | Out-Null

    Write-Host "Sent the following message to"$count "users:`n"$message
}


Function Get-SkypeFederation{


    

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Domain to verify the status of.")]
        [string]$domain
    )

    
    $TempTblDomain = New-Object System.Data.DataTable 
    $TempTblDomain.Columns.Add("Domain") | Out-Null
    $TempTblDomain.Columns.Add("MS=MS*") | Out-Null
    $TempTblDomain.Columns.Add("_sip._tcp") | Out-Null
    $TempTblDomain.Columns.Add("_sip._tls") | Out-Null
    $TempTblDomain.Columns.Add("_sipfederationtls._tcp") | Out-Null

    $txt = try{(Resolve-DnsName -Type TXT $domain -ErrorAction Stop | select Strings)}catch{}
    $sip = try{Resolve-DnsName -Type SRV "_sip._tcp.$domain" -ErrorAction Stop}catch{}
    $siptls = try{Resolve-DnsName -Type SRV "_sip._tls.$domain" -ErrorAction Stop}catch{}
    $sipFed = try{Resolve-DnsName -Type SRV "_sipfederationtls._tcp.$domain" -ErrorAction Stop}catch{}

    $ms = "False"
    $sipTrue = "False"
    $siptlsTrue = "False"
    $sipFedTrue = "False"

    if($txt -contains "MS=" -or "ms=")
    {
        $ms = "True"
    }
    if($sip)
    {
        $sipTrue = "True"
    }
    if($siptls)
    {
        $siptlsTrue = "True"
    }
    if($sipFed)
    {
        $sipFedTrue = "True"
    }

    
    $TempTblDomain.Rows.Add([string]$domain,[string]$ms,[string]$sipTrue,[string]$siptlsTrue,[string]$sipFedTrue) | Out-Null
    return $TempTblDomain   
}


function Get-SkypeContacts{



    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="The contact group to list.")]
        [string]$group
    )

    
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()
    }
    catch
    {
        Write-Host "`nYou need to have Skype open and signed in first"
        break
    }

    if ($group.length -ne 0){
            $groups = $client.ContactManager.Groups
            foreach ($g in $groups){
                if ($g.Name -eq $group) {
                    foreach ($contact in $g){
                        foreach ($email in $contact.GetContactInformation('email')){Get-SkypeStatus $email}
                    }
                }
            }
    }
    else{
        $groups = $client.ContactManager.Groups
        foreach ($g in $groups){ 
            foreach ($contact in $g){
                foreach ($email in $contact.GetContactInformation('email')){Get-SkypeStatus $email}
            }
        }
    }
}

function Get-SkypeDomainUsers{



    
    try
    {
        $client = [Microsoft.Lync.Model.LyncClient]::GetClient()
    }
    catch
    {
        Write-Host "`nYou need to have Skype open and signed in first"
        break
    }

    

    
    
    

    $letters = "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
    

    
    $TempTblUris = New-Object System.Data.DataTable 
    $TempTblUris.Columns.Add("URI") | Out-Null

    
    foreach($letter in $letters){
        $searcher = $client.ContactManager.BeginSearch($letter, $null, $null)
        $end = $client.ContactManager.EndSearch($searcher)

        $uris += ($end | ForEach-Object {$_.Contacts | ForEach-Object {$TempTblUris.Rows.Add([string]$_.Uri)}})

    }

    
    $finalTable = $TempTblUris | sort-object -Property uri -Unique

    
    foreach ($uri in $finalTable){Get-SkypeStatus -email ([string]$uri.URI.split(":")[1])}
        
    
}
