













$managementGroup = 'AzGovTest7'
$description = 'Unit test junk: sorry for littering. Please delete me!'
$updatedDescription = "Updated $description"
$metadataName = 'testName'
$metadataValue = 'testValue'
$metadata = "{'$metadataName':'$metadataValue'}"
$enforcementModeDefault = 'Default'
$enforcementModeDoNotEnforce = 'DoNotEnforce'

$updatedMetadataName = 'newTestName'
$updatedMetadataValue = 'newTestValue'
$updatedMetadata = "{'$metadataName':'$metadataValue', '$updatedMetadataName': '$updatedMetadataValue'}"

$parameterDisplayName = 'List of locations'
$parameterDescription = 'An array of permitted locations for resources.'
$parameterDefinition = "{ 'listOfAllowedLocations': { 'type': 'array', 'metadata': { 'description': '$parameterDescription', 'strongType': 'location', 'displayName': '$parameterDisplayName' } } }"
$fullParameterDefinition = "{ 'listOfAllowedLocations': { 'type': 'array', 'metadata': { 'description': '$parameterDescription', 'strongType': 'location', 'displayName': '$parameterDisplayName' } }, 'effectParam': { 'type': 'string', 'defaultValue': 'deny' } }"


function Test-PolicyDefinitionCRUD
{
    
    $policyName = Get-ResourceName

    
    $expected = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode Indexed -Description $description
    $actual = Get-AzPolicyDefinition -Name $policyName
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual $expected.Properties.Mode $actual.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -DisplayName testDisplay -Description $updatedDescription -Policy ".\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    New-AzPolicyDefinition -Name test2 -Policy "{""if"":{""source"":""action"",""equals"":""blah""},""then"":{""effect"":""deny""}}" -Description $description
    $list = Get-AzPolicyDefinition | ?{ $_.Name -in @($policyName, 'test2') }
    Assert-True { $list.Count -eq 2 }

    
    $list = Get-AzPolicyDefinition -Custom
    Assert-True { $list.Count -gt 0 }
    $builtIns = $list | Where-Object { $_.Properties.policyType -ieq 'BuiltIn' }
    Assert-True { $builtIns.Count -eq 0 }

    
    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name 'test2' -Force
    Assert-AreEqual True $remove
}


function Test-PolicyDefinitionMode
{
    
    $policyName = Get-ResourceName

    
    $expected = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode All -Description $description
    $actual = Get-AzPolicyDefinition -Name $policyName
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -DisplayName testDisplay -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -DisplayName testDisplay -Mode 'All' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -DisplayName testDisplay -Mode 'Indexed' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'Indexed' $actual.Properties.Mode
    Assert-AreEqual 'Indexed' $expected.Properties.Mode

    
    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    
    
    $expected = New-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode All -Description $description
    $actual = Get-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName -DisplayName testDisplay -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName -DisplayName testDisplay -Mode 'All' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName -DisplayName testDisplay -Mode 'Indexed' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'Indexed' $actual.Properties.Mode
    Assert-AreEqual 'Indexed' $expected.Properties.Mode

    
    $remove = Remove-AzPolicyDefinition -ManagementGroupName $managementGroup -Name $policyName -Force
    Assert-AreEqual True $remove

    
    $subscriptionId = $subscriptionId = (Get-AzContext).Subscription.Id

    
    $expected = New-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode All -Description $description
    $actual = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -DisplayName testDisplay -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -DisplayName testDisplay -Mode 'All' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'All' $actual.Properties.Mode
    Assert-AreEqual 'All' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -DisplayName testDisplay -Mode 'Indexed' -Description $updatedDescription -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'Indexed' $actual.Properties.Mode
    Assert-AreEqual 'Indexed' $expected.Properties.Mode

    
    $remove = Remove-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -Force
    Assert-AreEqual True $remove

    
    
    $expected = New-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -Policy "$TestOutputRoot\SampleKeyVaultDataPolicyDefinition.json" -Mode 'Microsoft.KeyVault.Data' -Description $description
    $actual = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual 'Microsoft.KeyVault.Data' $actual.Properties.Mode
    Assert-AreEqual 'Microsoft.KeyVault.Data' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -DisplayName testDisplay -Description $updatedDescription -Policy "$TestOutputRoot\SampleKeyVaultDataPolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'Microsoft.KeyVault.Data' $actual.Properties.Mode
    Assert-AreEqual 'Microsoft.KeyVault.Data' $expected.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -DisplayName testDisplay -Mode 'Microsoft.KeyVault.Data' -Description $updatedDescription -Policy "$TestOutputRoot\SampleKeyVaultDataPolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual 'Microsoft.KeyVault.Data' $actual.Properties.Mode
    Assert-AreEqual 'Microsoft.KeyVault.Data' $expected.Properties.Mode 

    
    $remove = Remove-AzPolicyDefinition -SubscriptionId $subscriptionId -Name $policyName -Force
    Assert-AreEqual True $remove
}


function Test-PolicyDefinitionWithUri
{
    
    $policyName = Get-ResourceName

    
    $actual = New-AzPolicyDefinition -Name $policyName -Policy "https://raw.githubusercontent.com/vivsriaus/armtemplates/master/policyDef.json" -Mode All -Description $description
    $expected = Get-AzPolicyDefinition -Name $policyName
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual $expected.Properties.Mode $actual.Properties.Mode

    
    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

}


function Test-PolicyAssignmentCRUD
{
    
    $rgname = Get-ResourceGroupName
    $policyName = Get-ResourceName

    
    $rg = New-AzResourceGroup -Name $rgname -Location "west us"
    $policy = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description

    
    $actual = New-AzPolicyAssignment -Name testPA -PolicyDefinition $policy -Scope $rg.ResourceId -Description $description
    $expected = Get-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId

    
    $actualId = Get-AzPolicyAssignment -Id $actual.ResourceId
    Assert-AreEqual $actual.ResourceId $actualId.ResourceId

    
    $set = Set-AzPolicyAssignment -Id $actualId.ResourceId -DisplayName testDisplay
    Assert-AreEqual testDisplay $set.Properties.DisplayName

    
    $expected = New-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId -PolicyDefinition $policy -Description $description
    $list = Get-AzPolicyAssignment -Scope $rg.ResourceId | ?{ $_.Name -in @('testPA', 'test2') }
    Assert-AreEqual 2 @($list).Count

    
    $list = Get-AzPolicyAssignment -IncludeDescendent | ?{ $_.Name -in @('testPA', 'test2') }
    Assert-AreEqual 2 @($list).Count

    
    $list = Get-AzPolicyAssignment | ?{ $_.Name -in @('testPA', 'test2') }
    Assert-AreEqual 0 @($list).Count

    
    $remove = Remove-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzResourceGroup -Name $rgname -Force
    Assert-AreEqual True $remove
}


function Test-PolicyAssignmentIdentity
{
    
    $rgname = Get-ResourceGroupName
    $policyName = Get-ResourceName
    $location = "westus"

    
    $rg = New-AzResourceGroup -Name $rgname -Location $location
    $policy = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description

    
    $actual = New-AzPolicyAssignment -Name testPA -PolicyDefinition $policy -Scope $rg.ResourceId -Description $description -AssignIdentity -Location $location
    $expected = Get-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual "SystemAssigned" $expected.Identity.Type
    Assert-NotNull($expected.Identity.PrincipalId)
    Assert-NotNull($expected.Identity.TenantId)
    Assert-AreEqual $location $actual.Location
    Assert-AreEqual $expected.Location $actual.Location

    
    $actualById = Get-AzPolicyAssignment -Id $actual.ResourceId
    Assert-AreEqual $actual.ResourceId $actualById.ResourceId
    Assert-AreEqual "SystemAssigned" $actualById.Identity.Type
    Assert-NotNull($actualById.Identity.PrincipalId)
    Assert-NotNull($actualById.Identity.TenantId)
    Assert-AreEqual $location $actualById.Location

    
    $setResult = Set-AzPolicyAssignment -Id $actualById.ResourceId -DisplayName "testDisplay"
    Assert-AreEqual "testDisplay" $setResult.Properties.DisplayName
    Assert-AreEqual "SystemAssigned" $setResult.Identity.Type
    Assert-NotNull($setResult.Identity.PrincipalId)
    Assert-NotNull($setResult.Identity.TenantId)
    Assert-AreEqual $location $setResult.Location

    
    $withoutIdentityResult = New-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId -PolicyDefinition $policy -Description $description
    Assert-Null($withoutIdentityResult.Identity)
    Assert-Null($withoutIdentityResult.Location)

    
    $setResult = Set-AzPolicyAssignment -Id $withoutIdentityResult.ResourceId -AssignIdentity -Location $location
    Assert-AreEqual "SystemAssigned" $setResult.Identity.Type
    Assert-NotNull($setResult.Identity.PrincipalId)
    Assert-NotNull($setResult.Identity.TenantId)
    Assert-AreEqual $location $setResult.Location

    
    $list = Get-AzPolicyAssignment -Scope $rg.ResourceId | ?{ $_.Name -in @('testPA', 'test2') }
    Assert-AreEqual "SystemAssigned" ($list.Identity.Type | Select -Unique)
    Assert-AreEqual 2 @($list.Identity.PrincipalId | Select -Unique).Count
    Assert-AreEqual 1 @($list.Identity.TenantId | Select -Unique).Count
    Assert-NotNull($list.Identity.TenantId | Select -Unique)
    Assert-AreEqual $location ($list.Location | Select -Unique)

    
    $remove = Remove-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzResourceGroup -Name $rgname -Force
    Assert-AreEqual True $remove
}


function Test-PolicyAssignmentEnforcementMode
{
    
    $rgname = Get-ResourceGroupName
    $policyName = Get-ResourceName
    $location = "westus"

    
    $rg = New-AzResourceGroup -Name $rgname -Location $location
    $policy = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description

    
    $actual = New-AzPolicyAssignment -Name testPA -PolicyDefinition $policy -Scope $rg.ResourceId -Description $description -Location $location -EnforcementMode DoNotEnforce
    $expected = Get-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual $expected.Properties.EnforcementMode $actual.Properties.EnforcementMode
	Assert-AreEqual $expected.Properties.EnforcementMode $enforcementModeDoNotEnforce
    Assert-AreEqual $location $actual.Location
    Assert-AreEqual $expected.Location $actual.Location

    
    $actualById = Get-AzPolicyAssignment -Id $actual.ResourceId    
    Assert-AreEqual $actual.Properties.EnforcementMode $actualById.Properties.EnforcementMode    

	
    $setResult = Set-AzPolicyAssignment -Id $actualById.ResourceId -DisplayName "testDisplay" -EnforcementMode Default
    Assert-AreEqual "testDisplay" $setResult.Properties.DisplayName
    Assert-AreEqual $enforcementModeDefault $setResult.Properties.EnforcementMode

    
    $setResult = Set-AzPolicyAssignment -Id $actualById.ResourceId -DisplayName "testDisplay" -EnforcementMode $enforcementModeDefault
    Assert-AreEqual "testDisplay" $setResult.Properties.DisplayName
    Assert-AreEqual $enforcementModeDefault $setResult.Properties.EnforcementMode	

    
    $withoutEnforcementMode = New-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId -PolicyDefinition $policy -Description $description
    Assert-AreEqual $enforcementModeDefault $withoutEnforcementMode.Properties.EnforcementMode

    
    $setResult = Set-AzPolicyAssignment -Id $withoutEnforcementMode.ResourceId -Location $location -EnforcementMode $enforcementModeDoNotEnforce
    Assert-AreEqual $enforcementModeDoNotEnforce $setResult.Properties.EnforcementMode

	
    $setResult = Set-AzPolicyAssignment -Id $withoutEnforcementMode.ResourceId -Location $location -EnforcementMode DoNotEnforce
    Assert-AreEqual $enforcementModeDoNotEnforce $setResult.Properties.EnforcementMode

    
    $list = Get-AzPolicyAssignment -Scope $rg.ResourceId | ?{ $_.Name -in @('testPA', 'test2') }
    Assert-AreEqual 2 @($list.Properties.EnforcementMode | Select -Unique).Count    

    
    $remove = Remove-AzPolicyAssignment -Name testPA -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyAssignment -Name test2 -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzResourceGroup -Name $rgname -Force
    Assert-AreEqual True $remove
}


function Test-PolicySetDefinitionCRUD
{
    
    $policySetDefName = Get-ResourceName
    $policyDefName = Get-ResourceName

    
    $policyDefinition = New-AzPolicyDefinition -Name $policyDefName -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description
    $policySet = "[{""policyDefinitionId"":""" + $policyDefinition.PolicyDefinitionId + """}]"
    $expected = New-AzPolicySetDefinition -Name $policySetDefName -PolicyDefinition $policySet -Description $description -Metadata $metadata
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    $expected = Set-AzPolicySetDefinition -Name $policySetDefName -DisplayName testDisplay -Description $updatedDescription
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    $actual = Get-AzPolicySetDefinition | ?{ $_.Name -eq $policySetDefName }
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    $list = Get-AzPolicySetDefinition -Custom
    Assert-True { $list.Count -gt 0 }
    $builtIns = $list | Where-Object { $_.Properties.policyType -ieq 'BuiltIn' }
    Assert-True { $builtIns.Count -eq 0 }

    
    $remove = Remove-AzPolicySetDefinition -Name $policySetDefName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyDefName -Force
    Assert-AreEqual True $remove
}


function Test-PolicyDefinitionWithParameters
{
    
    $actual = New-AzPolicyDefinition -Name testPDWP -Policy "$TestOutputRoot\SamplePolicyDefinitionWithParameters.json" -Parameter "$TestOutputRoot\SamplePolicyDefinitionParameters.json" -Description $description
    $expected = Get-AzPolicyDefinition -Name testPDWP
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-NotNull($actual.Properties.Parameters)
    Assert-NotNull($expected.Properties.Parameters)
    Assert-NotNull($expected.Properties.Parameters.listOfAllowedLocations)
    Assert-AreEqual "array" $expected.Properties.Parameters.listOfAllowedLocations.type
    Assert-AreEqual "location" $expected.Properties.Parameters.listOfAllowedLocations.metadata.strongType
    Assert-NotNull($expected.Properties.Parameters.effectParam)
    Assert-AreEqual "deny" $expected.Properties.Parameters.effectParam.defaultValue
    Assert-AreEqual "string" $expected.Properties.Parameters.effectParam.type

    
    $remove = Remove-AzPolicyDefinition -Name testPDWP -Force
    Assert-AreEqual True $remove

    
    $actual = New-AzPolicyDefinition -Name testPDWP -Policy "$TestOutputRoot\SamplePolicyDefinitionWithParameters.json" -Parameter $fullParameterDefinition -Description $description
    $expected = Get-AzPolicyDefinition -Name testPDWP
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-NotNull($actual.Properties.Parameters)
    Assert-NotNull($expected.Properties.Parameters)
    Assert-NotNull($expected.Properties.Parameters.listOfAllowedLocations)
    Assert-AreEqual "array" $expected.Properties.Parameters.listOfAllowedLocations.type
    Assert-AreEqual "location" $expected.Properties.Parameters.listOfAllowedLocations.metadata.strongType
    Assert-NotNull($expected.Properties.Parameters.effectParam)
    Assert-AreEqual "deny" $expected.Properties.Parameters.effectParam.defaultValue
    Assert-AreEqual "string" $expected.Properties.Parameters.effectParam.type

    
    $remove = Remove-AzPolicyDefinition -Name testPDWP -Force
    Assert-AreEqual True $remove
}


function Test-PolicySetDefinitionWithParameters
{
    $policyDefName = Get-ResourceName
    $policySetDefName = Get-ResourceName

    
    $policyDefinition = New-AzPolicyDefinition -Name $policyDefName -Policy "$TestOutputRoot\SamplePolicyDefinitionWithParameters.json" -Description $description -Parameter "$TestOutputRoot\SamplePolicyDefinitionParameters.json"

    
    $parameters = "{ 'listOfAllowedLocations': { 'value': ""[parameters('listOfAllowedLocations')]"" } }"
    $policySet = "[{'policyDefinitionId': '$($policyDefinition.PolicyDefinitionId)', 'parameters': $parameters}]"
    $expected = New-AzPolicySetDefinition -Name $policySetDefName -PolicyDefinition $policySet -Description $description -Metadata $metadata -Parameter $parameterDefinition
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName
    Assert-AreEqual $metadataValue $actual.Properties.metadata.testName
    Assert-AreEqual $parameterDescription $expected.Properties.Parameters.listOfAllowedLocations.metadata.description
    Assert-AreEqual $parameterDisplayName $expected.Properties.Parameters.listOfAllowedLocations.metadata.displayName

    
    $updatedParameterDisplayName = 'Location Array'
    $updatedParameterDescription = 'Array of allowed resource locations.'
    $updatedParameterDefinition = "{ 'listOfAllowedLocations': { 'type': 'array', 'metadata': { 'description': '$updatedParameterDescription', 'strongType': 'location', 'displayName': '$updatedParameterDisplayName' } } }"
    $expected = Set-AzPolicySetDefinition -Name $policySetDefName -PolicyDefinition $policySet -Description $updatedDescription -Metadata $updatedMetadata -Parameter $updatedParameterDefinition
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName
    Assert-AreEqual $metadataValue $actual.Properties.metadata.testName
    Assert-AreEqual $updatedMetadataValue $actual.Properties.metadata.newTestName
    Assert-AreEqual $updatedParameterDescription $expected.Properties.Parameters.listOfAllowedLocations.metadata.description
    Assert-AreEqual $updatedParameterDisplayName $expected.Properties.Parameters.listOfAllowedLocations.metadata.displayName

    
    $remove = Remove-AzPolicySetDefinition -Name $policySetDefName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyDefName -Force
    Assert-AreEqual True $remove
}


function Test-PolicyAssignmentWithParameters
{
    
    $rgname = Get-ResourceGroupName
    $policyName = Get-ResourceName

    
    $rg = New-AzResourceGroup -Name $rgname -Location "west us"
    $policy = New-AzPolicyDefinition -Name $policyName -Policy "$TestOutputRoot\SamplePolicyDefinitionWithParameters.json" -Parameter "$TestOutputRoot\SamplePolicyDefinitionParameters.json" -Description $description
    $array = @("West US", "West US 2")
    $param = @{"listOfAllowedLocations"=$array}

    
    $actual = New-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyDefinition $policy -PolicyParameterObject $param -Description $description
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    $remove = Remove-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    
    $actual = New-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyDefinition $policy -PolicyParameter "$TestOutputRoot\SamplePolicyAssignmentParameters.json" -Description $description
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

	
    
    $actual = Set-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyParameter '{ "listOfAllowedLocations": { "value": [ "something", "something else" ] } }'
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual "something" $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual "something else" $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    $remove = Remove-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    
    $actual = New-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyDefinition $policy -PolicyParameter '{ "listOfAllowedLocations": { "value": [ "West US", "West US 2" ] } }' -Description $description -Metadata $metadata
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    $remove = Remove-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    
    $actual = New-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyDefinition $policy -listOfAllowedLocations $array -Description $description -Metadata $metadata
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    $remove = Remove-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    
    $actual = New-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyDefinition $policy -listOfAllowedLocations $array -effectParam "Disabled" -Description $description -Metadata $metadata
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName
    Assert-AreEqual "Disabled" $expected.Properties.Parameters.effectParam.Value
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    
    $newDescription = "$description - Updated"
    $newMetadata =  "{'Meta1': 'Value1', 'Meta2': { 'Meta22': 'Value22' }}"
    $actual = Set-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -Description $newDescription -Metadata $newMetadata
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual $array[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]
    Assert-AreEqual $newDescription $expected.Properties.Description
    Assert-NotNull $expected.Properties.Metadata
    Assert-AreEqual 'Value1' $expected.Properties.Metadata.Meta1
    Assert-AreEqual 'Value22' $expected.Properties.Metadata.Meta2.Meta22

	
	
    $array2 = @("West2 US2", "West2 US22")
    $param2 = @{"listOfAllowedLocations"=$array2}
    $actual = Set-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId -PolicyParameterObject $param2
    $expected = Get-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual Microsoft.Authorization/policyAssignments $actual.ResourceType
    Assert-AreEqual $expected.PolicyAssignmentId $actual.PolicyAssignmentId
    Assert-AreEqual $expected.Properties.PolicyDefinitionId $policy.PolicyDefinitionId
    Assert-AreEqual $expected.Properties.Scope $rg.ResourceId
    Assert-AreEqual $array2[0] $expected.Properties.Parameters.listOfAllowedLocations.Value[0]
    Assert-AreEqual $array2[1] $expected.Properties.Parameters.listOfAllowedLocations.Value[1]

    
    $remove = Remove-AzPolicyAssignment -Name testPAWP -Scope $rg.ResourceId
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyName -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzResourceGroup -Name $rgname -Force
    Assert-AreEqual True $remove
}


function Test-PolicyDefinitionCRUDAtManagementGroup
{
    
    $policyName = Get-ResourceName

    
    $expected = New-AzPolicyDefinition -Name $policyName -ManagementGroupName $managementGroup -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode Indexed -Description $description
    $actual = Get-AzPolicyDefinition -Name $policyName -ManagementGroupName $managementGroup
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual $expected.Properties.Mode $actual.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -ManagementGroupName $managementGroup -DisplayName testDisplay -Description $updatedDescription -Policy ".\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName -ManagementGroupName $managementGroup 
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    New-AzPolicyDefinition -Name test2 -ManagementGroupName $managementGroup -Policy "{""if"":{""source"":""action"",""equals"":""blah""},""then"":{""effect"":""deny""}}" -Description $description
    $list = Get-AzPolicyDefinition -ManagementGroupName $managementGroup | ?{ $_.Name -in @($policyName, 'test2') }
    Assert-True { $list.Count -eq 2 }

    
    $remove = Remove-AzPolicyDefinition -Name $policyName -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name 'test2' -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $remove
}


function Test-PolicyDefinitionCRUDAtSubscription
{
    
    $policyName = Get-ResourceName
    $subscriptionId = (Get-AzContext).Subscription.Id

    
    $expected = New-AzPolicyDefinition -Name $policyName -SubscriptionId $subscriptionId -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Mode Indexed -Description $description
    $actual = Get-AzPolicyDefinition -Name $policyName -SubscriptionId $subscriptionId 
    Assert-NotNull $actual
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicyDefinitionId $actual.PolicyDefinitionId
    Assert-NotNull($actual.Properties.PolicyRule)
    Assert-AreEqual $expected.Properties.Mode $actual.Properties.Mode

    
    $actual = Set-AzPolicyDefinition -Name $policyName -SubscriptionId $subscriptionId -DisplayName testDisplay -Description $updatedDescription -Policy ".\SamplePolicyDefinition.json" -Metadata $metadata
    $expected = Get-AzPolicyDefinition -Name $policyName -SubscriptionId $subscriptionId
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description
    Assert-NotNull($actual.Properties.Metadata)
    Assert-AreEqual $metadataValue $actual.Properties.Metadata.$metadataName

    
    New-AzPolicyDefinition -Name test2 -SubscriptionId $subscriptionId -Policy "{""if"":{""source"":""action"",""equals"":""blah""},""then"":{""effect"":""deny""}}" -Description $description
    $list = Get-AzPolicyDefinition -SubscriptionId $subscriptionId | ?{ $_.Name -in @($policyName, 'test2') }
    Assert-True { $list.Count -eq 2 }

    
    $remove = Remove-AzPolicyDefinition -Name $policyName -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name 'test2' -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $remove
}


function Test-PolicySetDefinitionCRUDAtManagementGroup
{
    
    $policySetDefName = Get-ResourceName
    $policyDefName = Get-ResourceName

    
    $policyDefinition = New-AzPolicyDefinition -Name $policyDefName -ManagementGroupName $managementGroup -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description
    $policySet = "[{""policyDefinitionId"":""" + $policyDefinition.PolicyDefinitionId + """}]"
    $expected = New-AzPolicySetDefinition -Name $policySetDefName -ManagementGroupName $managementGroup -PolicyDefinition $policySet -Description $description
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName -ManagementGroupName $managementGroup
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)

    
    $expected = Set-AzPolicySetDefinition -Name $policySetDefName -ManagementGroupName $managementGroup -DisplayName testDisplay -Description $updatedDescription
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName -ManagementGroupName $managementGroup
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description

    
    $actual = Get-AzPolicySetDefinition -ManagementGroupName $managementGroup | ?{ $_.Name -eq $policySetDefName }
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description

    
    $remove = Remove-AzPolicySetDefinition -Name $policySetDefName -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyDefName -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $remove
}


function Test-PolicySetDefinitionCRUDAtSubscription
{
    
    $policySetDefName = Get-ResourceName
    $policyDefName = Get-ResourceName
    $subscriptionId = (Get-AzContext).Subscription.Id

    
    $policyDefinition = New-AzPolicyDefinition -Name $policyDefName -SubscriptionId $subscriptionId -Policy "$TestOutputRoot\SamplePolicyDefinition.json" -Description $description
    $policySet = "[{""policyDefinitionId"":""" + $policyDefinition.PolicyDefinitionId + """}]"
    $expected = New-AzPolicySetDefinition -Name $policySetDefName -SubscriptionId $subscriptionId -PolicyDefinition $policySet -Description $description
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName -SubscriptionId $subscriptionId
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)

    
    $expected = Set-AzPolicySetDefinition -Name $policySetDefName -SubscriptionId $subscriptionId -DisplayName testDisplay -Description $updatedDescription
    $actual = Get-AzPolicySetDefinition -Name $policySetDefName -SubscriptionId $subscriptionId
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description

    
    $actual = Get-AzPolicySetDefinition -SubscriptionId $subscriptionId | ?{ $_.Name -eq $policySetDefName }
    Assert-AreEqual $expected.Name $actual.Name
    Assert-AreEqual $expected.PolicySetDefinitionId $actual.PolicySetDefinitionId
    Assert-NotNull($actual.Properties.PolicyDefinitions)
    Assert-AreEqual $expected.Properties.DisplayName $actual.Properties.DisplayName
    Assert-AreEqual $expected.Properties.Description $actual.Properties.Description

    
    $remove = Remove-AzPolicySetDefinition -Name $policySetDefName -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $remove

    $remove = Remove-AzPolicyDefinition -Name $policyDefName -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $remove
}

function Test-GetCmdletFilterParameter
{
    
    $builtins = Get-AzureRmPolicyDefinition -Builtin
    $builtins | %{ Assert-AreEqual $_.Properties.PolicyType "Builtin" }

    $custom = Get-AzureRmPolicyDefinition -Custom
    $custom | %{ Assert-AreEqual $_.Properties.PolicyType "Custom" }

    $all = Get-AzureRmPolicyDefinition
    Assert-AreEqual ($builtins.Count + $custom.Count) $all.Count

    
    $builtins = Get-AzureRmPolicySetDefinition -Builtin
    $builtins | %{ Assert-AreEqual $_.Properties.PolicyType "Builtin" }

    $custom = Get-AzureRmPolicySetDefinition -Custom
    $custom | %{ Assert-AreEqual $_.Properties.PolicyType "Custom" }

    $all = Get-AzureRmPolicySetDefinition
    Assert-AreEqual ($builtins.Count + $custom.Count) $all.Count
}

function Test-GetBuiltinsByName
{
    
    $builtins = Get-AzureRmPolicyDefinition -Builtin
    foreach ($builtin in $builtins)
    {
        $definition = Get-AzureRmPolicyDefinition -Name $builtin.Name
        Assert-AreEqual $builtin.ResourceId $definition.ResourceId
    }

    
    $builtins = Get-AzureRmPolicySetDefinition -Builtin
    foreach ($builtin in $builtins)
    {
        $setDefinition = Get-AzureRmPolicySetDefinition -Name $builtin.Name
        Assert-AreEqual $builtin.ResourceId $setDefinition.ResourceId
    }
}




$someName = 'someName'
$someScope = 'someScope'
$someId = 'someId'
$someManagementGroup = 'someManagementGroup'
$someJsonSnippet = "{ 'someThing': 'someOtherThing' }"
$someJsonArray = "[$someJsonSnippet]"
$somePolicyDefinition = 'somePolicyDefinition'
$somePolicySetDefinition = 'somePolicySetDefinition'
$somePolicyParameter = 'somePolicyParameter'
$someParameterObject = @{'parm1'='a'; 'parm2'='b' }
$someDisplayName = "Some display name"


$parameterSetError = 'Parameter set cannot be resolved using the specified named parameters.'
$missingParameters = 'Cannot process command because of one or more missing mandatory parameters:'
$onlyDefinitionOrSetDefinition = 'Only one of PolicyDefinition or PolicySetDefinition can be specified, not both.'
$policyAssignmentNotFound = 'PolicyAssignmentNotFound : '
$policySetDefinitionNotFound = 'PolicySetDefinitionNotFound : '
$policyDefinitionNotFound = 'PolicyDefinitionNotFound : '
$invalidRequestContent = 'InvalidRequestContent : The request content was invalid and could not be deserialized: '
$missingSubscription = 'MissingSubscription : The request did not have a subscription or a valid tenant level resource provider.'
$undefinedPolicyParameter = 'UndefinedPolicyParameter : The policy assignment'
$invalidPolicyRule = 'InvalidPolicyRule : Failed to parse policy rule: '
$authorizationFailed = 'AuthorizationFailed : '
$allSwitchNotSupported = 'The -IncludeDescendent switch is not supported for management group scopes.'
$httpMethodNotSupported = "HttpMethodNotSupported : The http method 'DELETE' is not supported for a resource collection."
$parameterNullOrEmpty = '. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.'

function Test-GetPolicyAssignmentParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $mgScope = "/providers/Microsoft.Management/managementGroups/$someManagementGroup"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyAssignments/$someName"

    
    $ok = Get-AzPolicyAssignment

    
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName } $policyAssignmentNotFound
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -Scope $goodScope } $policyAssignmentNotFound
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -PolicyDefinitionId $someId } $policyAssignmentNotFound
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -IncludeDescendent } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -Scope $someScope -Id $someId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyDefinitionId $someId } $missingSubscription
    Assert-ThrowsContains { Get-AzPolicyAssignment -Name $someName -Scope $someScope -IncludeDescendent } $parameterSetError

    
    $ok = Get-AzPolicyAssignment -Scope $goodScope
    Assert-ThrowsContains { Get-AzPolicyAssignment -Scope $someScope -Id $someId } $parameterSetError
    $ok = Get-AzPolicyAssignment -Scope $goodScope -PolicyDefinitionId $someId
    Assert-AreEqual 0 $ok.Count
    $ok = Get-AzPolicyAssignment -Scope $goodScope -IncludeDescendent
    Assert-ThrowsContains { Get-AzPolicyAssignment -Scope $mgScope -IncludeDescendent } $allSwitchNotSupported
    Assert-ThrowsContains { Get-AzPolicyAssignment -Scope $someScope -PolicyDefinitionId $someId -IncludeDescendent } $parameterSetError

    
    Assert-ThrowsContains { Get-AzPolicyAssignment -Id $goodId } $policyAssignmentNotFound
    Assert-ThrowsContains { Get-AzPolicyAssignment -Id $someId -PolicyDefinitionId $someId } $missingSubscription
    Assert-ThrowsContains { Get-AzPolicyAssignment -Id $someId -IncludeDescendent } $parameterSetError

    
    $ok = Get-AzPolicyAssignment -PolicyDefinitionId $someId
    Assert-AreEqual 0 $ok.Count
    Assert-ThrowsContains { Get-AzPolicyAssignment -PolicyDefinitionId $someId -IncludeDescendent } $parameterSetError

    
    $ok = Get-AzPolicyAssignment -IncludeDescendent
}


function Test-NewPolicyAssignmentParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodPolicyDefinition = Get-AzPolicyDefinition | ?{ $_.Properties.parameters -eq $null } | select -First 1
    $goodPolicySetDefinition = Get-AzPolicySetDefinition | ?{ $_.Properties.parameters -eq $null } | select -First 1
    $wrongParameters = '{ "someKindaParameter": { "value": [ "Mmmm", "Doh!" ] } }'

    
    Assert-ThrowsContains { New-AzPolicyAssignment } $missingParameters

    
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName } $missingParameters
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $goodScope } $invalidRequestContent
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyDefinition $goodPolicyDefinition } $missingSubscription
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyDefinition $goodPolicyDefinition -PolicySetDefinition $goodPolicySetDefinition } $onlyDefinitionOrSetDefinition
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $goodScope -PolicyDefinition $goodPolicyDefinition -PolicyParameterObject $someParameterObject } $undefinedPolicyParameter
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $goodScope -PolicyDefinition $goodPolicyDefinition -PolicyParameter $wrongParameters } $undefinedPolicyParameter
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyDefinition $goodPolicyDefinition -PolicyParameterObject $someParameterObject -PolicyParameter $somePolicyParameter } $parameterSetError
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicySetDefinition $goodPolicySetDefinition -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicySetDefinition $goodPolicySetDefinition -PolicyParameterObject $someParameterObject -PolicyParameter $somePolicyParameter } $parameterSetError
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyParameterObject $someParameterObject } $parameterSetError
    Assert-ThrowsContains { New-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyParameter $somePolicyParameter } $parameterSetError

    
    Assert-ThrowsContains { New-AzPolicyAssignment -Scope $someScope } $missingParameters
}


function Test-RemovePolicyAssignmentParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyAssignments/$someName"
    $goodObject = Get-AzPolicyAssignment | ?{ $_.Name -like '*test*' -or $_.Properties.Description -like '*test*' } | select -First 1

    
    Assert-ThrowsContains { Remove-AzPolicyAssignment } $missingParameters

    
    Assert-ThrowsContains { Remove-AzPolicyAssignment -Name $someName } $missingParameters
    $ok = Remove-AzPolicyAssignment -Name $someName -Scope $goodScope
    Assert-AreEqual True $ok
    Assert-ThrowsContains { Remove-AzPolicyAssignment -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Remove-AzPolicyAssignment -Name $someName -Scope $someScope -Id $someId } $parameterSetError

    
    Assert-ThrowsContains { Remove-AzPolicyAssignment -Scope $someScope } $missingParameters
    Assert-ThrowsContains { Remove-AzPolicyAssignment -Scope $someScope -Id $someId } $parameterSetError

    
    $ok = Remove-AzPolicyAssignment -Id $goodId
    Assert-AreEqual True $ok
}


function Test-SetPolicyAssignmentParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyAssignments/$someName"
    $someParameters = '{ "someKindaParameter": { "value": [ "Mmmm", "Doh!" ] } }'
	$someLocation = 'west us'
	$someNotScope = 'not scope'

    
    Assert-ThrowsContains { Set-AzPolicyAssignment } $missingParameters

    
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $goodScope } $policyAssignmentNotFound
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -NotScope $someNotScope } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -DisplayName $someDisplayName } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Description $description } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Metadata $metadata } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -PolicyParameterObject $someParameterObject } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -PolicyParameter $someParameters } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -AssignIdentity } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Location $someLocation } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -Id $someId } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -DisplayName $someDisplayName } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -Id $someId } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -PolicyParameter $someParameters } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Name $someName -Scope $someScope -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -AssignIdentity -Location $someLocation } $missingSubscription

	
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $goodId } $policyAssignmentNotFound
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -DisplayName $someDisplayName } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameter $someParameters } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -PolicyParameter $someParameters } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -AssignIdentity } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -Location $someLocation } $missingSubscription
    Assert-ThrowsContains { Set-AzPolicyAssignment -Id $someId -NotScope $someNotScope -DisplayName $someDisplayName -Description $description -Metadata $metadata -PolicyParameterObject $someParameterObject -AssignIdentity -Location $someLocation } $missingSubscription
}


function Test-GetPolicyDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyDefinitions/$someName"

    
    $ok = Get-AzPolicyDefinition

    
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName } $policyDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -ManagementGroupName $someManagementGroup } $policyDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -SubscriptionId $subscriptionId } $policyDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Builtin } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Custom } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Id $someId -SubscriptionId $subscriptionId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Id $someId -BuiltIn } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Name $someName -Id $someId -Custom } $parameterSetError

    
    $ok = Get-AzureRmPolicyDefinition -Id $goodId
    Assert-ThrowsContains { Get-AzPolicyDefinition -Id $goodId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Id $goodId -SubscriptionId $subscriptionId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Id $goodId -BuiltIn } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicyDefinition -Id $goodId -Custom } $parameterSetError

    
    $ok = Get-AzPolicyDefinition -ManagementGroupName $someManagementGroup
    Assert-ThrowsContains { Get-AzPolicyDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError
    $ok = Get-AzPolicyDefinition -ManagementGroupName $someManagementGroup -BuiltIn
    $ok = Get-AzPolicyDefinition -ManagementGroupName $someManagementGroup -Custom
    Assert-ThrowsContains { Get-AzPolicyDefinition -ManagementGroupName $someManagementGroup -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicyDefinition -SubscriptionId $subscriptionId
    $ok = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -BuiltIn
    $ok = Get-AzPolicyDefinition -SubscriptionId $subscriptionId -Custom
    Assert-ThrowsContains { Get-AzPolicyDefinition -SubscriptionId $subscriptionId -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicyDefinition -BuiltIn
    Assert-ThrowsContains { Get-AzPolicyDefinition -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicyDefinition -Custom
}


function Test-NewPolicyDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id

    
    Assert-ThrowsContains { New-AzPolicyDefinition } $missingParameters

    
    Assert-ThrowsContains { New-AzPolicyDefinition -Name $someName } $missingParameters
    Assert-ThrowsContains { New-AzPolicyDefinition -Name $someName -Policy $someJsonSnippet } $invalidPolicyRule
    Assert-ThrowsContains { New-AzPolicyDefinition -Name $someName -Policy $someJsonSnippet -ManagementGroupName $someManagementGroup } $authorizationFailed
    Assert-ThrowsContains { New-AzPolicyDefinition -Name $someName -Policy $someJsonSnippet -SubscriptionId $subscriptionId } $invalidPolicyRule
    Assert-ThrowsContains { New-AzPolicyDefinition -Name $someName -Policy $someJsonSnippet -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { New-AzPolicyDefinition -Policy $someJsonSnippet } $missingParameters
}


function Test-RemovePolicyDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyDefinitions/$someName"
    $goodObject = Get-AzPolicyDefinition -Builtin | select -First 1

    
    Assert-ThrowsContains { Remove-AzPolicyDefinition } $missingParameters

    
    Assert-ThrowsContains { Remove-AzPolicyDefinition -Name $someName -Id $someId } $parameterSetError
    $ok = Remove-AzPolicyDefinition -Name $someName -Force
    Assert-AreEqual True $ok
    $ok = Remove-AzPolicyDefinition -Name $someName -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $ok
    $ok = Remove-AzPolicyDefinition -Name $someName -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $ok

    
    $ok = Remove-AzPolicyDefinition -Id $goodId -Force
    Assert-AreEqual True $ok
    Assert-ThrowsContains { Remove-AzPolicyDefinition -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Remove-AzPolicyDefinition -Id $someId -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Remove-AzPolicyDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Remove-AzPolicyDefinition -SubscriptionId $subscriptionId -Force } $missingParameters
}


function Test-SetPolicyDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policyDefinitions/$someName"
    $goodObject = Get-AzPolicyDefinition -Builtin | select -First 1

    
    Assert-ThrowsContains { Set-AzPolicyDefinition } $missingParameters

    
    Assert-ThrowsContains { Set-AzPolicyDefinition -Name $someName } $policyDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicyDefinition -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyDefinition -Name $someName -ManagementGroupName $someManagementGroup } $policyDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicyDefinition -Name $someName -SubscriptionId $subscriptionId } $policyDefinitionNotFound

    
    Assert-ThrowsContains { Set-AzPolicyDefinition -Id $goodId } $policyDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicyDefinition -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicyDefinition -Id $someId -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Set-AzPolicyDefinition -ManagementGroupName $someManagementGroup } $missingParameters
    Assert-ThrowsContains { Set-AzPolicyDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Set-AzPolicyDefinition -SubscriptionId $subscriptionId } $missingParameters
}


function Test-GetPolicySetDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policySetDefinitions/$someName"

    
    $ok = Get-AzPolicySetDefinition

    
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName } $policySetDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -ManagementGroupName $someManagementGroup } $policySetDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -SubscriptionId $subscriptionId } $policySetDefinitionNotFound
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Builtin } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Custom } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Id $someId -SubscriptionId $subscriptionId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Id $someId -BuiltIn } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Name $someName -Id $someId -Custom } $parameterSetError

    
    $ok = Get-AzPolicySetDefinition -Id $goodId
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Id $goodId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Id $goodId -SubscriptionId $subscriptionId } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Id $goodId -BuiltIn } $parameterSetError
    Assert-ThrowsContains { Get-AzPolicySetDefinition -Id $goodId -Custom } $parameterSetError

    
    $ok = Get-AzPolicySetDefinition -ManagementGroupName $someManagementGroup
    Assert-ThrowsContains { Get-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError
    $ok = Get-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -BuiltIn
    $ok = Get-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -Custom
    Assert-ThrowsContains { Get-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicySetDefinition -SubscriptionId $subscriptionId
    $ok = Get-AzPolicySetDefinition -SubscriptionId $subscriptionId -BuiltIn
    $ok = Get-AzPolicySetDefinition -SubscriptionId $subscriptionId -Custom
    Assert-ThrowsContains { Get-AzPolicySetDefinition -SubscriptionId $subscriptionId -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicySetDefinition -BuiltIn
    Assert-ThrowsContains { Get-AzPolicySetDefinition -BuiltIn -Custom } $parameterSetError

    
    $ok = Get-AzPolicySetDefinition -Custom
}


function Test-NewPolicySetDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id

    
    Assert-ThrowsContains { New-AzPolicySetDefinition } $missingParameters

    
    Assert-ThrowsContains { New-AzPolicySetDefinition -Name $someName } $missingParameters
    Assert-ThrowsContains { New-AzPolicySetDefinition -Name $someName -PolicyDefinition $someJsonArray } $invalidRequestContent
    Assert-ThrowsContains { New-AzPolicySetDefinition -Name $someName -PolicyDefinition $someJsonArray -ManagementGroupName $someManagementGroup } $authorizationFailed
    Assert-ThrowsContains { New-AzPolicySetDefinition -Name $someName -PolicyDefinition $someJsonArray -SubscriptionId $subscriptionId } $invalidRequestContent
    Assert-ThrowsContains { New-AzPolicySetDefinition -Name $someName -PolicyDefinition $someJsonArray -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { New-AzPolicySetDefinition -PolicyDefinition $someJsonArray } $missingParameters
}


function Test-RemovePolicySetDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policySetDefinitions/$someName"
    $goodObject = Get-AzPolicySetDefinition -Builtin | select -First 1

    
    Assert-ThrowsContains { Remove-AzPolicySetDefinition } $missingParameters

    
    Assert-ThrowsContains { Remove-AzPolicySetDefinition -Name $someName -Id $someId } $parameterSetError
    $ok = Remove-AzPolicySetDefinition -Name $someName -Force
    Assert-AreEqual True $ok
    $ok = Remove-AzPolicySetDefinition -Name $someName -ManagementGroupName $managementGroup -Force
    Assert-AreEqual True $ok
    $ok = Remove-AzPolicySetDefinition -Name $someName -SubscriptionId $subscriptionId -Force
    Assert-AreEqual True $ok

    
    $ok = Remove-AzPolicySetDefinition -Id $goodId -Force
    Assert-AreEqual True $ok
    Assert-ThrowsContains { Remove-AzPolicySetDefinition -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Remove-AzPolicySetDefinition -Id $someId -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Remove-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Remove-AzPolicySetDefinition -SubscriptionId $subscriptionId -Force } $httpMethodNotSupported
}


function Test-SetPolicySetDefinitionParameters
{
    $subscriptionId = (Get-AzContext).Subscription.Id
    $goodScope = "/subscriptions/$subscriptionId"
    $goodId = "$goodScope/providers/Microsoft.Authorization/policySetDefinitions/$someName"
    $goodObject = Get-AzPolicySetDefinition -Builtin | select -First 1

    
    Assert-ThrowsContains { Set-AzPolicySetDefinition } $missingParameters

    
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Name $someName } $policySetDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Name $someName -Id $someId } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Name $someName -ManagementGroupName $someManagementGroup } $policySetDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Name $someName -SubscriptionId $subscriptionId } $policySetDefinitionNotFound

    
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Id $goodId } $policySetDefinitionNotFound
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Id $someId -ManagementGroupName $someManagementGroup } $parameterSetError
    Assert-ThrowsContains { Set-AzPolicySetDefinition -Id $someId -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Set-AzPolicySetDefinition -ManagementGroupName $someManagementGroup } $missingParameters
    Assert-ThrowsContains { Set-AzPolicySetDefinition -ManagementGroupName $someManagementGroup -SubscriptionId $subscriptionId } $parameterSetError

    
    Assert-ThrowsContains { Set-AzPolicySetDefinition -SubscriptionId $subscriptionId } $missingParameters
}
