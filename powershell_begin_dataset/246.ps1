function New-CimSmartSession
{

    
    [CmdletBinding()]
    PARAM (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN
    {
        
        function Get-DefaultMessage
        {
    
            PARAM ($Message)
            Write-Output "[$(Get-Date -Format 'yyyy/MM/dd-HH:mm:ss:ff')][$((Get-Variable -Scope 1 -Name MyInvocation -ValueOnly).MyCommand.Name)] $Message"
        }

        
        $CIMSessionSplatting = @{ }

        
        IF ($PSBoundParameters['Credential']) { $CIMSessionSplatting.Credential = $Credential }

        
        $CIMSessionOption =    New-CimSessionOption -Protocol Dcom
    }

    PROCESS
    {
        FOREACH ($Computer in $ComputerName)
        {
            Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Test-Connection")
            IF (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
            {
                $CIMSessionSplatting.ComputerName = $Computer


                
                IF ((Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue).productversion -match 'Stack: ([3-9]|[1-9][0-9]+)\.[0-9]+')
                {
                    TRY
                    {
                        
                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Connecting using WSMAN protocol (Default, requires at least PowerShell v3.0)")
                        New-CimSession @CIMSessionSplatting -errorVariable ErrorProcessNewCimSessionWSMAN
                    }
                    CATCH
                    {
                        IF ($ErrorProcessNewCimSessionWSMAN) { Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Can't Connect using WSMAN protocol") }
                        Write-Warning -Message (Get-DefaultMessage -Message $Error.Exception.Message)
                    }
                }

                ELSE
                {
                    
                    $CIMSessionSplatting.SessionOption = $CIMSessionOption

                    TRY
                    {
                        Write-Verbose -Message (Get-DefaultMessage -Message "$Computer - Connecting using DCOM protocol")
                        New-CimSession @SessionParams -errorVariable ErrorProcessNewCimSessionDCOM
                    }
                    CATCH
                    {
                        IF ($ErrorProcessNewCimSessionDCOM) { Write-Warning -Message (Get-DefaultMessage -Message "$Computer - Can't connect using DCOM protocol either") }
                        Write-Warning -Message (Get-DefaultMessage -Message $Error.Exception.Message)
                    }
                    FINALLY
                    {
                        
                        $CIMSessionSplatting.Remove('CIMSessionOption')
                    }
                }
            }
        }
    }
}