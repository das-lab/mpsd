

function Update-ScheduledTask{



	param(
        [Parameter(Position=0, Mandatory=$false)]
        $Name,
        
        [switch]
        $All
	)    
    
    if(-not ($All -or $Name)){
        throw "Provide at least one parameter for this function."
    } 
    
    
	
	
	
	function Get-WindowsScheduledTasks{
    
        param(
            $Folder
        )
        
        
        $Folder.GetTasks(0) | Foreach-Object {
	        New-Object -TypeName PSCustomObject -Property @{
	            'Name' = $_.Name
                'Path' = $_.Path
                'State' = $_.State
                'Enabled' = $_.Enabled
                'LastRunTime' = $_.LastRunTime
                'LastTaskResult' = $_.LastTaskResult
                'NumberOfMissedRuns' = $_.NumberOfMissedRuns
                'NextRunTime' = $_.NextRunTime
                'Author' =  ([xml]$_.xml).Task.RegistrationInfo.Author
                'UserId' = ([xml]$_.xml).Task.Principals.Principal.UserID
                'Description' = ([xml]$_.xml).Task.RegistrationInfo.Description
            }
        }
        
        
        $Folder.getfolders(1) | %{Get-WindowsScheduledTasks -Folder $_} 
    }
    
    
	
	
	
    
    
    $ScheduledTasks = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.Task.Filter -Recurse
    
    
    $WindowsScheduledTasks = new-object -com("Schedule.Service")
    ($WindowsScheduledTasks).connect($env:COMPUTERNAME) 
    $WindowsScheduledTasks = Get-WindowsScheduledTasks -Folder $WindowsScheduledTasks.getfolder("\")
    
    $ScheduledTasks | %{    
    
        $Task = [xml]$(get-content $_.FullName) 
        $FilePathTemp = $_.FullName + "temp.xml" 
        
        $Task | where{$All -or $Name -eq $_.Task.RegistrationInfo.Description} | %{                
        
            
                   
            if($Task.Task.Actions.Exec.Command.contains("$")){$Task.Task.Actions.Exec.Command = Invoke-Expression $Task.Task.Actions.Exec.Command}
            if($Task.Task.Actions.Exec.Arguments.contains("$")){$Task.Task.Actions.Exec.Arguments = Invoke-Expression $Task.Task.Actions.Exec.Arguments}
            if($Task.Task.Actions.Exec.WorkingDirectory.contains("$")){$Task.Task.Actions.Exec.WorkingDirectory = [string](Invoke-Expression $Task.Task.Actions.Exec.WorkingDirectory)}
            $Task.Save($FilePathTemp)  
               
            $Title = $Task.task.RegistrationInfo.Description             

            if($WindowsScheduledTasks | where{$_.Description -eq $Title}){
                   
                Write-Host "Update Windows scheduled task: $Title"            
                SCHTASKS /DELETE /TN $Title /F
                SCHTASKS /Create /TN $Title /XML $FilePathTemp
                
            }else{       
                      
                Write-Host "Adding Windows scheduled task: $Title"            
                SCHTASKS /Create /TN $Title /XML $FilePathTemp            
            } 
            
            Remove-Item -Path $FilePathTemp  
        }  
    }
}