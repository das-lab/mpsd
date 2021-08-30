













function Assert-That
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]
        
        $InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='Contains')]
        [object]
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        $Contains,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotContain')]
        [object]
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        $DoesNotContain,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotThrowException')]
        [Switch]
        
        $DoesNotThrowException,

        [Parameter(Mandatory=$true,ParameterSetName='ThrowsException')]
        [Type]
        
        $Throws,

        [Parameter(ParameterSetName='ThrowsException')]
        [string]
        
        $AndMessageMatches,

        [Parameter(ParameterSetName='Contains',Position=1)]
        [Parameter(ParameterSetName='DoesNotContain',Position=1)]
        [Parameter(ParameterSetName='ThrowsException',Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    switch( $PSCmdlet.ParameterSetName )
    {
        'Contains'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

does not contain

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$Contains,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -notcontains $Contains )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( -not $InputObject.Contains( $Contains ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $Contains )
                    {
                        $found = $true
                        break
                    }
                }

                if( -not $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $InputObject.ToString() -notlike ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($Contains.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotContain'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

contains

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$DoesNotContain,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -contains $DoesNotContain )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( $InputObject.Contains( $DoesNotContain ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $DoesNotContain )
                    {
                        $found = $true
                        break
                    }
                }

                if( $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $Contains -eq $null )
                {
                    $Contains = ''
                }

                if( $InputObject.ToString() -like ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($DoesNotContain.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotThrowException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `DoesNotThrowException` parameter, `-InputObject` must be a ScriptBlock.'
            }

            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                Fail ('Script block threw an exception: {0}{1}{2}{1}{3}' -f $_.Exception.Message,([Environment]::NewLine),$_.ScriptStackTrace,$Message)
            }
        }

        'ThrowsException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `Throws` parameter, `-InputObject` must be a ScriptBlock.'
            }

            $threwException = $false
            $ex = $null
            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                $ex = $_.Exception
                if( $ex -is $Throws )
                {
                    $threwException = $true
                }
                else
                {
                    Fail ('Expected ScriptBlock to throw a {0} exception, but it threw: {1}  {2}' -f $Throws,$ex,$Message)
                }
            }

            if( -not $threwException )
            {
                Fail ('ScriptBlock did not throw a ''{0}'' exception. {1}' -f $Throws.FullName,$Message)
            }

            if( $AndMessageMatches )
            {
                if( $ex.Message -notmatch $AndMessageMatches )
                {
                    Fail ('Exception message ''{0}'' doesn''t match ''{1}''.' -f $ex.Message,$AndMessageMatches)
                }
            }
        }
    }
}