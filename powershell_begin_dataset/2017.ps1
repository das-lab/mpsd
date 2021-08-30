

function Test-ResourceStrings
{
    param ( $AssemblyName, $ExcludeList )

    
    
    $repoBase = (Resolve-Path (Join-Path $psScriptRoot ../../../..)).Path
    $asmBase = Join-Path $repoBase "src/$AssemblyName"
    $resourceDir = Join-Path $asmBase resources
    $resourceFiles = Get-ChildItem $resourceDir -Filter *.resx -ErrorAction stop |
        Where-Object { $excludeList -notcontains $_.Name }

    $bindingFlags = [reflection.bindingflags]"NonPublic,Static"

    
    
    
    $ASSEMBLY = [appdomain]::CurrentDomain.GetAssemblies()|
        Where-Object { $_.FullName -match "$AssemblyName" }

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    Describe "Resources strings in $AssemblyName (was -ResGen used with Start-PSBuild)" -tag Feature {

        function NormalizeLineEnd
        {
            param (
                [string] $string
            )

            $string -replace "`r`n", "`n"
        }

        foreach ( $resourceFile in $resourceFiles )
        {
            
            $classname = $resourcefile.Name -replace ".resx"
            It "'$classname' should be an available type and the strings should be correct" -Skip:(!$IsWindows) {
                
                $resourceType = $ASSEMBLY.GetType($classname, $false, $true)
                
                
                $resourceType | Should -Not -BeNullOrEmpty

                
                $xmlData = [xml](Get-Content $resourceFile.Fullname)
                foreach ( $inResource in $xmlData.root.data ) {
                    $resourceStringToCheck = $resourceType.GetProperty($inResource.name,$bindingFlags).GetValue(0)
                    NormalizeLineEnd($resourceStringToCheck) | Should -Be (NormalizeLineEnd($inresource.value))
                }
            }
        }
    }
}
