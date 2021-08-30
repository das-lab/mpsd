
































































[CmdletBinding()]
Param(
   [Parameter(Mandatory=$TRUE, HelpMessage="Name of capacity for scaling or target for workspaces migration.")]
   [string]$CapacityName,
   
   [Parameter(Mandatory=$TRUE, HelpMessage="ResourceGroup of capacity for scaling or target for workspaces migration")]
   [string]$CapacityResourceGroup,

   [Parameter(Mandatory=$False, HelpMessage="True if you want to assign all workspaces from srouce capacity only, provide SourceCapacityName and SourceCapacityResourceGroup params")]
   [bool]$AssignWorkspacesOnly = $FALSE,
   
   [Parameter(Mandatory=$FALSE, HelpMessage="Target SKU for scaling, e.g. A3")]
   [string]$TargetSku,
   
   [Parameter(Mandatory=$False, HelpMessage="Name of source capacity for workspaces migration.")]
   [string]$SourceCapacityName,
   
   [Parameter(Mandatory=$False, HelpMessage="ResourceGroup of source capacity for workspaces migration.")]
   [string]$SourceCapacityResourceGroup,

   [Parameter(Mandatory=$False, HelpMessage="User Name")]
   [string]$username,
   
   [Parameter(Mandatory=$False, HelpMessage="Password")]
   [string]$Password

)






$apiUri = "https://api.powerbi.com/v1.0/myorg/"



FUNCTION GetAuthToken
{
    Import-Module AzureRm

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"

    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    
    IF ($username -ne "" -and $Password -ne "")
    {
        $creds = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential" -ArgumentList $Username,$Password
        $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $creds)
    }
    ELSE
    {
        $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, 'Always')
    }

    return $authResult
}

$token = GetAuthToken



$auth_header = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}



FUNCTION GetCapacityObjectID($capacitiesList, $capacity_name) 
{
    $done = $False 
    
    
    $capacitiesList.value | ForEach-Object -Process {
        
        if ($_.DisplayName -eq $capacity_name)
        {
            Write-Host ">>> Object ID for" $capacity_name  "is" $_.id
            $done = $True
            return $_.id
        }
    }

    
    IF ($done -ne $True) {
        $errmsg = "Capacity " + $capacity_name + " object ID was not found!"
        Write-Error $errmsg
        Break Script
    }
}



FUNCTION AssignWorkspacesToCapacity($source_capacity_objectid, $target_capacity_objectid)
{
    $getCapacityGroupsUri = $apiUri + "groups?$" + "filter=capacityId eq " + "'$source_capacity_objectid'"
    $capacityWorkspaces = Invoke-RestMethod -Method GET -Headers $auth_header -Uri $getCapacityGroupsUri

    
    $capacityWorkspaces.value | ForEach-Object -Process {          
      Write-Host ">>> Assigning workspace Name:" $_.name " Id:" $_.id "to capacity id:" $target_capacity_objectid
      $assignToCapacityUri = $apiUri + "groups/" + $_.id + "/AssignToCapacity"
      $assignToCapacityBody = @{capacityId=$target_capacity_objectid} | ConvertTo-Json
      Invoke-RestMethod -Method Post -Headers $auth_header -Uri $assignToCapacityUri -Body $assignToCapacityBody -ContentType 'application/json'

      
      DO
      {
        $assignToCapacityStatusUri = $apiUri + "groups/" + $_.id + "/CapacityAssignmentStatus"
        $status = Invoke-RestMethod -Method Get -Headers $auth_header -Uri $assignToCapacityStatusUri

        
        IF ($status.status -eq 'AssignmentFailed')
        {
          $errmsg = "workspace " +  $_.id + " assignment has failed!, script will stop."
          Break Script
        }
        
        Start-Sleep -Milliseconds 200

        Write-Host ">>> Assigning workspace Id:" $_.id "to capacity id:" $target_capacity_objectid "Status:" $status.status
      } while ($status.status -ne 'CompletedSuccessfully')
    }

    $getCapacityGroupsUri = $apiUri + "groups?$" + "filter=capacityId eq " + "'$target_capacity_objectid'"
    $capacityWorkspaces = Invoke-RestMethod -Method GET -Headers $auth_header -Uri $getCapacityGroupsUri

    return $capacityWorkspaces
}



FUNCTION ValidateCapacityInActiveState($capacity_name, $resource_group)
{
    
    $getCapacityResult = Get-AzureRmPowerBIEmbeddedCapacity -Name $capacity_name -ResourceGroup $resource_group

    IF (!$getCapacityResult -OR $getCapacityResult -eq "")
    {
        $errmsg = "Capacity " + $capacity_name +" was not found!"
        Write-Error -Message $errmsg
        Break Script
    }
    ELSEIF ($getCapacityResult.State.ToString() -ne "Succeeded") 
    {
        $errmsg = "Capacity " + $capacity_name + " is not in active state!"
        Write-Error $errmsg
        Break Script
    }

    return $getCapacityResult
}


$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()


$mainCapacity = ValidateCapacityInActiveState $CapacityName $CapacityResourceGroup


IF ($AssignWorkspacesOnly -ne $TRUE)
{
    
    $context = Get-AzureRmContext
    $isUserAdminOnCapacity = $False
    $mainCapacity.Administrator | ForEach-Object -Process {
      IF ($_ -eq $context.Account.Id)
      {
        $isUserAdminOnCapacity = $TRUE
      } 
    }

    IF ($isUserAdminOnCapacity -eq $False)
    {
        $errmsg = "User is not capacity administrator!"
        Write-Error $errmsg
        Break Script 
    }

    
    IF ($mainCapacity.Sku -eq $TargetSku)
    { 
      Write-Host "Current SKU is equal to the target SKU, No scale is needed!"
      Break Script
    }        

    Write-Host
    Write-Host "========================================================================================================================" -ForegroundColor DarkGreen
    Write-Host "                                           SCALING CAPACITY FROM" $mainCapacity.Sku "To" $TargetSku -ForegroundColor DarkGreen
    Write-Host "========================================================================================================================" -ForegroundColor DarkGreen
    Write-Host 
    Write-Host ">>> Capacity" $CapacityName "is available and ready for scaling!"

    
    $guid = New-Guid
    $temporaryCapacityName = 'tmpcapacity' + $guid.ToString().Replace('-','s').ToLowerInvariant()
    $temporarycapacityResourceGroup = $mainCapacity.ResourceGroup
    
    Write-Host
    Write-Host ">>> STEP 1 - Creating a temporary capacity name:"$temporaryCapacityName
    $newcap = New-AzureRmPowerBIEmbeddedCapacity -ResourceGroupName $mainCapacity.ResourceGroup -Name $temporaryCapacityName -Location $mainCapacity.Location -Sku $TargetSku -Administrator $mainCapacity.Administrator
  
    
    IF (!$newcap -OR $newcap.State.ToString() -ne 'Succeeded') 
    {
        Remove-AzureRmPowerBIEmbeddedCapacity -Name $temporaryCapacityName -ResourceGroupName $temporarycapacityResourceGroup    
        $errmsg = "Try to remove temporary capacity due to some failure while provisioning!, Please restart script!"
        Write-Error -Message $errmsg	
        Break Script
    }

    
    $getCapacityUri = $apiUri + "capacities"
    $capacitiesList = Invoke-RestMethod -Method Get -Headers $auth_header -Uri $getCapacityUri
    $sourceCapacityObjectId = GetCapacityObjectID $capacitiesList $CapacityName
    $targetCapacityObjectId = GetCapacityObjectID $capacitiesList $temporaryCapacityName
    Write-Host ">>> STEP 1 - Completed!"

    Write-Host
    Write-Host ">>> STEP 2 - Assigning workspaces"
    $assignedMainCapacityWorkspaces = AssignWorkspacesToCapacity $sourceCapacityObjectId $targetCapacityObjectId
    Write-Host ">>> STEP 2 Completed!"

    Write-Host
    Write-Host ">>> STEP 3 - Scaling capacity " $CapacityName "to" $targetSku
    Update-AzureRmPowerBIEmbeddedCapacity -Name $CapacityName -sku $targetSku        
    $mainCapacity = ValidateCapacityInActiveState $CapacityName $CapacityResourceGroup
    Write-Host ">>> STEP 3 completed!" $CapacityName "to" $targetSku

    Write-Host
    Write-Host ">>> STEP 4 - Assigning workspaces to main capacity"
    $AssignedTargetCapacityWorkspaces = AssignWorkspacesToCapacity $targetCapacityObjectId $sourceCapacityObjectId
    
    
    $diff =  Compare-Object $AssignedTargetCapacityWorkspaces.value $assignedMainCapacityWorkspaces.value
    if ($diff -ne $null)
    {  
        $errmsg = "Something went wrong while assigning workspaces to the main capacity, Please re-execute the script"
        Write-Error -Message $errmsg
        Break Script
    }
    Write-Host ">>> STEP 4 Completed!"

    Write-Host
    Write-Host ">>> STEP 5 - Delete temporary capacity"
    
    Remove-AzureRmPowerBIEmbeddedCapacity -Name $temporaryCapacityName -ResourceGroupName $temporarycapacityResourceGroup
    Write-Host ">>> STEP 5 Completed!"
}
ELSE
{
    
    $getCapacityUri = $apiUri + "capacities"
    $capacitiesList = Invoke-RestMethod -Method Get -Headers $auth_header -Uri $getCapacityUri
 
    ValidateCapacityInActiveState $CapacityName $CapacityResourceGroup
    Write-Host ">>> Capacity" $CapacityName "is available and ready!"
    $sourceCapacityObjectId = GetCapacityObjectID $capacitiesList $SourceCapacityName

    ValidateCapacityInActiveState $SourceCapacityName $SourceCapacityResourceGroup
    $targetCapacityObjectId = GetCapacityObjectID $capacitiesList $CapacityName
    Write-Host ">>> Capacity" $SourceCapacityName "is available and ready!"

    $assignedcapacities = AssignWorkspacesToCapacity $sourceCapacityObjectId $targetCapacityObjectId
}

Write-Host
Write-Host "========================================================================================================================" -ForegroundColor DarkGreen
Write-Host "                                           Completed Successfully" -ForegroundColor DarkGreen
Write-Host "                                              Total Duration" -ForegroundColor DarkGreen
Write-Host "                                            "$stopwatch.Elapsed -ForegroundColor DarkGreen
Write-Host "========================================================================================================================" -ForegroundColor DarkGreen
