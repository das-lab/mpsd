


function Export-RsSubscriptionXml {
    
        
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [Parameter(Mandatory = $True, ValueFromPipeline=$true)]
        [object]
        $Subscription
    )

    Begin {
        $Subscriptions = @()
    }
    Process {
        $Subscriptions = $Subscriptions + $Subscription
    }
    End {
        
        if ($PSCmdlet.ShouldProcess($Path, "Exporting subscriptions")) 
        {
            Write-Verbose "Exporting subscriptions to $Path..."
            $Subscriptions | Export-Clixml $Path -Depth 3
        }
    }
}