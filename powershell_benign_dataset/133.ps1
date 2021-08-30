




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