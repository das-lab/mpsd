



$originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
$originalWarningPreference = $WarningPreference
$WarningPreference = "SilentlyContinue"
$skipTest = ! ($IsWindows -and $IsCoreCLR -and (Test-IsElevated))
$PSDefaultParameterValues["it:skip"] = $skipTest

try
{
    Describe "Implicit remoting and CIM cmdlets with AllSigned and Restricted policy" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {

            if ($skipTest) { return }

            
            
            

            $tempName = "TESTDRIVE:\signedscript_$(Get-Random).ps1"
            "123456" > $tempName
            $cert = $null
            foreach ($thisCertificate in (Get-ChildItem cert:\ -rec -codesigning))
            {
	            $null = Set-AuthenticodeSignature $tempName -Certificate $thisCertificate
	            if ((Get-AuthenticodeSignature $tempName).Status -eq "Valid")
	            {
		            $cert = $thisCertificate
		            break
	            }
            }

            
            
            if ($null -eq $cert)
            {
                $skipThisTest = $true
                return
            }
            $skipThisTest = $false

            
            if (-not (Test-Path "cert:\currentuser\TrustedPublisher\$($cert.Thumbprint)"))
            {
                $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "TrustedPublisher"
                $store.Open("ReadWrite")
                $store.Add($cert)
                $store.Close()
            }

            
            
            

            $session = New-RemoteSession

            
            
            

            $oldExecutionPolicy = Get-ExecutionPolicy -Scope Process
            Set-ExecutionPolicy AllSigned -Scope Process
        }

        AfterAll {
            if ($skipTest) { return }

            if ($null -ne $tempName) { Remove-Item -Path $tempName -Force -ErrorAction SilentlyContinue }
            if ($null -ne $oldExecutionPolicy) { Set-ExecutionPolicy $oldExecutionPolicy -Scope Process }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        
        
        

        It "Verifies that Import-PSSession works in AllSigned if Certificate is used" -Skip:($skipTest -or $skipThisTest) {
            try {
                $importedModule = Import-PSSession $session Get-Variable -Prefix Remote -Certificate $cert -AllowClobber
    	        $importedModule | Should -Not -BeNullOrEmpty
            } finally {
                $importedModule | Remove-Module -Force -ErrorAction SilentlyContinue
            }
        }

        It "Verifies security error when Certificate parameter is not used" -Skip:($skipTest -or $skipThisTest) {
            { $importedModule = Import-PSSession $session Get-Variable -Prefix Remote -AllowClobber } | Should -Throw -ErrorId "InvalidOperation,Microsoft.PowerShell.Commands.ImportPSSessionCommand"
        }
    }

    Describe "Tests Import-PSSession cmdlet works with types unavailable on the client" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {

            if ($skipTest) { return }

            $typeDefinition = @"
                namespace MyTest
                {
	                public enum MyEnum
	                {
		                Value1 = 1,
		                Value2 = 2
	                }
                }
"@
            
            
            

            $session = New-RemoteSession

            Invoke-Command -Session $session -Script { Add-Type -TypeDefinition $args[0] } -Args $typeDefinition
            Invoke-Command -Session $session -Script { function foo { param([MyTest.MyEnum][Parameter(Mandatory = $true)]$x) $x } }
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Verifies client-side unavailable enum is correctly handled" {
            try {
                $module = Import-PSSession -Session $session -CommandName foo -AllowClobber

                
                (foo -x "Value2") | Should -Be 2
                
                (foo -x "Value2").ToString() | Should -BeExactly "Value2"
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }
        }
    }

    Describe "Cmdlet help from remote session" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {

            if ($skipTest) { return }
            $session = New-RemoteSession
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Verifies that get-help name for remote proxied commands matches the get-command name" {
            try {
                $module = Import-PSSession $session -Name Select-Object -prefix My -AllowClobber
                $gcmOutPut = (Get-Command Select-MyObject ).Name
                $getHelpOutPut = (Get-Help Select-MyObject).Name

                $gcmOutPut | Should -Be $getHelpOutPut
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }
	}
    }

    Describe "Import-PSSession Cmdlet error handling" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {

            if ($skipTest) { return }
            $session = New-RemoteSession
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Verifies that broken alias results in one error" {
            try {
                Invoke-Command $session { Set-Alias BrokenAlias NonExistantCommand }
                $module = Import-PSSession $session -CommandName:BrokenAlias -CommandType:All -ErrorAction SilentlyContinue -ErrorVariable expectedError -AllowClobber

                $expectedError | Should -Not -BeNullOrEmpty
                $expectedError[0].ToString().Contains("BrokenAlias") | Should -BeTrue
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                Invoke-Command $session { Remove-Item alias:BrokenAlias }
            }
        }

        Context "Test content and format of proxied error message (Windows 7: 

            BeforeAll {
                if ($skipTest) { return }
                $module = Import-PSSession -Session $session -Name Get-Variable -Prefix My -AllowClobber
                $oldErrorView = $ErrorView
                $ErrorView = "NormalView"
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                $ErrorView = $oldErrorView
            }

            It "Test non-terminating error" {
                $results = Get-MyVariable blah,pid 2>&1

                ($results[1]).Value | Should -Not -Be $PID  

                $errorString = $results[0] | Out-String   
                ($errorString -like "*VariableNotFound*") | Should -BeTrue
            }

            It "Test terminating error" {
                $results = Get-MyVariable pid -Scope blah 2>&1

                $results.Count | Should -Be 1              

                $errorString = $results[0] | Out-String   
                ($errorString -like "*Argument*") | Should -BeTrue
            }
        }

        Context "Ordering of a sequence of error and output messages (Windows 7: 

            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command $session { function foo1{1; write-error 2; 3; write-error 4; 5; write-error 6} }
                $module = Import-PSSession $session -CommandName foo1 -AllowClobber

                $icmErr = $($icmOut = Invoke-Command $session { foo1 }) 2>&1
                $proxiedErr = $($proxiedOut = foo1) 2>&1
                $proxiedOut2 = foo1 2> $null

                $icmOut = "$icmOut"
                $icmErr = "$icmErr"
                $proxiedOut = "$proxiedOut"
                $proxiedOut2 = "$proxiedOut2"
                $proxiedErr = "$proxiedErr"
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Verifies proxied output = proxied output 2" {
                $proxiedOut2 | Should -Be $proxiedOut
            }

            It "Verifies proxied output = icm output (for mixed error and output results)" {
                $icmOut | Should -Be $proxiedOut
            }

            It "Verifies proxied error = icm error (for mixed error and output results)" {
                $icmErr | Should -Be $proxiedErr
            }

            It "Verifies proxied order = icm order (for mixed error and output results)" {
                $icmOrder = Invoke-Command $session { foo1 } 2>&1 | out-string
                $proxiedOrder = foo1 2>&1 | out-string

                $icmOrder | Should -Be $proxiedOrder
            }
        }

        Context "WarningVariable parameter works with implicit remoting (Windows 8: 

            BeforeAll {
                if ($skipTest) { return }
                $module = Import-PSSession $session -CommandName Write-Warning -Prefix Remote -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Verifies WarningVariable" {
                $global:myWarningVariable = @()
                Write-RemoteWarning MyWarning -WarningVariable global:myWarningVariable
                ([string]($myWarningVariable[0])) | Should -Be 'MyWarning'
	        }
        }
    }

    Describe "Tests Export-PSSession" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {

            if ($skipTest) { return }

            $sessionOption = New-PSSessionOption -ApplicationArguments @{myTest="MyValue"}
            $session = New-RemoteSession -SessionOption $sessionOption

            $file = [IO.Path]::Combine([IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString())
            $results = Export-PSSession -Session $session -CommandName Get-Variable -AllowClobber -ModuleName $file
            $oldTimestamp = $($results | Select-Object -First 1).LastWriteTime
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $file) { Remove-Item $file -Force -Recurse -ErrorAction SilentlyContinue }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Verifies Export-PSSession creates a file/directory" {
            @(Get-Item $file).Count | Should -Be 1
        }

        It "Verifies Export-PSSession creates a psd1 file" {
            ($results | Where-Object { $_.Name -like "*$(Split-Path -Leaf $file).psd1" }) | Should -BeTrue
        }

        It "Verifies Export-PSSession creates a psm1 file" {
            ($results | Where-Object { $_.Name -like "*.psm1" }) | Should -BeTrue
        }

        It "Verifies Export-PSSession creates a ps1xml file" {
            ($results | Where-Object { $_.Name -like "*.ps1xml" }) | Should -BeTrue
        }

        It "Verifies that Export-PSSession fails when a module directory already exists" {
            $e = { Export-PSSession -Session $session -CommandName Get-Variable -AllowClobber -ModuleName $file -ErrorAction Stop } |
                Should -Throw -PassThru

            $e | Should -Not -BeNullOrEmpty
            
            ([string]($e[0]) -like "*$file*") | Should -BeTrue
        }

        It "Verifies that overwriting an existing directory succeeds with -Force" {
            $newResults = Export-PSSession -Session $session -CommandName Get-Variable -AllowClobber -ModuleName $file -Force

            
            @($newResults).Count | Should -Be 4

            
            $newResults | ForEach-Object { $_.LastWriteTime | Should -BeGreaterThan $oldTimestamp }
        }

        Context "The module is usable when the original runspace is still around" {

            BeforeAll {
                if ($skipTest) { return }
                $module = Import-Module $file -PassThru
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Verifies that proxy returns remote pid" {
                (Get-Variable -Name pid).Value | Should -Not -Be $pid
            }

	        It "Verfies Remove-Module doesn't remove user's runspace" {
                Remove-Module $module -Force -ErrorAction SilentlyContinue
                (Get-PSSession -InstanceId $session.InstanceId) | Should -Not -BeNullOrEmpty
            }
        }
    }

    Describe "Proxy module is usable when the original runspace is no longer around" -tags "Feature","RequireAdminOnWindows" {
        BeforeAll {
            if ($skipTest) { return }

            $sessionOption = New-PSSessionOption -ApplicationArguments @{myTest="MyValue"}
            $session = New-RemoteSession -SessionOption $sessionOption

            $file = [IO.Path]::Combine([IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString())
            $null = Export-PSSession -Session $session -CommandName Get-Variable -AllowClobber -ModuleName $file

            
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue; $session = $null }
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $file) { Remove-Item $file -Force -Recurse -ErrorAction SilentlyContinue }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        
        

        Context "Proxy module should create a new session" {
            BeforeAll {
                if ($skipTest) { return }
                $module = import-Module $file -PassThru -Force
                $internalSession = & $module { $script:PSSession }
            }
            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Verifies proxy should return remote pid" -Pending {
                (Get-Variable -Name PID).Value | Should -Not -Be $PID
            }

            It "Verifies ApplicationArguments got preserved correctly" -Pending {
                $(Invoke-Command $internalSession { $PSSenderInfo.ApplicationArguments.MyTest }) | Should -BeExactly "MyValue"
            }

            It "Verifies Remove-Module removed the runspace that was automatically created" -Pending {
                Remove-Module $module -Force
                (Get-PSSession -InstanceId $internalSession.InstanceId -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
            }

            It "Verifies Runspace is closed after removing module from Export-PSSession that got initialized with an internal r-space" -Pending {
                ($internalSession.Runspace.RunspaceStateInfo.ToString()) | Should -BeExactly "Closed"
            }
        }

        Context "Runspace created by the module with explicit session options" {
            BeforeAll {
                if ($skipTest) { return }
                $explicitSessionOption = New-PSSessionOption -Culture fr-FR -UICulture de-DE
                $module = import-Module $file -PassThru -Force -ArgumentList $null, $explicitSessionOption
                $internalSession = & $module { $script:PSSession }
            }
            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Verifies proxy should return remote pid" -Pending {
                (Get-Variable -Name PID).Value | Should -Not -Be $PID
            }

            
            It "Verifies proxy returns modified culture" -Pending {
                (Get-Variable -Name PSCulture).Value | Should -BeExactly "fr-FR"
            }
            It "Verifies proxy returns modified culture" -Pending {
                (Get-Variable -Name PSUICulture).Value | Should -BeExactly "de-DE"
            }

            
            It "Verifies Remove-Module removes automatically created runspace" -Pending {
                Remove-Module $module -Force
                (Get-PSSession -InstanceId $internalSession.InstanceId -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
            }
            It "Verifies Runspace is closed after removing module from Export-PSSession that got initialized with an internal r-space" -Pending {
                ($internalSession.Runspace.RunspaceStateInfo.ToString()) | Should -BeExactly "Closed"
            }
        }

        Context "Passing a runspace into proxy module" {
            BeforeAll {
                if ($skipTest) { return }

                $newSession = New-RemoteSession
                $module = import-Module $file -PassThru -Force -ArgumentList $newSession
                $internalSession = & $module { $script:PSSession }
            }
            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                if ($null -ne $newSession) { Remove-PSSession $newSession -ErrorAction SilentlyContinue }
            }

            It "Verifies proxy returns remote pid" {
                (Get-Variable -Name PID).Value | Should -Not -Be $PID
            }

            It "Verifies switch parameters work" {
                (Get-Variable -Name PID -ValueOnly) | Should -Not -Be $PID
            }

            It "Verifies Adding a module affects runspace's state" {
                ($internalSession.Runspace.RunspaceStateInfo.ToString()) | Should -BeExactly "Opened"
            }

            It "Verifies Runspace stays opened after removing module from Export-PSSession that got initialized with an external runspace" {
                Remove-Module $module -Force
		        ($internalSession.Runspace.RunspaceStateInfo.ToString()) | Should -BeExactly "Opened"
	        }
        }
    }

    Describe "Import-PSSession with FormatAndTypes" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {
            if ($skipTest) { return }
            
            $samesession = New-RemoteSession -ConfigurationName $endpointName
            $session = New-RemoteSession
            function CreateTempPs1xmlFile
            {
                do {
                    $tmpFile = [IO.Path]::Combine([IO.Path]::GetTempPath(), [IO.Path]::GetRandomFileName()) + ".ps1xml";
                } while ([IO.File]::Exists($tmpFile))
                $tmpFile
            }

            function CreateTypeFile {
                $tmpFile = CreateTempPs1xmlFile
    @"
        <Types>
	        <Type>
		    <Name>System.Management.Automation.Host.Coordinates</Name>
		        <Members>
			        <NoteProperty>
				    <Name>MyTestLabel</Name>
				    <Value>123</Value>
			        </NoteProperty>
		        </Members>
	        </Type>
	        <Type>
		        <Name>MyTest.Root</Name>
		        <Members>
		        <MemberSet>
			    <Name>PSStandardMembers</Name>
			    <Members>
			        <NoteProperty>
				    <Name>SerializationDepth</Name>
				    <Value>1</Value>
			        </NoteProperty>
			    </Members>
		            </MemberSet>
		        </Members>
	        </Type>
	        <Type>
		        <Name>MyTest.Son</Name>
		        <Members>
		        <MemberSet>
			    <Name>PSStandardMembers</Name>
			    <Members>
			        <NoteProperty>
				    <Name>SerializationDepth</Name>
				    <Value>1</Value>
			        </NoteProperty>
			    </Members>
		            </MemberSet>
		        </Members>
	        </Type>
	        <Type>
		        <Name>MyTest.Grandson</Name>
		        <Members>
		        <MemberSet>
			    <Name>PSStandardMembers</Name>
			    <Members>
			        <NoteProperty>
				    <Name>SerializationDepth</Name>
				    <Value>1</Value>
			        </NoteProperty>
			    </Members>
		            </MemberSet>
		        </Members>
	        </Type>
	    </Types>
"@ | set-content $tmpFile
	            $tmpFile
            }

            function CreateFormatFile {
                $tmpFile = CreateTempPs1xmlFile
    @"
        <Configuration>
	        <ViewDefinitions>
		    <View>
		        <Name>MySizeView</Name>
		        <ViewSelectedBy>
			    <TypeName>System.Management.Automation.Host.Size</TypeName>
		        </ViewSelectedBy>
		        <TableControl>
			    <TableHeaders>
			        <TableColumnHeader>
				    <Label>MyTestWidth</Label>
			        </TableColumnHeader>
			        <TableColumnHeader>
				    <Label>MyTestHeight</Label>
			        </TableColumnHeader>
			    </TableHeaders>
			    <TableRowEntries>
			        <TableRowEntry>
				    <TableColumnItems>
				        <TableColumnItem>
					    <PropertyName>Width</PropertyName>
				        </TableColumnItem>
				        <TableColumnItem>
					    <PropertyName>Height</PropertyName>
				        </TableColumnItem>
				    </TableColumnItems>
			        </TableRowEntry>
			        </TableRowEntries>
		        </TableControl>
		    </View>
	        </ViewDefinitions>
	    </Configuration>
"@ | set-content $tmpFile
                $tmpFile
            }

            $formatFile = CreateFormatFile
            $typeFile = CreateTypeFile
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
            if ($null -ne $samesession) { Remove-PSSession $samesession -ErrorAction SilentlyContinue }
            if ($null -ne $formatFile) { Remove-Item $formatFile -Force -ErrorAction SilentlyContinue }
            if ($null -ne $typeFile) { Remove-Item $typeFile -Force -ErrorAction SilentlyContinue }
        }

        Context "Importing format file works" {
            BeforeAll {
                if ($skipTest) { return }

                $formattingScript = { new-object System.Management.Automation.Host.Size | ForEach-Object { $_.Width = 123; $_.Height = 456; $_ } | Out-String }
                $originalLocalFormatting = & $formattingScript

                
                $originalRemoteFormatting = Invoke-Command $samesession $formattingScript
                $originalLocalFormatting | Should -Be $originalRemoteFormatting

                Invoke-Command $samesession { param($file) Update-FormatData $file } -ArgumentList $formatFile

                
                $modifiedRemoteFormatting = Invoke-Command $samesession $formattingScript
                $originalRemoteFormatting | Should -Not -Be $modifiedRemoteFormatting

                $module = Import-PSSession -Session $samesession -CommandName @() -FormatTypeName * -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "modified remote and imported local should be equal" {
                $importedLocalFormatting = & $formattingScript
                $modifiedRemoteFormatting | Should -Be $importedLocalFormatting
            }

            It "original local and unimported local should be equal" {
                Remove-Module $module -Force
                $unimportedLocalFormatting = & $formattingScript
                $originalLocalFormatting | Should -Be $unimportedLocalFormatting
            }
        }

        It "Updating type table in a middle of a command has effect on serializer" {
            $results = Invoke-Command $session -ArgumentList $typeFile -ScriptBlock {
                param($file)

                New-Object System.Management.Automation.Host.Coordinates
                Update-TypeData $file
                New-Object System.Management.Automation.Host.Coordinates
            }

            
            $results.Count | Should -Be 2
            
            $results[0].MyTestLabel | Should -BeNullOrEmpty
            
            $results[1].MyTestLabel | Should -Be 123
        }

        Context "Implicit remoting works even when types.ps1xml is missing on the client" {
            BeforeAll {
                if ($skipTest) { return }

                $typeDefinition = @"
                    namespace MyTest
                    {
                        public class Root
                        {
        	                public Root(string s) { text = s; }
        	                public Son Son = new Son();
        	                public string text;
                        }

                        public class Son
                        {
                            public Grandson Grandson = new Grandson();
                        }

                        public class Grandson
                        {
                            public string text = "Grandson";
    	                }
                    }
"@
                Invoke-Command -Session $session -Script { Add-Type -TypeDefinition $args[0] } -ArgumentList $typeDefinition
                Invoke-Command -Session $session -Script { function foo { New-Object MyTest.Root "root" } }
                Invoke-Command -Session $session -Script { function bar { param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$Son) $Son.Grandson.text } }

                $module = import-pssession $session foo,bar -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Serialization works for top-level properties" {
                $x = foo
                $x.text | Should -BeExactly "root"
            }

            It "Serialization settings works for deep properties" {
                $x = foo
                $x.Son.Grandson.text | Should -BeExactly "Grandson"
            }

            It "Serialization settings are preserved even if types.ps1xml is missing on the client" {
                $y = foo | bar
                $y | Should -BeExactly "Grandson"
            }
        }
    }

    Describe "Import-PSSession functional tests" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {
            if ($skipTest) { return }
            $session = New-RemoteSession

            
            Invoke-Command -Session $session { function MyFunction { param($x) "x = '$x'; args = '$args'" } }

            
            $remoteCommandType = $ExecutionContext.InvokeCommand.GetCommand('Get-Variable', [System.Management.Automation.CommandTypes]::Cmdlet)
            $remoteProxyBody = [System.Management.Automation.ProxyCommand]::Create($remoteCommandType)
            $remoteProxyDeclaration = "function Get-VariableProxy { $remoteProxyBody }"
            Invoke-Command -Session $session { param($x) Invoke-Expression $x } -Arg $remoteProxyDeclaration
            $remoteAliasDeclaration = "set-alias gvalias Get-Variable"
            Invoke-Command -Session $session { param($x) Invoke-Expression $x } -Arg $remoteAliasDeclaration
            Remove-Item alias:gvalias -Force -ErrorAction silentlycontinue

            
            $module = Import-PSSession -Session $session -Name MyFunction,Get-VariableProxy,Get-Variable,gvalias,cmd -AllowClobber -Type All
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Import-PSSession should return a PSModuleInfo object" {
            $module | Should -Not -BeNullOrEmpty
        }

        It "Import-PSSession should return a PSModuleInfo object" {
            ($module -as [System.Management.Automation.PSModuleInfo]) | Should -Not -BeNullOrEmpty
        }

        It "Helper functions should not be imported" {
            (Get-Item function:*PSImplicitRemoting* -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        }

        It "Calls implicit remoting proxies 'MyFunction'" {
            (MyFunction 1 2 3) | Should -BeExactly "x = '1'; args = '2 3'"
        }

        It "proxy should return remote pid" {
            (Get-VariableProxy -Name:pid).Value | Should -Not -Be $pid
        }

        It "proxy should return remote pid" {
            (Get-Variable -Name:pid).Value | Should -Not -Be $pid
        }

        It "proxy should return remote pid" {
            $(& (Get-Command gvalias -Type alias) -Name:pid).Value | Should -Not -Be $pid
        }

        It "NoName-c8aeb5c8-2388-4d64-98c1-a9c6c218d404" {
            Invoke-Command -Session $session { $env:TestImplicitRemotingVariable = 123 }
            (cmd.exe /c "echo TestImplicitRemotingVariable=%TestImplicitRemotingVariable%") | Should -BeExactly "TestImplicitRemotingVariable=123"
        }

        Context "Test what happens after the runspace is closed" {
            BeforeAll {
                if ($skipTest) { return }

                Remove-PSSession $session

                
                
                $i = 0
                while ( ($i -lt 20) -and ($null -ne (Get-Module | Where-Object { $_.Path -eq $module.Path })) )
                {
                    $i++
                    Start-Sleep -Milliseconds 50
                }
            }

            It "Temporary module should be automatically removed after runspace is closed" {
                (Get-Module | Where-Object { $_.Path -eq $module.Path }) | Should -BeNullOrEmpty
            }

            It "Temporary psm1 file should be automatically removed after runspace is closed" {
                (Get-Item $module.Path -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
            }

            It "Event should be unregistered when the runspace is closed" {
                
                $implicitEventCount = 0
                foreach ($item in $ExecutionContext.Events.Subscribers)
                {
                    if ($item.SourceIdentifier -match "Implicit remoting event") { $implicitEventCount++ }
                }
                $implicitEventCount | Should -Be 0
            }

            It "Private functions from the implicit remoting module shouldn't get imported into global scope" {
                @(Get-ChildItem function:*Implicit* -ErrorAction SilentlyContinue).Count | Should -Be 0
            }
        }
    }

    Describe "Implicit remoting parameter binding" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {
            if ($skipTest) { return }
            $session = New-RemoteSession
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Binding of ValueFromPipeline should work" {
            try {
                $module = Import-PSSession -Session $session -Name Get-Random -AllowClobber
                $x = 1..20 | Get-Random -Count 5
                $x.Count | Should -Be 5
            } finally {
                Remove-Module $module -Force
            }
        }

        Context "Pipeline-based parameter binding works even when client has no type constraints (Windows 7: 
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        [cmdletbinding(defaultparametersetname="string")]
                        param(
                            [string]
                            [parameter(ParameterSetName="string", ValueFromPipeline = $true)]
                            $string,

                            [ipaddress]
                            [parameter(ParameterSetName="ipaddress", ValueFromPipeline = $true)]
                            $ipaddress
                        )

                        "Bound parameter: $($myInvocation.BoundParameters.Keys | Sort-Object)"
                    }
                }

                
                Invoke-Command $session {"s" | foo} | Should -BeExactly "Bound parameter: string"
                Invoke-Command $session {[ipaddress]::parse("127.0.0.1") | foo} | Should -BeExactly "Bound parameter: ipaddress"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Pipeline binding works even if it relies on type constraints" {
                ("s" | foo) | Should -BeExactly "Bound parameter: string"
            }

            It "Pipeline binding works even if it relies on type constraints" {
                ([ipaddress]::parse("127.0.0.1") | foo) | Should -BeExactly "Bound parameter: ipaddress"
            }
        }

        Context "Pipeline-based parameter binding works even when client has no type constraints and parameterset is ambiguous (Windows 7: 
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [string]
                            [parameter(ParameterSetName="string", ValueFromPipeline = $true)]
                            $string,

                            [ipaddress]
                            [parameter(ParameterSetName="ipaddress", ValueFromPipeline = $true)]
                            $ipaddress
                        )

                        "Bound parameter: $($myInvocation.BoundParameters.Keys)"
                    }
                }

                
                Invoke-Command $session {"s" | foo} | Should -BeExactly "Bound parameter: string"
                Invoke-Command $session {[ipaddress]::parse("127.0.0.1") | foo} | Should -BeExactly "Bound parameter: ipaddress"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Pipeline binding works even if it relies on type constraints and parameter set is ambiguous" {
                ("s" | foo) | Should -BeExactly "Bound parameter: string"
            }

            It "Pipeline binding works even if it relies on type constraints and parameter set is ambiguous" {
                ([ipaddress]::parse("127.0.0.1") | foo) | Should -BeExactly "Bound parameter: ipaddress"
            }
        }

        Context "pipeline-based parameter binding works even when one of parameters that can be bound by pipeline gets bound by name" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [DateTime]
                            [parameter(ValueFromPipeline = $true)]
                            $date,

                            [ipaddress]
                            [parameter(ValueFromPipeline = $true)]
                            $ipaddress
                        )

                        "Bound parameter: $($myInvocation.BoundParameters.Keys | Sort-Object)"
                    }
                }

                
                Invoke-Command $session {Get-Date | foo} | Should -BeExactly "Bound parameter: date"
                Invoke-Command $session {[ipaddress]::parse("127.0.0.1") | foo} | Should -BeExactly "Bound parameter: ipaddress"
                Invoke-Command $session {[ipaddress]::parse("127.0.0.1") | foo -date (get-date)} | Should -BeExactly "Bound parameter: date ipaddress"
                Invoke-Command $session {Get-Date | foo -ipaddress ([ipaddress]::parse("127.0.0.1"))} | Should -BeExactly "Bound parameter: date ipaddress"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Pipeline binding works even when also binding by name" {
                (Get-Date | foo) | Should -BeExactly "Bound parameter: date"
            }

            It "Pipeline binding works even when also binding by name" {
                ([ipaddress]::parse("127.0.0.1") | foo) | Should -BeExactly "Bound parameter: ipaddress"
            }

            It "Pipeline binding works even when also binding by name" {
                ([ipaddress]::parse("127.0.0.1") | foo -date $(Get-Date)) | Should -BeExactly "Bound parameter: date ipaddress"
            }

            It "Pipeline binding works even when also binding by name" {
    	        (Get-Date | foo -ipaddress ([ipaddress]::parse("127.0.0.1"))) | Should -BeExactly "Bound parameter: date ipaddress"
            }
        }

        Context "value from pipeline by property name - multiple parameters" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [System.TimeSpan]
                            [parameter(ValueFromPipelineByPropertyName = $true)]
                            $TotalProcessorTime,

                            [System.Diagnostics.ProcessPriorityClass]
                            [parameter(ValueFromPipelineByPropertyName = $true)]
                            $PriorityClass
                        )

                        "Bound parameter: $($myInvocation.BoundParameters.Keys | Sort-Object)"
                    }
                }

                
                Invoke-Command $session {Get-Process -pid $pid | foo} | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"
                Invoke-Command $session {Get-Process -pid $pid | foo -Total 5} | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"
                Invoke-Command $session {Get-Process -pid $pid | foo -Priority normal} | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Pipeline binding works by property name" {
                (Get-Process -id $pid | foo) | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"
            }

            It "Pipeline binding works by property name" {
                (Get-Process -id $pid | foo -Total 5) | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"
            }

            It "Pipeline binding works by property name" {
                (Get-Process -id $pid | foo -Priority normal) | Should -BeExactly "Bound parameter: PriorityClass TotalProcessorTime"
            }
        }

        Context "2 parameters on the same position" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [string]
                            [parameter(Position = 0, parametersetname = 'set1', mandatory = $true)]
                            $string,

                            [ipaddress]
                            [parameter(Position = 0, parametersetname = 'set2', mandatory = $true)]
                            $ipaddress
                        )

                        "Bound parameter: $($myInvocation.BoundParameters.Keys | Sort-Object)"
                    }
                }

                
                Invoke-Command $session {foo ([ipaddress]::parse("127.0.0.1"))} | Should -BeExactly "Bound parameter: ipaddress"
                Invoke-Command $session {foo "blah"} | Should -BeExactly "Bound parameter: string"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Positional binding works" {
                foo "blah" | Should -BeExactly "Bound parameter: string"
            }

            It "Positional binding works" {
                foo ([ipaddress]::parse("127.0.0.1")) | Should -BeExactly "Bound parameter: ipaddress"
            }
        }

        Context "positional binding and array argument value" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [object]
                            [parameter(Position = 0, mandatory = $true)]
                            $p1,

                            [object]
                            [parameter(Position = 1)]
                            $p2
                        )

                        "$p1 : $p2"
                    }
                }

                
                Invoke-Command $session {foo 1,2,3} | Should -BeExactly "1 2 3 : "
                Invoke-Command $session {foo 1,2,3 4} | Should -BeExactly "1 2 3 : 4"
                Invoke-Command $session {foo -p2 4 1,2,3} | Should -BeExactly "1 2 3 : 4"
                Invoke-Command $session {foo 1 4} | Should -BeExactly "1 : 4"
                Invoke-Command $session {foo -p2 4 1} | Should -BeExactly "1 : 4"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Positional binding works when binding an array value" {
                foo 1,2,3 | Should -BeExactly "1 2 3 : "
            }

            It "Positional binding works when binding an array value" {
                foo 1,2,3 4 | Should -BeExactly "1 2 3 : 4"
            }

            It "Positional binding works when binding an array value" {
                foo -p2 4 1,2,3 | Should -BeExactly "1 2 3 : 4"
            }

            It "Positional binding works when binding an array value" {
                foo 1 4 | Should -BeExactly "1 : 4"
            }

            It "Positional binding works when binding an array value" {
                foo -p2 4 1 | Should -BeExactly "1 : 4"
            }
        }

        Context "value from remaining arguments" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            [string]
                            [parameter(Position = 0)]
                            $firstArg,

                            [string[]]
                            [parameter(ValueFromRemainingArguments = $true)]
                            $remainingArgs
                        )

                        "$firstArg : $remainingArgs"
                    }
                }

                
                Invoke-Command $session {foo} | Should -BeExactly " : "
                Invoke-Command $session {foo 1} | Should -BeExactly "1 : "
                Invoke-Command $session {foo -first 1} | Should -BeExactly "1 : "
                Invoke-Command $session {foo 1 2 3} | Should -BeExactly "1 : 2 3"
                Invoke-Command $session {foo -first 1 2 3} | Should -BeExactly "1 : 2 3"
                Invoke-Command $session {foo 2 3 -first 1 4 5} | Should -BeExactly "1 : 2 3 4 5"
                Invoke-Command $session {foo -remainingArgs 2,3 1} | Should -BeExactly "1 : 2 3"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Value from remaining arguments works" {
                $( foo ) | Should -BeExactly " : "
            }

            It "Value from remaining arguments works" {
                $( foo 1 ) | Should -BeExactly "1 : "
            }

            It "Value from remaining arguments works" {
                $( foo -first 1 ) | Should -BeExactly "1 : "
            }

            It "Value from remaining arguments works" {
                $( foo 1 2 3 ) | Should -BeExactly "1 : 2 3"
            }

            It "Value from remaining arguments works" {
                $( foo -first 1 2 3 ) | Should -BeExactly "1 : 2 3"
            }

            It "Value from remaining arguments works" {
                $( foo 2 3 -first 1 4 5 ) | Should -BeExactly "1 : 2 3 4 5"
            }

            It "Value from remaining arguments works" {
                $( foo -remainingArgs 2,3 1 ) | Should -BeExactly "1 : 2 3"
            }
        }

        Context "non cmdlet-based binding" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function foo {
                        param(
                            $firstArg,
                            $secondArg
                        )

                        "$firstArg : $secondArg : $args"
                    }
                }

                
                Invoke-Command $session { foo } | Should -BeExactly " :  : "
                Invoke-Command $session { foo 1 } | Should -BeExactly "1 :  : "
                Invoke-Command $session { foo -first 1 } | Should -BeExactly "1 :  : "
                Invoke-Command $session { foo 1 2 } | Should -BeExactly "1 : 2 : "
                Invoke-Command $session { foo 1 -second 2 } | Should -BeExactly "1 : 2 : "
                Invoke-Command $session { foo -first 1 -second 2 } | Should -BeExactly "1 : 2 : "
                Invoke-Command $session { foo 1 2 3 4 } | Should -BeExactly "1 : 2 : 3 4"
                Invoke-Command $session { foo -first 1 2 3 4 } | Should -BeExactly "1 : 2 : 3 4"
                Invoke-Command $session { foo 1 -second 2 3 4 } | Should -BeExactly "1 : 2 : 3 4"
                Invoke-Command $session { foo 1 3 -second 2 4 } | Should -BeExactly "1 : 2 : 3 4"
                Invoke-Command $session { foo -first 1 -second 2 3 4 } | Should -BeExactly "1 : 2 : 3 4"

                $module = Import-PSSession $session foo -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Non cmdlet-based binding works." {
                foo | Should -BeExactly " :  : "
            }

            It "Non cmdlet-based binding works." {
                foo 1 | Should -BeExactly "1 :  : "
            }

            It "Non cmdlet-based binding works." {
                foo -first 1 | Should -BeExactly "1 :  : "
            }

            It "Non cmdlet-based binding works." {
                foo 1 2 | Should -BeExactly "1 : 2 : "
            }

            It "Non cmdlet-based binding works." {
                foo 1 -second 2 | Should -BeExactly "1 : 2 : "
            }

            It "Non cmdlet-based binding works." {
                foo -first 1 -second 2 | Should -BeExactly "1 : 2 : "
            }

            It "Non cmdlet-based binding works." {
                foo 1 2 3 4 | Should -BeExactly "1 : 2 : 3 4"
            }

            It "Non cmdlet-based binding works." {
                foo -first 1 2 3 4 | Should -BeExactly "1 : 2 : 3 4"
            }

            It "Non cmdlet-based binding works." {
                foo 1 -second 2 3 4 | Should -BeExactly "1 : 2 : 3 4"
            }

            It "Non cmdlet-based binding works." {
                foo 1 3 -second 2 4 | Should -BeExactly "1 : 2 : 3 4"
            }

            It "Non cmdlet-based binding works." {
                foo -first 1 -second 2 3 4 | Should -BeExactly "1 : 2 : 3 4"
            }
        }

        Context "default parameter initialization should be executed on the server" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command -Session $session -ScriptBlock {
                    function MyInitializerFunction { param($x = $PID) $x }
                }

                $localPid = $PID
                $remotePid = Invoke-Command $session { $PID }

                
                $localPid | Should -Not -Be $remotePid

                $module = Import-PSSession -Session $session -Name MyInitializerFunction -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Initializer run on the remote server" {
                (MyInitializerFunction) | Should -Be $remotePid
            }

            It "Initializer not run when value provided" {
                (MyInitializerFunction 123) | Should -Be 123
            }
        }

        Context "client-side parameters - cmdlet case" {
            BeforeAll {
                if ($skipTest) { return }
                $remotePid = Invoke-Command $session { $PID }
                $module = Import-PSSession -Session $session -Name Get-Variable -Type cmdlet -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Importing by name/type should work" {
                (Get-Variable -Name PID).Value | Should -Not -Be $PID
            }

            It "Test -AsJob parameter" {
                try {
                    $job = Get-Variable -Name PID -AsJob

                    $job | Should -Not -BeNullOrEmpty
                    ($job -is [System.Management.Automation.Job]) | Should -BeTrue
                    ($job.Finished.WaitOne([TimeSpan]::FromSeconds(10), $false)) | Should -BeTrue
                    $job.JobStateInfo.State | Should -Be 'Completed'

                    $childJob = $job.ChildJobs[0]
                    $childJob.Output.Count | Should -Be 1
                    $childJob.Output[0].Value | Should -Be $remotePid
                } finally {
                    Remove-Job $job -Force
                }
            }

            It "Test OutVariable" {
                $result1 = Get-Variable -Name PID -OutVariable global:result2
                $result1.Value | Should -Be $remotePid
                $global:result2[0].Value | Should -Be $remotePid
            }
        }

        Context "client-side parameters - Windows 7 bug 
            BeforeAll {
                if ($skipTest) { return }
                $module = Import-PSSession -Session $session -Name Write-Warning -Type cmdlet -Prefix Remote -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Test warnings present with '-WarningAction Continue'" {
                try {
                    $jobWithWarnings = write-remotewarning foo -WarningAction continue -Asjob
                    $null = Wait-Job $jobWithWarnings

                    $jobWithWarnings.ChildJobs[0].Warning.Count | Should -Be 1
                } finally {
                    Remove-Job $jobWithWarnings -Force
                }
            }

            It "Test no warnings with '-WarningAction SilentlyContinue'" {
                try {
                    $jobWithoutWarnings = write-remotewarning foo -WarningAction silentlycontinue -Asjob
                    $null = Wait-Job $jobWithoutWarnings

                    $jobWithoutWarnings.ChildJobs[0].Warning.Count | Should -Be 0
                } finally {
                    Remove-Job $jobWithoutWarnings -Force
                }
            }
        }

        Context "client-side parameters - non-cmdlet case" {
            BeforeAll {
                if ($skipTest) { return }

                Invoke-Command $session { function foo { param($OutVariable) "OutVariable = $OutVariable" } }

                
                Invoke-Command $session { foo -OutVariable x } | Should -BeExactly "OutVariable = x"

                $module = Import-PSSession -Session $session -Name foo -Type function -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Implicit remoting: OutVariable is not intercepted for non-cmdlet-bound functions" {
                foo -OutVariable x | Should -BeExactly "OutVariable = x"
            }
        }

        Context "switch and positional parameters" {
            BeforeAll {
                if ($skipTest) { return }
                $remotePid = Invoke-Command $session { $PID }
                $module = Import-PSSession -Session $session -Name Get-Variable -Type cmdlet -Prefix Remote -AllowClobber
            }

            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Switch parameters work fine" {
                $proxiedPid = Get-RemoteVariable -Name pid -ValueOnly
                $remotePid | Should -Be $proxiedPid
            }

            It "Positional parameters work fine" {
                $proxiedPid = Get-RemoteVariable pid
                $remotePid | Should -Be ($proxiedPid.Value)
            }
        }
    }

    Describe "Implicit remoting on restricted ISS" -tags "Feature","RequireAdminOnWindows","Slow" {

        BeforeAll {
            if ($skipTest) { return }

            $sessionConfigurationDll = [IO.Path]::Combine([IO.Path]::GetTempPath(), "ImplicitRemotingRestrictedConfiguration$(Get-Random).dll")
            Add-Type -OutputAssembly $sessionConfigurationDll -TypeDefinition @"

            using System;
            using System.Collections.Generic;
            using System.Management.Automation;
            using System.Management.Automation.Runspaces;
            using System.Management.Automation.Remoting;

            namespace MySessionConfiguration
            {
                public class MySessionConfiguration : PSSessionConfiguration
                {
                    public override InitialSessionState GetInitialSessionState(PSSenderInfo senderInfo)
                    {
                        //System.Diagnostics.Debugger.Launch();
                        //System.Diagnostics.Debugger.Break();

                        InitialSessionState iss = InitialSessionState.CreateRestricted(System.Management.Automation.SessionCapabilities.RemoteServer);

                        // add Out-String for testing stuff
                        iss.Commands["Out-String"][0].Visibility = SessionStateEntryVisibility.Public;

                        // remove all commands that are not public
                        List<string> commandsToRemove = new List<string>();
                        foreach (SessionStateCommandEntry entry in iss.Commands)
                        {
                            List<SessionStateCommandEntry> sameNameEntries = new List<SessionStateCommandEntry>(iss.Commands[entry.Name]);
                            if (!sameNameEntries.Exists(delegate(SessionStateCommandEntry e) { return e.Visibility == SessionStateEntryVisibility.Public; }))
                            {
                                commandsToRemove.Add(entry.Name);
                            }
                        }

                        foreach (string commandToRemove in commandsToRemove)
                        {
                            iss.Commands.Remove(commandToRemove, null /* all types */);
                        }

                        return iss;
                    }
                }
            }
"@

            Get-PSSessionConfiguration ImplicitRemotingRestrictedConfiguration* | Unregister-PSSessionConfiguration -Force

            
            
            

            $myConfiguration = Register-PSSessionConfiguration `
                -Name ImplicitRemotingRestrictedConfiguration `
                -ApplicationBase (Split-Path $sessionConfigurationDll) `
                -AssemblyName (Split-Path $sessionConfigurationDll -Leaf) `
                -ConfigurationTypeName "MySessionConfiguration.MySessionConfiguration" `
                -Force

            $session = New-RemoteSession -ConfigurationName $myConfiguration.Name
            $session | Should -Not -BeNullOrEmpty
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
            if ($null -ne $myConfiguration) { Unregister-PSSessionConfiguration -Name ($myConfiguration.Name) -Force -ErrorAction SilentlyContinue }
            if ($null -ne $sessionConfigurationDll) { Remove-Item $sessionConfigurationDll -Force -ErrorAction SilentlyContinue }
        }

        Context "restrictions works" {
            It "Get-Variable is private" {
                @(Invoke-Command $session { Get-Command -Name Get-Variabl* }).Count | Should -Be 0
            }
            It "Only 9 commands are public" {
                @(Invoke-Command $session { Get-Command }).Count | Should -Be 9
            }
        }

        Context "basic functionality of Import-PSSession works (against a directly exposed cmdlet and against a proxy function)" {
            BeforeAll {
                if ($skipTest) { return }
                $module = Import-PSSession $session Out-Strin*,Measure-Object -Type Cmdlet,Function -ArgumentList 123 -AllowClobber
            }
            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "Import-PSSession works against the ISS-restricted runspace (Out-String)" {
                @(Get-Command Out-String -Type Function).Count | Should -Be 1
            }

            It "Import-PSSession works against the ISS-restricted runspace (Measure-Object)" {
                @(Get-Command Measure-Object -Type Function).Count | Should -Be 1
            }

            It "Invoking an implicit remoting proxy works against the ISS-restricted runspace (Out-String)" {
                $remoteResult = Out-String -input ("blah " * 10) -Width 10
                $localResult = Microsoft.PowerShell.Utility\Out-String -input ("blah " * 10) -Width 10

                $localResult | Should -Be $remoteResult
            }

            It "Invoking an implicit remoting proxy works against the ISS-restricted runspace (Measure-Object)" {
                $remoteResult = 1..10 | Measure-Object
                $localResult = 1..10 | Microsoft.PowerShell.Utility\Measure-Object
                ($localResult.Count) | Should -Be ($remoteResult.Count)
            }
        }
    }

    Describe "Implicit remoting tests" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {
            if ($skipTest) { return }

            $session = New-RemoteSession
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        Context "Get-Command <Imported-Module> and <Imported-Module.Name> work (Windows 7: 
            BeforeAll {
                if ($skipTest) { return }
                $module = Import-PSSession $session Get-Variable -Prefix My -AllowClobber
            }
            AfterAll {
                if ($skipTest) { return }
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            It "PSModuleInfo.Name shouldn't contain a psd1 extension" {
                ($module.Name -notlike '*.psd1') | Should -BeTrue
            }

            It "PSModuleInfo.Name shouldn't contain a psm1 extension" {
                ($module.Name -notlike '*.psm1') | Should -BeTrue
            }

            It "PSModuleInfo.Name shouldn't contain a path" {
                ($module.Name -notlike "${env:TMP}*") | Should -BeTrue
            }

            
            
            It "Get-Command returns only 1 public command from implicit remoting module (1)" -Pending {
                $c = @(Get-Command -Module $module)
                $c.Count | Should -Be 1
                $c[0].Name | Should -BeExactly "Get-MyVariable"
            }

            
            
            It "Get-Command returns only 1 public command from implicit remoting module (2)" -Pending {
                $c = @(Get-Command -Module $module.Name)
                $c.Count | Should -Be 1
                $c[0].Name | Should -BeExactly "Get-MyVariable"
            }
        }

        Context "progress bar should be 1) present and 2) completed also" {
            BeforeAll {
                if ($skipTest) { return }

                $file = [IO.Path]::Combine([IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString())
                $powerShell = [PowerShell]::Create().AddCommand("Export-PSSession").AddParameter("Session", $session).AddParameter("ModuleName", $file).AddParameter("CommandName", "Get-Process").AddParameter("AllowClobber")
                $powerShell.Invoke() | Out-Null
            }
            AfterAll {
                if ($skipTest) { return }
                $powerShell.Dispose()
                if ($null -ne $file) { Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue }
            }

            It "'Completed' progress record should be present" {
                ($powerShell.Streams.Progress | Select-Object -last 1).RecordType.ToString() | Should -BeExactly "Completed"
            }
        }

        Context "display of property-less objects (not sure if this test belongs here) (Windows 7: 
            BeforeAll {
                if ($skipTest) { return }
                $x = new-object random
	            $expected = $x.ToString()
            }

            
            
            It "Display of local property-less objects" {
                ($x | Out-String).Trim() | Should -Be $expected
            }
            It "Display of remote property-less objects" {
                (Invoke-Command $session { Import-Module Microsoft.PowerShell.Utility; New-Object random } | out-string).Trim() | Should -Be $expected
            }
        }

        It "piping between remoting proxies should work" {
            try {
                $module = Import-PSSession -Session $session -Name Write-Output -AllowClobber
                $result = Write-Output 123 | Write-Output
                $result | Should -Be 123
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }
        }

        It "Strange parameter names should trigger an error" {
            try {
                Invoke-Command $session { function attack(${foo="$(calc)"}){Write-Output "It is done."}}
                $module = Import-PSSession -Session $session -CommandName attack -ErrorAction SilentlyContinue -ErrorVariable expectedError -AllowClobber
                $expectedError | Should -Not -BeNullOrEmpty
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }
        }

        It "Non-terminating error from remote end got duplicated locally" {
            try {
                Invoke-Command $session { $oldGetCommand = ${function:Get-Command} }
                Invoke-Command $session { function Get-Command { write-error blah } }
                $module = Import-PSSession -Session $session -ErrorAction SilentlyContinue -ErrorVariable expectedError -AllowClobber

                $expectedError | Should -Not -BeNullOrEmpty

                $msg = [string]($expectedError[0])
                $msg.Contains("blah") | Should -BeTrue
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                Invoke-Command $session { ${function:Get-Command} = $oldGetCommand }
            }
        }

        It "Should get an error if remote server returns something that wasn't asked for" {
            try {
                Invoke-Command $session { $oldGetCommand = ${function:Get-Command} }
                Invoke-Command $session { function notRequested { "notRequested" }; function Get-Command { Microsoft.PowerShell.Core\Get-Command Get-Variable,notRequested } }
                $module = Import-PSSession -Session $session Get-Variable -AllowClobber -ErrorAction SilentlyContinue -ErrorVariable expectedError

                $expectedError | Should -Not -BeNullOrEmpty

                $msg = [string]($expectedError[0])
                $msg.Contains("notRequested") | Should -BeTrue
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                Invoke-Command $session { ${function:Get-Command} = $oldGetCommand }
            }
        }

        It "Get-Command returns something that is not CommandInfo" {
            Invoke-Command $session { $oldGetCommand = ${function:Get-Command} }
            Invoke-Command $session { function Get-Command { Microsoft.PowerShell.Utility\Get-Variable } }
            $e = { $module = Import-PSSession -Session $session -AllowClobber } | Should -Throw -PassThru

            $msg = [string]($e)
            $msg.Contains("Get-Command") | Should -BeTrue

            if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            Invoke-Command $session { ${function:Get-Command} = $oldGetCommand }
        }

        
        It "Command resolution for 'myOrder' should be respected by implicit remoting" {
            try
            {
                $tempdir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
                $null = New-Item $tempdir -ItemType Directory -Force
                $oldPath = Invoke-Command $session { $env:PATH }

                'param([Parameter(Mandatory=$true)]$scriptParam) "external script / $scriptParam"' > $tempdir\myOrder.ps1
                Invoke-Command $session { param($x) $env:PATH = $env:PATH + [IO.Path]::PathSeparator + $x } -ArgumentList $tempDir
                Invoke-Command $session { function myOrder { param([Parameter(Mandatory=$true)]$functionParam) "function / $functionParam" } }
                Invoke-Command $session { function helper { param([Parameter(Mandatory=$true)]$aliasParam) "alias / $aliasParam" }; Set-Alias myOrder helper }

                $expectedResult = Invoke-Command $session { myOrder -aliasParam 123 }

                $module = Import-PSSession $session myOrder -CommandType All -AllowClobber
                $actualResult = myOrder -aliasParam 123

                $expectedResult | Should -Be $actualResult
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                Invoke-Command $session { param($x) $env:PATH = $x; Remove-Item Alias:\myOrder, Function:\myOrder, Function:\helper -Force -ErrorAction SilentlyContinue } -ArgumentList $oldPath
                Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue
            }
        }

        It "Test -Prefix parameter" {
            try {
                $module = Import-PSSession -Session $session -Name Get-Variable -Type cmdlet -Prefix My -AllowClobber
                (Get-MyVariable -Name pid).Value | Should -Not -Be $PID
            } finally {
                if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            (Get-Item function:Get-MyVariable -ErrorAction SilentlyContinue) | Should -BeNullOrEmpty
        }

        Context "BadVerbs of functions should trigger a warning" {
            BeforeAll {
                if ($skipTest) { return }
                Invoke-Command $session { function BadVerb-Variable { param($name) Get-Variable $name } }
            }
            AfterAll {
                if ($skipTest) { return }
                Invoke-Command $session { Remove-Item Function:\BadVerb-Variable }
            }

            It "Bad verb causes no error but warning" {
                try {
                    $ps = [powershell]::Create().AddCommand("Import-PSSession", $true).AddParameter("Session", $session).AddParameter("CommandName", "BadVerb-Variable")
                    $module = $ps.Invoke() | Select-Object -First 1

                    $ps.Streams.Error.Count | Should -Be 0
                    $ps.Streams.Warning.Count | Should -Not -Be 0
                } finally {
                    if ($null -ne $module) {
                        $ps.Commands.Clear()
                        $ps.AddCommand("Remove-Module").AddParameter("ModuleInfo", $module).AddParameter("Force", $true) > $null
                        $ps.Invoke() > $null
                    }
                    $ps.Dispose()
                }
            }

            It "Imported function with bad verb should work" {
                try {
                    $module = Import-PSSession $session BadVerb-Variable -WarningAction SilentlyContinue -AllowClobber

                    $remotePid = Invoke-Command $session { $PID }
                    $getVariablePid = Invoke-Command $session { (Get-Variable -Name PID).Value }
                    $getVariablePid | Should -Be $remotePid

                    
                    Get-Item Function:\Get-Variable -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                    
                    Get-Item Function:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

                    
                    Get-Item Alias:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                    (BadVerb-Variable -Name pid).Value | Should -Be $remotePid
                } finally {
                    if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                }
            }

            It "Test warning is supressed by '-DisableNameChecking'" {
                try {
                    $ps = [powershell]::Create().AddCommand("Import-PSSession", $true).AddParameter("Session", $session).AddParameter("CommandName", "BadVerb-Variable").AddParameter("DisableNameChecking", $true)
                    $module = $ps.Invoke() | Select-Object -First 1

                    $ps.Streams.Error.Count | Should -Be 0
                    $ps.Streams.Warning.Count | Should -Be 0
                } finally {
                    if ($null -ne $module) {
                        $ps.Commands.Clear()
                        $ps.AddCommand("Remove-Module").AddParameter("ModuleInfo", $module).AddParameter("Force", $true) > $null
                        $ps.Invoke() > $null
                    }
                    $ps.Dispose()
                }
            }

            It "Imported function with bad verb by 'Import-PSSession -DisableNameChecking' should work" {
                try {
                    $module = Import-PSSession $session BadVerb-Variable -DisableNameChecking -AllowClobber

                    $remotePid = Invoke-Command $session { $PID }
                    $getVariablePid = Invoke-Command $session { (Get-Variable -Name PID).Value }
                    $getVariablePid | Should -Be $remotePid

                    
                    Get-Item Function:\Get-Variable -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                    
                    Get-Item Function:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

                    
                    Get-Item Alias:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                    (BadVerb-Variable -Name pid).Value | Should -Be $remotePid
                } finally {
                    if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                }
            }
        }

        Context "BadVerbs of alias shouldn't trigger a warning + can import an alias without saying -CommandType Alias" {
            BeforeAll {
                if ($skipTest) { return }
                Invoke-Command $session { Set-Alias BadVerb-Variable Get-Variable }
            }
            AfterAll {
                if ($skipTest) { return }
                Invoke-Command $session { Remove-Item Alias:\BadVerb-Variable }
            }

            It "Bad verb alias causes no error or warning" {
                try {
                    $ps = [powershell]::Create().AddCommand("Import-PSSession", $true).AddParameter("Session", $session).AddParameter("CommandName", "BadVerb-Variable")
                    $module = $ps.Invoke() | Select-Object -First 1

                    $ps.Streams.Error.Count | Should -Be 0
                    $ps.Streams.Warning.Count | Should -Be 0
                } finally {
                    if ($null -ne $module) {
                        $ps.Commands.Clear()
                        $ps.AddCommand("Remove-Module").AddParameter("ModuleInfo", $module).AddParameter("Force", $true) > $null
                        $ps.Invoke() > $null
                    }
                    $ps.Dispose()
                }
            }

            It "Importing alias with bad verb should work" {
                try {
                    $module = Import-PSSession $session BadVerb-Variable -AllowClobber

                    $remotePid = Invoke-Command $session { $PID }
                    $getVariablePid = Invoke-Command $session { (Get-Variable -Name PID).Value }
                    $getVariablePid | Should -Be $remotePid

                    
                    Get-Item Function:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -BeNullOrEmpty

                    
                    Get-Item Alias:\BadVerb-Variable -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty

                    (BadVerb-Variable -Name pid).Value | Should -Be $remotePid
                } finally {
                    if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
                }
            }
        }

        It "Removing a module should clean-up event handlers (Windows 7: 
            $oldNumberOfHandlers = $executionContext.GetType().GetProperty("Events").GetValue($executionContext, $null).Subscribers.Count
            $module = Import-PSSession -Session $session -Name Get-Random -AllowClobber

            Remove-Module $module -Force
            $newNumberOfHandlers = $executionContext.GetType().GetProperty("Events").GetValue($executionContext, $null).Subscribers.Count

            
            $oldNumberOfHandlers | Should -Be $newNumberOfHandlers

            
            @(Get-ChildItem function:*Implicit* -ErrorAction SilentlyContinue).Count | Should -Be 0
        }
    }

    Describe "Export-PSSession function" -tags "Feature","RequireAdminOnWindows" {
        BeforeAll {
            if ($skipTest) { return }

            $session = New-RemoteSession

            $tempdir = Join-Path $env:TEMP ([IO.Path]::GetRandomFileName())
            New-Item $tempdir -ItemType Directory > $null

            @"
            Import-Module `"$tempdir\Diag`"
            `$mod = Get-Module Diag
            Return `$mod
"@ > $tempdir\TestBug450687.ps1
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
            if ($null -ne $tempdir) { Remove-Item $tempdir -Force -Recurse -ErrorAction SilentlyContinue }
        }

        It "Test the module created by Export-PSSession" {
            try {
                Export-PSSession -Session $session -OutputModule $tempdir\Diag -CommandName New-Guid -AllowClobber > $null

                
                $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
                $ps = [PowerShell]::Create($iss)
                $result = $ps.AddScript(" & $tempdir\TestBug450687.ps1").Invoke()

                
                ($null -ne $result -and $result.Count -eq 1 -and $result[0].Name -eq "Diag") | Should -BeTrue

                
                $c = $result[0].ExportedCommands["New-Guid"]
                ($null -ne $c -and $c.CommandType -eq "Function") | Should -BeTrue
            } finally {
                $ps.Dispose()
            }
        }
    }

    Describe "Implicit remoting with disconnected session" -tags "Feature","RequireAdminOnWindows" {
        BeforeAll {
            if ($skipTest) { return }

            $session = New-RemoteSession -Name Session102
            $remotePid = Invoke-Command $session { $PID }
            $module = Import-PSSession $session Get-Variable -prefix Remote -AllowClobber
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Remote session PID should be different" {
            $sessionPid = Get-RemoteVariable pid
            $sessionPid.Value | Should -Be $remotePid
        }

        It "Disconnected session should be reconnected when calling proxied command" {
            Disconnect-PSSession $session

            $dSessionPid = Get-RemoteVariable pid
            $dSessionPid.Value | Should -Be $remotePid

            $session.State | Should -Be 'Opened'
        }

        
        
        
        It "Should have a new session when the disconnected session cannot be re-connected" -Pending {
            
            Disconnect-PSSession $session
            Start-Process powershell -arg 'Get-PSSession -cn localhost -name Session102 | Connect-PSSession' -Wait

            Start-Sleep -Seconds 3

            
            $dSessionPid = Get-RemoteVariable pid
            $dSessionPid.Value | Should -Not -Be $remotePid
        }
    }

    Describe "Select-Object with implicit remoting" -tags "Feature","RequireAdminOnWindows" {
        BeforeAll {
            if ($skipTest) { return }

            $session = New-RemoteSession
            Invoke-Command $session { function foo { "a","b","c" } }
            $module = Import-PSSession $session foo -AllowClobber
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $module) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Select-Object -First should work with implicit remoting" {
            $bar = foo | Select-Object -First 2
            $bar | Should -Not -BeNullOrEmpty
            $bar.Count | Should -Be 2
            $bar[0] | Should -BeExactly "a"
            $bar[1] | Should -BeExactly "b"
        }
    }

    Describe "Get-FormatData used in Export-PSSession should work on DL targets" -tags "Feature","RequireAdminOnWindows" {
        BeforeAll {
            
            
            $skipThisTest = $skipTest -or $IsCoreCLR -or
                (! (Test-Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727')) -or
                (! (Test-Path 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine'))

            if ($skipThisTest) { return }

            
            
            
            

            $configName = "DLConfigTest"
            $null = Register-PSSessionConfiguration -Name $configName -PSVersion 2.0 -Force
            $session = New-RemoteSession -ConfigurationName $configName
        }

        AfterAll {
            if ($skipThisTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
            Unregister-PSSessionConfiguration -Name $configName -Force -ErrorAction SilentlyContinue
        }

        It "Verifies that Export-PSSession with PS 2.0 session and format type names succeeds" -Skip:$skipThisTest {
            try {
                $results = Export-PSSession -Session $session -OutputModule tempTest -CommandName Get-Process `
                                            -AllowClobber -FormatTypeName * -Force -ErrorAction Stop
                $results.Count | Should -Not -Be 0
            } finally {
                if ($results.Count -gt 0) {
                    Remove-Item -Path $results[0].DirectoryName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Describe "GetCommand locally and remotely" -tags "Feature","RequireAdminOnWindows" {

        BeforeAll {
            if ($skipTest) { return }
            $session = New-RemoteSession
        }

        AfterAll {
            if ($skipTest) { return }
            if ($null -ne $session) { Remove-PSSession $session -ErrorAction SilentlyContinue }
        }

        It "Verifies that the number of local cmdlet command count is the same as remote cmdlet command count." {
            $localCommandCount = (Get-Command -Type Cmdlet).Count
            $remoteCommandCount = Invoke-Command { (Get-Command -Type Cmdlet).Count }
            $localCommandCount | Should -Be $remoteCommandCount
        }
    }

    Describe "Import-PSSession on Restricted Session" -tags "Feature","RequireAdminOnWindows","Slow" {

        BeforeAll {
            if ($skipTest) { return }

            $configName = "restricted_" + (Get-RandomFileName)
            New-PSSessionConfigurationFile -Path $TestDrive\restricted.pssc -SessionType RestrictedRemoteServer
            Register-PSSessionConfiguration -Path $TestDrive\restricted.pssc -Name $configName -Force
            $session = New-RemoteSession -ConfigurationName $configName
        }

        AfterAll {
            if ($skipTest) { return }

            if ($session -ne $null) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
            Unregister-PSSessionConfiguration -Name $configName -Force -ErrorAction SilentlyContinue
        }

        It "Verifies that Import-PSSession works on a restricted session" {

            $errorVariable = $null
            try
            {
                $module = Import-PSSession -Session $session -AllowClobber -ErrorVariable $errorVariable -CommandName Get-Help
            }
            finally
            {
                if ($module -ne $null) { Remove-Module $module -Force -ErrorAction SilentlyContinue }
            }

            $errorVariable | Should -BeNullOrEmpty
        }
    }
}
finally
{
    $global:PSDefaultParameterValues = $originalDefaultParameterValues
    $WarningPreference = $originalWarningPreference
}
