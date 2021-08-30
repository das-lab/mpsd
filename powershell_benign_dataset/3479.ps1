














function Test-CreateSqlVirtualMachineGroup
{
    $location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location

	$groupName = Get-SqlVirtualMachineGroupName
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	
	try 
	{
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
	
		Assert-NotNull $group
		Assert-AreEqual $group.Name $groupName
		Assert-AreEqual $group.ResourceGroupName $rg.ResourceGroupName
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-GetSqlVirtualMachineGroup
{
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location

	$groupName = Get-SqlVirtualMachineGroupName
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	
	try 
	{
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
	
		
		$group1 = Get-AzSqlVMGroup -ResourceGroupName $group.ResourceGroupName -Name $groupName
		Validate-SqlVirtualMachineGroup $group $group1
		
		
		$group1 = Get-AzSqlVMGroup -ResourceId $group.ResourceId
		Validate-SqlVirtualMachineGroup $group $group1

		
		$groupList = Get-AzSqlVMGroup -ResourceGroupName $group.ResourceGroupName
		Assert-True {$group.Name -in $groupList.Name}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-UpdateSqlVirtualMachineGroup
{
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location

	$groupName = Get-SqlVirtualMachineGroupName
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	
	try 
	{
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
		Assert-NotNull $group
		
		
		$key = 'key'
		$value = 'value'
		$tags = @{$key=$value}
		$group1 = Update-AzSqlVMGroup -InputObject $group -Tag $tags
		$group1 = Get-AzSqlVMGroup -ResourceGroupName $rg.ResourceGroupName -Name $groupName
		
		Validate-SqlVirtualMachineGroup $group $group1
		Assert-NotNull $group1.Tags
		Assert-AreEqual $group1.Tags.count 1
		Assert-AreEqual $group1.Tags[$key] $value
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-RemoveSqlVirtualMachineGroup
{
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location

	$groupName = Get-SqlVirtualMachineGroupName
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	
	try 
	{
		
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
		Remove-AzSqlVMGroup -ResourceGroupName $group.ResourceGroupName -Name $group.Name
		
		
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
		Remove-AzSqlVMGroup -ResourceId $group.ResourceId
		
		
		$group = Create-SqlVMGroup $rg.ResourceGroupName $groupName $location
		Remove-AzSqlVMGroup -InputObject $group
		
		$groupList = Get-AzSqlVMGroup -ResourceGroupName $group.ResourceGroupName
		Assert-False {$group.Name -in $groupList.Name}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}

