









[CmdletBinding()]
param(
    
	[Parameter(
		Position=0,
		HelpMessage='Maximum number of threads at the same time (Default=100)')]
	[Int32]$Threads=100
)

Begin{
    
} 

Process{       
    
	[System.Management.Automation.ScriptBlock]$ScriptBlock = {
		Param(
			
			$Parameter1,
			$Parameter2
		)

		
		
		
		
		
		
		
		
		
		
		
		[pscustomobject] @{
			Parameter1 = Result1
			Parameter2 = Result2
		}		
	}

    
    Write-Verbose "Setting up RunspacePool..."
   
	Write-Verbose "Running with max $Threads threads"
   
    $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
    $RunspacePool.Open()
    [System.Collections.ArrayList]$Jobs = @()

    Write-Verbose "Setting up Jobs..."
        
    
	for($i = $StartRange; $i -le $EndRange; $i++)
	{
		
		$ScriptParams = @{
			Parameter1 = $Parameter1
			Parameter2 = $Parameter2
		}

        
        try {
            $Progress_Percent =  ($i / ($EndRange - $StartRange)) * 100 
        } 
        catch { 
            $Progress_Percent = 100 
        }

        Write-Progress -Activity "Setting up jobs..." -Id 1 -Status "Current Job: $i"  -PercentComplete ($Progress_Percent)
        
        
        $Job = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameters($ScriptParams)
        $Job.RunspacePool = $RunspacePool
        
        $JobObj = [pscustomobject] @{
            RunNum = $i - $StartRange
            Pipe = $Job
            Result = $Job.BeginInvoke()
        }

        
        [void]$Jobs.Add($JobObj)
    }

    Write-Verbose "Waiting for jobs to complete & starting to process results..."

    
    $Jobs_Total = $Jobs.Count

    
    Do {
        
        $Jobs_ToProcess = $Jobs | Where-Object {$_.Result.IsCompleted}

        
        if($Jobs_ToProcess -eq $null)
        {
            Write-Verbose "No jobs completed, wait 500ms..."

            Start-Sleep -Milliseconds 500
            continue
        }
        
        
        $Jobs_Remaining = ($Jobs | Where-Object {$_.Result.IsCompleted -eq $false}).Count

        
        try {            
            $Progress_Percent = 100 - (($Jobs_Remaining / $Jobs_Total) * 100) 
        }
        catch {
            $Progress_Percent = 100
        }

        Write-Progress -Activity "Waiting for jobs to complete... ($($Threads - $($RunspacePool.GetAvailableRunspaces())) of $Threads threads running)" -Id 1 -PercentComplete $Progress_Percent -Status "$Jobs_Remaining remaining..."
    
        Write-Verbose "Processing $(if($Jobs_ToProcess.Count -eq $null){"1"}else{$Jobs_ToProcess.Count}) job(s)..."

        
        foreach($Job in $Jobs_ToProcess)
        {       
            
            $Job_Result = $Job.Pipe.EndInvoke($Job.Result)
            $Job.Pipe.Dispose()

            
            $Jobs.Remove($Job)
        
            
            if($Job_Result -ne $null)
            {       
                $Job_Result    
            }
        } 

    } While ($Jobs.Count -gt 0)
    
    Write-Verbose "Closing RunspacePool and free resources..."

    
    $RunspacePool.Close()
    $RunspacePool.Dispose()
}

End{

}
