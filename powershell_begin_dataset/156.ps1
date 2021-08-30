
function Get-DistributionGroupMemberRecursive
{

    [CmdletBinding()]
    PARAM ($Group)
    BEGIN
    {
        TRY
        {
            
            Write-Verbose -Message "[BEGIN] Retrieving members of $Group"
            $GroupMembers = Get-DistributionGroupMember -Identity $Group -ErrorAction Stop -ErrorVariable ErrorBeginGetDistribMembers |
            Select-object -Property Name, PrimarySMTPAddress, @{ Label = "Group"; Expression = { $Group } }, RecipientType

        }
        CATCH
        {
            Write-Warning -Message "[BEGIN] Something wrong happened"
            if ($ErrorBeginGetDistribMembers) { Write-Warning -Message "[BEGIN] Issue while retrieving members of $Group" }
            Write-Warning -Message $Error[0].Exception.Message
        }
    }
    PROCESS
    {
        FOREACH ($Member in $GroupMembers)
        {
            TRY
            {
                Write-verbose "[PROCESS] Member: $($member.name)"

                SWITCH ($Member.RecipientType)
                {
                    "MailUniversalDistributionGroup" {
                        
                        Get-DistributionGroupMemberRecursive -Group $($Member.name) |
                            Select-Object -Property Name, PrimarySMTPAddress, @{ Label = "Group"; Expression = { $($Member.name) } }, RecipientType
                        Write-Verbose -Message "[PROCESS] $($Member.name)"
                    }
                    "UserMailbox" {
                        
                        $Member | Select-object -Property Name, PrimarySMTPAddress, @{ Label = "Group"; Expression = { $Group } }
                    }
                }
            }
            CATCH
            {
                Write-Warning -Message "[PROCESS] Something wrong happened"
                Write-Warning -Message $Error[0].Exception.Message
            }
        }
    }
    END
    {
        Write-Verbose -message "[END] Done"
    }
}
