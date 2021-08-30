function Get-CSDisassembly
{


    [OutputType([Capstone.Instruction])]
    [CmdletBinding(DefaultParameterSetName = 'Disassemble')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'Disassemble')]
        [Capstone.Architecture]
        $Architecture,

        [Parameter(Mandatory, ParameterSetName = 'Disassemble')]
        [Capstone.Mode]
        $Mode,

        [Parameter(Mandatory, ParameterSetName = 'Disassemble')]
        [ValidateNotNullOrEmpty()]
        [Byte[]]
        $Code,

        [Parameter( ParameterSetName = 'Disassemble' )]
        [UInt64]
        $Offset = 0,

        [Parameter( ParameterSetName = 'Disassemble' )]
        [UInt32]
        $Count = 0,

        [Parameter( ParameterSetName = 'Disassemble' )]
        [ValidateSet('Intel', 'ATT')]
        [String]
        $Syntax,

        [Parameter( ParameterSetName = 'Disassemble' )]
        [Switch]
        $DetailOn,

        [Parameter( ParameterSetName = 'Version' )]
        [Switch]
        $Version
    )

    if ($PsCmdlet.ParameterSetName -eq 'Version')
    {
        $Disassembly = New-Object Capstone.Capstone([Capstone.Architecture]::X86, [Capstone.Mode]::Mode16)
        $Disassembly.Version

        return
    }

    $Disassembly = New-Object Capstone.Capstone($Architecture, $Mode)

    if ($Disassembly.Version -ne [Capstone.Capstone]::BindingVersion)
    {
        Write-Error "capstone.dll version ($([Capstone.Capstone]::BindingVersion.ToString())) should be the same as libcapstone.dll version. Otherwise, undefined behavior is likely."
    }

    if ($Syntax)
    {
        switch ($Syntax)
        {
            'Intel' { $SyntaxMode = [Capstone.OptionValue]::SyntaxIntel }
            'ATT'   { $SyntaxMode = [Capstone.OptionValue]::SyntaxATT }
        }

        $Disassembly.SetSyntax($SyntaxMode)
    }

    if ($DetailOn)
    {
        $Disassembly.SetDetail($True)
    }

    $Disassembly.Disassemble($Code, $Offset, $Count)
}