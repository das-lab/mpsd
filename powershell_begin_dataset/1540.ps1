function Expand-MrZipFile {



    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)]
        [ValidateScript({
            If ((Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.zip")) {
                $true
            }
            else {
                Throw "$_ is not a valid zip file. Enter in 'c:\folder\file.zip' format"
            }
        })]
        [string]$File,

        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If (Test-Path -Path $_ -PathType Container) {
                $true
            }
            else {
                Throw "$_ is not a valid destination folder. Enter in 'c:\destination' format"
            }
        })]
        [string]$Destination = (Get-Location).Path,

        [switch]$ForceCOM
    )
    
    If (-not $ForceCOM -and ($PSVersionTable.PSVersion.Major -ge 3) -and
       ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or
       (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) {

        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using .NET 4.5"

        try {
            [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$File", "$Destination")
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }
        
    }
    else {

        Write-Verbose -Message "Attempting to Unzip $File to location $Destination using COM"

        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.Namespace($destination).copyhere(($shell.NameSpace($file)).items())
        }
        catch {
            Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
        }

    }

}