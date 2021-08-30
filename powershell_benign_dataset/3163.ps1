



function Get-GraphAPIToken
{
       param
       (
              [Parameter(Mandatory=$true)]
              $TenantName,
              [Parameter(Mandatory=$false)]
              $UserName,
              [Parameter(Mandatory=$false)]
              $Password,
              [Parameter(Mandatory=$false)]
              $Credential
       )

       $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
       $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
       [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
       [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null
       $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
       $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
       $resourceAppIdURI = "https://graph.windows.net"
       $authority = "https://login.windows.net/$TenantName"
       
       
       
       $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
       $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "auto")
       return $authResult
}




function Get-GraphData{
    param
    (
        [Parameter(Mandatory=$true)]
        $Token,
        [Parameter(Mandatory=$true)]
        $Tenant,
        [Parameter(Mandatory=$true)]
        [ValidateSet('contacts', 'directoryRoles', 'domains', 'groups', 'subscribedSkus', 'servicePrincipalsByAppId', 'tenantDetails', 'users')]
        $Resource,
        [Parameter(Mandatory=$false)]
        $Extended
    )

    $authHeader = @{

       'Content-Type'='application\json'

       'Authorization'=$Token.CreateAuthorizationHeader()

    }

    $uri = "https://graph.windows.net/$tenant/$($resource)?api-version=1.6"
    $uriPage = "https://graph.windows.net/$tenant/"
    

    
    $method = (Invoke-RestMethod -Uri $uri -Headers $authHeader -Method Get)

    $output = $method.value
    
    


    while($method.'odata.nextLink')
        {
            $nextLink = $method.'odata.nextLink'+'&api-version=1.6'

            $method = (Invoke-RestMethod -Uri $uriPage$nextLink -Headers $authHeader -Method Get)
            
            $output += $method.value
        }
    
    return $output
}