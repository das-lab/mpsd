

function Get-FileEncoding{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $Path
        
	)
  
    [byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path

    if($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf){ 
        Write-Output 'UTF8'
    }elseif($byte[0] -eq 0xfe -and $byte[1] -eq 0xff){
        Write-Output 'Unicode'
    }elseif($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff){
        Write-Output 'UTF32'
    }elseif($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76){
        Write-Output 'UTF7'
    }else{
        Write-Output 'ASCII'
    }
}