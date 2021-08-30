




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