filter ConvertTo-String
{


    [OutputType([String])]
    Param (
        [Parameter( Mandatory = $True,
                    Position = 0,
                    ValueFromPipeline = $True )]
        [ValidateScript({-not (Test-Path $_ -PathType Container)})]
        [String]
        $Path
    )

    $FileStream = New-Object -TypeName IO.FileStream -ArgumentList (Resolve-Path $Path), 'Open', 'Read'

    
    $Encoding = [Text.Encoding]::GetEncoding(28591)
    
    $StreamReader = New-Object IO.StreamReader($FileStream, $Encoding)

    $BinaryText = $StreamReader.ReadToEnd()

    $StreamReader.Close()
    $FileStream.Close()

    Write-Output $BinaryText
}
