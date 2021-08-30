




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



Function Get-DeviceEnrollmentConfigurations(){
    

    
[cmdletbinding()]
    
$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceEnrollmentConfigurations"
        
    try {
            
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
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


    
Function Set-DeviceEnrollmentConfiguration(){
    

    
[cmdletbinding()]
    
param
(
    $JSON,
    $DEC_Id
)
    
$graphApiVersion = "Beta"
$App_resource = "deviceManagement/deviceEnrollmentConfigurations"
        
    try {
    
        if(!$JSON){
    
        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break
    
        }
    
        elseif(!$DEC_Id){
    
        write-host "No Device Enrollment Configuration ID was passed to the function, provide a Device Enrollment Configuration ID" -f Red
        break
    
        }
    
        else {
    
        Test-JSON -JSON $JSON
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)/$DEC_Id"
        Invoke-RestMethod -Uri $uri -Method Patch -ContentType "application/json" -Body $JSON -Headers $authToken
    
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





$JSON = @"

{
    "@odata.type":"
    "displayName":"All Users",
    "description":"This is the default Device Type Restriction applied with the lowest priority to all users regardless of group membership.",

    "androidRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "androidForWorkRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":null,
    "osMaximumVersion":null
    },
    "iosRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "macRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":null,
    "osMaximumVersion":null
    },
    "windowsRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    },
    "windowsMobileRestriction":{
    "platformBlocked":false,
    "personalDeviceEnrollmentBlocked":false,
    "osMinimumVersion":"",
    "osMaximumVersion":""
    }

}

"@



$DeviceEnrollmentConfigurations = Get-DeviceEnrollmentConfigurations

$PlatformRestrictions = ($DeviceEnrollmentConfigurations | Where-Object { ($_.id).contains("DefaultPlatformRestrictions") }).id

Set-DeviceEnrollmentConfiguration -DEC_Id $PlatformRestrictions -JSON $JSON
