














function Get-AzureRmJitNetworkAccessPolicy-SubscriptionScope
{
	Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

    $jitNetworkAccessPolicies = Get-AzJitNetworkAccessPolicy
	Validate-JitNetworkAccessPolicies $jitNetworkAccessPolicies
}


function Get-AzureRmJitNetworkAccessPolicy-ResourceGroupScope
{
	Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

	$rgName = Get-TestResourceGroupName

    $jitNetworkAccessPolicies = Get-AzJitNetworkAccessPolicy -ResourceGroupName $rgName
	Validate-JitNetworkAccessPolicies $jitNetworkAccessPolicies
}


function Get-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource
{
	$jitNetworkAccessPolicy = Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

	$rgName = Extract-ResourceGroup -ResourceId $jitNetworkAccessPolicy.Id
	$location = Extract-ResourceLocation -ResourceId $jitNetworkAccessPolicy.Id

    $fetchedJitNetworkAccessPolicy = Get-AzJitNetworkAccessPolicy -ResourceGroupName $rgName -Location $location -Name $jitNetworkAccessPolicy.Name
	Validate-JitNetworkAccessPolicy $fetchedJitNetworkAccessPolicy
}


function Get-AzureRmJitNetworkAccessPolicy-ResourceId
{
	$jitNetworkAccessPolicy = Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

    $fetchedJitNetworkAccessPolicy = Get-AzJitNetworkAccessPolicy -ResourceId $jitNetworkAccessPolicy.Id
	Validate-JitNetworkAccessPolicy $fetchedJitNetworkAccessPolicy
}


function Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource
{
	Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier "Standard" | Out-Null

	$rgName = Get-TestResourceGroupName

	[Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyVirtualMachine]$vm = New-Object -TypeName Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyVirtualMachine
	  $vm.Id = "/subscriptions/487bb485-b5b0-471e-9c0d-10717612f869/resourceGroups/myService1/providers/Microsoft.Compute/virtualMachines/testService"
	[Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPortRule]$port = New-Object -TypeName Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPortRule
	$port.AllowedSourceAddressPrefix = "127.0.0.1"
	$port.MaxRequestAccessDuration = "PT3H"
	$port.Number = 22
	$port.Protocol = "TCP"
	$vm.Ports = [Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPortRule[]](,$port)

	[Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyVirtualMachine[]]$vms = (,$vm)

    return Set-AzureRmJitNetworkAccessPolicy -ResourceGroupName $rgName -Location "centralus" -Name "default" -Kind "Basic" -VirtualMachine $vms
}


function Remove-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource
{
	Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

	$rgName = Get-TestResourceGroupName

    Remove-AzJitNetworkAccessPolicy -ResourceGroupName $rgName -Location "centralus" -Name "default"
}


function Remove-AzureRmJitNetworkAccessPolicy-ResourceId
{
	$jitNetworkAccessPolicy = Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

	$rgName = Get-TestResourceGroupName

    Remove-AzJitNetworkAccessPolicy -ResourceId $jitNetworkAccessPolicy.Id
}


function Start-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource
{
	$jitNetworkAccessPolicy = Set-AzureRmJitNetworkAccessPolicy-ResourceGroupLevelResource

	$rgName = Get-TestResourceGroupName

	[Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyInitiateVirtualMachine]$vm = New-Object -TypeName Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyInitiateVirtualMachine
	$vm.Id = "/subscriptions/487bb485-b5b0-471e-9c0d-10717612f869/resourceGroups/myService1/providers/Microsoft.Compute/virtualMachines/testService"
	[Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyInitiatePort]$port = New-Object -TypeName Microsoft.Azure.Commands.Security.Models.JitNetworkAccessPolicies.PSSecurityJitNetworkAccessPolicyInitiatePort
	$port.AllowedSourceAddressPrefix = "127.0.0.1"
	$port.EndTimeUtc = [DateTime]::UtcNow.AddHours(2)
	$port.Number = 22
	$vm.Ports = (,$port)

    Start-AzJitNetworkAccessPolicy -ResourceGroupName $rgName -Location "centralus" -Name "default" -VirtualMachine (,$vm)
}


function Validate-JitNetworkAccessPolicies
{
	param($jitNetworkAccessPolicies)

    Assert-True { $jitNetworkAccessPolicies.Count -gt 0 }

	Foreach($jitNetworkAccessPolicy in $jitNetworkAccessPolicies)
	{
		Validate-JitNetworkAccessPolicy $jitNetworkAccessPolicy
	}
}


function Validate-JitNetworkAccessPolicy
{
	param($jitNetworkAccessPolicy)

	Assert-NotNull $jitNetworkAccessPolicy
}