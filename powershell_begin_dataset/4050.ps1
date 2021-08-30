











param([hashtable]$Theme)

Set-StrictMode -Version Latest




$Theme.HostBackgroundColor   = if ($Pscx:IsAdmin) { 'DarkRed' } else { 'Black' }
$Theme.HostForegroundColor   = if ($Pscx:IsAdmin) { 'White'   } else { 'Cyan'  }
$Theme.PromptForegroundColor = if ($Pscx:IsAdmin) { 'Gray'    } else { 'White' }




$Theme.PromptScriptBlock = {
    param($Id) 
    
    if ($NestedPromptLevel) {
        new-object string ([char]0xB7), $NestedPromptLevel
    }
    
    $sepChar = '>' 
    if ($Pscx:IsAdmin) {
        $sepChar = '
    }
    
    $path = ''    
    "${Id}$path$sepChar"
}




$Theme.UpdateWindowTitleScriptBlock = {
    $adminPrefix = ''
    if ($Pscx:IsAdmin) {
        $adminPrefix = 'Admin'
    }
    $location = Get-Location
    $version = $PSVersionTable.PSVersion
    
    $bitness = ''
    if ([IntPtr]::Size -eq 8) {
        $bitness = ' (x64)'
    }
    elseif ($Pscx:IsWow64Process) {
        $bitness = ' (x86)'
    }
    
    "$adminPrefix $location - Windows PowerShell $version$bitness"
}




$Theme.StartupMessageScriptBlock = {
    $logo = "Windows PowerShell $($PSVersionTable.PSVersion)"
    if ([IntPtr]::Size -eq 8) {
        $logo += ' (x64)'
    }
    elseif ($Pscx:IsWow64Process)
    {
        $logo += ' (x86)'
    }
    $logo
    
    $user =	"`nLogged in on $([DateTime]::Now.ToString((Get-Culture))) as $($Pscx:WindowsIdentity.Name)"
    
    if ($Pscx:IsAdmin) { 
        $user += ' (Elevated).' 
    }
    else { 
        $user += '.' 
    }
    
    $user
}