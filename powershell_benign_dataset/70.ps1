




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



Function Get-itunesApplication(){



[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true)]
    $SearchString,
    [int]$Limit
)

    try{

    Write-Verbose $SearchString

    
    $SearchString = $SearchString.replace(" ","+")

    Write-Verbose "SearchString variable converted if there is a space in the name $SearchString"

        if($Limit){

        $iTunesUrl = "https://itunes.apple.com/search?entity=software&term=$SearchString&attribute=softwareDeveloper&limit=$limit"
    
        }

        else {

        $iTunesUrl = "https://itunes.apple.com/search?entity=software&term=$SearchString&attribute=softwareDeveloper"

        }

    write-verbose $iTunesUrl
    $apps = Invoke-RestMethod -Uri $iTunesUrl -Method Get

    
    sleep 3

    return $apps
    
    }
    
    catch {

    write-host $_.Exception.Message -f Red        
    write-host $_.Exception.ItemName -f Red
    write-verbose $_.Exception
    write-host
    break

    }

}



Function Add-iOSApplication(){



[cmdletbinding()]

param
(
    $itunesApp
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps"
    
    try {
    
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        
    $app = $itunesApp

    Write-Verbose $app
            
    Write-Host "Publishing $($app.trackName)" -f Yellow

    
    $iconUrl = $app.artworkUrl60

        if ($iconUrl -eq $null){

        Write-Host "60x60 icon not found, using 100x100 icon"
        $iconUrl = $app.artworkUrl100
        
        }
        
        if ($iconUrl -eq $null){
        
        Write-Host "60x60 icon not found, using 512x512 icon"
        $iconUrl = $app.artworkUrl512
        
        }

    $iconResponse = Invoke-WebRequest $iconUrl
    $base64icon = [System.Convert]::ToBase64String($iconResponse.Content)
    $iconType = $iconResponse.Headers["Content-Type"]

        if(($app.minimumOsVersion.Split(".")).Count -gt 2){

        $Split = $app.minimumOsVersion.Split(".")

        $MOV = $Split[0] + "." + $Split[1]

        $osVersion = [Convert]::ToDouble($MOV)

        }

        else {

        $osVersion = [Convert]::ToDouble($app.minimumOsVersion)

        }

    
    if($app.supportedDevices -match "iPadMini"){ $iPad = $true } else { $iPad = $false }
    if($app.supportedDevices -match "iPhone6"){ $iPhone = $true } else { $iPhone = $false }

    

    $description = $app.description -replace "[^\x00-\x7F]+",""

    $graphApp = @{
        "@odata.type"="
        displayName=$app.trackName;
        publisher=$app.artistName;
        description=$description;
        largeIcon= @{
            type=$iconType;
            value=$base64icon;
        };
        isFeatured=$false;
        appStoreUrl=$app.trackViewUrl;
        applicableDeviceType=@{
            iPad=$iPad;
            iPhoneAndIPod=$iPhone;
        };
        minimumSupportedOperatingSystem=@{
            v8_0=$osVersion -lt 9.0;
            v9_0=$osVersion -eq 9.0;
            v10_0=$osVersion -gt 9.0;
        };
    };

    $JSON = ConvertTo-Json $graphApp

    
    Write-Host "Creating application via Graph"
    $createResult = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body (ConvertTo-Json $graphApp) -Headers $authToken
    Write-Host "Application created as $uri/$($createResult.id)"
    write-host

    return $createResult
    
    }
    
    catch {

    $ex = $_.Exception
    Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red

    $errorResponse = $ex.Response.GetResponseStream()
    
    $ex.Response.GetResponseStream()

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



Function Add-ApplicationAssignment(){



[cmdletbinding()]

param
(
    $ApplicationId,
    $TargetGroupId,
    $InstallIntent
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps/$ApplicationId/assign"
    
    try {

        if(!$ApplicationId){

        write-host "No Application Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$TargetGroupId){

        write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

        
        if(!$InstallIntent){

        write-host "No Install Intent specified, specify a valid Install Intent - available, notApplicable, required, uninstall, availableWithoutEnrollment" -f Red
        break

        }

$JSON = @"

{
    "mobileAppAssignments": [
    {
        "@odata.type": "
        "target": {
        "@odata.type": "
        "groupId": "$TargetGroupId"
        },
        "intent": "$InstallIntent"
    }
    ]
}

"@

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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







Write-Host
Write-Warning "This script adds all your iOS Store Apps as 'available' assignments for the Azure AD group you specify."
Write-Host
$AADGroup = Read-Host -Prompt "Enter the Azure AD Group name where applications will be assigned"

$TargetGroupId = (get-AADGroup -GroupName "$AADGroup").id

    if($TargetGroupId -eq $null -or $TargetGroupId -eq ""){

    Write-Host "AAD Group - '$AADGroup' doesn't exist, please specify a valid AAD Group..." -ForegroundColor Red
    Write-Host
    exit

    }

Write-Host




$culture = "EN-US"


$OldCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
$OldUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture



[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture



$itunesApps = Get-itunesApplication -SearchString "Microsoft Corporation" -Limit 50


$Applications = 'Microsoft Outlook','Microsoft Excel','OneDrive'



if($Applications) {
    
    
    foreach($Application in $Applications){

    $itunesApp = $itunesApps.results | ? { ($_.trackName).contains("$Application") }

        
        if($itunesApp.count -gt 1){

        $itunesApp.count
        write-host "More than 1 application was found in the itunes store" -f Cyan

            foreach($iapp in $itunesApp){

            $Create_App = Add-iOSApplication -itunesApp $iApp

            $ApplicationId = $Create_App.id

            $Assign_App = Add-ApplicationAssignment -ApplicationId $ApplicationId -TargetGroupId $TargetGroupId -InstallIntent "available"
            Write-Host "Assigned '$AADGroup' to $($Create_App.displayName)/$($create_App.id) with" $Assign_App.InstallIntent "install Intent"

            Write-Host

            }

        }
        
        
        elseif($itunesApp){

        $Create_App = Add-iOSApplication -itunesApp $itunesApp

        $ApplicationId = $Create_App.id

        $Assign_App = Add-ApplicationAssignment -ApplicationId $ApplicationId -TargetGroupId $TargetGroupId -InstallIntent "available"
        Write-Host "Assigned '$AADGroup' to $($Create_App.displayName)/$($create_App.id) with" $Assign_App.InstallIntent "install Intent"

        Write-Host
    
        }

        
        else {

        write-host
        write-host "Application '$Application' doesn't exist" -f Red
        write-host

        }

    }

}


else {
    
    
    if($itunesApps.results){

    write-host
    write-host "Number of iOS applications to add:" $itunesApps.results.count -f Yellow
    Write-Host
        
        
        foreach($itunesApp in $itunesApps.results){

        $Create_App = Add-iOSApplication -itunesApp $itunesApp

        $ApplicationId = $Create_App.id

        $Assign_App = Add-ApplicationAssignment -ApplicationId $ApplicationId -TargetGroupId $TargetGroupId -InstallIntent "available"
        Write-Host "Assigned '$AADGroup' to $($Create_App.displayName)/$($create_App.id) with" $Assign_App.InstallIntent "install Intent"

        Write-Host

        }

    }

    
    else {

    write-host
    write-host "No applications found..." -f Red
    write-host

    }

}

[System.Threading.Thread]::CurrentThread.CurrentCulture = $OldCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $OldUICulture
