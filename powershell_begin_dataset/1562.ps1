
function Get-MrVssProvider {



    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]      
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Params = @{
        ComputerName = $ComputerName
        ScriptBlock = {Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\VSS\Providers' |
                       Get-ItemProperty -Name '(default)'}
        ErrorAction = 'SilentlyContinue'
        ErrorVariable = 'Problem'
    }

    if ($PSBoundParameters.Credential) {
        $Params.Credential = $Credential
    }

    Invoke-Command @Params |
    Select-Object -Property PSComputerName, @{label='VSSProviderName';expression={$_.'(default)'}}

    foreach ($p in $Problem) {
        if ($p.origininfo.pscomputername) {
            Write-Warning -Message "Unable to read registry key on $($p.origininfo.pscomputername)" 
        }
        elseif ($p.targetobject) {
            Write-Warning -Message "Unable to connect to $($p.targetobject)"
        }
    }

}