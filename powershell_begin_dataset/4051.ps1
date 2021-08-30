










param([hashtable]$Theme)

Set-StrictMode -Version Latest





if ($Pscx:IsAdmin -and ([System.Environment]::OSVersion.Version.Major -gt 5)) {
    $Theme.PromptForegroundColor = 'Red'
}




$Theme.PromptScriptBlock = {
    param($nextCommandId) 
    
    
    $nestingLevel = ''
    if ($nestedpromptlevel -ge 1) {
        $nestingLevel = " [Nested:${nestedpromptlevel}]"
    }
    
    $promptChar = '>'
    if ($Pscx:IsAdmin) {
        $promptChar = '
    }
    
    
    "${nextCommandId}${nestingLevel}$promptChar"
}




$Theme.UpdateWindowTitleScriptBlock = {
    
    
    $isVistaOrHigher = ([System.Environment]::OSVersion.Version.Major -gt 5)	

    $adminStatus = ''
    if ($Pscx:IsAdmin -and $isVistaOrHigher) { $adminStatus = 'Admin: ' }
        
    $location = Get-Location
    $version = $PSVersionTable.PSVersion
    
    $bitness = ''
    if ([IntPtr]::Size -eq 8) {
        $bitness = ' (x64)'
    }
    elseif ($Pscx:IsWow64Process) {
        $bitness = ' (x86)'
    }
    
    "$adminStatus$location - Windows PowerShell $version$bitness"
}
