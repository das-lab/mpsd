
function Get-CMsi
{
    
    [CmdletBinding()]
    [OutputType('Carbon.Msi.MsiInfo')]
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('FullName')]
        [string[]]
        
        $Path
    )
    
    begin 
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process 
    {
        $Path |
            Resolve-Path |
            Select-Object -ExpandProperty 'ProviderPath' |
            ForEach-Object {

                $msiPath = $_

                try
                {
                    Write-Verbose ('Opening MSI {0}' -f $msiPath)
                    New-Object -TypeName 'Carbon.Msi.MsiInfo' -ArgumentList $msiPath
                }
                catch
                {
                    $ex = $_.Exception
                    $errMsg = 'Failed to open MSI file ''{0}''.' -f $msiPath
                    if( $ex )
                    {
                        $errMsg = '{0} {1} was thrown. The exception message is: ''{2}''.' -f $errMsg,$ex.GetType().FullName,$ex.Message
                        if( $ex -is [Runtime.InteropServices.COMException] )
                        {
                            $errMsg = '{0} HRESULT: {1:x}. (You can look up the meaning of HRESULT values at https://msdn.microsoft.com/en-us/library/cc704587.aspx.)' -f $errMsg,$ex.ErrorCode
                        }
                    }
                    Write-Error -Message $errMsg
                    return
                }


            }
    }

    end 
    {
    }
}
