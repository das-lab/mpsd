

function Get-PathAndFilename{



    [CmdletBinding()]
    param(

		[Parameter( Mandatory=$true)]
		[String]
		$Path
	)

    
    $Path = [System.Environment]::ExpandEnvironmentVariables($Path)
    
    
    if($Path.contains("$")){
        $Path = Invoke-Expression "`"$Path`""
    }

    
    if($Path.StartsWith("\")){
        $Path = Join-Path -Path $(Get-Location).Path -Childpath $Path
    }
    
    
    if(-not $Path.Contains("\")){
    
        $Filename = $Path
        $Path = $null
    
    }else{
    
        
        $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $Path = $ResolvedPath + $(if($Path.EndsWith("\") -and -not $ResolvedPath.EndsWith("\")){"\"})

        
        if($Path.EndsWith("\")){
        
            $Filename = $null
        
        }else{
            
            $Filename = Split-Path $Path -Leaf
            $Path = Split-Path $Path -Parent         
        }
    }
    
    @{
        Path = $Path
        Filename = $FileName    
    }
}