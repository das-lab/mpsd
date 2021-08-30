


[CmdletBinding(SupportsShouldProcess)]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
    [Parameter(Mandatory)]
    [string[]]$Group,
    [Parameter()]
    [ValidatePattern('\b[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\b')]
    [string]$Email = 'admin@lab.local',
    [Parameter()]
    [string]$LogFilePath = "$PsScriptRoot\$($MyInvocation.MyCommand.Name).csv"
)

begin {
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    Set-StrictMode -Version Latest

    function Write-Log {
        
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Message,
            [Parameter()]
            [ValidateSet(1, 2, 3)]
            [int]$LogLevel = 1
        )
		
        try {
            $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
            
            $Line = '{2} {1}: {0}'
            $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy)
            $Line = $Line -f $LineFormat
			
            Add-Content -Value $Line -Path $LogFilePath
        } catch {
            Write-Error $_.Exception.Message
        }
    }

    function Add-GroupMemberToLogFile ($GroupName,[string[]]$Member) {
        foreach ($m in $Member) {
            [pscustomobject]@{'Group' = $GroupName; 'Member' = $m} | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
        }   
    }
    
    function Get-GroupMemberFromLogFile ([string]$GroupName) {
        (Import-Csv -Path $LogFilePath | Where-Object { $_.Group -eq $GroupName }).Member
    }
    
    function Send-ChangeNotification ($GroupName,$ChangeType,$Members) {
        $EmailBody = "
            The following group has changed: $GroupName`n`r
            The following members were $ChangeType`n`r
            $($Members -join ',')
        "
        
        $Params = @{
            'From' = 'Active Directory Administrator <admin@mycompany.com>'
            'To' = $Email
            'Subject' = 'AD Group Change'
            'SmtpServer' = 'my.smptpserver.local'
            'Body' = $EmailBody
        }
        Send-MailMessage @Params
    }
}

process {
    try {
        Write-Log -Message 'Querying Active directory domain for group memberships...'
        foreach ($g in $Group) {
            Write-Log -Message "Querying the [$g] group for members..."
            $CurrentMembers = (Get-ADGroupMember -Identity $g).Name
            if (-not $CurrentMembers) {
                Write-Log -Message "No members found in the [$g] group."
            } else {
                Write-Log -Message "Found [$($CurrentMembers.Count)] members in the [$g] group"
                if (-not (Test-Path -Path $LogFilePath -PathType Leaf)) {
                    Write-Log -Message "The log file [$LogFilePath] does not exist yet. This must be the first run. Dumping all members into it..."
                    Add-GroupMemberToLogFile -GroupName $g -Member $CurrentMembers
                } else {
                    Write-Log -Message 'Existing log file found. Reading previous group members...'
                    $PreviousMembers = Get-GroupMemberFromLogFile -GroupName $g
                    $ComparedMembers = Compare-Object -ReferenceObject $PreviousMembers -DifferenceObject $CurrentMembers
                    if (-not $ComparedMembers) {
                        Write-Log "No differences found in group $g"
                    } else {
                        $RemovedMembers = ($ComparedMembers |  Where-Object { $_.SideIndicator -eq '<=' }).InputObject
                        if (-not $RemovedMembers) {
                            Write-Log -Message 'No members have been removed since last check'
                        } else {
                            Write-Log -Message "Found [$($RemovedMembers.Count)] members that have been removed since last check"
                            Send-ChangeNotification -GroupName $g -ChangeType 'Removed' -Members $RemovedMembers
                            Write-Log -Message "Emailed change notification to $Email"
                            
                            (Import-Csv -Path $LogFilePath | Where-Object {$RemovedMembers -notcontains $_.Member}) | Export-Csv -Path $LogFilePath -NoTypeInformation
                        }
                         $AddedMembers = ($ComparedMembers |  Where-Object { $_.SideIndicator -eq '=>' }).InputObject
                         if (-not $AddedMembers) {
                             Write-Log -Message 'No members have been removed since last check'
                         } else {
                             Write-Log -Message "Found [$($AddedMembers.Count)] members that have been added since last check"
                             Send-ChangeNotification -GroupName $g -ChangeType 'Added' -Members $AddedMembers
                             Write-Log -Message "Emailed change notification to $Email"
                             
                            $AddedMembers | foreach {[pscustomobject]@{'Group' = $g; 'Member' = $_}} | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
                         }
                        
                    }
                }
            }

        }

    } catch {
        Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
    }
}