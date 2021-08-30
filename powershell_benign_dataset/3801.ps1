














function Test-NoWaitParameter
{
    
    $rgname = Get-ComputeTestResourceName

    try
    {
		
        $loc = Get-ComputeVMLocation;
        New-AzResourceGroup -Name $rgname -Location $loc -Force;

        $vmname = 'vm' + $rgname;
        $user = "Foo12";
        $password = $PLACEHOLDER;
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force;
        $cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword);
        [string]$domainNameLabel = "$vmname-$vmname".tolower();
        $vmobject = New-AzVm -Name $vmname -ResourceGroupName $rgname -Credential $cred -DomainNameLabel $domainNameLabel;

		$response = Start-AzVm -ResourceGroupName $rgname -Name $vmname -NoWait
		Assert-NotNull $response.RequestId
    }
    finally
    {
        
        Clean-ResourceGroup $rgname;
    }
}
