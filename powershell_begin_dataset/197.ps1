Function Add-SRComment
{

    [CmdletBinding()]
    PARAM (

        [Alias("SRObject")]
        [parameter(Mandatory = $true)]
        [System.WorkItem.ServiceRequest]$ServiceRequestObject,

        [parameter(Mandatory = $True)]
        [String]$Comment,

        [ValidateSet("User", "Analyst")]
        [parameter(Mandatory = $True)]
        [System.WorkItem.TroubleTicket]
        [String]$CommentType,

        [parameter(Mandatory = $True)]
        [String]$EnteredBy,

        [Switch]$IsPrivate
    )
    BEGIN
    {
        TRY
        {
            if (-not (Get-Module -Name Smlets))
            {
                Import-Module -Name Smlets -ErrorAction 'Stop'
            }
        }
        CATCH
        {
            $Error[0]
        }
    }
    PROCESS
    {
        TRY
        {
            
            If ($ServiceRequestObject.Id -ne $NULL)
            {
                Switch ($CommentType)
                {
                    "Analyst" {
                        $CommentClass = "System.WorkItem.TroubleTicket.AnalystCommentLog"
                        $CommentClassName = "AnalystCommentLog"
                    }
                    "User" {
                        $CommentClass = "System.WorkItem.TroubleTicket.UserCommentLog"
                        $CommentClassName = "EndUserCommentLog"
                    }
                }
                
                $NewGUID = ([guid]::NewGuid()).ToString()

                
                $Projection = @{
                    __CLASS = "System.WorkItem.ServiceRequest";
                    __SEED = $ServiceRequestObject;
                    EndUserCommentLog = @{
                        __CLASS = $CommentClass;
                        __OBJECT = @{
                            Id = $NewGUID;
                            DisplayName = $NewGUID;
                            Comment = $Comment;
                            EnteredBy = $EnteredBy;
                            EnteredDate = (Get-Date).ToUniversalTime();
                            IsPrivate = $IsPrivate.ToBool();
                        }
                    }
                }

                
                New-SCSMObjectProjection -Type "System.WorkItem.ServiceRequestProjection" -Projection $Projection
            }
            else
            {
                Throw "Invalid Service Request Object!"
            }
        }
        CATCH
        {
            $Error[0]
        } 
    } 
} 