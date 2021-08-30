

$imageName = "remotetestimage"
Describe "Basic remoting test with docker" -tags @("Scenario","Slow"){
    BeforeAll {
        $Timeout = 600 
        $dockerimage = docker images --format "{{ .Repository }}" $imageName
        if ( $dockerimage -ne $imageName ) {
            $pending = $true
            write-warning "Docker image '$imageName' not found, not running tests"
            return
        }
        else {
            $pending = $false
        }

        
        Write-Verbose -verbose "setting up docker container PowerShell server"
        $server = docker run -d $imageName powershell -c Start-Sleep -Seconds $timeout
        Write-Verbose -verbose "setting up docker container PowerShell client"
        $client = docker run -d $imageName powershell -c Start-Sleep -Seconds $timeout

        
        Write-Verbose -verbose "Getting path to PowerShell"
        $powershellcorepath = docker exec $server powershell -c "(get-childitem 'c:\program files\powershell\*\pwsh.exe').fullname"
        if ( ! $powershellcorepath )
        {
            $pending = $true
            write-warning "Cannot find powershell executable, not running tests"
            return
        }
        $powershellcoreversion = ($powershellcorepath -split "[\\/]")[-2]
        
        $powershellcoreConfiguration = "powershell.${powershellcoreversion}"

        
        write-verbose -verbose "getting server hostname"
        $serverhostname = docker exec $server hostname
        write-verbose -verbose "getting client hostname"
        $clienthostname = docker exec $client hostname

        
        write-verbose -verbose "getting powershell full version"
        $fullVersion = docker exec $client powershell -c "`$psversiontable.psversion.tostring()"
        if ( ! $fullVersion )
        {
            $pending = $true
            write-warning "Cannot determine PowerShell full version, not running tests"
            return
        }

        write-verbose -verbose "getting powershell version"
        $coreVersion = docker exec $client "$powershellcorepath" -c "`$psversiontable.psversion.tostring()"
        if ( ! $coreVersion )
        {
            $pending = $true
            write-warning "Cannot determine PowerShell version, not running tests"
            return
        }
    }

    AfterAll {
        
        if ( $pending -eq $false ) {
            docker rm -f $server
            docker rm -f $client
        }
    }

    It "Full powershell can get correct remote powershell version" -pending:$pending {
        $result = docker exec $client powershell -c "`$ss = [security.securestring]::new(); '11aa!!AA'.ToCharArray() | ForEach-Object { `$ss.appendchar(`$_)}; `$c = [pscredential]::new('testuser',`$ss); `$ses=new-pssession $serverhostname -configurationname $powershellcoreConfiguration -auth basic -credential `$c; invoke-command -session `$ses { `$psversiontable.psversion.tostring() }"
        $result | should be $coreVersion
    }

    It "Full powershell can get correct remote powershell full version" -pending:$pending {
        $result = docker exec $client powershell -c "`$ss = [security.securestring]::new(); '11aa!!AA'.ToCharArray() | ForEach-Object { `$ss.appendchar(`$_)}; `$c = [pscredential]::new('testuser',`$ss); `$ses=new-pssession $serverhostname -auth basic -credential `$c; invoke-command -session `$ses { `$psversiontable.psversion.tostring() }"
        $result | should be $fullVersion
    }

    It "Core powershell can get correct remote powershell version" -pending:$pending {
        $result = docker exec $client "$powershellcorepath" -c "`$ss = [security.securestring]::new(); '11aa!!AA'.ToCharArray() | ForEach-Object { `$ss.appendchar(`$_)}; `$c = [pscredential]::new('testuser',`$ss); `$ses=new-pssession $serverhostname -configurationname $powershellcoreConfiguration -auth basic -credential `$c; invoke-command -session `$ses { `$psversiontable.psversion.tostring() }"
        $result | should be $coreVersion
    }

    It "Core powershell can get correct remote powershell full version" -pending:$pending {
        $result = docker exec $client "$powershellcorepath" -c "`$ss = [security.securestring]::new(); '11aa!!AA'.ToCharArray() | ForEach-Object { `$ss.appendchar(`$_)}; `$c = [pscredential]::new('testuser',`$ss); `$ses=new-pssession $serverhostname -auth basic -credential `$c; invoke-command -session `$ses { `$psversiontable.psversion.tostring() }"
        $result | should be $fullVersion
    }
}
