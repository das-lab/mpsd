function Get-AssemblyResources
{


    Param (
        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyPath', ValueFromPipeline = $True)]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [String]
        $AssemblyPath,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyByteArray')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $AssemblyBytes,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyInfo', ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Reflection.Assembly]
        $AssemblyInfo
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        'AssemblyPath' {
            $FullPath = Resolve-Path $AssemblyPath
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($FullPath.Path)
        }

        'AssemblyByteArray' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyBytes)
        }

        'AssemblyInfo' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyInfo.GetModules()[0])
        }
    }

    foreach ($Resource in $Module.Resources)
    {
        $Type = $Resource.ResourceType.ToString()

        switch ($Type)
        {
            'Embedded' {
                $Properties = @{
                    Type = $Type
                    Name = $Resource.Name
                    Data = $Resource.GetResourceData()
                }
            }

            'Linked' {
                $Properties = @{
                    Type = $Type
                    Name = $Resource.Name
                    Data = $null
                }
            }

            'AssemblyLinked' {
                $Properties = @{
                    Type = $Type
                    Name = $Resource.Assembly.FullName
                    Data = $null
                }
            }
        }

        New-Object PSObject -Property $Properties
    }
}

function Get-AssemblyStrings
{


    Param (
        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyPath', ValueFromPipeline = $True)]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [String]
        $AssemblyPath,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyByteArray')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $AssemblyBytes,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyInfo', ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Reflection.Assembly]
        $AssemblyInfo,

        [ValidateSet('Strings', 'US', 'All')]
        [String]
        $HeapType = 'All',

        [Switch]
        $Raw
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        'AssemblyPath' {
            $FullPath = Resolve-Path $AssemblyPath
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($FullPath.Path)
        }

        'AssemblyByteArray' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyBytes)
        }

        'AssemblyInfo' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyInfo.GetModules()[0])
        }
    }

    $StringType = 0x70000000
    $StringsHeapName = $Module.StringsStream.Name
    $USHeapName = $Module.USStream.Name

    if (($HeapType -eq 'US') -or ($HeapType -eq 'All'))
    {
        $Stream = $Module.USStream.GetClonedImageStream()

        if ($Stream.Length -gt 3)
        {
            $Bytes = New-Object Byte[]($Stream.Length)
            $null = $Stream.Read($Bytes, 0, $Bytes.Length)

            $CurrentOffset = 1

            do
            {
                $MetadataToken = $CurrentOffset -bor $StringType
                $StringLength = $Bytes[$CurrentOffset]

                
                if (($StringLength -band 0xC0) -eq 0xC0)
                {
                    $LengthBytes = $Bytes[$CurrentOffset..($CurrentOffset+3)]
                    [Array]::Reverse($LengthBytes)
                    $LengthTemp = [BitConverter]::ToInt32($LengthBytes, 0)
                    $StringLength = $LengthTemp -band 0x3FFFFFFF
                    $CurrentOffset += 3
                } 
                elseif (($StringLength -band 0x80) -eq 0x80)
                {
                    $LengthBytes = $Bytes[$CurrentOffset..($CurrentOffset+1)]
                    [Array]::Reverse($LengthBytes)
                    $LengthTemp = [BitConverter]::ToInt16($LengthBytes, 0)
                    $StringLength = $LengthTemp -band 0x7FFF
                    $CurrentOffset += 1
                }

                $CurrentOffset++

                $Encoder = New-Object Text.UnicodeEncoding
                $String = $Encoder.GetString($Bytes, $CurrentOffset, $StringLength - 1)

                if ($Raw)
                {
                    $String
                }
                else
                {
                    $Properties = @{
                        MetadataToken = "0x$($MetadataToken.ToString('X8'))"
                        String = $String
                        Heap = $USHeapName
                    }

                    New-Object PSObject -Property $Properties
                }

                $CurrentOffset = $CurrentOffset + $StringLength
            } while ($CurrentOffset -lt $Bytes.Length - 3)
        }
    }

    if (($HeapType -eq 'Strings') -or ($HeapType -eq 'All'))
    {
        $StreamLength = $Module.StringsStream.ImageStreamLength

        $CurrentPosition = 0

        while ($CurrentPosition -lt $StreamLength)
        {
            $StringInfo = $Module.StringsStream.Read($CurrentPosition)

            if ($StringInfo.Length -eq 0)
            {
                $CurrentPosition++
            }
            else
            {
                $String = $StringInfo.String
                $CurrentPosition += $StringInfo.Length

                if ($Raw)
                {
                    $String
                }
                else
                {
                    $Properties = @{
                        MetadataToken = ''
                        String = $String
                        Heap = $StringsHeapName
                    }

                    New-Object PSObject -Property $Properties
                }
            }
        }
    }
}

function Get-AssemblyImplementedMethods {


    [OutputType([dnlib.DotNet.MethodDef])]
    [CMdletBinding()]
    Param (
        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyPath', ValueFromPipeline = $True)]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [String]
        $AssemblyPath,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyByteArray')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $AssemblyBytes,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyInfo', ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Reflection.Assembly]
        $AssemblyInfo
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        'AssemblyPath' {
            $FullPath = Resolve-Path $AssemblyPath
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($FullPath.Path)
        }

        'AssemblyByteArray' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyBytes)
        }

        'AssemblyInfo' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyInfo.GetModules()[0])
        }
    }

    $ImplementedMethods = New-Object 'Collections.Generic.List`1[dnlib.DotNet.MethodDef]'

    foreach ($Type in $Module.GetTypes()) {
        if ($Type.HasMethods) {
            foreach ($Method in $Type.Methods) {
                if ($Method.HasBody -and $Method.MethodBody.Instructions.Count) {
                    $ImplementedMethods.Add($Method)
                }
            }
        }  
    }

    return $ImplementedMethods
}

function Remove-AssemblySuppressIldasmAttribute
{


    [CmdletBinding()] Param (
        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyPath', ValueFromPipeline = $True)]
        [ValidateScript({Test-Path $_})]
        [Alias('Path')]
        [String]
        $AssemblyPath,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyByteArray')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $AssemblyBytes,

        [Parameter(Mandatory = $True,  ParameterSetName = 'AssemblyInfo', ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [Reflection.Assembly]
        $AssemblyInfo,

        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath
    )

    switch ($PsCmdlet.ParameterSetName)
    {
        'AssemblyPath' {
            $FullPath = Resolve-Path $AssemblyPath
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($FullPath.Path)
        }

        'AssemblyByteArray' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyBytes)
        }

        'AssemblyInfo' {
            $Module = [dnlib.DotNet.ModuleDefMD]::Load($AssemblyInfo.GetModules()[0])
        }
    }

    $Path = Split-Path $FilePath
    $FileName = Split-Path -Leaf $FilePath

    if (($Path -eq '') -or ($Path -eq '.')) {
        $Path = $PWD
    } else {
        $Path = Resolve-Path $Path -ErrorAction Stop
    }

    $FullPath = Join-Path $Path $FileName

    $Assembly = $Module.Assembly

    $CustomAttributes = $Assembly.CustomAttributes

    $AttributeFound = $False

    for ($i = 0; $i -lt $CustomAttributes.Count; $i++) {
        $AttributeName = $CustomAttributes[$i].TypeFullName

        if ($AttributeName -eq 'System.Runtime.CompilerServices.SuppressIldasmAttribute') {
            Write-Verbose 'Found SuppressIldasmAttribute attribute.'

            $CustomAttributes.RemoveAt($i)
            $Assembly.Write($FullPath)
            Get-ChildItem $FullPath

            $AttributeFound = $True
        }
    }

    if (!$AttributeFound) {
        Write-Verbose 'No SuppressIldasmAttribute is present.'
    }
}