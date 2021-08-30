function Update-ServiceNowIncident {
    Param
    (   
        [parameter(mandatory=$true)]        
        [parameter(ParameterSetName='SpecifyConnectionFields', mandatory=$true)]
        [parameter(ParameterSetName='UseConnectionObject', mandatory=$true)]
        [parameter(ParameterSetName='SetGlobalAuth', mandatory=$true)]       
        [string]$SysId,

         
        [parameter(mandatory=$true)]        
        [hashtable]$Values,

         
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

    $updateServiceNowTableEntrySplat = @{
        SysId = $SysId
        Table = 'incident'
        Values = $Values
    }
    
    
    if ($null -ne $PSBoundParameters.Connection)
    {     
        $updateServiceNowTableEntrySplat.Add('Connection',$Connection)
    }
    elseif ($null -ne $PSBoundParameters.ServiceNowCredential -and $null -ne $PSBoundParameters.ServiceNowURL) 
    {
         $updateServiceNowTableEntrySplat.Add('ServiceNowCredential',$ServiceNowCredential)
         $updateServiceNowTableEntrySplat.Add('ServiceNowURL',$ServiceNowURL)
    }
       
    Update-ServiceNowTableEntry @updateServiceNowTableEntrySplat
}

