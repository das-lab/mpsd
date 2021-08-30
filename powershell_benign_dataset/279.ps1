






















$sourceReportGroupId = " FILL ME IN "    
$sourceReportId = " FILL ME IN "         







$targetReportName = " FILL ME IN "       
$targetGroupId = " FILL ME IN "          
$targetDatasetId = " FILL ME IN "        








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
if ($sourceReportGroupId -eq "me") {
    $sourceGroupsPath = "myorg"
} else {
    $sourceGroupsPath = "myorg/groups/$sourceReportGroupId"
}


$postParams = @{
    "Name" = "$targetReportName"
    "TargetWorkspaceId" = "$targetGroupId"
    "TargetModelId" = "$targetDatasetId"
}

$jsonPostBody = $postParams | ConvertTo-JSON


$uri = "https://api.powerbi.com/v1.0/$sourceGroupsPath/reports/$sourceReportId/clone"
Invoke-RestMethod -Uri $uri –Headers $authHeader –Method POST -Body $jsonPostBody –Verbose