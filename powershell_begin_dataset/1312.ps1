
function Write-CFile
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        
        $Path,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        
        [string[]]$InputObject,

        
        [int]$MaximumTries = 100,

        
        [int]$RetryDelayMilliseconds = 100
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

        Write-Timing ('Write-CFile  BEGIN')

        $Path = Resolve-Path -Path $Path
        if( -not $Path )
        {
            return
        }

        $tryNum = 0
        $newLineBytes = [Text.Encoding]::UTF8.GetBytes([Environment]::NewLine)

        [IO.FileStream]$fileWriter = $null

        if( -not $PSCmdlet.ShouldProcess($Path,'write') )
        {
            return
        }

        while( $tryNum++ -lt $MaximumTries )
        {
            $lastTry = $tryNum -eq $MaximumTries

            $numErrorsBefore = $Global:Error.Count
            try
            {
                $fileWriter = New-Object 'IO.FileStream' ($Path,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::None,4096,$false)
                break
            }
            catch 
            {
                $numErrorsAfter = $Global:Error.Count
                $numErrors = $numErrorsAfter - $numErrorsBefore
                for( $idx = 0; $idx -lt $numErrors; ++$idx )
                {
                    $Global:Error.RemoveAt(0)
                }

                if( $lastTry )
                {
                    Write-Error -ErrorRecord $_
                }
                else
                {
                    Write-Timing ('Attempt {0,4} to open file "{1}" failed. Sleeping {2} milliseconds.' -f $tryNum,$Path,$RetryDelayMilliseconds)
                    Start-Sleep -Milliseconds $RetryDelayMilliseconds
                }
            }
        }
    }

    process
    {
        Write-Timing ('Write-CFile  PROCESS')
        if( -not $fileWriter )
        {
            return
        }

        foreach( $item in $InputObject )
        {
            [byte[]]$bytes = [Text.Encoding]::UTF8.GetBytes($item)
            $fileWriter.Write($bytes,0,$bytes.Length)
            $fileWriter.Write($newLineBytes,0,$newLineBytes.Length)
        }
    }

    end
    {
        if( $fileWriter )
        {
            $fileWriter.Close()
            $fileWriter.Dispose()
        }
        Write-Timing ('Write-CFile  END')
    }
}
