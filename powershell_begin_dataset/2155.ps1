


Describe "Verify Markdown Links" {
    BeforeAll {
        if(!(Get-Command -Name 'markdown-link-check' -ErrorAction SilentlyContinue))
        {
            Write-Verbose "installing markdown-link-check ..." -Verbose
            start-nativeExecution {
                sudo yarn global add markdown-link-check@3.7.2
            }
        }

        if(!(Get-Module -Name 'ThreadJob' -ListAvailable -ErrorAction SilentlyContinue))
        {
            Install-Module -Name ThreadJob -Scope CurrentUser
        }

        
        get-job | remove-job -force
    }

    AfterAll {
        
        get-job | remove-job -force
    }

    $groups = Get-ChildItem -Path "$PSScriptRoot\..\..\..\*.md" -Recurse | Where-Object {$_.DirectoryName -notlike '*node_modules*'} | Group-Object -Property directory

    $jobs = @{}
    
    Foreach($group in $groups)
    {
        Write-Verbose -verbose "starting jobs for $($group.Name) ..."
        $job = Start-ThreadJob {
            param([object] $group)
            foreach($file in $group.Group)
            {
                $results = markdown-link-check $file 2>&1
                Write-Output ([PSCustomObject]@{
                    file = $file
                    results = $results
                })
            }
        } -ArgumentList @($group)
        $jobs.add($group.name,$job)
    }

    Write-Verbose -verbose "Getting results ..."
    
    foreach($key in $jobs.keys)
    {
        $job = $jobs.$key
        $results = Receive-Job -Job $job -Wait
        Remove-job -job $Job
        foreach($jobResult in $results)
        {
            $file = $jobResult.file
            $result = $jobResult.results
            Context "Verify links in $file" {
                
                
                $failures = $result -like '*[✖]*' | ForEach-Object { $_.Substring(4).Trim() }
                $passes = $result -like '*[✓]*' | ForEach-Object {
                    @{url=$_.Substring(4).Trim() }
                }
                $trueFailures = @()
                $verifyFailures = @()
                foreach ($failure in $failures) {
                    if($failure -like 'https://www.amazon.com*')
                    {
                        
                        
                        $verifyFailures += @{url = $failure}
                    }
                    else
                    {
                        $trueFailures += @{url = $failure}
                    }
                }

                
                function noop {
                }

                if($passes)
                {
                    it "<url> should work" -TestCases $passes {
                        noop
                    }
                }

                if($trueFailures)
                {
                    it "<url> should work" -TestCases $trueFailures  {
                        param($url)

                        
                        
                        
                        $allowedFailures = @( 503 )

                        $prefix = $url.Substring(0,7)

                        
                        Write-Verbose "prefix: '$prefix'" -Verbose
                        if($url -match '^http(s)?:')
                        {
                            
                            try
                            {
                                $null = Invoke-WebRequest -uri $url -RetryIntervalSec 3 -MaximumRetryCount 6
                            }
                            catch
                            {
                                if ( $allowedFailures -notcontains $_.Exception.Response.StatusCode )  {
                                    throw "retry of URL failed with error: $($_.Exception.Message)"
                                }
                            }
                        }
                        else {
                            throw "Tool reported URL as unreachable."
                        }
                    }
                }

                if($verifyFailures)
                {
                    it "<url> should work" -TestCases $verifyFailures -Pending  {
                    }
                }

                if(!$passes -and !$trueFailures -and !$verifyFailures)
                {
                    It "has no links" {
                        noop
                    }
                }
            }
        }
    }
}
