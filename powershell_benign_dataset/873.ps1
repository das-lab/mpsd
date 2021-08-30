$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests', ''
. "$here\$sut"

$clusterName = $ENV:ClusterName
$httpUserPassword = $ENV:HttpPassword
$securePassword = ConvertTo-SecureString $httpUserPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "admin", $securePassword



function Get-Credential { return $creds }


$mapper= @"



import sys


def read_input(file):
    
    for line in file:
        yield line.split()

def main(separator='\t'):
    
    data = read_input(sys.stdin)
    
    for words in data:
        
        for word in words:
            
            print '%s%s%d' % (word, separator, 1)

if __name__ == "__main__":
    main()
"@
$reducer=@"



from itertools import groupby
from operator import itemgetter
import sys


def read_mapper_output(file, separator='\t'):
    
    for line in file:
        
        yield line.rstrip().split(separator, 1)

def main(separator='\t'):
    
    data = read_mapper_output(sys.stdin, separator=separator)
    
    
    
    
    for current_word, group in groupby(data, itemgetter(0)):
        try:
            
            
            total_count = sum(int(count) for current_word, count in group)
            
            print "%s%s%d" % (current_word, separator, total_count)
        except ValueError:
            
            pass

if __name__ == "__main__":
    main()
"@

Describe "streaming-python" {
    
    in $TestDrive {
        
        $mapper | Out-File .\mapper.py
        $reducer | Out-File .\reducer.py
        
        Mock Read-Host { $clusterName }
        
        Mock Write-Progress { }

        It "Converts CRLF line endings to just LF" {
            
            {Fix-LineEnding("$TestDrive\mapper.py")} | Should not throw
            {Fix-LineEnding("$TestDrive\reducer.py")} | Should not throw
            '.\mapper.py' | Should not Contain "`r`n"
            '.\reducer.py' | Should not Contain "`r`n"
        }

        It "Uploads the python files and runs the job" {
            
            
            
            
            {Start-PythonExample} |  Should not throw
        }
    }
}
