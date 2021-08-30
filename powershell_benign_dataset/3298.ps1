
function Get-PoshBotStatefulData {
    
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [string]$Name = '*',

        [switch]$ValueOnly,

        [validateset('Global','Module')]
        [string]$Scope = 'Module'
    )
    process {
        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName

        if(-not (Test-Path $Path)) {
            Write-Verbose "Requested stateful data file not found: [$Path]"
            return
        }
        Write-Verbose "Getting stateful data from [$Path]"
        $Output = Import-Clixml -Path $Path | Select-Object -Property $Name
        if($ValueOnly)
        {
            $Output = $Output.${Name}
        }
        $Output
    }
}

Export-ModuleMember -Function 'Get-PoshBotStatefulData'
