



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
    
    
    
    Function Get-ManagedAppPolicyRegistrationSummary() {
    
    
    
        [cmdletbinding()]
    
        param
        (
            [ValidateSet("Android_iOS", "WIP_WE", "WIP_MDM")]
            $ReportType,
            $NextPage
        )
    
        $graphApiVersion = "Beta"
        $Stoploop = $false
        [int]$Retrycount = "0"
        do{
        try {
        
            if ($ReportType -eq "" -or $ReportType -eq $null) {
                $ReportType = "Android_iOS"
        
            }
            elseif ($ReportType -eq "Android_iOS") {
        
                $Resource = "/deviceAppManagement/managedAppStatuses('appregistrationsummary')?fetch=6000&policyMode=0&columns=DisplayName,UserEmail,ApplicationName,ApplicationInstanceId,ApplicationVersion,DeviceName,DeviceType,DeviceManufacturer,DeviceModel,AndroidPatchVersion,AzureADDeviceId,MDMDeviceID,Platform,PlatformVersion,ManagementLevel,PolicyName,LastCheckInDate"
                if ($NextPage -ne "" -and $NextPage -ne $null) {
                    $Resource += "&seek=$NextPage"
                }
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        
            }
    
            elseif ($ReportType -eq "WIP_WE") {
        
                $Resource = "deviceAppManagement/managedAppStatuses('windowsprotectionreport')"
                if ($NextPage -ne "" -and $NextPage -ne $null) {
                    $Resource += "&seek=$NextPage"
                }
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
        
            }
    
            elseif ($ReportType -eq "WIP_MDM") {
        
                $Resource = "deviceAppManagement/mdmWindowsInformationProtectionPolicies"
        
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
            }
            $Stoploop = $true
        }
    
        catch {
    
            $ex = $_.Exception
    
            
            if($ex.Response.StatusCode.value__ -eq "503") {
                $Retrycount = $Retrycount + 1
                $Stoploop = $Retrycount -gt 3
                if($Stoploop -eq $false) {
                    Start-Sleep -Seconds 5
                    continue
                }
            }
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
            $Stoploop = $true
            break
        }
    }
    while ($Stoploop -eq $false)
    
    }
    
    
    
    Function Test-AuthToken(){
    
        
        if ($global:authToken) {
    
            
            $DateTime = (Get-Date).ToUniversalTime()
    
            
            $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
    
            if ($TokenExpires -le 0) {
    
                write-host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
                write-host
    
                
    
                if ($User -eq $null -or $User -eq "") {
    
                    $global:User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                    Write-Host
    
                }
    
                $global:authToken = Get-AuthToken -User $User
    
            }
        }
    
        
    
        else {
    
            if ($User -eq $null -or $User -eq "") {
    
                $global:User = Read-Host -Prompt "Please specify your user principal name for Azure Authentication"
                Write-Host
    
            }
    
            
            $global:authToken = Get-AuthToken -User $User
    
        }
    }
    
    
    
    Test-AuthToken
    
    
    
    Write-Host
    
    $ExportPath = Read-Host -Prompt "Please specify a path to export the policy data to e.g. C:\IntuneOutput"
    
    
    
    if (!(Test-Path "$ExportPath")) {
    
        Write-Host
        Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow
    
        $Confirm = read-host
    
        if ($Confirm -eq "y" -or $Confirm -eq "Y") {
    
            new-item -ItemType Directory -Path "$ExportPath" | Out-Null
            Write-Host
    
        }
    
        else {
    
            Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
            Write-Host
            break
    
        }
    
    }
    
    Write-Host
    
    
    
    $AppType = Read-Host -Prompt "Please specify the type of report [Android_iOS, WIP_WE, WIP_MDM]"
    
    if($AppType -eq "Android_iOS" -or $AppType -eq "WIP_WE" -or $AppType -eq "WIP_MDM") {
                
        Write-Host
        write-host "Running query against Microsoft Graph to download App Protection Report for '$AppType'.." -f Yellow
    
        $ofs = ','
        $stream = [System.IO.StreamWriter]::new("$ExportPath\AppRegistrationSummary_$AppType.csv", $false, [System.Text.Encoding]::UTF8)
        $ManagedAppPolicies = Get-ManagedAppPolicyRegistrationSummary -ReportType $AppType
        $stream.WriteLine([string]($ManagedAppPolicies.content.header | % {$_.columnName } ))
    
        do {
            Test-AuthToken
    
            write-host "Your data is being downloaded for '$AppType'..."
            $MoreItem = $ManagedAppPolicies.content.skipToken -ne "" -and $ManagedAppPolicies.content.skipToken -ne $null
            
            foreach ($SummaryItem in $ManagedAppPolicies.content.body) {
    
                $stream.WriteLine([string]($SummaryItem.values -replace ",","."))
            }
            
            if ($MoreItem){
    
                $ManagedAppPolicies = Get-ManagedAppPolicyRegistrationSummary -ReportType $AppType -NextPage ($ManagedAppPolicies.content.skipToken)
            }
    
        } while ($MoreItem)
        
        $stream.close()
        
        write-host
        
    }
        
    else {
        
        Write-Host "AppType isn't a valid option..." -ForegroundColor Red
        Write-Host
        
    }