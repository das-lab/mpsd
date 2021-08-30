function Get-ADSIObject {  
    	
    [cmdletbinding(DefaultParameterSetName='SAM')]
    Param(
        [Parameter( Position=0,
                    Mandatory = $true,
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
                Throw "Using the Credential parameter requires a valid Path parameter"
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