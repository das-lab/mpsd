function Set-RemoteDesktop
{


	[CmdletBinding()]
	PARAM (
		[String[]]$ComputerName = $env:COMPUTERNAME,
		[Parameter(Mandatory = $true)]
		[Boolean]$Enable
	)
	PROCESS
	{
		FOREACH ($Computer in $ComputerName)
		{
			TRY
			{
				IF (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
				{
					$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $Computer)
					$regKey = $regKey.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server", $True)

					IF ($Enable){$regkey.SetValue("fDenyTSConnections", 0)}
					ELSE { $regkey.SetValue("fDenyTSConnections", 1)}
					$regKey.flush()
					$regKey.Close()
				} 
			} 
			CATCH
			{
				$Error[0].Exception.Message
			} 
		} 
	} 
}