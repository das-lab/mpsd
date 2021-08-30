
function Read-CFile
{
    
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        
        $Path,

        
        [int]
        $MaximumTries = 30,

        
        [int]
        $RetryDelayMilliseconds = 100,

        [Switch]
        
        $Raw
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $tryNum = 1
    $output = @()
    do
    {
        $lastTry = $tryNum -eq $MaximumTries
        if( $lastTry )
        {
            $errorAction = @{}
        }

        $cmdErrors = @()
        $numErrorsAtStart = $Global:Error.Count
        try
        {

            if( $Raw )
            {
                $output = [IO.File]::ReadAllText($Path)
            }
            else
            {
                $output = Get-Content -Path $Path -ErrorAction SilentlyContinue -ErrorVariable 'cmdErrors'
                if( $cmdErrors -and $lastTry )
                {
                    foreach( $item in $cmdErrors )
                    {
                        $Global:Error.RemoveAt(0)
                    }
                    $cmdErrors | Write-Error 
                }
            }
        }
        catch
        {
            if( $lastTry )
            {
                Write-Error -ErrorRecord $_
            }
        }

        $numErrors = $Global:Error.Count - $numErrorsAtStart

        if( -not $lastTry )
        {
            for( $idx = 0; $idx -lt $numErrors; ++$idx )
            {
                $Global:Error[0] | Out-String | Write-Debug
                $Global:Error.RemoveAt(0)
            }
        }

        
        if( $cmdErrors -or $numErrors )
        {
            if( -not $lastTry )
            {
                Write-Debug -Message ('Failed to read file ''{0}'' (attempt 
                Start-Sleep -Milliseconds $RetryDelayMilliseconds
            }
        }
        else
        {
            return $output
        }
    }
    while( $tryNum++ -lt $MaximumTries )
}
