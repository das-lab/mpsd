
function Set-PoshBotStatefulData {
    
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(ValueFromPipeline,
                   Mandatory)]
        [object[]]$Value,

        [validateset('Global','Module')]
        [string]$Scope = 'Module',

        [int]$Depth = 2
    )

    end {
        if ($Value.Count -eq 1) {
            $Value = $Value[0]
        }

        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName

        if(-not (Test-Path $Path)) {
            $ToWrite = [pscustomobject]@{
                $Name = $Value
            }
        } else {
            $Existing = Import-Clixml -Path $Path
            
            If($Existing.PSObject.Properties.Name -contains $Name) {
                Write-Verbose "Overwriting [$Name]`nCurrent value: [$($Existing.$Name | Out-String)])`nNew Value: [$($Value | Out-String)]"
            }
            Add-Member -InputObject $Existing -MemberType NoteProperty -Name $Name -Value $Value -Force
            $ToWrite = $Existing
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Set stateful data')) {
            Export-Clixml -Path $Path -InputObject $ToWrite -Depth $Depth -Force
            Write-Verbose -Message "Stateful data [$Name] saved to [$Path]"
        }
    }
}

Export-ModuleMember -Function 'Set-PoshBotStatefulData'
