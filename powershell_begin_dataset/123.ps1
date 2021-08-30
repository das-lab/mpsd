



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



Function Get-iOSProvisioningProfile{



[cmdletbinding()]

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/iosLobAppProvisioningConfigurations?`$expand=assignments"
    
    try {
                
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

            
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
write-host "-------------------------------------------------------------------"
Write-Host
write-host "Analysing iOS App Provisioning Profiles..." -ForegroundColor Yellow
Write-Host
write-host "-------------------------------------------------------------------"
write-host
$Profiles = (Get-iOSProvisioningProfile)
$Days = 30
$CSV = @()
$CSV += "iOSAppProvisioningProfileName,GroupAssignedName,ExpiryDate"
$GroupsOutput = @()

    foreach ($Profile in $Profiles) {
    
        $Payload = $Profile.payload
        $payloadFileName = $Profile.payloadFileName
        $PayloadRaw = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Payload))
        $Exp = ($PayloadRaw | C:\windows\System32\findstr.exe /i "date").trim()[3]
        [datetime]$ProfileExpirationDate = $Exp.TrimStart('<date>').trimend('</date>')
        $displayName = $Profile.displayName
        $GroupID = ($Profile.assignments.target.groupId)
        $CurrentTime = [System.DateTimeOffset]::Now
        $TimeDifference = ($CurrentTime - $ProfileExpirationDate)
        $TotalDays = ($TimeDifference.Days)

        write-host "iOS App Provisioning Profile Name: $($displayName)"
            
            
                if ($GroupID) {
               
                    foreach ($id in $GroupID) {
                
                            $GroupName = (Get-AADGroup -id $id).DisplayName
                            write-host "Group assigned: $($GroupName)"
                            $CSV += "$($displayName),$($GroupName),$($ProfileExpirationDate)"

                        }

                }

                else {
                
                write-host "Group assigned: " -NoNewline 
                Write-Host "Unassigned"
                $CSV += "$($displayName),,$($ProfileExpirationDate)"
                
                }
            
            if ($TotalDays -gt "0") {
           
                Write-Host "iOS App Provisioning Profile Expiration Date: " -NoNewline
                write-host "$($ProfileExpirationDate)" -ForegroundColor Red

            }

            elseif ($TotalDays -gt "-30") {
            
                    Write-Host "iOS App Provisioning Profile Expiration Date: " -NoNewline
                    write-host "$($ProfileExpirationDate)" -ForegroundColor Yellow 

            }

            else {
            
                    Write-Host "iOS App Provisioning Profile: $($ProfileExpirationDate)"

            }

        
        Write-Host
        write-host "-------------------------------------------------------------------"
        write-host
        
    
    }

    if (!($Profiles.count -eq 0)) {

    Write-Host "Export results? [Y]es, [N]o"
    $conf = Read-Host
 
        if ($conf -eq "Y"){

        $parent = [System.IO.Path]::GetTempPath()
        [string] $name = [System.Guid]::NewGuid()
        New-Item -ItemType Directory -Path (Join-Path $parent $name) | Out-Null
        $TempDirPath = "$parent$name" 
        $TempExportFilePath = "$($TempDirPath)\iOSAppProvisioningProfileExport.txt"
        $CSV | Add-Content $TempExportFilePath -Force
        Write-Host
        Write-Host "$($TempExportFilePath)"
        Write-Host

        }

    }

    else {
    
        write-host "No iOS App Provisioning Profiles found."
        write-host

    }
