









function Take-Ownership {
    param (
        [String]$Folder,
        [switch]$Everyone,
        [switch]$ThisItemOnly,
        [switch]$File,
        [switch]$Revoke
    )

    if ( !$file -and !($Folder.EndsWith('\')) ) {
        $Folder += '\'
    }

    if ($Folder -match ' ') {
        $Folder = '"' + $Folder + '"'
    }

    if ($Everyone) {
        if ($Revoke) {
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /REVOKE=Everyone
            }
            SubInACL.exe /FILE $Folder /REVOKE=Everyone
        } else {
            SubInACL.exe /FILE $Folder /GRANT=Everyone=F
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /GRANT=Everyone=F
            }
        }
    } else {
        if ($Revoke) {
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /REVOKE=Administrators
            }
            SubInACL.exe /FILE $Folder /REVOKE=Administrators
        } else {
            SubInACL.exe /FILE $Folder /GRANT=Administrators=F
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /GRANT=Administrators=F
            }
        }
    }
}
