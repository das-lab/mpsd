

$Files = Get-Content -Path "e:\Dexma\ClientFilePaths.txt"

IF ($Files)
{
	foreach ($file IN $Files) 
	{
		IF (Test-Path $file = $true)
		{
			
			Out-File -InputObject $file -FilePath "e:\Dexma\logs\ClientFilesFound.txt" -append -NoClobber
		}
		else
		{
			
			Out-File -InputObject $file -FilePath "e:\Dexma\logs\ClientFilesNotFound.txt" -append -NoClobber
		}
	}
}