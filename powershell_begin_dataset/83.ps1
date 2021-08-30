




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
