














function Test-CreateSqlVirtualMachine
{
	
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location
	$vmName = 'vm'
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"

	try
	{
		Create-VM $rg.ResourceGroupName $vmName $location
		
		
		New-AzSqlVM -ResourceGroupName $rg.ResourceGroupName -Name $vmName -LicenseType "PAYG" -Location $location -Sku Enterprise
		$sqlvm = Get-AzSqlVM -ResourceGroupName $rg.ResourceGroupName -Name $vmName
		
		Assert-NotNull $sqlvm
		$sqlvm | Remove-AzSqlVM

		
		$config = New-AzSqlVMConfig -LicenseType "PAYG"
		New-AzSqlVM $rg.ResourceGroupName $vmName -SqlVM $config -Location $location
		$sqlvm = Get-AzSqlVM -ResourceGroupName $rg.ResourceGroupName -Name $vmName
		$sqlvm | Remove-AzSqlVM
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-GetSqlVirtualMachine
{
	
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"
	
	try 
	{
		$sqlvm = Create-SqlVM $rg.ResourceGroupName 'vm' $location
	
		
		$sqlvm1 = Get-AzSqlVM -ResourceGroupName $rg.ResourceGroupName -Name $sqlvm.Name
		Validate-SqlVirtualMachine $sqlvm $sqlvm1
		
		
		$sqlvm = Get-AzSqlVM -ResourceId $sqlvm.ResourceId
		Validate-SqlVirtualMachine $sqlvm $sqlvm1

		
		$sqlvmList = Get-AzSqlVM -ResourceGroupName $sqlvm.ResourceGroupName
		Assert-True {$sqlvm.Name -in $sqlvmList.Name}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-UpdateSqlVirtualMachine
{
	
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"

	try 
	{
		$sqlvm = Create-SqlVM $rg.ResourceGroupName 'vm' $location
		Assert-NotNull $sqlvm
	
		
		$key = 'key'
		$value = 'value'
		$tags = @{$key=$value}
		$sqlvm1 = Update-AzSqlVM -ResourceGroupName $sqlvm.ResourceGroupName -Name $sqlvm.Name -Tag $tags
		$sqlvm1 = Get-AzSqlVM -ResourceGroupName $sqlvm.ResourceGroupName -Name $sqlvm.Name
		Assert-NotNull $sqlvm1
		
		Validate-SqlVirtualMachine $sqlvm $sqlvm1 

		Assert-AreEqual $sqlvm1.Tags.count 1 
		Assert-AreEqual $sqlvm1.Tags[$key] $value
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}


function Test-RemoveSqlVirtualMachine
{
	
	$location = Get-LocationForTest
	$rg = Create-ResourceGroupForTest $location
	$previousErrorActionPreferenceValue = $ErrorActionPreference
	$ErrorActionPreference = "SilentlyContinue"

	try 
	{
		$sqlvm = Create-SqlVM $rg.ResourceGroupName 'vm' $location
		Assert-NotNull $sqlvm
	
		Remove-AzSqlVM -ResourceId $sqlvm.ResourceId

		$sqlvmList = Get-AzSqlVM -ResourceGroupName $rg.ResourceGroupName
		Assert-False {$sqlvm.Name -in $sqlvmList.Name}
	}
	finally
	{
		Remove-ResourceGroupForTest $rg
		$ErrorActionPreference = $previousErrorActionPreferenceValue
	}
}
