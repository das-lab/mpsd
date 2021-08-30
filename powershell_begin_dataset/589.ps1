

function Connect-PSS{

	param (
        [parameter(Mandatory=$true)]
		[string[]]$Name,
        
        [parameter(Mandatory=$false)]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
	)
	
	
	
	
        
    
	$Servers = Get-RemoteConnection -Name $Name
	
	foreach($Server in $Servers){
		
		
		Remove-PSSession -ComputerName $Server.Name -ErrorAction SilentlyContinue
		
		
        if($Credential.UserName -eq $null){
            $Credential = Get-Credential $Server.User
        }		

		
		$s = New-PSSession -Name $Server.Name  -ComputerName $Server.Name -Credential $Credential

		
		if ($Server.SnapIns -ne ""){
            foreach($SnapIn in $Server.SnapIns){
			    Invoke-Command -Session $s -ScriptBlock {param ($Name) Add-PSSnapin -Name $Name} -ArgumentList $SnapIn
            }
		}

        $Sessions += $s
	}
    $Sessions	
}

