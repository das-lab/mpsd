



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



Function Sync-AppleDEP(){



[cmdletbinding()]

Param(
[parameter(Mandatory=$true)]
[string]$id
)


$graphApiVersion = "beta"
$Resource = "deviceManagement/depOnboardingSettings/$id/syncWithAppleDeviceEnrollmentProgram"

    try {

        $SyncURI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        Invoke-RestMethod -Uri $SyncURI -Headers $authToken -Method Post

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

    if($tokencount -gt 1){

    $DEP_Tokens = $tokens.tokenName | Sort-Object -Unique

    $menu = @{}

    for ($i=1;$i -le $DEP_Tokens.count; $i++) 
    { Write-Host "$i. $($DEP_Tokens[$i-1])" 
    $menu.Add($i,($DEP_Tokens[$i-1]))}

    Write-Host
    [int]$ans = Read-Host 'Select the token you wish to sync (numerical value)'
    $selection = $menu.Item($ans)
    Write-Host

        if($selection){

        $SelectedToken = $tokens | Where-Object { $_.TokenName -eq "$Selection" }

        $SelectedTokenId = $SelectedToken | Select-Object -ExpandProperty id

        $id = $SelectedTokenId

        }

    }

    elseif ($tokencount -eq 1){

        $id = (Get-DEPOnboardingSettings).id

        }

    else {
    
        Write-Host
        Write-Warning "No DEP tokens found!"
        break

    }

    $LastSync = (Get-DEPOnboardingSettings -tokenid $id).lastSyncTriggeredDateTime
    $TokenDisplayName = (Get-DEPOnboardingSettings -tokenid $id).TokenName

    $CurrentTime = [System.DateTimeOffset]::Now

    $LastSyncTime = [datetimeoffset]::Parse($LastSync)

    $TimeDifference = ($CurrentTime - $LastSyncTime)

    $TotalMinutes = ($TimeDifference.Minutes)

    $RemainingTimeToSync = (15 - [int]$TotalMinutes)

        if ($RemainingTimeToSync -gt 0 -AND $RemainingTimeToSync -lt 16) {

            Write-Warning "Syncing in progress. You can retry sync in $RemainingTimeToSync minutes"
            Write-Host

        } 
           
        else {
    
            Write-Host "Syncing '$TokenDisplayName' DEP token with Apple DEP service..."
            Sync-AppleDEP $id

        }

}

else {

    Write-Warning "No DEP tokens found!"
    Write-Host
    break

}