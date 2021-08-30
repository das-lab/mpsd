









[CmdletBinding(DefaultParameterSetName='Decrypt')]
param (
    [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage='String which you want to encrypt or decrypt')]    
    [String]$Text,

    [Parameter(
        Position=1,
        HelpMessage='Specify which rotation you want to use (Default=1..47)')]
    [ValidateRange(1,47)]
    [Int32[]]$Rot=1..47,

    [Parameter(
        ParameterSetName='Encrypt',
        Position=2,
        HelpMessage='Encrypt a string')]
    [switch]$Encrypt,
    
    [Parameter(
        ParameterSetName='Decrypt',
        Position=2,
        HelpMessage='Decrypt a string')]
    [switch]$Decrypt,

    [Parameter(
        Position=3,
        HelpMessage='Use complete ascii table 0..255 chars (Default=33..126)')]
    [switch]$UseAllAsciiChars
)

Begin{
    [System.Collections.ArrayList]$AsciiChars = @()
     
    $CharsIndex = 1
    
    $StartAscii = 33
    $EndAscii = 126

    
    if($UseAllAsciiChars)
    {
        $StartAscii = 0
        $EndAscii = 255

        Write-Host "Warning: Parameter -UseAllAsciiChars will use all chars from 0 to 255 in the ascii table. This may not work properly, but could be usefull to encrypt or decrypt languages like german with umlauts!" -ForegroundColor Yellow
    }

    
    foreach($i in $StartAscii..$EndAscii)
    {
        $Char = [char]$i

        [pscustomobject]$Result = @{
            Index = $CharsIndex
            Char = $Char
        }   

        [void]$AsciiChars.Add($Result)

        $CharsIndex++
    }

    
    if(($Encrypt -eq $false -and $Decrypt -eq $false) -or ($Decrypt)) 
    {        
        $Mode = "Decrypt"
    }    
    else 
    {
        $Mode = "Encrypt"
    }

    Write-Verbose -Message "Mode is set to: $Mode"
}

Process{
    foreach($Rot2 in $Rot)
    {        
        $ResultText = [String]::Empty

        
        foreach($i in 0..($Text.Length -1))
        {
            $CurrentChar = $Text.Substring($i, 1)

            if(($AsciiChars.Char -ccontains $CurrentChar) -and ($CurrentChar -ne " ")) 
            {
                if($Mode -eq  "Encrypt")
                {                    
                    [int]$NewIndex = ($AsciiChars | Where-Object {$_.Char -ceq $CurrentChar}).Index + $Rot2 
                    
                    if($NewIndex -gt $AsciiChars.Count)
                    {
                        $NewIndex -= $AsciiChars.Count                     
                    
                        $ResultText +=  ($AsciiChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($AsciiChars | Where-Object {$_.Index -eq $NewIndex}).Char    
                    }
                }
                else 
                {
                    [int]$NewIndex = ($AsciiChars | Where-Object {$_.Char -ceq $CurrentChar}).Index - $Rot2 

                    if($NewIndex -lt 1)
                    {
                        $NewIndex += $AsciiChars.Count                     
                    
                        $ResultText +=  ($AsciiChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($AsciiChars | Where-Object {$_.Index -eq $NewIndex}).Char    
                    }
                }   
            }
            else 
            {
                $ResultText += $CurrentChar  
            }
        } 
    
        [pscustomobject] @{
            Rot = $Rot2
            Text = $ResultText
        }
    }
}

End{

}
        