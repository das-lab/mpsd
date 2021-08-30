















function Test-GetNonExistingDataBoxJob
{	
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
    $rglocation = Get-ProviderLocation ResourceManagement
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force
    
    
    Assert-ThrowsContains { Get-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname } "not found"    
}


function Test-GetCredentialForNewlyCreatedJob
{	
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
	$rglocation = 'WestUS'
    
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

	$storageaccountname = Get-StorageAccountName
	$storageaccount = New-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname  -Location $rglocation 

    try
    {
        $a = Create-Job $dfname $rgname $storageaccount.Id
		
		Assert-ThrowsContains {Get-AzDataBoxCredential -ResourceId $a.Id} "Secrets are not yet generated"

    }
    finally
    {
        Stop-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Reason "Random" -Force
		Remove-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname  -Force
		Remove-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname 
    }    
}


function Create-Job {
	$dfname = $args[0]
	$rgname = $args[1]
	$storagergid = $args[2]
	$a = New-AzDataBoxJob -Location 'WestUS' -StreetAddress1 '16 TOWNSEND ST' -PostalCode 94107 -City 'San Francisco' -StateOrProvinceCode 'CA' -CountryCode 'US' -EmailId 'abc@outlook.com' -PhoneNumber 1234567891 -ContactName 'Random' -StorageAccountResourceId $storagergid  -DataBoxType DataBox -ResourceGroupName $rgname -Name $dfname -ErrorAction Ignore
	return $a
}

function Test-CreateDataBoxJob
{
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
	$rglocation = 'WestUS'
    
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

	$storageaccountname = Get-StorageAccountName
	$storageaccount = New-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname  -Location $rglocation 

    try
    {
        $actual = Create-Job $dfname $rgname $storageaccount.Id
		$expected = Get-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname

        Assert-AreEqual $expected.Id $actual.Id
    }
    finally
    {
        Stop-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Reason "Random" -Force
		Remove-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname  -Force
		Remove-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname 
    }
}


function Test-CreateAlreadyExistingDataBoxJob
{
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
	$rglocation = 'WestUS'
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force

	$storageaccountname = Get-StorageAccountName
	$storageaccount = New-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname -Location $rglocation 

    try
    {
        Create-Job $dfname $rgname $storageaccount.Id
        Assert-ThrowsContains {New-AzDataBoxJob -Location 'WestUS' -StreetAddress1 '16 TOWNSEND ST' -PostalCode 94107 -City 'San Francisco' -StateOrProvinceCode 'CA' -CountryCode 'US' -EmailId 'abc@outlook.com' -PhoneNumber 1234567891 -ContactName 'Random' -StorageAccountResourceId $storageaccount.Id  -DataBoxType DataBox -ResourceGroupName $rgname -Name $dfname 
		} "order already exists with the same name"
    }
    finally
    {
        Stop-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Reason "Random" -Force
		Remove-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname  -Force
		Remove-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname 
    }
}


function Test-StopDataBoxJob
{
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
	$rglocation = Get-ProviderLocation ResourceManagement
    
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force
	
	$storageaccountname = Get-StorageAccountName
	$storageaccount = New-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname -Location $rglocation 

    try
    {
        Create-Job $dfname $rgname $storageaccount.Id
		Stop-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Reason "Random" -Force
        $expected = Get-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname

        Assert-AreEqual $expected.JobResource.Status "Cancelled"
    }
    finally
    {

		Remove-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Force
		Remove-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname 
    }
}


function Test-RemoveDataBoxJob
{
    $dfname = Get-DataBoxJobName
    $rgname = Get-ResourceGroupName
	$rglocation = Get-ProviderLocation ResourceManagement
    
    
    New-AzResourceGroup -Name $rgname -Location $rglocation -Force
	
	$storageaccountname = Get-StorageAccountName
	$storageaccount = New-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname -Location $rglocation

    try
    {
        Create-Job $dfname $rgname $storageaccount.Id
		Stop-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Reason "Random" -Force
		Remove-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname -Force

        Assert-ThrowsContains { Get-AzDataBoxJob -ResourceGroupName $rgname -Name $dfname } "Could not find" 
    }
	finally
	{
		Remove-AzStorageAccount -ResourceGroupName $rgname -Name $storageaccountname 
	}
}



function Test-JobResourceObjectAmbiguousAddress
{
    
	Assert-ThrowsContains {New-AzDataBoxJob -Location 'WestUS' -StreetAddress1 '16 TOWNSEND ST11' -PostalCode 94107 -City 'San Francisco' -StateOrProvinceCode 'CA' -CountryCode 'US' -EmailId 'abc@outlook.com' -PhoneNumber 1234567891 -ContactName 'Random' -StorageAccountResourceId "random"  -DataBoxType DataBox -ResourceGroupName "Random" -Name "Random" 
    } "ambiguous"
 
}


function Test-JobResourceObjectInvalidAddress
{
    
	Assert-ThrowsContains {New-AzDataBoxJob -Location 'WestUS' -StreetAddress1 'blah blah' -PostalCode 94107 -City 'San Francisco' -StateOrProvinceCode 'CA' -CountryCode 'US' -EmailId 'abc@outlook.com' -PhoneNumber 1234567891 -ContactName 'Random' -StorageAccountResourceId "Random"  -DataBoxType DataBox -ResourceGroupName "Random" -Name "Random" 
	} "not Valid"
 
}