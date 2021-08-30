

function New-ScreenShot
{
	
	[OutputType([System.IO.FileInfo])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ -not (Test-Path -Path $_ -PathType Leaf) })]
		[ValidatePattern('\.jpg|\.jpeg|\.bmp')]
		[string]$FilePath
			
	)
	begin {
		$ErrorActionPreference = 'Stop'
		Add-Type -AssemblyName System.Windows.Forms
		Add-type -AssemblyName System.Drawing
	}
	process {
		try
		{
			
			$Screen = [System.Windows.Forms.SystemInformation]::VirtualScreen

			
			$bitmap = New-Object System.Drawing.Bitmap $Screen.Width, $Screen.Height
			
			
			$graphic = [System.Drawing.Graphics]::FromImage($bitmap)
			
			
			$graphic.CopyFromScreen($Screen.Left, $Screen.Top, 0, 0, $bitmap.Size)
			
			
			$bitmap.Save($FilePath)
			
			Get-Item -Path $FilePath
		}
		catch
		{
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}