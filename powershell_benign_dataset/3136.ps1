









[CmdletBinding(DefaultParameterSetName='Decrypt')]
param(
    [Parameter(
        Position=0,
        Mandatory=$true,
        HelpMessage='String which you want to encrypt or decrypt')]    
    [String]$Text,

    [Parameter(
        Position=1,
        HelpMessage='Specify which rotation you want to use (Default=1..26)')]
    [ValidateRange(1,26)]
    [Int32[]]$Rot=1..26,

    [Parameter(
        ParameterSetName='Encrypt',
        Position=2,
        HelpMessage='Encrypt a string')]
    [switch]$Encrypt,
    
    [Parameter(
        ParameterSetName='Decrypt',
        Position=2,
        HelpMessage='Decrypt a string')]
    [switch]$Decrypt   
)

Begin{
    [System.Collections.ArrayList]$UpperChars = @()
    [System.Collections.ArrayList]$LowerChars = @()
 
    $UpperIndex = 1
    $LowerIndex = 1

    
    foreach($i in 65..90)
    {
        $Char = [char]$i

        [pscustomobject]$Result = @{
            Index = $UpperIndex
            Char = $Char
        }   

        [void]$UpperChars.Add($Result)

        $UpperIndex++
    }

    
    foreach($i in 97..122)
    {
        $Char = [char]$i

        [pscustomobject]$Result = @{
            Index = $LowerIndex
            Char = $Char
        }   

        [void]$LowerChars.Add($Result)

        $LowerIndex++
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

            if($UpperChars.Char -ccontains $CurrentChar) 
            {
                if($Mode -eq  "Encrypt")
                {
                    [int]$NewIndex = ($UpperChars | Where-Object {$_.Char -ceq $CurrentChar}).Index + $Rot2 

                    if($NewIndex -gt $UpperChars.Count)
                    {
                        $NewIndex -= $UpperChars.Count                     
                    
                        $ResultText +=  ($UpperChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($UpperChars | Where-Object {$_.Index -eq $NewIndex}).Char    
                    }
                }
                else 
                {
                    [int]$NewIndex = ($UpperChars | Where-Object {$_.Char -ceq $CurrentChar}).Index - $Rot2 

                    if($NewIndex -lt 1)
                    {
                        $NewIndex += $UpperChars.Count                     
                    
                        $ResultText +=  ($UpperChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($UpperChars | Where-Object {$_.Index -eq $NewIndex}).Char    
                    }
                }   
            }
            elseif($LowerChars.Char -ccontains $CurrentChar) 
            {
                if($Mode -eq "Encrypt")
                {
                    [int]$NewIndex = ($LowerChars | Where-Object {$_.Char -ceq $CurrentChar}).Index + $Rot2

                    if($NewIndex -gt $LowerChars.Count)
                    {
                        $NewIndex -=  $LowerChars.Count

                        $ResultText += ($LowerChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($LowerChars | Where-Object {$_.Index -eq $NewIndex}).Char  
                    }
                }
                else 
                {
                    [int]$NewIndex = ($LowerChars | Where-Object {$_.Char -ceq $CurrentChar}).Index - $Rot2

                    if($NewIndex -lt 1)
                    {
                        $NewIndex += $LowerChars.Count

                        $ResultText += ($LowerChars | Where-Object {$_.Index -eq $NewIndex}).Char
                    }
                    else 
                    {
                        $ResultText += ($LowerChars | Where-Object {$_.Index -eq $NewIndex}).Char  
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
        