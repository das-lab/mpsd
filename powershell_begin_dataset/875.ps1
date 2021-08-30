$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword



function Get-Credential { return $creds }


$streamingpy= @"

import sys
import string
import hashlib

while True:
    line = sys.stdin.readline()
    if not line:
        break

    line = string.strip(line, "\n ")
    clientid, devicemake, devicemodel = string.split(line, "\t")
    phone_label = devicemake + ' ' + devicemodel
    print "\t".join([clientid, phone_label, hashlib.md5(phone_label).hexdigest()])
"@
$pigpython=@"



@outputSchema("log: {(date:chararray, time:chararray, classname:chararray, level:chararray, detail:chararray)}")
def create_structure(input):
    if (input.startswith('java.lang.Exception')):
        input = input[21:len(input)] + ' - java.lang.Exception'
    date, time, classname, level, detail = input.split(' ', 4)
    return date, time, classname, level, detail
"@

Describe "hdinsight-python" {
    
    in $TestDrive {
        
        $streamingpy | Out-File .\streaming.py
        $pigpython | Out-File .\pig_python.py
        
        Mock Read-Host { $clusterName }
        
        Mock Write-Progress { }

        It "Converts CRLF line endings to just LF" {
            
            {Fix-LineEnding("$TestDrive\streaming.py")} | Should not throw
            {Fix-LineEnding("$TestDrive\pig_python.py")} | Should not throw
            '.\streaming.py' | Should not Contain "`r`n"
            '.\pig_python.py' | Should not Contain "`r`n"
        }

        It "Uploads the python files to Az.Storage" {
            
            { Add-PythonFiles } | Should not throw
        }
        It "Runs the hive job" {
            
            (Start-HiveJob)[-1].Contains("100004") | Should be True
        }
        It "Runs the pig job" {
            
            (Start-PigJob)[-1].StartsWith("((2012-02-03") | Should be True
        }
    }
}
