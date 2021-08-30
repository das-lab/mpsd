function Set-ServiceNowAuth {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-ServiceNowURL -Url $_})]
        [Alias('ServiceNowUrl')]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credentials
    )
    $Global:serviceNowUrl = 'https://' + $Url
    $Global:serviceNowRestUrl = $serviceNowUrl + '/api/now/v1'
    $Global:serviceNowCredentials = $Credentials
    return $true
}
