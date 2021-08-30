

function Get-File{



    [CmdletBinding()]
    param(

		[Parameter( Mandatory=$true)]
		[String]
		$Url,

		[Parameter( Mandatory=$false)]
		[String]
		$Path,
        
        [Switch]
        $Force
	)
    
    
    
    
 
    begin {
    
        $WebClient = New-Object System.Net.WebClient
        $Global:DownloadComplete = $false
     
        $eventDataComplete = Register-ObjectEvent $WebClient DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -Action {$Global:DownloadComplete = $true}
            
        $eventDataProgress = Register-ObjectEvent $WebClient DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -Action { $Global:DPCEventArgs = $EventArgs }    
    } 
       
    process{
    
        $PathAndFilename = Get-PathAndFilename $Path
    
        if(-not $PathAndFilename.Filename){$PathAndFilename.Filename = (Split-Path ([uri]$Url).LocalPath -Leaf)}
        if(-not $PathAndFilename.Path){$PathAndFilename.Path = (Get-Location).Path}
        if(-not (Test-Path $PathAndFilename.Path)){New-Item -Path $PathAndFilename.Path -ItemType Directory}
        $Path = Join-Path $PathAndFilename.Path ($PathAndFilename.Filename)
        
        Write-Progress -Activity "Downloading file" -Status $Url
        
        $WebClient.DownloadFileAsync($Url, $Path)
       
        while (!($Global:DownloadComplete)) {                
            $ProgressPercentage = $Global:DPCEventArgs.ProgressPercentage
            if ($ProgressPercentage -ne $null) {
                Write-Progress -Activity "Downloading file" -Status $Url -PercentComplete $ProgressPercentage
            }
        }
       
        Write-Progress -Activity "Downloading file" -Status $Url -Complete
        
        $PathAndFilename
    }   
      
    end{
    
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        $WebClient.Dispose()
        $Global:DownloadComplete = $null
        $Global:DPCEventArgs = $null
        Remove-Variable WebClient
        Remove-Variable eventDataComplete
        Remove-Variable eventDataProgress
        [GC]::Collect()    
    }  
}  