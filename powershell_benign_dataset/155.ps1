Function Get-Something
{

    PARAM (
        [Alias("CN", "__SERVER", "PSComputerName")]
        [String[]]$ComputerName = $env:COMPUTERNAME,

        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        [pscredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    TRY
    {
        $FunctionName = $MyInvocation.MyCommand.Name


        $Splatting = @{
            ComputerName = $ComputerName
        }

        IF ($PSBoundParameters['Credential'])
        {
            Write-Verbose -Message "[$FunctionName] Appending Credential"
            $Splatting.Credential = $Credential
        }

        
        Write-Verbose -Message "[$FunctionName] Connect to..."

    }
    CATCH
    {
        $PSCmdlet.ThrowTerminatingError($_)
    }
    FINALLY
    {
        
    }
}