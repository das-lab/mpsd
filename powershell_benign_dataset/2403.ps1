param (
    [Parameter(Mandatory)]
    [string[]]$Client,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$InstallerFilePath
)

foreach ($c in $Client) {
    try {
        
        $clientMsg = "The client [$($c)] "
        if (-not (Test-Connection -ComputerName $c -Quiet -Count 1)) {
            throw "$clientMsg cannot be pinged"
        } elseif (-not (Test-Path "\\$c\c$")) {
            throw "$clientMsg 's admin share is unavailable"
        } else {
            Write-Verbose -Message "$clientMsg is ready to go!"
        }

        
        Write-Verbose -Message "Copying installer to client..."
        Copy-Item -Path $InstallerFilePath -Destination "\\$c\c$"

        
        Write-Verbose -Message "Installing software on client..."
        Invoke-Command -ComputerName $c -ScriptBlock {
            $installerFileName = $using:InstallerFilePath | Split-Path -Leaf

            
            Start-Process -NoNewWindow -Wait -FilePath "C:\$installerFileName" -ArgumentList '/silent /norestart'
            
            
            Remove-Item -Path "C:\$installerFileName" -Recurse
         }
    } catch {
        Write-Error -Message $_.Exception.Message
    }
}