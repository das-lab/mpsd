
function Add-CTrustedHost
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
		[Alias("Entries")]
        
        $Entry
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $trustedHosts = @( Get-CTrustedHost )
    $newEntries = @()
    
	$Entry | ForEach-Object {
		if( $trustedHosts -notcontains $_ )
		{
            $trustedHosts += $_ 
            $newEntries += $_
		}
	}
    
    if( $pscmdlet.ShouldProcess( "trusted hosts", "adding $( ($newEntries -join ',') )" ) )
    {
        Set-CTrustedHost -Entry $trustedHosts
    }
}

Set-Alias -Name 'Add-TrustedHosts' -Value 'Add-CTrustedHost'
