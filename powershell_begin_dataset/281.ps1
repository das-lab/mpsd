



















$groupID = " FILL ME IN " 
$datasetID = " FILL ME IN " 








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


$groupsPath = ""
if ($groupID -eq "me") {
    $groupsPath = "myorg"
} else {
    $groupsPath = "myorg/groups/$groupID"
}


$uri = "https://api.powerbi.com/v1.0/$groupsPath/datasets/$datasetID/refreshes"
Invoke-RestMethod -Uri $uri –Headers $authHeader –Method POST –Verbose


$uri = "https://api.powerbi.com/v1.0/$groupsPath/datasets/$datasetID/refreshes"
Invoke-RestMethod -Uri $uri –Headers $authHeader –Method GET –Verbose