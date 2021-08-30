














function OperationsListTest
{
    
    Write-Debug "Get Operations List"
    $OperationsList = Get-AzRelayOperation
	
	
	Assert-True { $OperationsList.Count -gt 0 }

}