


Describe 'Native UNIX globbing tests' -tags "CI" {

    BeforeAll {
        if (-Not $IsWindows )
        {
            "" > "$TESTDRIVE/abc.txt"
            "" > "$TESTDRIVE/bbb.txt"
            "" > "$TESTDRIVE/cbb.txt"
        }

        $defaultParamValues = $PSDefaultParameterValues.Clone()
        $PSDefaultParameterValues["it:skip"] = $IsWindows
    }

    AfterAll {
        $global:PSDefaultParameterValues = $defaultParamValues
    }

    
    It 'The globbing pattern *.txt should match 3 files' {
        (/bin/ls $TESTDRIVE/*.txt).Length | Should -Be 3
    }
    It 'The globbing pattern *b.txt should match 2 files whose basenames end in "b"' {
        (/bin/ls $TESTDRIVE/*b.txt).Length | Should -Be 2
    }
    
    It 'The globbing pattern should match 2 files whose names start with either "a" or "b"' {
        (/bin/ls $TESTDRIVE/[ab]*.txt).Length | Should -Be 2
    }
    It 'Globbing abc.* should return one file name "abc.txt"' {
        /bin/ls $TESTDRIVE/abc.* | Should -Match "abc.txt"
    }
    
    It 'Globbing [cde]b?.* should return one file name "cbb.txt"' {
        /bin/ls $TESTDRIVE/[cde]b?.* | Should -Match "cbb.txt"
    }
	
	It 'Globbing should work with unquoted expressions' {
	    $v = "$TESTDRIVE/abc*"
		/bin/ls $v | Should -Match "abc.txt"

		$h = [pscustomobject]@{P=$v}
		/bin/ls $h.P | Should -Match "abc.txt"

		$a = $v,$v
		/bin/ls $a[1] | Should -Match "abc.txt"
    }
    
    It 'Should not normalize absolute paths' {
        $matches = /bin/echo /etc/*
        
        $matches.substring(0,5) | Should Be '/etc/'
    }
	It 'Globbing should not happen with quoted expressions' {
	    $v = "$TESTDRIVE/abc*"
		/bin/echo "$v" | Should -BeExactly $v
		/bin/echo '$v' | Should -BeExactly '$v'
	}
    It 'Should return the original pattern (<arg>) if there are no matches' -TestCases @(
        @{arg = '/nOSuCH*file'},               
        @{arg = '/bin/nOSuCHdir/*'},           
        @{arg = '-NosUch*fIle'},               
        @{arg = '-nOsuCh*drive:nosUch*fIle'},  
        @{arg = '-nOs[u]ChdrIve:nosUch*fIle'}, 
        @{arg = '-nOsuChdRive:nosUch*fIle'},   
        @{arg = '-nOsuChdRive: nosUch*fIle'},  
        @{arg = '/no[suchFilE'},               
        @{arg = '[]'}                          
    ) {
        param($arg)
        /bin/echo $arg | Should -BeExactly $arg
    }
    $quoteTests = @(
        @{arg = '"*"'},
        @{arg = "'*'"}
    )
    It 'Should not expand quoted strings: <arg>' -TestCases $quoteTests {
        param($arg)
        Invoke-Expression "/bin/echo $arg" | Should -BeExactly '*'
    }
	
	
	
	
    It 'Should not expand quoted strings via splat array: <arg>' -TestCases $quoteTests -Skip {
        param($arg)

        function Invoke-Echo
        {
            /bin/echo @args
        }
        Invoke-Expression "Invoke-Echo $arg" | Should -BeExactly '*'
    }
    It 'Should not expand quoted strings via splat hash: <arg>' -TestCases $quoteTests -Skip {
        param($arg)

        function Invoke-Echo($quotedArg)
        {
            /bin/echo @PSBoundParameters
        }
        Invoke-Expression "Invoke-Echo -quotedArg:$arg" | Should -BeExactly "-quotedArg:*"

        
        
        
        Invoke-Expression "Invoke-Echo -quotedArg: $arg" | Should -BeExactly "-quotedArg:*"
    }
    
    It 'Should not expand patterns on non-filesystem drives' {
        /bin/echo env:ps* | Should -BeExactly "env:ps*"
    }
    
    It 'Globbing filenames with spaces should match 2 files' {
        "" > "$TESTDRIVE/foo bar.txt"
        "" > "$TESTDRIVE/foo baz.txt"
        (/bin/ls $TESTDRIVE/foo*.txt).Length | Should -Be 2
    }
    
    It 'Tilde should be replaced by the filesystem provider home directory' {
        /bin/echo ~ | Should -BeExactly ($executioncontext.SessionState.Provider.Get("FileSystem").Home)
    }
    
    It '~/foo should be replaced by the <filesystem provider home directory>/foo' {
        /bin/echo ~/foo | Should -BeExactly "$($executioncontext.SessionState.Provider.Get("FileSystem").Home)/foo"
    }
	It '~ should not be replaced when quoted' {
		/bin/echo '~' | Should -BeExactly '~'
		/bin/echo "~" | Should -BeExactly '~'
		/bin/echo '~/foo' | Should -BeExactly '~/foo'
		/bin/echo "~/foo" | Should -BeExactly '~/foo'
	}
}
