













function Assert-Error
{
    
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='CheckLastError')]
        [Switch]
        
        $Last,

        [Parameter(Mandatory=$true,ParameterSetName='CheckFirstError')]
        [Switch]
        
        $First,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName='CheckSpecificError')]
        [int]
        
        $Index,

        [int]
        
        $Count,

        [Parameter(Mandatory=$true,Position=0,ParameterSetName='CheckLastError')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='CheckFirstError')]
        [Parameter(Mandatory=$true,Position=1,ParameterSetName='CheckSpecificError')]
        [Regex]
        
        $Regex,

        [Parameter(Position=0,ParameterSetName='Default')]
        [Parameter(Position=1,ParameterSetName='CheckLastError')]
        [Parameter(Position=1,ParameterSetName='CheckFirstError')]
        [Parameter(Position=2,ParameterSetName='CheckSpecificError')]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'
    
    Assert-GreaterThan $Global:Error.Count 0 'Expected there to be errors, but there aren''t any.'
    if( $PSBoundParameters.ContainsKey('Count') )
    {
        Assert-Equal $Count $Global:Error.Count ('Expected ''{0}'' errors, but found ''{1}''' -f $Count,$Global:Error.Count)
    }

    if( $PSCmdlet.ParameterSetName -like 'Check*Error' )
    {
        if( $PSCmdlet.ParameterSetName -eq 'CheckFirstError' )
        {
            $Index = -1
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'CheckLastError' )
        {
            $Index = 0
        }

        Assert-True ($Index -lt $Global:Error.Count) ('Expected there to be at least {0} errors, but there are only {1}. {2}' -f ($Index + 1),$Global:Error.Count,$Message)
        Assert-Match -Haystack $Global:Error[$Index].Exception.Message -Regex $Regex -Message $Message
    }
}