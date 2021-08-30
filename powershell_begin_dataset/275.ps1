

function Get-ComputerInfo
{



 [CmdletBinding()]

    PARAM(
    [Parameter(ValueFromPipeline=$true)]
    [String[]]$ComputerName = "LocalHost",

    [String]$ErrorLog = ".\Errors.log",

    [Alias("RunAs")]
    [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty
    )

    BEGIN {}

    PROCESS{
        FOREACH ($Computer in $ComputerName) {
            Write-Verbose -Message "PROCESS - Querying $Computer ..."

            TRY{
                $Splatting = @{
                    ComputerName = $Computer
                }

                IF ($PSBoundParameters["Credential"]){
                    $Splatting.Credential = $Credential
                }


                $Everything_is_OK = $true
                Write-Verbose -Message "PROCESS - $Computer - Testing Connection"
                Test-Connection -Count 1 -ComputerName $Computer -ErrorAction Stop -ErrorVariable ProcessError | Out-Null

                
                Write-Verbose -Message "PROCESS - $Computer - WMI:Win32_OperatingSystem"
                $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem @Splatting -ErrorAction Stop -ErrorVariable ProcessError

                
                Write-Verbose -Message "PROCESS - $Computer - WMI:Win32_ComputerSystem"
                $ComputerSystem = Get-WmiObject -Class win32_ComputerSystem @Splatting -ErrorAction Stop -ErrorVariable ProcessError

                
                Write-Verbose -Message "PROCESS - $Computer - WMI:Win32_Processor"
                $Processors = Get-WmiObject -Class win32_Processor @Splatting -ErrorAction Stop -ErrorVariable ProcessError

                
                
                
                Write-Verbose -Message "PROCESS - $Computer - Determine the number of Socket(s)/Core(s)"
                $Cores = 0
                $Sockets = 0
                FOREACH ($Proc in $Processors){
                    IF($Proc.numberofcores -eq $null){
                        IF ($Proc.SocketDesignation -ne $null){$Sockets++}
                        $Cores++
                    }ELSE {
                        $Sockets++
                        $Cores += $proc.numberofcores
                    }
                }

            }CATCH{
                $Everything_is_OK = $false
                Write-Warning -Message "Error on $Computer"
                $Computer | Out-file -FilePath $ErrorLog -Append -ErrorAction Continue
                $ProcessError | Out-file -FilePath $ErrorLog -Append -ErrorAction Continue
                Write-Warning -Message "Logged in $ErrorLog"

            }


            IF ($Everything_is_OK){
                Write-Verbose -Message "PROCESS - $Computer - Building the Output Information"
                $Info = [ordered]@{
                    "ComputerName" = $OperatingSystem.__Server;
                    "OSName" = $OperatingSystem.Caption;
                    "OSVersion" = $OperatingSystem.version;
                    "MemoryGB" = $ComputerSystem.TotalPhysicalMemory/1GB -as [int];
                    "NumberOfProcessors" = $ComputerSystem.NumberOfProcessors;
                    "NumberOfSockets" = $Sockets;
                    "NumberOfCores" = $Cores}

                $output = New-Object -TypeName PSObject -Property $Info
                $output
            } 
        }
    }
    END{
        
        Write-Verbose -Message "END - Cleanup Variables"
        Remove-Variable -Name output,info,ProcessError,Sockets,Cores,OperatingSystem,ComputerSystem,Processors,
        ComputerName, ComputerName, Computer, Everything_is_OK -ErrorAction SilentlyContinue

        
        Write-Verbose -Message "END - Script End !"
    }
}
