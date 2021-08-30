function Set-NetworkLevelAuthentication
{

    
    [CmdletBinding()]
    PARAM (
        [Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [System.String[]]$ComputerName = $env:ComputerName,

        [Parameter(Mandatory)]
        [System.Boolean]$EnableNLA,

        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    BEGIN
    {
        TRY
        {
            IF (-not (Get-Module -Name CimCmdlets))
            {
                Write-Verbose -Message '[BEGIN] Import Module CimCmdlets'
                Import-Module CimCmdlets -ErrorAction 'Stop' -ErrorVariable ErrorBeginCimCmdlets
            }
        }
        CATCH
        {
            IF ($ErrorBeginCimCmdlets)
            {
                Write-Error -Message "[BEGIN] Can't find CimCmdlets Module"
            }
        }
    }

    PROCESS
    {
        FOREACH ($Computer in $ComputerName)
        {
            Write-Verbose -message $Computer
            TRY
            {
                
                Write-Verbose -message "$Computer - CIM/WIM - Building Splatting"
                $CIMSessionParams = @{
                    ComputerName = $Computer
                    ErrorAction = 'Stop'
                    ErrorVariable = 'ProcessError'
                }

                
                IF ($PSBoundParameters['Credential'])
                {
                    Write-Verbose -message "[PROCESS] $Computer - CIM/WMI - Add Credential Specified"
                    $CIMSessionParams.credential = $Credential
                }

                
                Write-Verbose -Message "[PROCESS] $Computer - Testing Connection..."
                Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Stop -ErrorVariable ErrorTestConnection | Out-Null

                
                
                IF ((Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue).productversion -match 'Stack: 3.0')
                {
                    Write-Verbose -Message "[PROCESS] $Computer - WSMAN is responsive"
                    $CimSession = New-CimSession @CIMSessionParams
                    $CimProtocol = $CimSession.protocol
                    Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Opened"
                }

                
                ELSE
                {
                    
                    Write-Verbose -Message "[PROCESS] $Computer - Trying to connect via DCOM protocol"
                    $CIMSessionParams.SessionOption = New-CimSessionOption -Protocol Dcom
                    $CimSession = New-CimSession @CIMSessionParams
                    $CimProtocol = $CimSession.protocol
                    Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Opened"
                }

                
                Write-Verbose -message "[PROCESS] $Computer - [$CimProtocol] CIM SESSION - Get the Terminal Services Information"
                $NLAinfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
                $NLAinfo | Invoke-CimMethod -MethodName SetUserAuthenticationRequired -Arguments @{ UserAuthenticationRequired = $EnableNLA } -ErrorAction 'Continue' -ErrorVariable ErrorProcessInvokeWmiMethod
            }

            CATCH
            {
                Write-Warning -Message "Error on $Computer"
                Write-Error -Message $_.Exception.Message
                if ($ErrorTestConnection) { Write-Warning -Message "[PROCESS] Error - $ErrorTestConnection" }
                if ($ProcessError) { Write-Warning -Message "[PROCESS] Error - $ProcessError" }
                if ($ErrorProcessInvokeWmiMethod) { Write-Warning -Message "[PROCESS] Error - $ErrorProcessInvokeWmiMethod" }
            }
            FINALLY
            {
                if ($CimSession)
                {
                    
                    Write-Verbose -Message "[PROCESS] Finally Close any CIM Session(s)"
                    Remove-CimSession -CimSession $CimSession
                }
            }
        } 
    }
    END
    {
        Write-Verbose -Message "[END] Script is completed"
    }
}
