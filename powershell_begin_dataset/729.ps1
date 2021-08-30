


function Import-RsSubscriptionXml {
    

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True,Position=0)]
        [string]
        $Path,

        [string]
        $ReportServerUri,

        [System.Management.Automation.PSCredential]
        $Credential,

        $Proxy
    )

    Begin
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        $Namespace = $Proxy.GetType().NameSpace
    }
    Process
    {
        Write-Verbose "Importing Subscription from $Path..."
        $Subscription = Import-Clixml $Path

        foreach ($Sub in $Subscription) 
        {
            
            $ParameterValues = @()

            $Sub.DeliverySettings.ParameterValues | ForEach-Object {
                if ($_.Name)
                {
                    $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
                }
                elseif ($_.ParameterName)
                {
                    $ParameterValues = $ParameterValues + (New-Object "$Namespace.ParameterFieldReference" -Property @{ ParameterName = $_.ParameterName; FieldAlias = $_.FieldAlias })
                }
            }

            $DeliverySettings = @{
                Extension = $Sub.DeliverySettings.Extension
                ParameterValues = $ParameterValues 
            }

            $Sub.DeliverySettings = (New-Object "$Namespace.ExtensionSettings" -Property $DeliverySettings)

            
            $Values = @()

            $Sub.Values | ForEach-Object {

                if ($_.Name)
                {
                    $Values = $Values + (New-Object "$Namespace.ParameterValue" -Property @{ Name = $_.Name; Value = $_.Value })
                }
                elseif ($_.ParameterName)
                {
                    $Values = $Values + (New-Object "$Namespace.ParameterFieldReference" -Property @{ ParameterName = $_.ParameterName; FieldAlias = $_.FieldAlias })
                }
            }
            $Sub.Values = $Values


            
            if ($Sub.IsDataDriven)
            {
                $DataSetDefinitionFields = @()
                    
                $Sub.DataRetrievalPlan.DataSet.Fields | ForEach-Object {
                    $DataSetDefinitionFields     = $DataSetDefinitionFields + (New-Object "$Namespace.Field" -Property @{ Alias = $_.Alias; Name  = $_.Name })
                }

                $DataSetDefinition = New-Object "$Namespace.DataSetDefinition"
                $DataSetDefinition.Fields = $DataSetDefinitionFields

                $DataSetDefinition.Query = New-Object "$Namespace.QueryDefinition"

                $DataSetDefinition.Query.CommandType            = $sub.DataRetrievalPlan.DataSet.Query.CommandType
                $DataSetDefinition.Query.CommandText            = $sub.DataRetrievalPlan.DataSet.Query.CommandText
                $DataSetDefinition.Query.Timeout                = $sub.DataRetrievalPlan.DataSet.Query.Timeout
                $DataSetDefinition.Query.TimeoutSpecified       = $sub.DataRetrievalPlan.DataSet.Query.TimeoutSpecified

                $DataSetDefinition.CaseSensitivity              = $sub.DataRetrievalPlan.DataSet.CaseSensitivity
                $DataSetDefinition.CaseSensitivitySpecified     = $sub.DataRetrievalPlan.DataSet.CaseSensitivitySpecified
                $DataSetDefinition.Collation                    = $sub.DataRetrievalPlan.DataSet.Collation
                $DataSetDefinition.AccentSensitivity            = $sub.DataRetrievalPlan.DataSet.AccentSensitivity
                $DataSetDefinition.AccentSensitivitySpecified   = $sub.DataRetrievalPlan.DataSet.AccentSensitivitySpecified
                $DataSetDefinition.KanatypeSensitivity          = $sub.DataRetrievalPlan.DataSet.KanatypeSensitivity
                $DataSetDefinition.KanatypeSensitivitySpecified = $sub.DataRetrievalPlan.DataSet.KanatypeSensitivitySpecified
                $DataSetDefinition.WidthSensitivity             = $sub.DataRetrievalPlan.DataSet.WidthSensitivity
                $DataSetDefinition.WidthSensitivitySpecified    = $sub.DataRetrievalPlan.DataSet.WidthSensitivitySpecified
                $DataSetDefinition.Name                         = $sub.DataRetrievalPlan.DataSet.Name

                $DataRetrievalPlanItem = New-Object "$Namespace.DataSourceReference"
                $DataRetrievalPlanItem.Reference = $sub.DataRetrievalPlan.Item.Reference

                $DataRetrievalSettings = @{ 
                    Item = $DataRetrievalPlanItem
                    DataSet = $DataSetDefinition
                }

                $DataRetrievalPlan = New-Object "$Namespace.DataRetrievalPlan" -Property $DataRetrievalSettings

                $Sub.DataRetrievalPlan = $DataRetrievalPlan  
            }

            
            $Sub
        }
    }
}