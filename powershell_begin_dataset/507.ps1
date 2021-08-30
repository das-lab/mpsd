

function Write-PPErrorEventLog{



	param(        
        [Parameter(Mandatory=$false)]
		[string]$Message,
        
        [Parameter(Mandatory=$false)]
		[string]$Source,
		
		[switch]
		$ClearErrorVariable  
	)
	
	
	
	
    if($Error){
        $Error | %{$ErrorLog += "$($_.ToString()) $($_.InvocationInfo.PositionMessage) `n`n"}
        
        if($Message){$ErrorLog = "$Message `n`n" + $ErrorLog}
        
        if($ClearErrorVariable){$Error.clear()}
        
        Write-PPEventLog -Message $ErrorLog -Source $Source -EntryType Error -WriteMessage
    }
}