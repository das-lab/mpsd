

function Uninstall-PPApp{



	param(
        [Parameter(Mandatory=$true)]
		[String[]]
		$Name,
                
        [switch]
        $Force,
        
        [switch]
        $IgnoreDependencies
	)
    
    Install-PPApp -Name $Name -Force:$Force -IgnoreDependencies:$IgnoreDependencies -Uninstall
}