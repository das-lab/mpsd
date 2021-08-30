
















$groupId = " FILL ME IN "           
$newGatewayId = " FILL ME IN "      
$datasetId = " FILL ME IN "         








$clientId = " FILL ME IN " 





function GetAuthToken
{
    if(-not (Get-Module AzureRm.Profile)) {
      Import-Module AzureRm.Profile
    }

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"

    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

    return $authResult
}


$token = GetAuthToken


$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'=$token.CreateAuthorizationHeader()
 }

 
$sourceGroupsPath = ""
if ($groupId -eq "me") {
    $sourceGroupsPath = "myorg"
} else {
    $sourceGroupsPath = "myorg/groups/$groupId"
}


$postParams = @{
    "gatewayObjectId" = "$newGatewayId"
}

$jsonPostBody = $postParams | ConvertTo-JSON


$uri = "https://api.powerbi.com/v1.0/$sourceGroupsPath/datasets/$datasetId/BindToGateway"


try {
    Invoke-RestMethod -Uri $uri -Headers $authHeader -Method POST -Body $jsonPostBody -Verbose 
} catch {

    $result = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($result)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();

    
    
    If(($responseBody).Contains("DMTS_CanNotFindMatchingDatasourceInGatewayError"))
    {
        Write-Host "Error: No data source available in gateway."
    }
    elseif($_.Exception.Response.StatusCode.value__ -eq "401")
    {
        Write-Host "Error: No access to app workspace."
    }
    elseif($_.Exception.Response.StatusCode.value__ -eq "404")
    {
        Write-Host "Error: Dataset may be owned by someone else. Call take over API to assume ownership and try again. For more information, see https://msdn.microsoft.com/en-us/library/mt784651.aspx."
    }
    else
    {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host "StatusBody:" $responseBody
    }
}