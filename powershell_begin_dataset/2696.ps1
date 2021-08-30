function Get-Entropy
{


    [CmdletBinding()] Param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = 'Bytes')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $ByteArray,

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = 'File')]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo]
        $FilePath
    )

    BEGIN
    {
        $FrequencyTable = @{}
        $ByteArrayLength = 0
    }

    PROCESS
    {
        if ($PsCmdlet.ParameterSetName -eq 'File')
        {
            $ByteArray = [IO.File]::ReadAllBytes($FilePath.FullName)
        }

        foreach ($Byte in $ByteArray)
        {
            $FrequencyTable[$Byte]++
            $ByteArrayLength++
        }
    }

    END
    {
        $Entropy = 0.0

        foreach ($Byte in 0..255)
        {
            $ByteProbability = ([Double] $FrequencyTable[[Byte]$Byte]) / $ByteArrayLength
            if ($ByteProbability -gt 0)
            {
                $Entropy += -$ByteProbability * [Math]::Log($ByteProbability, 2)
            }
        }

        Write-Output $Entropy
    }
}