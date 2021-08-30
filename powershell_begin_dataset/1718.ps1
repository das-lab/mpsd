
function Update-ServiceNowChangeRequest
{
    Param(
        
        [parameter(Mandatory=$true)]        
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]       
        [string]$SysId,

         
        [parameter(Mandatory=$true)]        
        [hashtable]$Values,

         
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]$ServiceNowCredential, 

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceNowURL, 

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$true)] 
        [ValidateNotNullOrEmpty()]
        [Hashtable]$Connection
    )                      

    $updateServiceNowTableEntrySplat = @{
        SysId = $SysId
        Table = 'change_request'
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
