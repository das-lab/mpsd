function Enable-RemoteDesktop
{

    
    [CmdletBinding(DefaultParameterSetName = 'CimSession',
                   SupportsShouldProcess = $true)]
    param
    (
        [Parameter(ParameterSetName = 'Main',
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('CN', '__SERVER', 'PSComputerName')]
        [String[]]$ComputerName,

        [Parameter(ParameterSetName = 'Main')]
        [System.Management.Automation.Credential()]
        [Alias('RunAs')]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter(ParameterSetName = 'CimSession')]
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

                IF ($PSCmdlet.ShouldProcess($CIMComputer, "Enable Remote Desktop via Win32_TerminalServiceSetting"))
                {

                    TRY
                    {
                        
                        $CIMSplatting = @{
                            Class = "Win32_TerminalServiceSetting"
                            NameSpace = "root\cimv2\terminalservices"
                            CimSession = $Cim
                            Authentication = 'PacketPrivacy'
                            ErrorAction = 'Stop'
                            ErrorVariable = "ErrorProcessGetCimInstance"
                        }

                        
                        $CIMInvokeSplatting = @{
                            MethodName = "SetAllowTSConnections"
                            Arguments = @{
                                AllowTSConnections = 1
                                ModifyFirewallException = 1
                            }
                            ErrorAction = 'Stop'
                            ErrorVariable = "ErrorProcessInvokeCim"
                        }

                        Write-Verbose -Message (Get-DefaultMessage -Message "$CIMComputer - CIMSession - Enable Remote Desktop (and Modify Firewall Exception")
                        Get-CimInstance @CIMSplatting | Invoke-CimMethod @CIMInvokeSplatting
                    }
                    CATCH
                    {
                        Write-Warning -Message (Get-DefaultMessage -Message "$CIMComputer - CIMSession - Something wrong happened")
                        IF ($ErrorProcessGetCimInstance) { Write-Warning -Message (Get-DefaultMessage -Message "$CIMComputer - Issue with Get-CimInstance") }
                        IF ($ErrorProcessInvokeCim) { Write-Warning -Message (Get-DefaultMessage -Message "$CIMComputer - Issue with Invoke-CimMethod") }
                        Write-Warning -Message $Error[0].Exception.Message
                    } 
                    FINALLY
                    {
                        $CIMSplatting.Clear()
                        $CIMInvokeSplatting.Clear()
                    } 
                } 
            } 
        } 
        ELSE
        {
            FOREACH ($Computer in $ComputerName)
            {
                $Computer = $Computer.ToUpper()

                IF ($PSCmdlet.ShouldProcess($Computer, "Enable Remote Desktop via Win32_TerminalServiceSetting"))
                {
                    TRY
                    {
                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Test-Connection")
                        IF (Test-Connection -Computer $Computer -count 1 -quiet)
                        {
                            $Splatting = @{
                                Class = "Win32_TerminalServiceSetting"
                                NameSpace = "root\cimv2\terminalservices"
                                ComputerName = $Computer
                                Authentication = 'PacketPrivacy'
                                ErrorAction = 'Stop'
                                ErrorVariable = 'ErrorProcessGetWmi'
                            }

                            IF ($PSBoundParameters['Credential'])
                            {
                                $Splatting.credential = $Credential
                            }

                            
                            Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Get-WmiObject - Enable Remote Desktop")
                            (Get-WmiObject @Splatting).SetAllowTsConnections(1, 1) | Out-Null

                            
                            
                        }
                    } 
                    CATCH
                    {
                        Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Something wrong happened")
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
}
