




function Get-AuthToken {



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $User
)

$userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User

$tenant = $userUpn.Host

Write-Host "Checking for AzureAD module..."

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable

    if ($AadModule -eq $null) {

        Write-Host "AzureAD PowerShell module not found, looking for AzureADPreview"
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable

    }

    if ($AadModule -eq $null) {
        write-host
        write-host "AzureAD Powershell module not installed..." -f Red
        write-host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        write-host "Script can't continue..." -f Red
        write-host
        exit
    }




    if($AadModule.count -gt 1){

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

            

            if($AadModule.count -gt 1){

            $aadModule = $AadModule | select -Unique

            }

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

    else {

        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    }

[System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

[System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

$clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"

$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

$resourceAppIdURI = "https://graph.microsoft.com"

$authority = "https://login.microsoftonline.com/$Tenant"

    try {

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    
    

    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"

    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")

    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI,$clientId,$redirectUri,$platformParameters,$userId).Result

        

        if($authResult.AccessToken){

        

        $authHeader = @{
            'Content-Type'='application/json'
            'Authorization'="Bearer " + $authResult.AccessToken
            'ExpiresOn'=$authResult.ExpiresOn
            }

        return $authHeader

        }

        else {

        Write-Host
        Write-Host "Authorization Access Token is null, please re-run authentication..." -ForegroundColor Red
        Write-Host
        break

        }

    }

    catch {

    write-host $_.Exception.Message -f Red
    write-host $_.Exception.ItemName -f Red
    write-host
    break

    }

}



Function Add-ManagedAppPolicy(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for a Managed App Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        }

    }

    catch {

    Write-Host
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}



Function Assign-ManagedAppPolicy(){



[cmdletbinding()]

param
(
    $Id,
    $TargetGroupId,
    $OS
)

$graphApiVersion = "Beta"
    
    try {

        if(!$Id){

        write-host "No Policy Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$TargetGroupId){

        write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

$JSON = @"

{
    "assignments":[
    {
        "target":
        {
            "groupId":"$TargetGroupId",
            "@odata.type":"
        }
    }
    ]
}

"@

        if($OS -eq "" -or $OS -eq $null){

        write-host "No OS parameter specified, please provide an OS. Supported value Android or iOS..." -f Red
        Write-Host
        break

        }

        elseif($OS -eq "Android"){

        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/iosManagedAppProtections('$ID')/assign"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

        }

        elseif($OS -eq "iOS"){

        $uri = "https://graph.microsoft.com/$graphApiVersion/deviceAppManagement/iosManagedAppProtections('$ID')/assign"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

        }
    
    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}



Function Test-JSON(){



param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}



Function Get-AADGroup(){



[cmdletbinding()]

param
(
    $GroupName,
    $id,
    [switch]$Members
)


$graphApiVersion = "v1.0"
$Group_resource = "groups"
    
    try {

        if($id){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }
        
        elseif($GroupName -eq "" -or $GroupName -eq $null){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        
        }

        else {
            
            if(!$Members){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
            }
            
            elseif($Members){
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
            $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
                if($Group){

                $GID = $Group.id

                $Group.displayName
                write-host

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                }

            }
        
        }

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}





write-host


if($global:authToken){

    
    $DateTime = (Get-Date).ToUniversalTime()

    
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

            

            if($User -eq $null -or $User -eq ""){

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

            }

        $global:authToken = Get-AuthToken -User $User

        }
}



else {

    if($User -eq $null -or $User -eq ""){

    $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
    Write-Host

    }


$global:authToken = Get-AuthToken -User $User

}







$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where policies will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

    }

Write-Host



$iOS = @"

{
  "@odata.type": "
  "displayName": "Graph MAM iOS Policy Assigned",
  "description": "Graph MAM iOS Policy Assigned",
  "periodOfflineBeforeAccessCheck": "PT12H",
  "periodOnlineBeforeAccessCheck": "PT30M",
  "allowedInboundDataTransferSources": "allApps",
  "allowedOutboundDataTransferDestinations": "allApps",
  "organizationalCredentialsRequired": false,
  "allowedOutboundClipboardSharingLevel": "allApps",
  "dataBackupBlocked": true,
  "deviceComplianceRequired": true,
  "managedBrowserToOpenLinksRequired": true,
  "saveAsBlocked": true,
  "periodOfflineBeforeWipeIsEnforced": "P90D",
  "pinRequired": true,
  "maximumPinRetries": 5,
  "simplePinBlocked": true,
  "minimumPinLength": 4,
  "pinCharacterSet": "numeric",
  "allowedDataStorageLocations": [],
  "contactSyncBlocked": true,
  "printBlocked": true,
  "fingerprintBlocked": true,
  "appDataEncryptionType": "afterDeviceRestart",

  "apps": [
    {
        "mobileAppIdentifier": {
        "@odata.type": "
        "bundleId": "com.microsoft.office.outlook"
        }
    },
    {
        "mobileAppIdentifier": {
        "@odata.type": "
        "bundleId": "com.microsoft.office.excel"
        }
    }

    ]
}

"@



$Android = @"

{
  "@odata.type": "
  "displayName": "Graph MAM Android Policy Assigned",
  "description": "Graph MAM Android Policy Assigned",
  "periodOfflineBeforeAccessCheck": "PT12H",
  "periodOnlineBeforeAccessCheck": "PT30M",
  "allowedInboundDataTransferSources": "allApps",
  "allowedOutboundDataTransferDestinations": "allApps",
  "organizationalCredentialsRequired": false,
  "allowedOutboundClipboardSharingLevel": "allApps",
  "dataBackupBlocked": true,
  "deviceComplianceRequired": true,
  "managedBrowserToOpenLinksRequired": true,
  "saveAsBlocked": true,
  "periodOfflineBeforeWipeIsEnforced": "P90D",
  "pinRequired": true,
  "maximumPinRetries": 5,
  "simplePinBlocked": true,
  "minimumPinLength": 4,
  "pinCharacterSet": "numeric",
  "allowedDataStorageLocations": [],
  "contactSyncBlocked": true,
  "printBlocked": true,
  "fingerprintBlocked": true,
  "appDataEncryptionType": "afterDeviceRestart",

  "apps": [
    {
        "mobileAppIdentifier": {
        "@odata.type": "
        "packageId": "com.microsoft.office.outlook"
        }
    },
    {
        "mobileAppIdentifier": {
        "@odata.type": "
        "packageId": "com.microsoft.office.excel"
        }
    }

    ]
}

"@



Write-Host "Adding App Protection Policies to Intune..." -ForegroundColor Cyan
Write-Host

Write-Host "Adding iOS Managed App Policy from JSON..." -ForegroundColor Yellow
Write-Host "Creating Policy via Graph"

$CreateResult = Add-ManagedAppPolicy -Json $iOS
write-host "Policy created with id" $CreateResult.id

$MAM_PolicyID = $CreateResult.id

$Assign_Policy = Assign-ManagedAppPolicy -Id $MAM_PolicyID -TargetGroupId $TargetGroupId -OS iOS
Write-Host "Assigned '$AADGroup' to $($CreateResult.displayName)/$($CreateResult.id)"

Write-Host

write-host "Adding Android Managed App Policy from JSON..." -f Yellow
Write-Host "Creating Policy via Graph"

$CreateResult = Add-ManagedAppPolicy -Json $Android
write-host "Policy created with id" $CreateResult.id

$MAM_PolicyID = $CreateResult.id

$Assign_Policy = Assign-ManagedAppPolicy -Id $MAM_PolicyID -TargetGroupId $TargetGroupId -OS Android
Write-Host "Assigned '$AADGroup' to $($CreateResult.displayName)/$($CreateResult.id)"

Write-Host
