function Test-RunningAsElevated

{
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    if(-not $script:IsRunningAsElevatedTested -and $script:IsRunningAsElevated)
    {
        if($script:IsWindows)
        {
            $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
            $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
            $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
            $script:IsRunningAsElevated = $prp.IsInRole($adm)
        }
        elseif($script:IsCoreCLR)
        {
            
            
            $script:IsRunningAsElevated = $true
        }

        $script:IsRunningAsElevatedTested = $true
    }

    return $script:IsRunningAsElevated
}
