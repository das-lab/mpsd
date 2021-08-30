














$InternalGallery = "https://www.poshtestgallery.com/api/v2/"
$InternalSource = 'OneGetTestSource'

Describe "PackageManagement Acceptance Test" -Tags "Feature" {

 BeforeAll{
    Register-PackageSource -Name Nugettest -provider NuGet -Location https://www.nuget.org/api/v2 -force
    Register-PackageSource -Name $InternalSource -Location $InternalGallery -ProviderName 'PowerShellGet' -Trusted -ErrorAction SilentlyContinue
    $SavedProgressPreference = $ProgressPreference
    $ProgressPreference = "SilentlyContinue"
 }
 AfterAll {
     $ProgressPreference = $SavedProgressPreference
 }
    It "get-packageprovider" {

        $gpp = Get-PackageProvider

        $gpp.Name | Should -Contain 'NuGet'

        $gpp.Name | Should -Contain 'PowerShellGet'
    }

    It "find-packageprovider PowerShellGet" {
        $fpp = (Find-PackageProvider -Name "PowerShellGet" -force).name
        $fpp | Should -Contain "PowerShellGet"
    }

     It "install-packageprovider, Expect succeed" {
        $ipp = (install-PackageProvider -name gistprovider -force -source $InternalSource -Scope CurrentUser).name
        $ipp | Should -Contain "gistprovider"
    }

    it "Find-package"  {
        $f = Find-Package -ProviderName NuGet -Name jquery -source Nugettest
        $f.Name | Should -Contain "jquery"
	}

    it "Install-package"  {
        $i = install-Package -ProviderName NuGet -Name jquery -force -source Nugettest -Scope CurrentUser
        $i.Name | Should -Contain "jquery"
	}

    it "Get-package"  {
        $g = Get-Package -ProviderName NuGet -Name jquery
        $g.Name | Should -Contain "jquery"
	}

    it "save-package"  {
        $s = save-Package -ProviderName NuGet -Name jquery -path $TestDrive -force -source Nugettest
        $s.Name | Should -Contain "jquery"
	}

    it "uninstall-package"  {
        $u = uninstall-Package -ProviderName NuGet -Name jquery
        $u.Name | Should -Contain "jquery"
	}
}
