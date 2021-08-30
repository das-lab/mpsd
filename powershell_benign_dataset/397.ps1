
$PSF_OnRemoveScript = {
	
	if ([runspace]::DefaultRunspace.Id -eq 1)
	{
		Wait-PSFMessage -Timeout 30s -Terminate
		Get-PSFRunspace | Stop-PSFRunspace
		[PSFramework.PSFCore.PSFCoreHost]::Uninitialize()
	}
	
	
	$psframework_pssessions.Values | Remove-PSSession
	
	[PSFramework.FlowControl.CallbackHost]::RemoveRunspaceOwned()
}
$ExecutionContext.SessionState.Module.OnRemove += $PSF_OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $PSF_OnRemoveScript
