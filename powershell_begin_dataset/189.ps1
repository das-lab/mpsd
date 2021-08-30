function Remove-StringLatinCharacter
{

    [CmdletBinding()]
	PARAM (
		[Parameter(ValueFromPipeline=$true)]
		[System.String[]]$String
		)
	PROCESS
	{
        FOREACH ($StringValue in $String)
        {
            Write-Verbose -Message "$StringValue"

            TRY
            {
                [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($StringValue))
            }
		    CATCH
            {
                Write-Error -Message $Error[0].exception.message
            }
        }
	}
}