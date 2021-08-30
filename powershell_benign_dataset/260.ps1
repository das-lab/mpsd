function Get-StringLastDigit
{

[CmdletBinding()]
PARAM($String)
    
    if ($String -match "^.*\d$")
    {
        
        $String.Substring(($String.ToCharArray().count)-1)
    }
    else {Write-Verbose -Message "The following string does not finish by a digit: $String"}
}