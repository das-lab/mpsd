

function Delete-ObsoleteLogFiles{
	
	
	

	
	$Features = @()

	
	Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.Profile.Filter -Recurse | 
		%{
			[xml]$(Get-Content $_.fullname) | 
			%{
				$Features += $_.Content.Feature | where{$_.Name -eq "Log File Retention"}
			}
		}

	
	$Features | %{$Days += $_.Days};$Days = ($Days | Measure-Object -Maximum).Maximum
	$Features | %{$MaxFilesToKeep += $_.MaxFilesToKeep};$MaxFilesToKeep = ($MaxFilesToKeep | Measure-Object -Maximum).Maximum

	if($Days){        
		Get-Childitem $PSlogs.Path | where{-not $_.PsIsContainer} | sort CreationTime -Descending | where{$_.Name.EndsWith("txt")} | where{$_.LastWriteTime -le $(Get-Date).AddDays(-$Days)} | Remove-Item -Force
	}

	if($MaxFilesToKeep){
		Get-Childitem $PSlogs.Path | where{-not $_.PsIsContainer} | sort CreationTime -Descending | where{$_.Name.EndsWith("txt")} | select -Skip $MaxFilesToKeep | Remove-Item -Force
	}
}