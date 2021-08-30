filter Get-ILDisassembly {


    Param (
        [Parameter(Mandatory = $True, ParameterSetName = 'AssemblyPath')]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [String]
        $AssemblyPath,

        [Parameter(Mandatory = $True, ParameterSetName = 'AssemblyPath')]
        [ValidateScript({($_ -band 0x06000000) -eq 0x06000000})]
        [Int32]
        $MetadataToken,

        [Parameter(Mandatory = $True, ParameterSetName = 'MethodInfo', ValueFromPipeline = $True)]
        [Reflection.MethodBase]
        $MethodInfo,

        [Parameter(Mandatory = $True, ParameterSetName = 'MethodDef', ValueFromPipeline = $True)]
        [dnlib.DotNet.MethodDef]
        $MethodDef
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        'AssemblyPath' {
            $FullPath = Resolve-Path $AssemblyPath
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($FullPath.Path)
            $Method = $Module.ResolveMethod(($MetadataToken -band 0xFFFFFF))
        }

        'MethodInfo' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($MethodInfo.Module)
            $Method = $Module.ResolveMethod(($MethodInfo.MetadataToken -band 0xFFFFFF))
        }

        'MethodDef' {
            $Method = $MethodDef
        }
    }

    if ($Method.HasBody) {
        $Result = @{
            Name = $Method.Name.String
            MetadataToken = "0x$($Method.MDToken.Raw.ToString('X8'))"
            Signature = $Method.ToString()
            Instructions = $Method.MethodBody.Instructions
        }

        $Disasm = New-Object PSObject -Property $Result
        $Disasm.PSObject.TypeNames.Insert(0, 'IL_METAINFO')

        return $Disasm
    } else {
        Write-Warning "Method is not implemented. Name: $($Method.Name.String), MetadataToken: 0x$($Method.MDToken.Raw.ToString('X8'))"
    }
}