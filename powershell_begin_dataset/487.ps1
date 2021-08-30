

function Get-Path {



	param(
		[Parameter(Mandatory=$true)]
        [string]
		$Path
	)
    	
	
	
	
    
    
    $Path = [System.Environment]::ExpandEnvironmentVariables($Path)
    
    
    if($Path.contains("$")){
        $Path = Invoke-Expression "`"$Path`""
    }
    
    
    if($Path.StartsWith("\")){$Path = Join-Path -Path $(Get-Location).Path -Childpath $Path}
    
    
    $Path = Resolve-Path $Path -ErrorAction SilentlyContinue -ErrorVariable _frperror
    if(-not($Path)) {
        $Path = $_frperror[0].TargetObject
    }
    
    
    $Path
}