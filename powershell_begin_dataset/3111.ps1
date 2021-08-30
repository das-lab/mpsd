









function ConvertTo-Base64
{
    [CmdletBinding(DefaultParameterSetName='Text')]
    param(
        [Parameter(
            ParameterSetName='Text',
            Mandatory=$true,
            Position=0,
            HelpMessage='Text (command), which is to be converted to a Base64 encoded string')]
        [String]$Text,

        [Parameter(
            ParameterSetName='File',
            Mandatory=$true,
            Position=0,
            HelpMessage='Path to the file where the text (command) is stored, which is to be converterd to a Base64 encoded string')]
        [String]$FilePath
    )

    Begin{

    }

    Process{
        switch ($PSCmdlet.ParameterSetName) 
        {
            "Text" {
                $TextToConvert = $Text
            }

            "File" {
                if(Test-Path -Path $FilePath -PathType Leaf)
                {
                    $TextToConvert = Get-Content -Path $FilePath
                }
                else 
                {
                    throw "No valid file path entered... Check your input!"
                }
            }                                   
        }

        try{
            
            $BytesToConvert = [Text.Encoding]::Unicode.GetBytes($TextToConvert)

            
            $EncodedText = [Convert]::ToBase64String($BytesToConvert)
        }
        catch{
            throw
        }

        if($EncodedText.Length -gt 8100)
        {
            Write-Warning -Message "Encoded command may be to long to run via ""-EncodedCommand"" of PowerShell.exe"    
        }

        $EncodedText
    }

    End{

    }
}