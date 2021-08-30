function Get-SCCMClientCacheInformation
{

    PARAM(
        [string[]]$ComputerName=".",

        [Alias('RunAs')]
        [System.Management.Automation.Credential()]
        [pscredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    FOREACH ($Computer in $ComputerName)
    {
        Write-Verbose -message "[PROCESS] ComputerName: $Computer"

        
        $SplattingWMI = @{
            NameSpace = "ROOT\CCM\SoftMgmtAgent"
            Class = "CacheConfig"
        }

        IF ($PSBoundParameters['ComputerName'])
        {
            $SplattingWMI.ComputerName = $Computer
        }
        IF ($PSBoundParameters['Credential'])
        {
            $SplattingWMI.Credential = $Credential
        }

        TRY
        {
            
            Get-WmiObject @SplattingWMI

        }
        CATCH
        {
            Write-Warning -message "[PROCESS] Something Wrong happened with $Computer"
            $Error[0].execption.message
        }
    }
}
