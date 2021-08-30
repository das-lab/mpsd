function Get-ScriptCommentHelpInfoString
{
    [CmdletBinding(PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Synopsis,

        [Parameter()]
        [string[]]
        $Example,

        [Parameter()]
        [string[]]
        $Inputs,

        [Parameter()]
        [string[]]
        $Outputs,

        [Parameter()]
        [string[]]
        $Notes,

        [Parameter()]
        [string[]]
        $Link,

        [Parameter()]
        [string]
        $Component,

        [Parameter()]
        [string]
        $Role,

        [Parameter()]
        [string]
        $Functionality
    )

    Process
    {
        $ScriptCommentHelpInfoString = " `r`n"

        return $ScriptCommentHelpInfoString
    }
}