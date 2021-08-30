














function Test-WorkspaceCreateUpdateDelete
{
    $wsname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku "STANDARD" -Tag @{"tag1" = "val1"} -Force
    Assert-AreEqual $rgname $workspace.ResourceGroupName
    Assert-AreEqual $wsname $workspace.Name
    Assert-AreEqual $wslocation $workspace.Location
    Assert-AreEqual "STANDARD" $workspace.Sku
    
    Assert-AreEqual 30 $workspace.RetentionInDays
    Assert-NotNull $workspace.ResourceId
    Assert-AreEqual 1 $workspace.Tags.Count
    Assert-NotNull $workspace.CustomerId
    Assert-NotNull $workspace.PortalUrl

    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname
    Assert-AreEqual $rgname $workspace.ResourceGroupName
    Assert-AreEqual $wsname $workspace.Name
    Assert-AreEqual $wslocation $workspace.Location
    Assert-AreEqual "STANDARD" $workspace.Sku
    Assert-AreEqual 30 $workspace.RetentionInDays
    Assert-NotNull $workspace.ResourceId
    Assert-AreEqual 1 $workspace.Tags.Count
    Assert-NotNull $workspace.CustomerId
    Assert-NotNull $workspace.PortalUrl

    
    $wstwoname = Get-ResourceName
    $workspacetwo = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wstwoname -Location $wslocation -Sku "PerNode" -RetentionInDays 60 -Force

    $workspacetwo = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wstwoname
    Assert-AreEqual 60 $workspacetwo.RetentionInDays

    
    $workspaces = Get-AzOperationalInsightsWorkspace
    Assert-AreEqual 1 ($workspaces | Where {$_.Name -eq $wsname}).Count
    Assert-AreEqual 1 ($workspaces | Where {$_.Name -eq $wstwoname}).Count

    
    $workspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname
    Assert-AreEqual 1 ($workspaces | Where {$_.Name -eq $wsname}).Count
    Assert-AreEqual 1 ($workspaces | Where {$_.Name -eq $wstwoname}).Count

    
    Remove-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name $wstwoname -Force
    Assert-ThrowsContains { Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wstwoname } "NotFound"
    $workspaces = Get-AzOperationalInsightsWorkspace
    Assert-AreEqual 1 ($workspaces | Where {$_.Name -eq $wsname}).Count
    Assert-AreEqual 0 ($workspaces | Where {$_.Name -eq $wstwoname}).Count

    
    $workspace = Set-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Tag @{"foo" = "bar"; "foo2" = "bar2"}
    Assert-AreEqual 2 $workspace.Tags.Count

    $workspace = $workspace | New-AzOperationalInsightsWorkspace -Tag @{"foo" = "bar"} -Force
    Assert-AreEqual 1 $workspace.Tags.Count

    
    $workspace | Set-AzOperationalInsightsWorkspace -Tag @{} -Sku standalone -RetentionInDays 123
    $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname
    Assert-AreEqual 0 $workspace.Tags.Count
    Assert-AreEqual standalone $workspace.Sku
    Assert-AreEqual 123 $workspace.RetentionInDays

    
    $workspace | Remove-AzOperationalInsightsWorkspace -Force
    $workspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname
    Assert-AreEqual 0 $workspaces.Count
    Assert-ThrowsContains { Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name wsname } "NotFound"
}


function Test-WorkspaceActions
{
    $wsname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $wslocation = Get-ProviderLocation

    New-AzResourceGroup -Name $rgname -Location $wslocation -Force

    
    $accounts = Get-AzOperationalInsightsLinkTargets
    Assert-AreEqual 0 $accounts.Count

    
    Assert-ThrowsContains { New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku "STANDARD" -CustomerId ([guid]::NewGuid()) } "BadRequest"

    
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku "STANDARD" -Tag @{"tag1" = "val1"} -Force

    
    $keys = Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $rgname -Name $wsname
    Assert-NotNull $keys.PrimarySharedKey
    Assert-NotNull $keys.SecondarySharedKey

    $keys = $workspace | Get-AzOperationalInsightsWorkspaceSharedKeys
    Assert-NotNull $keys.PrimarySharedKey
    Assert-NotNull $keys.SecondarySharedKey

    
    $mgs = Get-AzOperationalInsightsWorkspaceManagementGroups -ResourceGroupName $rgname -Name $wsname
    Assert-AreEqual 0 $mgs.Count

    $mgs = $workspace | Get-AzOperationalInsightsWorkspaceManagementGroups
    Assert-AreEqual 0 $mgs.Count

    
    $usages = Get-AzOperationalInsightsWorkspaceUsage -ResourceGroupName $rgname -Name $wsname
    Assert-AreEqual 1 $usages.Count
    Assert-AreEqual "DataAnalyzed" $usages[0].Id
    Assert-NotNull $usages[0].Name
    Assert-NotNull $usages[0].NextResetTime
    Assert-AreEqual "Bytes" $usages[0].Unit
    Assert-AreEqual ([Timespan]::FromDays(1)) $usages[0].QuotaPeriod

    $usages = $workspace | Get-AzOperationalInsightsWorkspaceUsage
    Assert-AreEqual 1 $usages.Count
    Assert-AreEqual "DataAnalyzed" $usages[0].Id
    Assert-NotNull $usages[0].Name
    Assert-NotNull $usages[0].NextResetTime
    Assert-AreEqual "Bytes" $usages[0].Unit
    Assert-AreEqual ([Timespan]::FromDays(1)) $usages[0].QuotaPeriod
}


function Test-WorkspaceEnableDisableListIntelligencePacks
{

    $wsname = Get-ResourceName
    $rgname = Get-ResourceGroupName
    $wslocation = Get-ProviderLocation

	New-AzResourceGroup -Name $rgname -Location $wslocation -Force

	
    $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name $wsname -Location $wslocation -Sku "STANDARD" -Tag @{"tag1" = "val1"} -Force
    Assert-AreEqual $rgname $workspace.ResourceGroupName
    Assert-AreEqual $wsname $workspace.Name
    Assert-AreEqual $wslocation $workspace.Location
    Assert-AreEqual "STANDARD" $workspace.Sku
    Assert-NotNull $workspace.ResourceId
    Assert-AreEqual 1 $workspace.Tags.Count
    Assert-NotNull $workspace.CustomerId
    Assert-NotNull $workspace.PortalUrl

    
	Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgname -WorkspaceName $wsname -IntelligencePackName "ChangeTracking" -Enabled $true
	Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgname -WorkspaceName $wsname -IntelligencePackName "SiteRecovery" -Enabled $true

	
	$ipList = Get-AzOperationalInsightsIntelligencePacks -ResourceGroupName $rgname -WorkspaceName $wsname
	Foreach ($ip in $ipList)
	{
		if (($ip.Name -eq "ChangeTracking") -or ($ip.Name -eq "SiteRecovery") -or ($ip.Name -eq "LogManagement"))
		{
			Assert-AreEqual $ip.Enabled $true
		}
		else
		{
			Assert-AreEqual $ip.Enabled $false
		}
	}

	
	Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgname -WorkspaceName $wsname -IntelligencePackName "ChangeTracking" -Enabled $false
	Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $rgname -WorkspaceName $wsname -IntelligencePackName "SiteRecovery" -Enabled $false

	
	$ipList = Get-AzOperationalInsightsIntelligencePacks -ResourceGroupName $rgname -WorkspaceName $wsname
	Foreach ($ip in $ipList)
	{
		if ($ip.Name -eq "LogManagement")
		{
			Assert-AreEqual $ip.Enabled $true
		}
		else
		{
			Assert-AreEqual $ip.Enabled $false
		}
	}

	
    $workspace | Remove-AzOperationalInsightsWorkspace -Force
    $workspaces = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname
    Assert-AreEqual 0 $workspaces.Count
    Assert-ThrowsContains { Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgname -Name wsname } "NotFound"
}