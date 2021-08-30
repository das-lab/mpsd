














function Test-GetResourceSku
{
	$skulist = Get-AzComputeResourceSku | where {$_.Locations -eq "eastus"};
	Assert-True { $skulist.Count -gt 0; }
	$output = $skulist | Out-String;
	Assert-True { $output.Contains("availabilitySets"); }
	Assert-True { $output.Contains("virtualMachines"); }
	Assert-True { $output.Contains("Zones"); }
}
