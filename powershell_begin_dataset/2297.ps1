
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$FolderPath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$CompanyReference
)

$defaultCommandNames = (Get-Command -Module 'Microsoft.PowerShell.*','Pester' -All).Name
$defaultModules = (Get-Module -Name 'Microsoft.PowerShell.*','Pester').Name

if ($scripts = Get-ChildItem -Path $FolderPath -Recurse -Filter '*.ps*' | Sort-Object Name) {
    $scripts | foreach({
        $script = $_.FullName
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script,[ref]$null,[ref]$null)
        $commandRefs = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]},$true)
        if ($testRefs = (Select-String -path $script -Pattern "mock [`"|'](.*)[`"|']").Matches) {
            $commandRefsInTest = $testRefs | foreach {
                $_.Groups[1].Value
            }
        }

        $script:commandRefNames += (@($commandRefs).foreach({ [string]$_.CommandElements[0] }) | Select-Object -Unique) + $commandRefsInTest
        $script:commandDeclarationNames += $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) | Select-Object -ExpandProperty Name
        
        describe "[$($script)] Test" {

            if ($CompanyReference) {
                $companyRefRegex = ('({0})' -f ($CompanyReference -join '|'))
                if ($companyReferences = [regex]::Matches((Get-Content $script -Raw),$companyRefRegex).Groups) {
                    $companyReferences = $companyReferences.Groups[1].Value
                }
            }

            $properties = @(
                @{
                    Name = 'Command'
                    Expression = { $alias = Get-Alias -Name $_ -ErrorAction Ignore
                        if ($alias) {
                            $alias.ResolvedCommandName
                        } else {
                            $_
                        }
                    }
                }
            )

            $privateCommandNames = $script:commandRefNames | Select-Object -Property $properties | Where {
                $_.Command -notin $defaultCommandNames -and 
                $_.Command -notin $commandDeclarationNames -and
                $_.Command -match '^\w' -and
                $_.Command -notmatch 'powershell_ise\.exe'
            } | Select-Object -ExpandProperty Command

            if ($privateModuleNames = (Select-String -Path $script -Pattern "($($defaultModules -join '|'))" -NotMatch).Matches) {
                $privateModuleNames = $privateModuleNames.Group[1].Value
            }
            
            it 'has no references to our company-specific strings' {
                $companyReferences | should benullOrempty
            }

            it 'has no references to private functions' {
                $privateCommandNames | should be $null
            }

            it 'has no references to private modules' {
                $privateModuleNames | should benullOrempty
            }
        }
    })
}