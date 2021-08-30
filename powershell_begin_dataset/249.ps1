function Get-ImageInformation
{

	PARAM (
		[System.String[]]$FilePath
	)
	Foreach ($Image in $FilePath)
	{
		
		Add-type -AssemblyName System.Drawing

		
		New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Image
	}
}