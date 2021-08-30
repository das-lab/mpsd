














function Get-AzVMGuestPolicyStatusHistory-VmNameScope
{
	$rgName = "aashishGoodPolicy"
	$vmName = "aashishvm1"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-VmNameScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-InitiativeIdScope
{
	$rgName = "aashishGoodPolicy"
	$vmName = "aashishvm1"
	$initiativeId = "/providers/Microsoft.Authorization/policySetDefinitions/8bc55e6b-e9d5-4266-8dac-f688d151ec9c"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -InitiativeId $initiativeId
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-InitiativeIdScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"
	$initiativeId = "/subscriptions/b5e4748c-f69a-467c-8749-e2f9c8cd3db0/providers/Microsoft.Authorization/policySetDefinitions/60062d3c-3282-4a3d-9bc4-3557dded22ca"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -InitiativeId $initiativeId
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-InitiativeNameScope
{
	$rgName = "aashishGoodPolicy"
	$vmName = "aashishvm1"
	$initiativeName = "8bc55e6b-e9d5-4266-8dac-f688d151ec9c"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-InitiativeNameScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"
	$initiativeName = "60062d3c-3282-4a3d-9bc4-3557dded22ca"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-ShowOnlyChangeSwitch-VmNameScope
{
	$rgName = "aashishGoodPolicy"
	$vmName = "aashishvm1"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -ShowOnlyChange
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatusHistory-ShowOnlyChangeSwitch-VmNameScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"

    $historicalStatuses = Get-AzVMGuestPolicyStatusHistory -ResourceGroupName $rgName -VMName $vmName -ShowOnlyChange
	Assert-NotNull $historicalStatuses
	Assert-True { $historicalStatuses.Count -gt 0 }
}