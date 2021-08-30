














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