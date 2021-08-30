













function Assert-CEqual
{
    
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        
        $Expected,

        [Parameter(Mandatory=$true,Position=1)]
        [string]
        
        $Actual,

        [Parameter(Mandatory=$true,Position=2)]
        [string]
        
        $Message
    )

    Write-Warning ('Assert-CEqual is obsolete.  Use Assert-Equal with the -CaseSensitive switch instead.')
    Assert-Equal -Expected $Expected -Actual $Actual -Message $Message -CaseSensitive
}

