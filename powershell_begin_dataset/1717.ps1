function New-ServiceNowIncident{


    Param(

        
        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Caller,

        
        [parameter(Mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ShortDescription,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Description,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$AssignmentGroup,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Comment,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Category,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Subcategory,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$ConfigurationItem,

        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$CustomFields,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential,

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL,

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )

    
    $DefinedIncidentParameters = @('AssignmentGroup','Caller','Category','Comment','ConfigurationItem','Description','ShortDescription','Subcategory')
    $TableEntryValues = @{}
    ForEach ($Parameter in $DefinedIncidentParameters) {
        If ($null -ne $PSBoundParameters.$Parameter) {
            
            $KeyToAdd = Switch ($Parameter) {
                AssignmentGroup     {'assignment_group'; break}
                Caller              {'caller_id'; break}
                Category            {'category'; break}
                Comment             {'comments'; break}
                ConfigurationItem   {'cmdb_ci'; break}
                Description         {'description'; break}
                ShortDescription    {'short_description'; break}
                Subcategory         {'subcategory'; break}
            }
            $TableEntryValues.Add($KeyToAdd,$PSBoundParameters.$Parameter)
        }
    }

    
    If ($null -ne $PSBoundParameters.CustomFields) {
        $DuplicateTableEntryValues = ForEach ($Key in $CustomFields.Keys) {
            If (($TableEntryValues.ContainsKey($Key) -eq $False)) {
                
                $TableEntryValues.Add($Key,$CustomFields[$Key])
            }
            Else {
                
                $Key
            }
        }
    }

    
    If ($null -ne $DuplicateTableEntryValues) {
        $DuplicateKeyList = $DuplicateTableEntryValues -join ","
        Throw "Ticket fields may only be used once:  $DuplicateKeyList"
    }

    
    $newServiceNowTableEntrySplat = @{
        Table = 'incident'
        Values = $TableEntryValues
    }

    
    if ($null -ne $PSBoundParameters.Connection)
    {
        $newServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL)
    {
        $newServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
        $newServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }

    
    New-ServiceNowTableEntry @newServiceNowTableEntrySplat
}
