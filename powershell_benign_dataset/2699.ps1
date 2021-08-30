function Get-Strings
{


    Param
    (
        [Parameter(Position = 1, Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [String[]]
        [Alias('PSPath')]
        $Path,

        [ValidateSet('Default','Ascii','Unicode')]
        [String]
        $Encoding = 'Default',

        [UInt32]
        $MinimumLength = 3
    )

    BEGIN
    {
        $FileContents = ''
    }
    PROCESS
    {
        foreach ($File in $Path)
        {
            if ($Encoding -eq 'Unicode' -or $Encoding -eq 'Default')
            {
                $UnicodeFileContents = Get-Content -Encoding 'Unicode' $File
                $UnicodeRegex = [Regex] "[\u0020-\u007E]{$MinimumLength,}"
                $Results += $UnicodeRegex.Matches($UnicodeFileContents)
            }
            
            if ($Encoding -eq 'Ascii' -or $Encoding -eq 'Default')
            {
                $AsciiFileContents = Get-Content -Encoding 'UTF7' $File
                $AsciiRegex = [Regex] "[\x20-\x7E]{$MinimumLength,}"
                $Results = $AsciiRegex.Matches($AsciiFileContents)
            }

            $Results | ForEach-Object { Write-Output $_.Value }
        }
    }
    END {}
}
