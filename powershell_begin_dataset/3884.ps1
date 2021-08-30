
function Test-CrudUserAssignedIdentity
{
    $MSINamespace = "Microsoft.ManagedIdentity";
    $MSIResourceType = "userAssignedIdentities";
    $MSIPreferredLocation = "westus";
    $rgName1 = getAssetName;
    $rgName2 = getAssetName;
    $identityName1 = getAssetName;
    $identityName2 = getAssetName;
    $identityName3 = getAssetName;
    $location = Get-Location -ProviderNamespace $MSINamespace -ResourceType $MSIResourceType -PreferredLocation $MSIPreferredLocation;
    $identityType = "$MSINamespace/$MSIResourceType";

    try
    {
        
        New-AzResourceGroup -Name $rgName1 -Location $location;
        
        New-AzResourceGroup -Name $rgName2 -Location $location;

        
        $identity1 = New-AzUserAssignedIdentity -ResourceGroupName $rgName1 -Name $identityName1;
        Assert-AreEqual $identity1.ResourceGroupName $rgName1
        Assert-AreEqual $identity1.Name $identityName1;
        Assert-AreEqual $identity1.Type $identityType;

        
        $identity2 = New-AzUserAssignedIdentity -ResourceGroupName $rgName2 -Name $identityName2 -Location $location;
        Assert-AreEqual $identity2.ResourceGroupName $rgName2;
        Assert-AreEqual $identity2.Name $identityName2;
        Assert-AreEqual $identity2.Type $identityType;

        
        $createJob = New-AzUserAssignedIdentity -ResourceGroupName $rgName2 -Name $identityName3 -Location $location -AsJob;
        $createJob | Wait-Job;
        $identity3 = $createJob | Receive-Job;
        Assert-AreEqual $identity3.ResourceGroupName $rgName2;
        Assert-AreEqual $identity3.Name $identityName3;
        Assert-AreEqual $identity3.Type $identityType;

        
        $identity1 = Get-AzUserAssignedIdentity -ResourceGroupName $rgName1 -Name $identityName1
        Assert-NotNull $identity1;
        Assert-AreEqual $identity1.ResourceGroupName $rgName1;
        Assert-AreEqual $identity1.Name $identityName1;
        Assert-AreEqual $identity1.Type $identityType;

        
        $identities = Get-AzUserAssignedIdentity -ResourceGroupName $rgName1
        Assert-AreEqual $identities.Count 1
        Assert-AreEqual $identities[0].ResourceGroupName $rgName1;
        Assert-AreEqual $identities[0].Name $identityName1;
        Assert-AreEqual $identities[0].Type $identityType;

        
        $identities = Get-AzUserAssignedIdentity -ResourceGroupName $rgName2
        Assert-AreEqual $identities.Count 2

        
        Remove-AzUserAssignedIdentity -ResourceGroupName $rgName1 -Name $identityName1 -Force;
        $resourceGroupIdentities = Get-AzUserAssignedIdentity -ResourceGroupName $rgName1
        Assert-Null $resourceGroupIdentities;

        
        $deleteJob = Remove-AzUserAssignedIdentity -ResourceGroupName $rgName2 -Name $identityName2 -AsJob -Force;
        $deleteJob | Wait-Job;
        $resourceGroupIdentities = Get-AzUserAssignedIdentity -ResourceGroupName $rgName2
        Assert-AreEqual $resourceGroupIdentities.Count 1
    }
    finally
    {
        Remove-AzResourceGroup -Name $rgname1 -Force
        Remove-AzResourceGroup -Name $rgname1 -Force
    }
}