

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$LogName
)

Get-WinEvent -LogName $LogName