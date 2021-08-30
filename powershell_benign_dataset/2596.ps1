



















function Split-Job (
    $Scriptblock = $(throw 'You must specify a command or script block!'),
    [int]$MaxPipelines=10,
    [switch]$UseProfile,
    [string[]]$Variable,
    [string[]]$Alias

) {
    
    $Queue = [Collections.Queue]::Synchronized([Collections.Queue]@($Input))
    $QueueLength = $Queue.Count
    if ($MaxPipelines -gt $QueueLength) {$MaxPipelines = $QueueLength}
    
    $Script  = "Set-Location '$PWD'; "
    $Script += '$Queue = $($Input); '
    $Script += '& {trap {continue}; while ($Queue.Count) {$Queue.Dequeue()}} |'
    $Script += $Scriptblock

    
    $Pipelines = New-Object System.Collections.ArrayList

    function Add-Pipeline {
        
        
        $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($Host)
        $Runspace.Open()
        
        if ($UseProfile) {
            $Pipeline = $Runspace.CreatePipeline(". '$PROFILE'")
            $Pipeline.Invoke()
            $Pipeline.Dispose()
        }
        if ($Variable) {
            Get-Variable $Variable -Scope 2 | foreach {
                trap {continue}
                $Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
            }
        }
        if ($Alias) {
            $Pipeline = $Runspace.CreatePipeline({$Input | Set-Alias -value {$_.Definition}})
            $Null = $Pipeline.Input.Write((Get-Alias $Alias -Scope 2), $True)
            $Pipeline.Input.Close()
            $Pipeline.Invoke()
            $Pipeline.Dispose()
        }
        $Pipeline = $Runspace.CreatePipeline($Script)
        $Null = $Pipeline.Input.Write($Queue)
        $Pipeline.Input.Close()
        $Pipeline.InvokeAsync()
        $Null = $Pipelines.Add($Pipeline)
    }

    function Remove-Pipeline ($Pipeline) {
        
        $Pipeline.RunSpace.Close()
        $Pipeline.Dispose()
        $Pipelines.Remove($Pipeline)
    }

    
    while ($Pipelines.Count -lt $MaxPipelines -and $Queue.Count) {Add-Pipeline} 

    
    while ($Pipelines.Count) {
        Write-Progress 'Split-Job' "Queues: $($Pipelines.Count)" `
            -PercentComplete (100 - [Int]($Queue.Count)/$QueueLength*100)
        foreach ($Pipeline in (New-Object System.Collections.ArrayList(,$Pipelines))) {
            if ( -not $Pipeline.Output.EndOfPipeline -or -not $Pipeline.Error.EndOfPipeline ) {
                $Pipeline.Output.NonBlockingRead()
                $Pipeline.Error.NonBlockingRead() | Write-Error
            } else {
                if ($Pipeline.PipelineStateInfo.State -eq 'Failed') {
                    Write-Error $Pipeline.PipelineStateInfo.Reason
                    
                    if ($Queue.Count -lt $QueueLength) {Add-Pipeline}
                }
                Remove-Pipeline $Pipeline
            }
        }
        Start-Sleep -Milliseconds 100
    }
}