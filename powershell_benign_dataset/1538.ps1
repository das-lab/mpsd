
function New-MrFunction {



    [CmdletBinding()]
    [OutputType('System.IO.FileInfo')]
    param (
        [ValidateScript({
          If ((Get-Verb -Verb ($_ -replace '-.*$')).Verb) {
            $true
          }
          else {
            Throw "'$_' does NOT use an approved Verb."
          }
        })]
        [string]$Name,

        [ValidateScript({
          If (Test-Path -Path $_ -PathType Container) {
            $true
          }
          else {
            Throw "'$_' is not a valid directory."
          }
        })]
        [string]$Path
    )

    $FunctionPath = Join-Path -Path $Path -ChildPath "$Name.ps1"

    if (-not(Test-Path -Path $FunctionPath)) {
    
        New-Fixture -Path $Path -Name $Name
        Set-Content -Path $FunctionPath -Force -Value "
function $($Name) {



    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param (
        [Parameter(Mandatory, 
                   ValueFromPipeline)]
        [string[]]`$Param1,

        [ValidateNotNullOrEmpty()]
        [string]`$Param2
    )

    BEGIN {
        
    }

    PROCESS {
        

        foreach (`$Param in `$Param1) {
            
        }
    }

    END {
        
    }

}"
    
    }
    else {
        Write-Error -Message 'Unable to create function. Specified file already exists!'
    }    

}