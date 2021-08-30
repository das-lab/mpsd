function ConvertTo-StringList
{


    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true)]
        [System.Array]$Array,

        [system.string]$Delimiter = ","
    )

    BEGIN { $StringList = "" }
    PROCESS
    {
        Write-Verbose -Message "Array: $Array"
        foreach ($item in $Array)
        {
            
            $StringList += "$item$Delimiter"
        }
        Write-Verbose "StringList: $StringList"
    }
    END
    {
        TRY
        {
            IF ($StringList)
            {
                $lenght = $StringList.Length
                Write-Verbose -Message "StringList Lenght: $lenght"

                
                $StringList.Substring(0, ($lenght - $($Delimiter.length)))
            }
        }
        CATCH
        {
            Write-Warning -Message "[END] Something wrong happening when output the result"
            $Error[0].Exception.Message
        }
        FINALLY
        {
            
            $StringList = ""
        }
    }
}