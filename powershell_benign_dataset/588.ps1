

function Connect-VSphere{



	param (
        [parameter(Mandatory=$true)]
        [string[]]$Name
	)
    
    
    
    
    if((Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $Null){Add-PSSnapin VMware.VimAutomation.Core}
    if((Get-PSSnapin VMware.VimAutomation.Vds -ErrorAction SilentlyContinue) -eq $Null){Add-PSSnapin VMware.VimAutomation.Vds}

    
    
    
    
    
	$Servers = Get-RemoteConnection -Name $Name

    $Servers | %{
		
        Connect-VIServer $_.Name
        
    }
}