




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



Function Get-ManagedDevices(){



[cmdletbinding()]

param
(
    [switch]$IncludeEAS,
    [switch]$ExcludeMDM
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/managedDevices"

try {

    $Count_Params = 0

    if($IncludeEAS.IsPresent){ $Count_Params++ }
    if($ExcludeMDM.IsPresent){ $Count_Params++ }
        
        if($Count_Params -gt 1){

        write-warning "Multiple parameters set, specify a single parameter -IncludeEAS, -ExcludeMDM or no parameter against the function"
        Write-Host
        break

        }
        
        elseif($IncludeEAS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

        }

        elseif($ExcludeMDM){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'eas'"

        }
        
        else {
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource`?`$filter=managementAgent eq 'mdm' and managementAgent eq 'easmdm'"
        Write-Warning "EAS Devices are excluded by default, please use -IncludeEAS if you want to include those devices"
        Write-Host

        }

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



Function Set-ManagedDevice(){



[cmdletbinding()]

param
(
    $id,
    $ownertype
)


$graphApiVersion = "Beta"
$Resource = "deviceManagement/managedDevices"

    try {

        if($id -eq "" -or $id -eq $null){

        write-host "No Device id specified, please provide a device id..." -f Red
        break

        }
        
        if($ownerType -eq "" -or $ownerType -eq $null){

            write-host "No ownerType parameter specified, please provide an ownerType. Supported value personal or company..." -f Red
            Write-Host
            break

            }

        elseif($ownerType -eq "company"){

$JSON = @"

{
    ownerType:"company"
}

"@

                write-host
                write-host "Are you sure you want to change the device ownership to 'company' on this device? Y or N?"
                $Confirm = read-host

                if($Confirm -eq "y" -or $Confirm -eq "Y"){
            
                
                $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ID')"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $Json -ContentType "application/json"

                }

                else {

                Write-Host "Change of Device Ownership for the device $ID was cancelled..." -ForegroundColor Yellow
                Write-Host

                }
            
            }

        elseif($ownerType -eq "personal"){

$JSON = @"

{
    ownerType:"personal"
}

"@

                write-host
                write-host "Are you sure you want to change the device ownership to 'personal' on this device? Y or N?"
                $Confirm = read-host

                if($Confirm -eq "y" -or $Confirm -eq "Y"){
            
                
                $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$ID')"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $Json -ContentType "application/json"

                }

                else {

                Write-Host "Change of Device Ownership for the device $ID was cancelled..." -ForegroundColor Yellow
                Write-Host

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






$ManagedDevice = Get-ManagedDevices | Where-Object { $_.deviceName -eq "IPADMINI4" }

if($ManagedDevice){

    if(@($ManagedDevice.count) -gt 1){

    Write-Host "More than 1 device was found, script supports single deviceID..." -ForegroundColor Red
    Write-Host
    break

    }

    else {

    write-host "Device Name:"$ManagedDevice.deviceName -ForegroundColor Cyan
    write-host "Management State:"$ManagedDevice.managementState
    write-host "Operating System:"$ManagedDevice.operatingSystem
    write-host "Device Type:"$ManagedDevice.deviceType
    write-host "Last Sync Date Time:"$ManagedDevice.lastSyncDateTime
    write-host "Jail Broken:"$ManagedDevice.jailBroken
    write-host "Compliance State:"$ManagedDevice.complianceState
    write-host "Enrollment Type:"$ManagedDevice.enrollmentType
    write-host "AAD Registered:"$ManagedDevice.aadRegistered
    write-host "Management Agent:"$ManagedDevice.managementAgent
    Write-Host "User Principal Name:"$ManagedDevice.userPrincipalName
    Write-Host "Owner Type:"$ManagedDevice.ownerType -ForegroundColor Yellow

    Set-ManagedDevice -id $ManagedDevice.id -ownertype personal

    }

}

else {

Write-Host "No Managed Device found..." -ForegroundColor Red
Write-Host

}
