

function Join-SPOParts
{
	[CmdletBinding()]
    param
    (
		[Parameter(Mandatory=$false, Position=1)]
        $Parts = $null,
		
		[Parameter(Mandatory=$false, Position=2)]
        $Separator = ''
    )

    $returnValue = (($Parts | ? { $_ } | % { ([string]$_).trim($Separator) } | ? { $_ } ) -join $Separator)

    if (-not ($returnValue.StartsWith("http", "CurrentCultureIgnoreCase")))
    {
        
        $returnValue = $Separator + $returnValue
    }

    return $returnValue
}
