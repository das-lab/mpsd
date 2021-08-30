









Begin{

}

Process{
	
	if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		$Arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
		Start-Process PowerShell.exe -Verb RunAs -ArgumentList $Arguments
		Break
	}

	Write-Host -Object "Start optimization..." -ForegroundColor Yellow

	
	$ngen_path = Join-Path -Path $env:windir -ChildPath "Microsoft.NET"

	if($env:PROCESSOR_ARCHITECTURE -eq "AMD64")
	{
		$ngen_path = Join-Path -Path $ngen_path -ChildPath "Framework64\ngen.exe"
	}
	else
	{
		$ngen_path = Join-Path -Path $ngen_path -ChildPath "Framework\ngen.exe"
	}

	
	$ngen_application_path = (Get-ChildItem -Path $ngen_path -Filter "ngen.exe" -Recurse | Where-Object {$_.Length -gt 0} | Select-Object -Last 1).Fullname

	Set-Alias -Name ngen -Value $ngen_application_path

	
	[System.AppDomain]::CurrentDomain.GetAssemblies() | foreach { ngen install $_.Location /nologo /verbose}

	Write-Host -Object "Optimization finished!" -ForegroundColor Green

	Write-Host -Object "Press any key to continue..."
	[void]$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

End{

}