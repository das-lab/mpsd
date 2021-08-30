function New-ServiceNowTableEntry{
    Param
    (
        
        [parameter(mandatory=$true)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [string]$Table,
        
        
        [parameter(mandatory=$false)]
        [parameter(ParameterSetName='SpecifyConnectionFields')]
        [parameter(ParameterSetName='UseConnectionObject')]
        [parameter(ParameterSetName='SetGlobalAuth')]
        [hashtable]$Values,
        
        
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

    
    $Body = $Values | ConvertTo-Json;

    
    $utf8Bytes = [System.Text.Encoding]::UTf8.GetBytes($Body)

    
    $Uri = $ServiceNowURL + "/table/$Table"
    return (Invoke-RestMethod -Uri $uri -Method Post -Credential $ServiceNowCredential -Body $utf8Bytes -ContentType "application/json" -UseBasicParsing).result
}
