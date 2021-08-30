function Get-Uptime
{

    [CmdletBinding()]
    PARAM (
        [Parameter(
                   ParameterSetName = "Main",
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [Alias("CN", "__SERVER", "PSComputerName")]
        [String[]]$ComputerName=$env:COMPUTERNAME,

        [Parameter(ParameterSetName = "Main")]
        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(ParameterSetName = "CimSession")]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )
    BEGIN
    {
        
        function Get-DefaultMessage
        {

            PARAM ($Message)
            $DateFormat = Get-Date -Format 'yyyy/MM/dd-HH:mm:ss:ff'
            $FunctionName = (Get-Variable -Scope 1 -Name MyInvocation -ValueOnly).MyCommand.Name
            Write-Output "[$DateFormat][$FunctionName] $Message"
        }
    }
    PROCESS
    {
        IF ($PSBoundParameters['CimSession'])
        {
            FOREACH ($Cim in $CimSession)
            {
                $CIMComputer = $($Cim.ComputerName).ToUpper()

                TRY
                {
                    
                    $CIMSplatting = @{
                        Class = "Win32_OperatingSystem"
                        CimSession = $Cim
                        ErrorAction = 'Stop'
                        ErrorVariable = "ErrorProcessGetCimInstance"
                    }


                    Write-Verbose -Message (Get-DefaultMessage -Message "$CIMComputer - Get-Uptime")
                    $CimResult = Get-CimInstance @CIMSplatting

                    
                    $Uptime = New-TimeSpan -Start $($CimResult.lastbootuptime) -End (get-date)

                    $Properties = @{
                        ComputerName = $CIMComputer
                        Days = $Uptime.days
                        Hours = $Uptime.hours
                        Minutes = $Uptime.minutes
                        Seconds = $Uptime.seconds
                        LastBootUpTime = $CimResult.lastbootuptime
                    }

                    
                    New-Object -TypeName PSObject -Property $Properties

                }
                CATCH
                {
                    Write-Warning -Message (Get-DefaultMessage -Message "$CIMComputer - Something wrong happened")
                    IF ($ErrorProcessGetCimInstance) { Write-Warning -Message (Get-DefaultMessage -Message "$CIMComputer - Issue with Get-CimInstance") }
                    Write-Warning -Message $Error[0].Exception.Message
                } 
                FINALLY
                {
                    $CIMSplatting.Clear() | Out-Null
                }
            } 
        } 
        ELSE
        {
            FOREACH ($Computer in $ComputerName)
            {
                $Computer = $Computer.ToUpper()

                TRY
                {
                    Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Test-Connection")
                    IF (Test-Connection -Computer $Computer -count 1 -quiet)
                    {
                        $Splatting = @{
                            Class = "Win32_OperatingSystem"
                            ComputerName = $Computer
                            ErrorAction = 'Stop'
                            ErrorVariable = 'ErrorProcessGetWmi'
                        }

                        IF ($PSBoundParameters['Credential'])
                        {
                            $Splatting.credential = $Credential
                        }

                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Getting Uptime")
                        $result = Get-WmiObject @Splatting


                        
                        $HumanTimeFormat = $Result.ConvertToDateTime($Result.Lastbootuptime)
                        $Uptime = New-TimeSpan -Start $HumanTimeFormat -End $(get-date)

                        $Properties = @{
                            ComputerName = $Computer
                            Days = $Uptime.days
                            Hours = $Uptime.hours
                            Minutes = $Uptime.minutes
                            Seconds = $Uptime.seconds
                            LastBootUpTime = $CimResult.lastbootuptime
                        }
                        
                        New-Object -TypeName PSObject -Property $Properties
                    }
                }
                CATCH
                {
                    Write-Warning -Message (Get-DefaultMessage -Message "$$Computer - Something wrong happened")
                    IF ($ErrorProcessGetWmi) { Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Issue with Get-WmiObject") }
                    Write-Warning -MEssage $Error[0].Exception.Message
                }
                FINALLY
                {
                    $Splatting.Clear()
                }
            }
        } 
    }
}