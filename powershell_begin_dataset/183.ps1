function Get-LocalGroup
{



    PARAM
    (
        [Alias('cn')]
        [String[]]$ComputerName = $Env:COMPUTERNAME,

        [String]$AccountName,

        [System.Management.Automation.PsCredential]$Credential
    )

    $Splatting = @{
        Class = "Win32_Group"
        Namespace = "root\cimv2"
        Filter = "LocalAccount='$True'"
    }

    
    If ($PSBoundParameters['Credential']) { $Splatting.Credential = $Credential }

    Foreach ($Computer in $ComputerName)
    {
        TRY
        {
            Write-Verbose -Message "[PROCESS] ComputerName: $Computer"
            Get-WmiObject @Splatting -ComputerName $Computer | Select-Object -Property Name, Caption, Status, SID, SIDType, Domain, Description
        }
        CATCH
        {
            Write-Warning -Message "[PROCESS] Issue connecting to $Computer"
        }
    }
}