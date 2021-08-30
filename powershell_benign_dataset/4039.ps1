














function Test-SkuCreate
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Microsoft"
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku

    Assert-NotNull $createdProfile
    Assert-AreEqual $profileName $createdProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName
    Assert-AreEqual $profileSku $createdProfile.Sku.Name

	$profileSku = "Standard_Verizon"
    $profileName = getAssetName
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku 
    Assert-NotNull $createdProfile
    Assert-AreEqual $profileName $createdProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName
    Assert-AreEqual $profileSku $createdProfile.Sku.Name

	$profileSku = "Premium_Verizon"
    $profileName = getAssetName
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku 
    Assert-NotNull $createdProfile
    Assert-AreEqual $profileName $createdProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName
    Assert-AreEqual $profileSku $createdProfile.Sku.Name
	
	$profileSku = "Standard_Akamai"
    $profileName = getAssetName
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku 
    Assert-NotNull $createdProfile
    Assert-AreEqual $profileName $createdProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName
    Assert-AreEqual $profileSku $createdProfile.Sku.Name

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}

function Test-ProfileCrud
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku -Tag $tags

    Assert-NotNull $createdProfile
    Assert-AreEqual $profileName $createdProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $createdProfile.ResourceGroupName
    Assert-AreEqual $profileSku $createdProfile.Sku.Name
    Assert-Tags $tags $createdProfile.Tags

    $retrievedProfile = Get-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-NotNull $retrievedProfile
    Assert-AreEqual $profileName $retrievedProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $retrievedProfile.ResourceGroupName
    Assert-Tags $tags $createdProfile.Tags

    $newTags = @{"tag1" = "value3"; "tag2" = "value4"}
    $retrievedProfile.Tags = $newTags

    $updatedProfile = Set-AzCdnProfile -CdnProfile $retrievedProfile

    Assert-NotNull $updatedProfile
    Assert-AreEqual $profileName $updatedProfile.Name
    Assert-AreEqual $resourceGroup.ResourceGroupName $updatedProfile.ResourceGroupName
    Assert-Tags $newTags $updatedProfile.Tags

    $sso = Get-AzCdnProfileSsoUrl -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName
    Assert-NotNull $sso.SsoUriValue

    $removed = Remove-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -PassThru

    Assert-True { $removed }
    Assert-ThrowsContains { Get-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "does not exist"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-ProfileDeleteWithEndpoints
{
    $profileName = getAssetName
    $endpointName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Akamai"

    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku

    New-AzCdnEndpoint -CdnProfile $createdProfile -OriginName "contoso" -OriginHostName "www.contoso.com" -EndpointName $endpointName

    $removed = Remove-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Force -PassThru

    Assert-True { $removed }
    Assert-ThrowsContains { Get-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "does not exist"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-ProfileDeleteAndSsoWithPiping
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku -Tag $tags

    Assert-NotNull $createdProfile

    $sso = Get-AzCdnProfileSsoUrl -CdnProfile $createdProfile
    Assert-NotNull $sso.SsoUriValue

    $removed = Remove-AzCdnProfile -CdnProfile $createdProfile -PassThru

    Assert-True { $removed }
    Assert-ThrowsContains { Get-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName } "does not exist"

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-ProfilePipeline
{
    $profileName1 = getAssetName
    $profileName2 = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Verizon"
    $tags = @{"tag1" = "value1"; "tag2" = "value2"}
    $createdProfile1 = New-AzCdnProfile -ProfileName $profileName1 -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku -Tag $tags

    Assert-NotNull $createdProfile1

    $createdProfile2 = New-AzCdnProfile -ProfileName $profileName2 -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku -Tag $tags

    Assert-NotNull $createdProfile2

    $profiles = Get-AzCdnProfile | where {($_.Name -eq $profileName1) -or ($_.Name -eq $profileName2)}

    Assert-True { $profiles.Count -eq 2 }

    Get-AzCdnProfile | where {($_.Name -eq $profileName1) -or ($_.Name -eq $profileName2)} | Remove-AzCdnProfile -Force

    $deletedProfiles = Get-AzCdnProfile | where {($_.Name -eq $profileName1) -or ($_.Name -eq $profileName2)}

    Assert-True { $deletedProfiles.Count -eq 0 }

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-ProfileGetResourceUsages
{
    $profileName = getAssetName
    $endpointName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Akamai"

    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku

    $profileResourceUsage = Get-AzCdnProfileResourceUsage -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

    Assert-True {$profileResourceUsage.Count -eq 1}
    Assert-True {$profileResourceUsage[0].CurrentValue -eq 0}

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}


function Test-ProfileGetSupportedOptimizationType
{
    $profileName = getAssetName
    $resourceGroup = TestSetup-CreateResourceGroup
    $profileLocation = "EastUS"
    $profileSku = "Standard_Akamai"
    
    $createdProfile = New-AzCdnProfile -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName -Location $profileLocation -Sku $profileSku

	$supportedOptimizationTypes = Get-AzCdnProfileSupportedOptimizationType -ProfileName $profileName -ResourceGroupName $resourceGroup.ResourceGroupName

	Assert-NotNull $supportedOptimizationTypes

    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}