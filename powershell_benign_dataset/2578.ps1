	[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
	[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum")
	[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

	$namedInstance = new-object('Microsoft.SqlServer.Management.Smo.server') 'XSQLUTIL18'
	
	$jobs = $namedInstance.jobserver.jobs 

	
	foreach ($job in $jobs) 
	{
		[int]$outcome = 0
		[string]$output = ""
	
		
		if ($job.LastRunOutcome -ne "Succeeded") 
		{
			$outcome++;
			$output = $output + " Job failed (" + $job.name + ")" + " Result: " + $job.LastRunOutcome;
		}
		elseif ($job.LastRunOutcome -eq "Succeeded")
		{
			$outcome++;
			$output = $output + " Job succeeded " + $job.Name + ")" + " Result: " + $job.LastRunOutcome;
		}
		
		
		foreach ($jobStep in $job.jobsteps) 
		{
			if ($jobStep.LastRunOutcome -ne "Succeeded")
			{
				$outcome++;
				$output = $output + " Step failed (" + $jobStep.name + ")" + " Result: " + $jobStep.LastRunOutcome + " -- ";
			}
			elseif ($jobstep.LastRunOutcome -eq "Succeeded")
			{
				$outcome++;
				$output = $output + " Step succeeded (" + $jobStep.Name + ")" + "Result: " + $jobStep.LastRunOutcome + " -- ";
			}
		}
		
		if ($outcome -gt 0)    
		{
			$obj = New-Object Object;
			$obj | Add-Member Noteproperty name -value $job.name;
			$obj | Add-Member Noteproperty lastrundate -value $job.lastrundate;
			$obj | Add-Member Noteproperty lastrunoutcome -value $output;
			$obj | Add-Member Noteproperty lastrunduration -value $jobStep.LastRunDuration;
			$obj
		}
	}