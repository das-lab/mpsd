function Remove-StringDiacritic
{

	[CMdletBinding()]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		[Alias('Text')]
		[System.String[]]$String,
		[System.Text.NormalizationForm]$NormalizationForm = "FormD"
	)

	FOREACH ($StringValue in $String)
	{
		Write-Verbose -Message "$StringValue"
		try
		{
			
			$Normalized = $StringValue.Normalize($NormalizationForm)
			$NewString = New-Object -TypeName System.Text.StringBuilder

			
			$normalized.ToCharArray() |
			ForEach-Object -Process {
				if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($psitem) -ne [Globalization.UnicodeCategory]::NonSpacingMark)
				{
					[void]$NewString.Append($psitem)
				}
			}

			
			Write-Output $($NewString -as [string])
		}
		Catch
		{
			Write-Error -Message $Error[0].Exception.Message
		}
	}
}