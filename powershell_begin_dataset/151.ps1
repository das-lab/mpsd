function Get-ISEShortCut
{

	PARAM($Key,$Name)
	BEGIN
	{
		function Test-IsISE
		{
			
			
			try
			{
				return $psISE -ne $null;
			}
			catch
			{
				return $false;
			}
		}
	}
	PROCESS
	{
		if ($(Test-IsISE) -eq $true)
		{
			

			
			$gps = $psISE.GetType().Assembly
			$rm = New-Object System.Resources.ResourceManager GuiStrings, $gps
			$rs = $rm.GetResourceSet((Get-Culture), $true, $true)
			$rs | Where-Object Name -match 'Shortcut\d?$|^F\d+Keyboard' |
			Sort-Object Value

		}
	}
}