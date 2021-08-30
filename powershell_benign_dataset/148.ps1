




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



Function Get-AADUserDevices(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="UserID (guid) for the user you want to take action on must be specified:")]
    $UserID
)


$graphApiVersion = "beta"
$Resource = "users/$UserID/managedDevices"
    
    try {
    
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Write-Verbose $uri
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



Function Get-DeviceCompliancePolicy(){



[cmdletbinding()]

param
(
    [switch]$Android,
    [switch]$iOS,
    [switch]$Win10,
    $Name
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceCompliancePolicies"
    
    try {
        
        
        

        $Count_Params = 0

        if($Android.IsPresent){ $Count_Params++ }
        if($iOS.IsPresent){ $Count_Params++ }
        if($Win10.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){
        
        write-host "Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function" -f Red
        
        }
        
        elseif($Android){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("android") }
        
        }
        
        elseif($iOS){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ios") }
        
        }

        elseif($Win10){
        
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") }
        
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



Function Get-UserDeviceStatus(){

[cmdletbinding()]

param
(
    [switch]$Analyze
)

Write-Host "Getting User Devices..." -ForegroundColor Yellow
Write-Host

$UserDevices = Get-AADUserDevices -UserID $UserID

    if($UserDevices){

        write-host "-------------------------------------------------------------------"
        Write-Host

        foreach($UserDevice in $UserDevices){

        $UserDeviceId = $UserDevice.id
        $UserDeviceName = $UserDevice.deviceName
        $UserDeviceAADDeviceId = $UserDevice.azureActiveDirectoryDeviceId
        $UserDeviceComplianceState = $UserDevice.complianceState

        write-host "Device Name:" $UserDevice.deviceName -f Cyan
        Write-Host "Device Id:" $UserDevice.id
        write-host "Owner Type:" $UserDevice.ownerType
        write-host "Last Sync Date:" $UserDevice.lastSyncDateTime
        write-host "OS:" $UserDevice.operatingSystem
        write-host "OS Version:" $UserDevice.osVersion

            if($UserDevice.easActivated -eq $false){
            write-host "EAS Activated:" $UserDevice.easActivated -ForegroundColor Red
            }

            else {
            write-host "EAS Activated:" $UserDevice.easActivated
            }

        Write-Host "EAS DeviceId:" $UserDevice.easDeviceId

            if($UserDevice.aadRegistered -eq $false){
            write-host "AAD Registered:" $UserDevice.aadRegistered -ForegroundColor Red
            }

            else {
            write-host "AAD Registered:" $UserDevice.aadRegistered
            }
        
        write-host "Enrollment Type:" $UserDevice.enrollmentType
        write-host "Management State:" $UserDevice.managementState

            if($UserDevice.complianceState -eq "noncompliant"){
            
                write-host "Compliance State:" $UserDevice.complianceState -f Red

                $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$UserDeviceId/deviceCompliancePolicyStates"
                
                $deviceCompliancePolicyStates = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                    foreach($DCPS in $deviceCompliancePolicyStates){

                        if($DCPS.State -eq "nonCompliant"){

                        Write-Host
                        Write-Host "Non Compliant Policy for device $UserDeviceName" -ForegroundColor Yellow
                        write-host "Display Name:" $DCPS.displayName

                        $SettingStatesId = $DCPS.id

                        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$UserDeviceId/deviceCompliancePolicyStates/$SettingStatesId/settingStates?`$filter=(userId eq '$UserID')"

                        $SettingStates = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                            foreach($SS in $SettingStates){

                                if($SS.state -eq "nonCompliant"){

                                    write-host
                                    Write-Host "Setting:" $SS.setting
                                    Write-Host "State:" $SS.state -ForegroundColor Red

                                }

                            }

                        }

                    }

                
                $uri = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$UserDeviceAADDeviceId'"
                $AADDevice = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                $AAD_Compliant = $AADDevice.isCompliant

                

                Write-Host
                Write-Host "Compliance State - AAD and ManagedDevices" -ForegroundColor Yellow
                Write-Host "AAD Compliance State:" $AAD_Compliant
                Write-Host "Intune Managed Device State:" $UserDeviceComplianceState
            
            }
            
            else {

                write-host "Compliance State:" $UserDevice.complianceState -f Green

                
                $uri = "https://graph.microsoft.com/v1.0/devices?`$filter=deviceId eq '$UserDeviceAADDeviceId'"
                $AADDevice = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                $AAD_Compliant = $AADDevice.isCompliant

                

                Write-Host
                Write-Host "Compliance State - AAD and ManagedDevices" -ForegroundColor Yellow
                Write-Host "AAD Compliance State:" $AAD_Compliant
                Write-Host "Intune Managed Device State:" $UserDeviceComplianceState
            
            }

        write-host
        write-host "-------------------------------------------------------------------"
        Write-Host

        }

    }

    else {

    
    write-host "User has no devices"
    write-host

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





write-host "User Principal Name:" -f Yellow
$UPN = Read-Host

$User = Get-AADUser -userPrincipalName $UPN

$UserID = $User.id

write-host
write-host "Display Name:"$User.displayName
write-host "User ID:"$User.id
write-host "User Principal Name:"$User.userPrincipalName
write-host



$MemberOf = Get-AADUser -userPrincipalName $UPN -Property MemberOf

$AADGroups = $MemberOf | ? { $_.'@odata.type' -eq "

    if($AADGroups){

    write-host "User AAD Group Membership:" -f Yellow
        
        foreach($AADGroup in $AADGroups){
        
        (Get-AADGroup -id $AADGroup.id).displayName

        }

    write-host

    }

    else {

    write-host "AAD Group Membership:" -f Yellow
    write-host "No Group Membership in AAD Groups"
    Write-Host

    }



$CPs = Get-DeviceCompliancePolicy

if($CPs){

    write-host "Assigned Compliance Policies:" -f Yellow
    $CP_Names = @()

    foreach($CP in $CPs){

    $id = $CP.id

    $DCPA = Get-DeviceCompliancePolicyAssignment -id $id

        if($DCPA){

            foreach($Com_Group in $DCPA){
            
                if($AADGroups.id -contains $Com_Group.target.GroupId){

                $CP_Names += $CP.displayName + " - " + $CP.'@odata.type'

                }

            }

        }

    }

    if($CP_Names -ne $null){
    
    $CP_Names
    
    }
    
    else {
    
    write-host "No Device Compliance Policies Assigned"
    
    }

}

else {

write-host "Device Compliance Policies:" -f Yellow
write-host "No Device Compliance Policies Assigned"

}

write-host



Get-UserDeviceStatus


