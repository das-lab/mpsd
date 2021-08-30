
































































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



















Function Out-EncodedBinaryCommand
{


    [CmdletBinding(DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [Switch]
        $NoExit,

        [Switch]
        $NoProfile,

        [Switch]
        $NonInteractive,

        [Switch]
        $NoLogo,

        [Switch]
        $Wow64,
        
        [Switch]
        $Command,

        [ValidateSet('Normal', 'Minimized', 'Maximized', 'Hidden')]
        [String]
        $WindowStyle,

        [ValidateSet('Bypass', 'Unrestricted', 'RemoteSigned', 'AllSigned', 'Restricted')]
        [String]
        $ExecutionPolicy,
        
        [Switch]
        $PassThru
    )

    
    $EncodingBase = 2

    
    If($PSBoundParameters['Path'])
    {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else
    {
        $ScriptString = [String]$ScriptBlock
    }

    
    
    $RandomDelimiters  = @('_','-',',','{','}','~','!','@','%','&','<','>',';',':')

    
    @('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z') | ForEach-Object {$UpperLowerChar = $_; If(((Get-Random -Input @(1..2))-1 -eq 0)) {$UpperLowerChar = $UpperLowerChar.ToUpper()} $RandomDelimiters += $UpperLowerChar}
    
    
    $RandomDelimiters = (Get-Random -Input $RandomDelimiters -Count ($RandomDelimiters.Count/4))

    
    $DelimitedEncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {$DelimitedEncodedArray += ([Convert]::ToString(([Int][Char]$_),$EncodingBase) + (Get-Random -Input $RandomDelimiters))}

    
    $DelimitedEncodedArray = $DelimitedEncodedArray.SubString(0,$DelimitedEncodedArray.Length-1)

    
    $RandomDelimitersToPrint = (Get-Random -Input $RandomDelimiters -Count $RandomDelimiters.Length) -Join ''

    
    $ForEachObject = Get-Random -Input @('ForEach','ForEach-Object','%')
    $StrJoin       = ([Char[]]'[String]::Join'      | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $StrStr        = ([Char[]]'[String]'            | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Join          = ([Char[]]'-Join'               | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $CharStr       = ([Char[]]'Char'                | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $Int           = ([Char[]]'Int'                 | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ForEachObject = ([Char[]]$ForEachObject        | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $ToInt16       = ([Char[]]'[Convert]::ToInt16(' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $RandomDelimitersToPrintForDashSplit = ''
    ForEach($RandomDelimiter in $RandomDelimiters)
    {
        
        $Split = ([Char[]]'Split' | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

        $RandomDelimitersToPrintForDashSplit += ('-' + $Split + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimiter + "'" + ' '*(Get-Random -Input @(0,1)))
    }
    $RandomDelimitersToPrintForDashSplit = $RandomDelimitersToPrintForDashSplit.Trim()
    
    
    $RandomStringSyntax = ([Char[]](Get-Random -Input @('[String]$_','$_.ToString()')) | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $RandomConversionSyntax  = @()
    $RandomConversionSyntax += "[$CharStr]" + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $ToInt16 + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomStringSyntax + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ',' + $EncodingBase + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ')'
    $RandomConversionSyntax += $ToInt16 + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomStringSyntax + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + $EncodingBase + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input @('-as','-As','-aS','-AS')) + ' '*(Get-Random -Input @(0,1)) + "[$CharStr]"
    $RandomConversionSyntax = (Get-Random -Input $RandomConversionSyntax)

    
    $EncodedArray = ''
    ([Char[]]$ScriptString) | ForEach-Object {
        
        If([Convert]::ToString(([Int][Char]$_),$EncodingBase).Trim('0123456789').Length -gt 0) {$Quote = "'"}
        Else {$Quote = ''}
        $EncodedArray += ($Quote + [Convert]::ToString(([Int][Char]$_),$EncodingBase) + $Quote + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)))
    }

    
    $EncodedArray = ('(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray.Trim().Trim(',') + ')')

    
    
    
    
    $SetOfsVarSyntax      = @()
    $SetOfsVarSyntax     += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVarSyntax     += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "''"
    $SetOfsVar            = (Get-Random -Input $SetOfsVarSyntax)

    $SetOfsVarBackSyntax  = @()
    $SetOfsVarBackSyntax += 'Set-Item' + ' '*(Get-Random -Input @(1,2)) + "'Variable:OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBackSyntax += (Get-Random -Input @('Set-Variable','SV','SET')) + ' '*(Get-Random -Input @(1,2)) + "'OFS'" + ' '*(Get-Random -Input @(1,2)) + "' '"
    $SetOfsVarBack        = (Get-Random -Input $SetOfsVarBackSyntax)

    
    $SetOfsVar            = ([Char[]]$SetOfsVar     | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    $SetOfsVarBack        = ([Char[]]$SetOfsVarBack | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''

    
    $BaseScriptArray  = @()
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'." + $Split + "(" + ' '*(Get-Random -Input @(0,1)) + "'" + $RandomDelimitersToPrint + "'" + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + "'" + $DelimitedEncodedArray + "'" + ' '*(Get-Random -Input @(0,1)) + $RandomDelimitersToPrintForDashSplit + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    $BaseScriptArray += '(' + ' '*(Get-Random -Input @(0,1)) + $EncodedArray + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $ForEachObject + ' '*(Get-Random -Input @(0,1)) + '{' + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $RandomConversionSyntax + ')' +  ' '*(Get-Random -Input @(0,1)) + '}' + ' '*(Get-Random -Input @(0,1)) + ')'
    
    
    $NewScriptArray   = @()
    $NewScriptArray  += (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + $Join + ' '*(Get-Random -Input @(0,1)) + "''"
    $NewScriptArray  += $Join + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray)
    $NewScriptArray  += $StrJoin + '(' + ' '*(Get-Random -Input @(0,1)) + "''" + ' '*(Get-Random -Input @(0,1)) + ',' + ' '*(Get-Random -Input @(0,1)) + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + ')'
    $NewScriptArray  += '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVar + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"' + ' '*(Get-Random -Input @(0,1)) + '+' + ' '*(Get-Random -Input @(0,1)) + $StrStr + (Get-Random -Input $BaseScriptArray) + ' '*(Get-Random -Input @(0,1)) + '+' + '"' + ' '*(Get-Random -Input @(0,1)) + '$(' + ' '*(Get-Random -Input @(0,1)) + $SetOfsVarBack + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1)) + '"'

    
    $NewScript = (Get-Random -Input $NewScriptArray)

    
    
    $InvokeExpressionSyntax  = @()
    $InvokeExpressionSyntax += (Get-Random -Input @('IEX','Invoke-Expression'))
    
    
    
    $InvocationOperator = (Get-Random -Input @('.','&')) + ' '*(Get-Random -Input @(0,1))
    $InvokeExpressionSyntax += $InvocationOperator + "( `$ShellId[1]+`$ShellId[13]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$PSHome[" + (Get-Random -Input @(4,21)) + "]+`$PSHome[" + (Get-Random -Input @(30,34)) + "]+'x')"
    $InvokeExpressionSyntax += $InvocationOperator + "( `$env:ComSpec[4," + (Get-Random -Input @(15,24,26)) + ",25]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "((" + (Get-Random -Input @('Get-Variable','GV','Variable')) + " '*mdr*').Name[3,11,2]-Join'')"
    $InvokeExpressionSyntax += $InvocationOperator + "( " + (Get-Random -Input @('$VerbosePreference.ToString()','([String]$VerbosePreference)')) + "[1,3]+'x'-Join'')"
    
    

    
    $InvokeExpression = (Get-Random -Input $InvokeExpressionSyntax)

    
    $InvokeExpression = ([Char[]]$InvokeExpression | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
    
    
    $InvokeOptions  = @()
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $InvokeExpression + ' '*(Get-Random -Input @(0,1)) + '(' + ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + ')' + ' '*(Get-Random -Input @(0,1))
    $InvokeOptions += ' '*(Get-Random -Input @(0,1)) + $NewScript + ' '*(Get-Random -Input @(0,1)) + '|' + ' '*(Get-Random -Input @(0,1)) + $InvokeExpression

    $NewScript = (Get-Random -Input $InvokeOptions)

    
    If(!$PSBoundParameters['PassThru'])
    {
        
        $PowerShellFlags = @()

        
        
        $CommandlineOptions = New-Object String[](0)
        If($PSBoundParameters['NoExit'])
        {
          $FullArgument = "-NoExit";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoProfile'])
        {
          $FullArgument = "-NoProfile";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NonInteractive'])
        {
          $FullArgument = "-NonInteractive";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 5 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['NoLogo'])
        {
          $FullArgument = "-NoLogo";
          $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 4 -Maximum ($FullArgument.Length+1)))
        }
        If($PSBoundParameters['WindowStyle'] -OR $WindowsStyle)
        {
            $FullArgument = "-WindowStyle"
            If($WindowsStyle) {$ArgumentValue = $WindowsStyle}
            Else {$ArgumentValue = $PSBoundParameters['WindowStyle']}

            
            Switch($ArgumentValue.ToLower())
            {
                'normal'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('0','n','no','nor','norm','norma'))}}
                'hidden'    {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('1','h','hi','hid','hidd','hidde'))}}
                'minimized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('2','mi','min','mini','minim','minimi','minimiz','minimize'))}}
                'maximized' {If(Get-Random -Input @(0..1)) {$ArgumentValue = (Get-Random -Input @('3','ma','max','maxi','maxim','maximi','maximiz','maximize'))}}
                default {Write-Error "An invalid `$ArgumentValue value ($ArgumentValue) was passed to switch block for Out-PowerShellLauncher."; Exit;}
            }

            $PowerShellFlags += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1))) + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }
        If($PSBoundParameters['ExecutionPolicy'] -OR $ExecutionPolicy)
        {
            $FullArgument = "-ExecutionPolicy"
            If($ExecutionPolicy) {$ArgumentValue = $ExecutionPolicy}
            Else {$ArgumentValue = $PSBoundParameters['ExecutionPolicy']}
            
            $ExecutionPolicyFlags = @()
            $ExecutionPolicyFlags += '-EP'
            For($Index=3; $Index -le $FullArgument.Length; $Index++)
            {
                $ExecutionPolicyFlags += $FullArgument.SubString(0,$Index)
            }
            $ExecutionPolicyFlag = Get-Random -Input $ExecutionPolicyFlags
            $PowerShellFlags += $ExecutionPolicyFlag + ' '*(Get-Random -Minimum 1 -Maximum 3) + $ArgumentValue
        }
        
        
        
        If($CommandlineOptions.Count -gt 1)
        {
            $CommandlineOptions = Get-Random -InputObject $CommandlineOptions -Count $CommandlineOptions.Count
        }

        
        If($PSBoundParameters['Command'])
        {
            $FullArgument = "-Command"
            $CommandlineOptions += $FullArgument.SubString(0,(Get-Random -Minimum 2 -Maximum ($FullArgument.Length+1)))
        }

        
        For($i=0; $i -lt $PowerShellFlags.Count; $i++)
        {
            $PowerShellFlags[$i] = ([Char[]]$PowerShellFlags[$i] | ForEach-Object {$Char = $_.ToString().ToLower(); If(Get-Random -Input @(0..1)) {$Char = $Char.ToUpper()} $Char}) -Join ''
        }

        
        $CommandlineOptions = ($CommandlineOptions | ForEach-Object {$_ + " "*(Get-Random -Minimum 1 -Maximum 3)}) -Join ''
        $CommandlineOptions = " "*(Get-Random -Minimum 0 -Maximum 3) + $CommandlineOptions + " "*(Get-Random -Minimum 0 -Maximum 3)

        
        If($PSBoundParameters['Wow64'])
        {
            $CommandLineOutput = "C:\WINDOWS\SysWOW64\WindowsPowerShell\v1.0\powershell.exe $($CommandlineOptions) `"$NewScript`""
        }
        Else
        {
            
            
            $CommandLineOutput = "powershell $($CommandlineOptions) `"$NewScript`""
        }

        
        $CmdMaxLength = 8190
        If($CommandLineOutput.Length -gt $CmdMaxLength)
        {
            Write-Warning "This command exceeds the cmd.exe maximum allowed length of $CmdMaxLength characters! Its length is $($CmdLineOutput.Length) characters."
        }
        
        $NewScript = $CommandLineOutput
    }

    Return $NewScript
}