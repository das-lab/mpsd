function Remove-ServiceNowTableEntry{
[CmdletBinding(ConfirmImpact='High')]
    Param(
        
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$SysId,
        
        
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $ServiceNowCredential, 

        
        [Parameter(ParameterSetName='SpecifyConnectionFields', Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceNowURL, 

        
        [Parameter(ParameterSetName='UseConnectionObject', Mandatory=$True)] 
        [ValidateNotNullOrEmpty()]
        [Hashtable]
        $Connection
    )

	
    if ($Connection -ne $null)
    {
        $SecurePassword = ConvertTo-SecureString $Connection.Password -AsPlainText -Force
        $ServiceNowCredential = New-Object System.Management.Automation.PSCredential ($Connection.Username, $SecurePassword)
        $ServiceNowURL = 'https://' + $Connection.ServiceNowUri + '/api/now/v1'
        
    } 
    elseif ($ServiceNowCredential -ne $null -and $ServiceNowURL -ne $null)
    {
        $ServiceNowURL = 'https://' + $ServiceNowURL + '/api/now/v1'
    }
    elseif((Test-ServiceNowAuthIsSet))
    {
        $ServiceNowCredential = $Global:ServiceNowCredentials
        $ServiceNowURL = $global:ServiceNowRESTURL
    } 
    else 
    {
        throw "Exception:  You must do one of the following to authenticate: `n 1. Call the Set-ServiceNowAuth cmdlet `n 2. Pass in an Azure Automation connection object `n 3. Pass in an endpoint and credential"
    }

    
    $Uri = $ServiceNowURL + "/table/$Table/$SysID"
    return (Invoke-RestMethod -Uri $uri -Method Delete -Credential $ServiceNowCredential -Body $Body -ContentType "application/json").result
}
