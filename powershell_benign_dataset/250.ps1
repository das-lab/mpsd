function New-DjoinFile
{
    
    [Cmdletbinding()]
    PARAM (
        [Parameter(Mandatory = $true)]
        [System.String]$Blob,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$DestinationFile = "c:\temp\djoin.tmp"
    )

    PROCESS
    {
        TRY
        {
            
            $bytechain = New-Object -TypeName byte[] -ArgumentList 2
            
            $bytechain[0] = 255
            $bytechain[1] = 254

            
            $FileStream = $DestinationFile.Openwrite()

            
            $bytechain += [System.Text.Encoding]::unicode.GetBytes($Blob)
            
            $bytechain += 0
            $bytechain += 0

            
            $FileStream.write($bytechain, 0, $bytechain.Length)

            
            $FileStream.Close()
        }
        CATCH
        {
            $Error[0]
        }
    }
}