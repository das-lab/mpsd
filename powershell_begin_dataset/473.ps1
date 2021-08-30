

function Start-PPScript{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name,
		
		[Parameter(Mandatory=$false)]
		[String]
		$Arguments
	)
  
    
    
    
    
    $ScriptShortcut = Get-PPScript -Name $Name -Shortcut
    
    $(if( -not $ScriptShortcut){
    
        Get-PPScript -Name $Name | select -First 1
        
    }else{
    
        Get-PPScript -Name $ScriptShortcut.Filename
    
    }) | %{            

        iex "& `"$($_.Fullname)`" $(if($Arguments){$Arguments})"
    }
}