



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



Function Test-JSON(){



param (

$JSON

)

    try {

    $TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
    $validJson = $true

    }

    catch {

    $validJson = $false
    $_.Exception

    }

    if (!$validJson){

    Write-Host "Provided JSON isn't in valid JSON format" -f Red
    break

    }

}



Function Get-DEPOnboardingSettings {


    
[cmdletbinding()]
    
Param(
[parameter(Mandatory=$false)]
[string]$tokenid
)
    
    $graphApiVersion = "beta"
    
        try {
    
                if ($tokenid){
                
                $Resource = "deviceManagement/depOnboardingSettings/$tokenid/"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get)
                     
                }
    
                else {
                
                $Resource = "deviceManagement/depOnboardingSettings/"
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value
                
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



Function Get-DEPProfiles(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles"

    try {

        $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method GET

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



Function Assign-ProfileToDevice(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $id,
    [Parameter(Mandatory=$true)]
    $DeviceSerialNumber,
    [Parameter(Mandatory=$true)]
    $ProfileId
)

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/enrollmentProfiles('$ProfileId')/updateDeviceProfileAssignment"

    try {

        $DevicesArray = $DeviceSerialNumber -split ","

        $JSON = @{ "deviceIds" = $DevicesArray } | ConvertTo-Json

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

        Write-Host "Success: " -f Green -NoNewline
        Write-Host "Device assigned!"
        Write-Host

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







$tokens = (Get-DEPOnboardingSettings)

if($tokens){

$tokencount = @($tokens).count

Write-Host "DEP tokens found: $tokencount"
Write-Host

    if ($tokencount -gt 1){

    write-host "Listing DEP tokens..." -ForegroundColor Yellow
    Write-Host
    $DEP_Tokens = $tokens.tokenName | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $DEP_Tokens.count; $i++) 
    { Write-Host "$i. $($DEP_Tokens[$i-1])" 
    $menu.Add($i,($DEP_Tokens[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Select the token you wish you to use (numerical value)'
    $selection = $menu.Item($ans)
    Write-Host

        if ($selection){

        $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$Selection" }

        $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id
        $id = $SelectedTokenId

        }

    }

    elseif ($tokencount -eq 1) {

        $id = (Get-DEPOnboardingSettings).id
    
    }

}

else {
    
    Write-Warning "No DEP tokens found!"
    Write-Host
    break

}





$DeviceSerialNumber = Read-Host "Please enter device serial number"


$DeviceSerialNumber = $DeviceSerialNumber.replace(" ","")

if(!($DeviceSerialNumber)){
    
    Write-Host "Error: No serial number entered!" -ForegroundColor Red
    Write-Host
    break
    
}

$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$($id)/importedAppleDeviceIdentities?`$filter=discoverySource eq 'deviceEnrollmentProgram' and contains(serialNumber,'$DeviceSerialNumber')"

$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
$SearchResult = (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).value

if (!($SearchResult)){

    Write-warning "Can't find device $DeviceSerialNumber."
    Write-Host
    break

}



$Profiles = (Get-DEPProfiles -id $id).value

if($Profiles){
                
Write-Host
Write-Host "Listing DEP Profiles..." -ForegroundColor Yellow
Write-Host

$enrollmentProfiles = $Profiles.displayname | Sort-Object -Unique

$menu = @{}

for ($i=1;$i -le $enrollmentProfiles.count; $i++) 
{ Write-Host "$i. $($enrollmentProfiles[$i-1])" 
$menu.Add($i,($enrollmentProfiles[$i-1]))}

Write-Host
$ans = Read-Host 'Select the profile you wish to assign (numerical value)'

    
    if(($ans -match "^[\d\.]+$") -eq $true){

        $selection = $menu.Item([int]$ans)

    }

    if ($selection){
   
        $SelectedProfile = $Profiles | Where-Object { $_.DisplayName -eq "$Selection" }
        $SelectedProfileId = $SelectedProfile | Select-Object -ExpandProperty id
        $ProfileID = $SelectedProfileId

    }

    else {

        Write-Host
        Write-Warning "DEP Profile selection invalid. Exiting..."
        Write-Host
        break

    }

}

else {
    
    Write-Host
    Write-Warning "No DEP profiles found!"
    break

}



Assign-ProfileToDevice -id $id -DeviceSerialNumber $DeviceSerialNumber -ProfileId $ProfileID