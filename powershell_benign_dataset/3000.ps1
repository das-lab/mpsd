function Set-ItResult {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Inconclusive")][switch]$Inconclusive,
        [Parameter(Mandatory = $false, ParameterSetName = "Pending")][switch]$Pending,
        [Parameter(Mandatory = $false, ParameterSetName = "Skipped")][switch]$Skipped,
        [string]$Because
    )

    Assert-DescribeInProgress -CommandName Set-ItResult

    $result = $PSCmdlet.ParameterSetName
    $message = "It result set to $result$(if ($Because) { ", $Because" })"
    $data = @{
        Result  = $result
        Because = $Because
    }
    $errorRecord = New-PesterErrorRecord -Result $result  -Message $message -Data $data
    throw $errorRecord
}

function New-PesterErrorRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Result,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$File,
        [string]$Line,
        [string]$LineText,
        [hashtable]$Data
    )

    $exception = New-Object Exception $Message
    $errorID = "PesterTest$Result"
    $errorCategory = [Management.Automation.ErrorCategory]::InvalidResult

    
    $targetObject = @{
        Message  = $Message
        Data     = $Data
        File     = $(if ($File -ne $null) {
                $File
            }
            else {
                $MyInvocation.ScriptName
            })
        Line     = $(if ($Line -ne $null) {
                $Line
            }
            else {
                $MyInvocation.ScriptLineNumber
            })
        LineText = $(if ($LineText -ne $null) {
                $LineText
            }
            else {
                $MyInvocation.Line
            }).TrimEnd($([System.Environment]::NewLine))
    }

    New-Object Management.Automation.ErrorRecord $exception, $errorID, $errorCategory, $targetObject
}
