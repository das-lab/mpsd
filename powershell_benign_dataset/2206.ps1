
New-EventLog -LogName "Application" -Source "CCM Clean Primary User"


Write-Eventlog -Logname "Application" -Source "CCM Clean Primary User" -EventID 64351 -EntryType Information -Message "Start Processing object(s)."

try {
    
    $StateMsgs = Get-WmiObject -Namespace root\ccm\StateMsg -Class CCM_StateMsg -Filter "TopicID like '%Auto%'" -ErrorAction Stop

    
    $StateMsgsCount = ($StateMsgs | Measure-Object).Count
    Write-Eventlog -Logname "Application" -Source "CCM Clean Primary User" -EventID 64352 -EntryType Information -Message "Found $($StateMsgsCount) Object(s)."

    
    if ($StateMsgs -ne $null) {
        
        foreach ($StateMsg in $StateMsgs) {
            $StateMsg.Get()
            $PrimaryUserName = $StateMsg.UserParameters | Select-Object -First 1
            Write-Eventlog -Logname "Application" -Source "CCM Clean Primary User" -EventID 64353 -EntryType Information -Message "Removing $($PrimaryUserName) from CCM_StateMsg class."
            Remove-WmiObject -InputObject $StateMsg
        }
    }
}
catch [Exception] {
    Write-EventLog -LogName "Application" -Source "CCM Clean Primary User" -EventId 64354 -EntryType Error -Message "Unable to query WMI for objects"
}