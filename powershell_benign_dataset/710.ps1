


function New-RsRestCredentialsByUserObject
{
    
    [CmdletBinding()]
    param(
        [Alias('DisplayText')]
        [string]
        $PromptMessage,

        [Alias('UseAsWindowsCredentials')]
        [switch]
        $WindowsCredentials
    )
    Process
    {
        return @{
            "DisplayText" = $PromptMessage;
            "UseAsWindowsCredentials" = $WindowsCredentials -eq $true;
        }
    }
}