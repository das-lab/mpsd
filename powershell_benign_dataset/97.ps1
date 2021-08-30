




[CmdletBinding()]

Param(

    [Parameter(Mandatory=$true, HelpMessage="AdminUser@myenvironment.onmicrosoft.com")]
    $AdminUser,

    [Parameter(Mandatory=$false, HelpMessage="MySecAdminGroup")]
    [string]$SecAdminGroup,

    [Parameter(Mandatory=$false, HelpMessage="c:\mylist.txt")]
    $SecurityGroupList

)





if ($SecurityGroupList){

    $SecurityGroupList = Get-Content "$SecurityGroupList"

}

$AADEnvironment = (New-Object "System.Net.Mail.MailAddress" -ArgumentList $AdminUser).Host

$RBACRoleName    = "MDATP SecAdmin"  
$SecurityGroup   = "MDATP SecAdmin SG"  
$User = $AdminUser





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
          Write-Host
          Write-Host "AzureAD Powershell module not installed..." -f Red
          Write-Host "Install by running 'Install-Module AzureAD' or 'Install-Module AzureADPreview' from an elevated PowerShell prompt" -f Yellow
          Write-Host "Script can't continue..." -f Red
          Write-Host
          exit
      }
  
  
  
  
      if($AadModule.count -gt 1){
  
          $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
  
          $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }
  
              
  
              if($AadModule.count -gt 1){
  
              $aadModule = $AadModule | Select-Object -Unique
  
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
  
      Write-Host $_.Exception.Message -f Red
      Write-Host $_.Exception.ItemName -f Red
      Write-Host
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
              Write-Host

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
  Write-Host
  break

  }
  
}



Function Add-RBACRole(){



[cmdletbinding()]

param
(
    $JSON
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleDefinitions"

    try {

        if(!$JSON){

        Write-Host "No JSON was passed to the function, provide a JSON variable" -f Red
        break

        }

        Test-JSON -JSON $JSON

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $Json -ContentType "application/json"

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
    Write-Host
    break

    }

}
  


Function Get-RBACRole(){

  
  
  [cmdletbinding()]
  
  param
  (
      $Name
  )
  
  $graphApiVersion = "v1.0"
  $Resource = "deviceManagement/roleDefinitions"
  
      try {
  
        if($Name){
          $QueryString = "?`$filter=contains(displayName, '$Name')"
          $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)$($QueryString)"
          $rbacRoles = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
          $customRbacRoles = $rbacRoles | Where-Object { $_isBuiltInRoleDefinition -eq $false }
          return $customRbacRoles
        }
  
          else {
  
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
      Write-Host
      break
  
      }
  
}


  
Function Assign-RBACRole(){



[cmdletbinding()]

param
(
    $Id,
    $DisplayName,
    $MemberGroupId,
    $TargetGroupId
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/roleAssignments"
    
    try {

        if(!$Id){

        Write-Host "No Policy Id specified, specify a valid Application Id" -f Red
        break

        }

        if(!$DisplayName){

        Write-Host "No Display Name specified, specify a Display Name" -f Red
        break

        }

        if(!$MemberGroupId){

        Write-Host "No Member Group Id specified, specify a valid Target Group Id" -f Red
        break

        }

        if(!$TargetGroupId){

        Write-Host "No Target Group Id specified, specify a valid Target Group Id" -f Red
        break

        }


$JSON = @"
    {
    "id":"",
    "description":"",
    "displayName":"$DisplayName",
    "members":["$MemberGroupId"],
    "scopeMembers":["$TargetGroupId"],
    "roleDefinition@odata.bind":"https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$ID')"
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
    Write-Host
    break

    }

}




  
Write-Host
  

if($global:authToken){
  
    
    $DateTime = (Get-Date).ToUniversalTime()
  
    
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes
  
        if($TokenExpires -le 0){
  
        Write-Host "Authentication Token expired" $TokenExpires "minutes ago" -ForegroundColor Yellow
        Write-Host
  
            
  
            if($User -eq $null -or $User -eq ""){
  
            $User = Read-Host -Prompt "Please specify your Global Admin user for Azure Authentication (e.g. globaladmin@myenvironment.onmicrosoft.com):"
            Write-Host
  
            }
  
        $global:authToken = Get-AuthToken -User $User
  
        }
}
  

  
else {
  
    if($User -eq $null -or $User -eq ""){
  
    $User = Read-Host -Prompt "Please specify your Global Admin user for Azure Authentication (e.g. globaladmin@myenvironment.onmicrosoft.com):"
    Write-Host
  
    }
  

$global:authToken = Get-AuthToken -User $User
  
}
  

  


$JSON = @"
{
  "@odata.type": "
  "displayName": "$RBACRoleName",
  "description": "Role with access to modify Intune SecuriyBaselines and DeviceConfigurations",
  "permissions": [
    {
      "actions": [
        "Microsoft.Intune_Organization_Read",
        "Microsoft.Intune/SecurityBaselines/Assign",
        "Microsoft.Intune/SecurityBaselines/Create",
        "Microsoft.Intune/SecurityBaselines/Delete",
        "Microsoft.Intune/SecurityBaselines/Read",
        "Microsoft.Intune/SecurityBaselines/Update",
        "Microsoft.Intune/DeviceConfigurations/Assign",
        "Microsoft.Intune/DeviceConfigurations/Create",
        "Microsoft.Intune/DeviceConfigurations/Delete",
        "Microsoft.Intune/DeviceConfigurations/Read",
        "Microsoft.Intune/DeviceConfigurations/Update"
      ]
    }
  ],
  "isBuiltInRoleDefinition": false
}
"@
  




Write-Host "Configuring MDATP Intune SecAdmin Role..." -ForegroundColor Cyan
Write-Host
Write-Host "Connecting to Azure AD environment: $AADEnvironment..." -ForegroundColor Yellow
Write-Host

$RBAC_Roles = Get-RBACRole


if($RBAC_Roles | Where-Object { $_.displayName -eq "$RBACRoleName" }){

    Write-Host "Intune Role already exists with name '$RBACRoleName'..." -ForegroundColor Red
    Write-Host "Script can't continue..." -ForegroundColor Red
    Write-Host
    break

}


Write-Host "Adding new RBAC Role: $RBACRoleName..." -ForegroundColor Yellow
Write-Host "JSON:"
Write-Host $JSON
Write-Host

$NewRBACRole = Add-RBACRole -JSON $JSON
$NewRBACRoleID = $NewRBACRole.id


Write-Host "Getting Id for new role..." -ForegroundColor Yellow
$Updated_RBAC_Roles = Get-RBACRole

$NewRBACRoleID = ($Updated_RBAC_Roles | Where-Object {$_.displayName -eq "$RBACRoleName"}).id

Write-Host "$NewRBACRoleID"
Write-Host



if($SecAdminGroup){

  
  Write-Host "Verifying group '$SecAdminGroup' exists..." -ForegroundColor Yellow

  Connect-AzureAD -AzureEnvironmentName AzureCloud -AccountId $AdminUser | Out-Null
  $ValidatedSecAdminGroup = (Get-AzureADGroup -SearchString $SecAdminGroup).ObjectId

  if ($ValidatedSecAdminGroup){

    Write-Host "AAD Group '$SecAdminGroup' exists" -ForegroundColor Green
    Write-Host ""
    Write-Host "Adding AAD group $SecAdminGroup - $ValidatedSecAdminGroup to MDATP Role..." -ForegroundColor Yellow
    
    
    try {

      [System.Guid]::Parse($ValidatedSecAdminGroup) | Out-Null
      Write-Host "ObjectId: $ValidatedSecAdminGroup" -ForegroundColor Green
      Write-Host

    }
    
    catch {
    
        Write-Host "ObjectId: $ValidatedSecAdminGroup is not a valid ObjectId" -ForegroundColor Red
        Write-Host "Verify that your security group list only contains valid ObjectIds and try again." -ForegroundColor Cyan
        exit -1
    
    }

  Write-Host "Adding security group to RBAC role $RBACRoleName ..." -ForegroundColor Yellow

  Assign-RBACRole -Id $NewRBACRoleID -DisplayName 'MDATP RBAC Assignment' -MemberGroupId $ValidatedSecAdminGroup -TargetGroupId "default"
  

  }
  
  else {

    Write-Host "Group '$SecAdminGroup' does not exist. Please run script again and specify a valid group." -ForegroundColor Red
    Write-Host
    break
  
  }

}



if($SecurityGroupList){

  Write-Host "Validating Security Groups to add to Intune Role:" -ForegroundColor Yellow

  foreach ($SecurityGroup in $SecurityGroupList) {
    
    
    try {

      [System.Guid]::Parse($SecurityGroup) | Out-Null
      Write-Host "ObjectId: $SecurityGroup" -ForegroundColor Green
    
    }
    
    catch {

        Write-Host "ObjectId: $SecurityGroup is not a valid ObjectId" -ForegroundColor Red
        Write-Host "Verify that your security group list only contains valid ObjectIds and try again." -ForegroundColor Cyan
        exit -1
    
    }

  }

  
  $ValidatedSecurityGroupList = $SecurityGroupList -join "`",`""

  $SecurityGroupList
  $ValidatedSecurityGroupList

  Write-Host ""
  Write-Host "Adding security groups to RBAC role '$RBACRoleName'..." -ForegroundColor Yellow

  Assign-RBACRole -Id $NewRBACRoleID -DisplayName 'MDATP RBAC Assignment' -MemberGroupId $ValidatedSecurityGroupList -TargetGroupId "default"
  

}



Write-Host "Retrieving permissions for new role: $RBACRoleName..." -ForegroundColor Yellow
Write-Host

$RBAC_Role = Get-RBACRole | Where-Object { $_.displayName -eq "$RBACRoleName" }

Write-Host $RBAC_Role.displayName -ForegroundColor Green
Write-Host $RBAC_Role.id -ForegroundColor Cyan
$RBAC_Role.RolePermissions.resourceActions.allowedResourceActions
Write-Host



Write-Host "Members of RBAC Role '$RBACRoleName' should now have access to Security Baseline and" -ForegroundColor Cyan
write-host "Onboarded machines tiles in Microsoft Defender Security Center." -ForegroundColor Cyan
Write-Host
Write-Host "https://securitycenter.windows.com/configuration-management"
Write-Host
Write-Host "Add users and groups to the new role assignment 'MDATP RBAC Assignment' as needed." -ForegroundColor Cyan

Write-Host
Write-Host "Configuration of MDATP Intune SecAdmin Role complete..." -ForegroundColor Green
Write-Host
