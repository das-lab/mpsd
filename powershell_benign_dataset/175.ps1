function Get-ComputerOS
{

    [CmdletBinding()]
    PARAM (
        [Parameter(ParameterSetName = "Main")]
        [Alias("CN","__SERVER","PSComputerName")]
        [String[]]$ComputerName = $env:ComputerName,

        [Parameter(ParameterSetName="Main")]
        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(ParameterSetName = "CimSession")]
        [Microsoft.Management.Infrastructure.CimSession]$CimSession
    )
    BEGIN
    {
        
        function Get-DefaultMessage
        {
    
            PARAM ($Message)
            Write-Output "[$(Get-Date -Format 'yyyy/MM/dd-HH:mm:ss:ff')][$((Get-Variable -Scope 1 -Name MyInvocation -ValueOnly).MyCommand.Name)] $Message"
        }
    }
    PROCESS
    {
        FOREACH ($Computer in $ComputerName)
        {
            TRY
            {
                Write-Verbose -Message (Get-DefaultMessage -Message $Computer)
                IF (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
                {
                    
                    $Splatting = @{
                        class = "Win32_OperatingSystem"
                        ErrorAction = Stop
                    }

                    IF ($PSBoundParameters['CimSession'])
                    {
                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - CimSession")
                        
                        $Query = Get-CIMInstance @Splatting -CimSession $CimSession
                    }
                    ELSE
                    {
                        
                        IF ($PSBoundParameters['Credential'])
                        {
                            Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Credential specified $($Credential.username)")
                            $Splatting.Credential = $Credential
                        }

                        
                        $Splatting.ComputerName = $ComputerName
                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Get-WmiObject")
                        $Query = Get-WmiObject @Splatting
                    }

                    
                    $Properties = @{
                        ComputerName = $Computer
                        OperatingSystem = $Query.Caption
                    }

                    
                    New-Object -TypeName PSObject -Property $Properties
                }
            }
            CATCH
            {
                Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Issue to connect")
                Write-Verbose -Message $Error[0].Exception.Message
            }
            FINALLY
            {
                $Splatting.Clear()
            }
        }
    }
    END
    {
        Write-Warning -Message (Get-DefaultMessage -Message "Script completed")
    }
}