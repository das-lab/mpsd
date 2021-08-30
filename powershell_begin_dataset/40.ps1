



function Get-AuthToken {

    

    [cmdletbinding()]

    param
    (
        [Parameter(Mandatory = $true)]
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

    
    

    if ($AadModule.count -gt 1) {

        $Latest_Version = ($AadModule | select version | Sort-Object)[-1]

        $aadModule = $AadModule | ? { $_.version -eq $Latest_Version.version }

        

        if ($AadModule.count -gt 1) {

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

        $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result

        

        if ($authResult.AccessToken) {

            

            $authHeader = @{
                'Content-Type'  = 'application/json'
                'Authorization' = "Bearer " + $authResult.AccessToken
                'ExpiresOn'     = $authResult.ExpiresOn
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



Function Add-DeviceManagementScript() {
    
    [cmdletbinding()]
    Param (
        
        [Parameter(Mandatory = $true)]
        [string]$File,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [switch][bool]$URL = $false
    )
    if ($URL -eq $true) {
        $FileName = $File -split "/"
        $FileName = $FileName[-1]
        $OutFile = "$env:TEMP\$FileName"
        try {
            Invoke-WebRequest -Uri $File -UseBasicParsing -OutFile $OutFile
        }
        catch {
            Write-Host "Could not download file from URL: $File" -ForegroundColor Red
            break
        }
        $File = $OutFile
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
    }
    elseif ($URL -eq $false) {
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
        $FileName = Get-Item $File | Select-Object -ExpandProperty Name
    }
    $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$File"));

    if ($URL -eq $true) {
        Remove-Item $File -Force
    }

    $JSON = @"
{
    "@odata.type": "
    "displayName": "$FileName",
    "description": "$Description",
    "runSchedule": {
    "@odata.type": "microsoft.graph.runSchedule"
},
    "scriptContent": "$B64File",
    "runAsAccount": "system",
    "enforceSignatureCheck": "false",
    "fileName": "$FileName"
}
"@

    $graphApiVersion = "Beta"
    $DMS_resource = "deviceManagement/deviceManagementScripts"
    Write-Verbose "Resource: $DMS_resource"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$DMS_resource"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
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



Function Add-DeviceManagementScriptAssignment() {
    

    [cmdletbinding()]

    param
    (
        $ScriptId,
        $TargetGroupId
    )

    $graphApiVersion = "Beta"
    $Resource = "deviceManagement/deviceManagementScripts/$ScriptId/assign"

    try {

        if (!$ScriptId) {

            write-host "No Script Policy Id specified, specify a valid Script Policy Id" -f Red
            break

        }

        if (!$TargetGroupId) {

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
            break

        }

        $JSON = @"
{
    "deviceManagementScriptGroupAssignments":  [
        {
            "@odata.type":  "
            "targetGroupId": "$TargetGroupId",
            "id": "$ScriptId"
        }
    ]
}
"@

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

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



Function Get-AADGroup() {

    

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

        if ($id) {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        elseif ($GroupName -eq "" -or $GroupName -eq $null) {

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

        else {

            if (!$Members) {

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

            }

            elseif ($Members) {

                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                $Group = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

                if ($Group) {

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


if ($global:authToken) {

    
    $DateTime = (Get-Date).ToUniversalTime()

    
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if ($TokenExpires -le 0) {

        write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        write-host

        

        if ($User -eq $null -or $User -eq "") {

            $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
            Write-Host

        }

        $global:authToken = Get-AuthToken -User $User

    }
}



else {

    if ($User -eq $null -or $User -eq "") {

        $User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
        Write-Host

    }

    
    $global:authToken = Get-AuthToken -User $User

}







$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where PowerShell scripts will be assigned"

$TargetGroupId = (Get-AADGroup -GroupName "$AADGroup").id

if ($TargetGroupId -eq $null -or $TargetGroupId -eq "") {

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

}



Write-Host "Adding Device Management Script from 'C:\Scripts\test-script.ps1'" -ForegroundColor Yellow

$Create_Local_Script = Add-DeviceManagementScript -File "C:\Scripts\test-script.ps1" -Description "Test script"

Write-Host "Device Management Script created as" $Create_Local_Script.id
write-host
write-host "Assigning Device Management Script to AAD Group '$AADGroup'" -f Cyan

$Assign_Local_Script = Add-DeviceManagementScriptAssignment -ScriptId $Create_Local_Script.id -TargetGroupId $TargetGroupId

Write-Host "Assigned '$AADGroup' to $($Create_Local_Script.displayName)/$($Create_Local_Script.id)"
Write-Host



Write-Host "Adding Device Management Script from 'https://pathtourl/test-script.ps1'" -ForegroundColor Yellow
Write-Host

$Create_Web_Script = Add-DeviceManagementScript -File "https://pathtourl/test-script.ps1" -URL -Description "Test script"

Write-Host "Device Management Script created as" $Create_Web_Script.id
write-host
write-host "Assigning Device Management Script to AAD Group '$AADGroup'" -f Cyan

$Assign_Web_Script = Add-DeviceManagementScriptAssignment -ScriptId $Create_Web_Script.id -TargetGroupId $TargetGroupId

Write-Host "Assigned '$AADGroup' to $($Create_Web_Script.displayName)/$($Create_Web_Script.id)"
Write-Host