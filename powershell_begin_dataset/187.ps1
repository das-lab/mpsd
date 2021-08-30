function Set-SCCMClientCacheSize
{
    
    PARAM(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$SizeMB = 10240,

        [Switch]$ServiceRestart,

        [Alias('RunAs')]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    FOREACH ($Computer in $ComputerName)
    {
        Write-Verbose -message "[PROCESS] ComputerName: $Computer"

        
        $SplattingWMI = @{
            NameSpace = "ROOT\CCM\SoftMgmtAgent"
            Class = "CacheConfig"
        }
        $SplattingService = @{
            Name = 'ccmexec'
        }

        IF ($PSBoundParameters['ComputerName'])
        {
            $SplattingWMI.ComputerName = $Computer
            $SplattingService.ComputerName = $Computer
        }
        IF ($PSBoundParameters['Credential'])
        {
            $SplattingWMI.Credential = $Credential
        }

        TRY
        {
            
            $Cache = Get-WmiObject @SplattingWMI
            $Cache.Size = $SizeMB
            $Cache.Put()

            
            IF($PSBoundParameters['ServiceRestart'])
            {
                Get-Service @SplattingService | Restart-Service
            }
        }
        CATCH
        {
            Write-Warning -message "[PROCESS] Something Wrong happened with $Computer"
            $Error[0].execption.message
        }
    }
}
