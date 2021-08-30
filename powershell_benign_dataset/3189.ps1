function Get-ADMigratedSourceObject {
    	
    [cmdletbinding()]
    param(
        [Parameter( Position=0,
                    Mandatory = $true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName='SAM')]
        [string[]]$samAccountName = "*",

        [string]$Path = $env:USERDOMAIN,

        [string]$SourcePath,

        [string]$ObjectCategory,

        [validateset("PSObject","DirectoryEntry","SearchResult")]
        [string]$As = "PSObject",

        [switch]$Simple,

        [string[]]$Property = $Null,

        [System.Management.Automation.PSCredential]$Credential,

        [System.Management.Automation.PSCredential]$SourceCredential
    )
    Begin
    {

        
        function Get-ADSIObject {
            [cmdletbinding(DefaultParameterSetName='SAM')]
            Param(
                [Parameter( Position=0,
                            ValueFromPipeline=$true,
                            ValueFromPipelineByPropertyName=$true,
                            ParameterSetName='SAM')]
                [string[]]$samAccountName = "*",

                [Parameter( Position=1,
                            ParameterSetName='SAM')]
                [string[]]$ObjectCategory = "*",

                [Parameter( ParameterSetName='Query',
                            Mandatory = $true )]
                [string]$Query = $null,

                [string]$Path = $Null,

                [string[]]$Property = $Null,

                [int]$Limit,

                [string]$SearchRoot,

                [System.Management.Automation.PSCredential]$Credential,

                [validateset("PSObject","DirectoryEntry","SearchResult")]
                [string]$As = "PSObject"
            )

            Begin 
            {
                
                $Params = @{
                    TypeName = "System.DirectoryServices.DirectoryEntry"
                    ErrorAction = "Stop"
                }

                
                    if($Path){

                        if($Path -notlike "^LDAP")
                        {
                            $Path = "LDAP://$Path"
                        }
            
                        $Params.ArgumentList = @($Path)

                        
                        if($Credential)
                        {
                            $Params.ArgumentList += $Credential.UserName
                            $Params.ArgumentList += $Credential.GetNetworkCredential().Password
                        }
                    }
                    elseif($Credential)
                    {
                        Throw "Using the Credential parameter requires a Path parameter"
                    }

                
                    Try
                    {
                        Write-Verbose "Bound parameters:`n$($PSBoundParameters | Format-List | Out-String )`nCreating DirectoryEntry with parameters:`n$($Params | Out-String)"
                        $DomainEntry = New-Object @Params
                    }
                    Catch
                    {
                        Throw "Could not establish DirectoryEntry: $_"
                    }
                    $DomainName = $DomainEntry.name

                
                    $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
                    $Searcher.PageSize = 1000
                    $Searcher.SearchRoot = $DomainEntry
                    if($Limit)
                    {
                        $Searcher.SizeLimit = $limit
                    }
                    if($Property)
                    {
                        foreach($Prop in $Property)
                        {
                            $Searcher.PropertiesToLoad.Add($Prop) | Out-Null
                        }
                    }
                    if($SearchRoot)
                    {
                        if($SearchRoot -notlike "^LDAP")
                        {
                            $SearchRoot = "LDAP://$SearchRoot"
                        }

                        $Searcher.SearchRoot = [adsi]$SearchRoot
                    }

                
                Function Get-ADSIResult
                {
                    [cmdletbinding()]
                    param(
                        [string[]]$Property = $Null,
                        [string]$Query,
                        [string]$As,
                        $Searcher
                    )
            
                    
                        $Results = $null
                        $Searcher.Filter = $Query
                        $Results = $Searcher.FindAll()
            
                    
                        if($As -eq "SearchResult")
                        {
                            $Results
                        }
                    
                        elseif($As -eq "DirectoryEntry")
                        {
                            $Results | ForEach-Object { $_.GetDirectoryEntry() }
                        }
                    
                        else
                        {
                            $Results | ForEach-Object {
                
                                
                                    $object = $_
                                    
                                    [string[]]$properties = ($object.properties.PropertyNames) -split "`r|`n" | Where-Object { $_ } | ForEach-Object { $_.Trim() }
            
                                
                                    if($Property)
                                    {
                                        $properties = $properties | Where-Object {$Property -Contains $_}
                                    }
            
                                
                                    
                                        $hash = @{}
                                        foreach($prop in $properties)
                                        {
                                            $hash.$prop = $null
                                        }
                                        $Temp = New-Object -TypeName PSObject -Property $hash | Select -Property $properties
                        
                                    foreach($Prop in $properties)
                                    {
                                        Try
                                        {
                                            $Temp.$Prop = foreach($item in $object.properties.$prop)
                                            {
                                                $item
                                            }
                                        }
                                        Catch
                                        {
                                            Write-Warning "Could not get property '$Prop': $_"
                                        }   
                                    }
                                    $Temp
                            }
                        }
                }
            }
            Process
            {
                
                    if($PsCmdlet.ParameterSetName -eq 'Query'){
                        Write-Verbose "Working on Query '$Query'"
                        Get-ADSIResult -Searcher $Searcher -Property $Property -Query $Query -As $As
                    }
                    else
                    {
                        foreach($AccountName in $samAccountName)
                        {
                            
                                $QueryArray = @( "(samAccountName=$AccountName)" )
                                if($ObjectCategory)
                                {
                                    [string]$TempString = ( $ObjectCategory | ForEach-Object {"(objectCategory=$_)"} ) -join ""
                                    $QueryArray += "(|$TempString)"
                                }
                                $Query = "(&$($QueryArray -join ''))"
                            Write-Verbose "Working on built Query '$Query'"
                            Get-ADSIResult -Searcher $Searcher -Property $Property -Query $Query -As $As
                        }
                    }
            }
            End
            {
                $Searcher = $null
                $DomainEntry = $null
            }
        }

        
        
        if(-not $SourcePath)
        {

            $DomainsToQueryObjects = Get-ADSIObject -Query "(ObjectClass=trustedDomain)" -Property trustpartner, securityIdentifier -as DirectoryEntry
            $DomainsToQuery = $DomainsToQueryObjects | Select -ExpandProperty trustPartner
            $DomainsHash = @{}
            foreach($Domain in $DomainsToQueryObjects)
            {
                Try
                {
                    $TrustPartner = $null
                    $TrustPartner = $Domain.trustPartner.value

                    $SID = $null
                    $SID = (New-Object System.Security.Principal.SecurityIdentifier($Domain.securityIdentifier[0],0) -ErrorAction Stop).Value

                    $DomainsHash.Add($TrustPartner, $SID)
                }
                Catch
                {
                    Write-Error "Could not find SID for trustPartner $TrustPartner"
                }
            }
            Write-Verbose "Found trusts: $DomainsToQuery"
        }
        else
        {
            $DomainsToQuery = @($SourcePath)
        }

        
            $OldParams = @{} 
            if($SourceCredential)
            {
                $OldParams.Credential = $SourceCredential
            }
            if($as)
            {
                $OldParams.As = $As
            }
            if($Property)
            {
                $OldParams.Property = $Property
                if($Simple)
                {
                    $OldParams.Property += "SamAccountName"
                    $OldParams.Property += "ObjectClass"
                }
            }

        
            $NewParams = @{} 
            if($Credential)
            {
                $NewParams.add('Credential', $Credential)
            }
            if($ObjectCategory)
            {
                $NewParams.add('ObjectCategory',$ObjectCategory)
            } 
    }
    Process
    {
        foreach($account in $samAccountName)
        {
            
            Try
            {
                $newADSIObject = $null
                $newADSIObject = @( Get-ADSIObject -samaccountname $account -Path $Path -Property samaccountname, objectSID, SIDHistory -as DirectoryEntry @NewParams -ErrorAction Stop )
                if(-not $newADSIObject)
                {
                    Write-Warning "No target object found for account $account on path $Path"
                    continue
                }
            }
            Catch
            {
                Write-Error "Error obtaining account $account on path $Path`: $_"
                continue
            }

            foreach($ADSIObject in $newADSIObject)
            {
                
                    $OldSID = $Null
                    $AllSids = @(
                        foreach($Sid in @($ADSIObject.SIDHistory))
                        {
                            Try
                            {
                                $OldSID = (New-Object System.Security.Principal.SecurityIdentifier($Sid,0)).Value
                                Write-Verbose "Found SID '$OldSid'"
                                $OldSID
                            }
                            Catch
                            {
                                Write-Error "Error obtaining SID from account $account on path $Path with sid $($sid | out-string)"
                                Continue
                            }
                        }
                    )

                
                    foreach($sid in $AllSids)
                    {
                        foreach($Domain in $DomainsToQuery)
                        {
                            if($sid -match $DomainsHash.$Domain)
                            {
                                Write-Verbose "Checking '$Domain' for '$sid':"
                                Try
                                {
                                    $Raw = Get-ADSIObject -Path $Domain -Query "(objectSID=$sid)" @OldParams -ErrorAction stop
                                    if($Raw)
                                    {
                                        if($Simple)
                                        {
                                            $Props = @(
                                                @{ label = "SamAccountName"; expression = {$ADSIObject.sAMAccountName.Value} },
                                                @{ label = "SourceSamAccountName"; expression = {$Raw.samaccountname} },
                                                @{ label = "ObjectClass"; expression = {$Raw.ObjectClass[-1]}}
                                                @{ label = "TrustedDomain"; expression = {$Domain} }
                                            )
                                            if($Property)
                                            {
                                                $Props += @($Property | ?{$_ -ne 'SamAccountName'})
                                            }
                                            
                                            $Raw | Select -property $Props
                                        }
                                        else
                                        {
                                            $Raw
                                        }
                                    }
                                }
                                Catch
                                {
                                    Write-Error "Error obtaining sid $sid on path $SourcePath`: $_"
                                    Continue
                                }
                            }
                            else
                            {
                                Write-Verbose "Skipping domain $Domain, sid '$sid' does not match domain sid '$($DomainsHash.$domain)'"
                            }
                        }
                    }
            }
        }
    }
}