
function New-CCredential
{
    
    [CmdletBinding()]
    [OutputType([Management.Automation.PSCredential])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams","")]
    param(
        [Alias('User')]
        [string]
        
        $UserName, 

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        
        $Password
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        if( $Password -is [string] )
        {
            $Password = ConvertTo-SecureString -AsPlainText -Force -String $Password
        }
        elseif( $Password -isnot [securestring] )
        {
            Write-Error ('Value for Password parameter must be a [String] or [System.Security.SecureString]. You passed a [{0}].' -f $Password.GetType())
            return
        }

        return New-Object 'Management.Automation.PsCredential' $UserName,$Password
    }
    
    end
    {
    }
}

