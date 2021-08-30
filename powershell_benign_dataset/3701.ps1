














function Get-AzVMGuestPolicyStatus-VmNameScope
{
	$rgName = "vivga"
	$vmName = "Viv1809SDDC"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-VmNameScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-InitiativeIdScope
{
	$rgName = "vivga"
	$vmName = "Viv1809SDDC"
	$initiativeId = "/providers/Microsoft.Authorization/policySetDefinitions/25ef9b72-4af2-4501-acd1-fc814e73dde1"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeId $initiativeId
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-InitiativeIdScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"
	$initiativeId = "/subscriptions/b5e4748c-f69a-467c-8749-e2f9c8cd3db0/providers/Microsoft.Authorization/policySetDefinitions/60062d3c-3282-4a3d-9bc4-3557dded22ca"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeId $initiativeId
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-InitiativeNameScope
{
	$rgName = "vivga"
	$vmName = "Viv1809SDDC"
	$initiativeName = "25ef9b72-4af2-4501-acd1-fc814e73dde1"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-InitiativeNameScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"
	$initiativeName = "60062d3c-3282-4a3d-9bc4-3557dded22ca"

    $reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }
}


function Get-AzVMGuestPolicyStatus-ReportIdScope
{
	$rgName = "vivga"
	$vmName = "Viv1809SDDC"
	$initiativeName = "25ef9b72-4af2-4501-acd1-fc814e73dde1"
	$reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }

	$Id= $reports[0].ReportId;

    $report = Get-AzVMGuestPolicyStatus -ReportId $Id
	Assert-NotNull $report
}


function Get-AzVMGuestPolicyStatus-ReportIdScope_Custom
{
	$rgName = "aashishCustomrole7ux"
	$vmName = "aashishCustomrole7ux"
	$initiativeName = "60062d3c-3282-4a3d-9bc4-3557dded22ca"
	$reports = Get-AzVMGuestPolicyStatus -ResourceGroupName $rgName -VMName $vmName -InitiativeName $initiativeName
	Assert-NotNull $reports
	Assert-True { $reports.Count -gt 0 }

	$Id= $reports[0].ReportId;

    $report = Get-AzVMGuestPolicyStatus -ReportId $Id
	Assert-NotNull $report
}
