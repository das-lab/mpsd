
function Remove-PoshBotStatefulData {
    
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [string[]]$Name,

        [validateset('Global','Module')]
        [string]$Scope = 'Module',

        [int]$Depth = 2
    )
    process {
        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName


        if(-not (Test-Path $Path)) {
            return
        } else {
            $ToWrite = Import-Clixml -Path $Path | Select-Object * -ExcludeProperty $Name
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Remove stateful data')) {
            Export-Clixml -Path $Path -InputObject $ToWrite -Depth $Depth -Force
            Write-Verbose -Message "Stateful data [$Name] removed from [$Path]"
        }
    }
}

Export-ModuleMember -Function 'Remove-PoshBotStatefulData'
