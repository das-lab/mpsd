Function Wait-Path {
    
    [cmdletbinding()]
    param (
        [string[]]$Path,
        [int]$Timeout = 5,
        [int]$Interval = 1,
        [switch]$Passthru
    )

    $StartDate = Get-Date
    $First = $True

    Do
    {
        
            if($First -eq $True)
            {
                $First = $False
            }
            else
            {
                Start-Sleep -Seconds $Interval
            }

        
            [bool[]]$Tests = foreach($PathItem in $Path)
            {
                Try
                {
                    if(Test-Path $PathItem -ErrorAction stop)
                    {
                        Write-Verbose "'$PathItem' exists"
                        $True
                    }
                    else
                    {
                        Write-Verbose "Waiting for '$PathItem'"
                        $False
                    }
                }
                Catch
                {
                    Write-Error "Error testing path '$PathItem': $_"
                    $False
                }
            }

        
            $Return = $Tests -notcontains $False -and $Tests -contains $True
        
        
            
            
            if ( ((Get-Date) - $StartDate).TotalSeconds -gt $Timeout)
            {
                if( $Passthru )
                {
                    $False
                    break
                }
                else
                {
                    Throw "Timed out waiting for paths $($Path -join ", ")"
                }
            }
            elseif($Return)
            {
                if( $Passthru )
                {
                    $True
                }
                break
            }
    }
    Until( $False ) 

}