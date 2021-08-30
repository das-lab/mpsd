



function Set-RsSubscription
{
  
    
  [CmdletBinding()]
  param (
    [string]
    $ReportServerUri,
    
    [System.Management.Automation.PSCredential]
    $Credential,

    $Proxy,

    [parameter(Mandatory = $false)]
    [DateTime]$StartDateTime,

    [parameter(Mandatory = $false)]
    [DateTime]$EndDate,

    [parameter(Mandatory = $False)]
    [string]$Owner,

    [Parameter(Mandatory=$true,ValueFromPipeLine)]
    [PSCustomObject[]]$SubProperties
        
  )
    
  Begin
  {
    $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    
  }
  Process
  {
    Write-Verbose "Updating Subscriptions..."
try
 {
   [xml]$XMLMatch = $SubProperties.MatchData

    if ($owner){
    $proxy.ChangeSubscriptionOwner($SubProperties.subscriptionID,$owner)
    }

            
    if ($StartDateTime)
    {
        $XMLMatch.ScheduleDefinition.StartDateTime.InnerText = $StartDateTime
    }
    
    if ($EndDate)
    {
      
      $EndExists = $XMLMatch.SelectNodes("//*") | Select-Object name | Where-Object name -eq "EndDate"
      
      if ($EndExists -eq $null)
      {
        $child = $XMLMatch.CreateElement("EndDate")
        $child.InnerText = $EndDate
        
        $XMLMatch.ScheduleDefinition.AppendChild($child)
        
      }
      else
      {
          
          $XMLMatch.ScheduleDefinition.EndDate.InnerText = $EndDate         
      } 
        
    }
    
    if ($StartDateTime -ne $null -or $EndDate -ne $null)
    {
      $null = $Proxy.SetSubscriptionProperties($SubProperties.subscriptionID, $SubProperties.DeliverySettings, $SubProperties.Description, $SubProperties.EventType, $XMLMatch.OuterXml, $SubProperties.Values) 
      Write-Verbose "subscription $($SubProperties.subscriptionId) for $($SubProperties.report) report successfully updated!"
    }
    }
    Catch
    {
     throw (New-Object System.Exception("Exception while updating subscription(s)! $($_.Exception.Message)", $_.Exception))
    }
    
  }
}

