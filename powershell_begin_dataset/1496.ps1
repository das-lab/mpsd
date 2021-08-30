













function Assert-Equal
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        
        $Expected, 

        [Parameter(Position=1)]
        [object]
        
        $Actual, 

        [Parameter(Position=2)]
        [string]
        
        $Message,

        [Switch]
        
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Is '$Expected' -eq '$Actual'?"
    $equal = $Expected -eq $Actual
    if( $CaseSensitive )
    {
        $equal = $Expected -ceq $Actual
    }

    if( -not $equal )
    {
        if( $Expected -is [string] -and $Actual -is [string] )
        {
            $expectedLength = $Expected.Length
            $actualLength = $Actual.Length

            function Convert-UnprintableChars
            {
                param(
                    [Parameter(Mandatory=$true,Position=0)]
                    [AllowEmptyString()]
                    [AllowNull()]
                    [string]
                    $InputObject
                )
                $InputObject = $InputObject -replace "`r","\r"
                $InputObject = $InputObject -replace "`n","\n`n"
                $InputObject = $InputObject -replace "`t","\t`t"
                return $InputObject
            }

            if( $expectedLength -ne $actualLength )
            {
                Fail ("Strings are different length ({0} != {1}).`n----- EXPECTED`n{2}`n----- ACTUAL`n{3}`n-----`n{4}" -f $expectedlength,$actualLength,(Convert-UnprintableChars $Expected),(Convert-UnprintableChars $Actual),$Message)
                return
            }

            for( $idx = 0; $idx -lt $Expected.Length; ++$idx )
            {
                $charEqual = $Expected[$idx] -eq $Actual[$idx]
                if( $CaseSensitive )
                {
                    $charEqual = $Expected[$idx] -ceq $Actual[$idx]
                }

                if( -not $charEqual )
                {
                    $startIdx = $idx - 70
                    if( $startIdx -lt 0 )
                    {
                        $startIdx = 0
                    }

                    $expectedSubstring = $Expected.Substring($startIdx,$idx - $startIdx + 1)
                    $actualSubstring = $Actual.Substring($startIdx,$idx - $startIdx + 1)
                    Fail ("Strings different beginning at index {0}:`n'{1}' != '{2}'`n----- EXPECTED`n{3}`n----- ACTUAL`n{4}`n-----`n{5}" -f $idx,(Convert-UnprintableChars $Expected[$idx]),(Convert-UnprintableChars $Actual[$idx]),(Convert-UnprintableChars $expectedSubstring),(Convert-UnprintableChars $actualSubstring),$Message)
                }
            }
            
        }
        Fail "Expected '$Expected', but was '$Actual'. $Message"
    }
}

