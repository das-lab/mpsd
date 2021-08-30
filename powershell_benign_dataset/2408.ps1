
[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
	[string]$DestinationComputername,
	[string[]]$ExcludePaths,
	[string[]]$ExcludeTasks,
	[switch]$SkipDisabledTasks
)

function Get-MyScheduledTask ($Computername) {
	$ScriptBlock = {
		$Service = New-object -ComObject ("Schedule.Service")
		$Service.Connect()
		$Folders = [System.Collections.ArrayList]@()
		$Root = $Service.GetFolder("\")
		$Folders.Add($Root) | Out-Null
		$Root.GetFolders(0) | foreach { $Folders.Add($_) | Out-Null }
		foreach ($Folder in $Folders) {
			$Folder.GetTasks(0)
		}
	}
	if (-not $PSBoundParameters.ContainsKey('ComputerName')) {
		$ScriptBlock.Invoke()
	} else {
		Invoke-Command -ComputerName $Computername -ScriptBlock $ScriptBlock
	}
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

try {
	
	$SrcSchTasks = Get-MyScheduledTask | where { $ExcludePaths -notcontains $_.Path }
	Write-Verbose "Found $(@($SrcSchTasks).Count) scheduled tasks on [$DestinationComputername] to migrate."
	
	if (!$SrcSchTasks) {
		throw "No scheduled tasks found on localhost"
	}
	
	
	$ExcludePaths += '\Microsoft'
	
	
	
	$DestSession = New-PSSession -ComputerName $DestinationComputername
	
	
	
	
	$UserAccountsAffected = $SrcSchTasks | foreach { ([xml]$_.xml).Task.Principals.Principal.UserId } | Select-Object -Unique
	if ($UserAccountsAffected) {
		$StoredCredentials = @{ }
		$UserAccountsAffected | foreach {
			$Password = Read-Host "What is the password for $($_)?"
			$StoredCredentials[$_] = $Password
		}
	}
	
	
	$BeforeDestSchTasks = Get-MyScheduledTask -Computername $DestinationComputername | Select-Object -ExpandProperty Path
	Write-Verbose "Found $(@($BeforeDestSchTasks).Count) scheduled tasks on destination computer pre-migration"
	
	foreach ($Task in $SrcSchTasks) {
		
		if ($BeforeDestSchTasks -contains $Task.Path) {
			Write-Warning "The task $($Task.Path) already exists on the destination computer"
		} elseif ($ExcludeTasks -contains $Task.Name) {
			Write-Verbose "Skipping the task $($Task.Name)"
		} else {
			
			$xTask = [xml]$Task.xml
			if (($xTask.Task.Settings.Enabled -eq 'false') -and $SkipDisabledTasks.IsPresent) {
				Write-Verbose "Skipping disabled task $($Task.Path)"
			} else {
				
				
				$User = $xTask.Task.Principals.Principal.UserId
				$Password = $StoredCredentials[$User]
				$Path = $Task.Path | Split-Path -Parent
				
				
				$taskName = $Task.Name
				Invoke-Command -Session $DestSession -ScriptBlock {
					Register-ScheduledTask -Xml $using:xTask -TaskName $using:taskName -TaskPath $using:Path -User $using:User -Password $using:Password | Out-Null
				}
			}
		}
	}
} catch {
	Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
} finally {
	if (Get-Variable -name DestSession -ErrorAction Ignore) {
		Remove-PSSession $DestSession
	}
}
