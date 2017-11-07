FROM microsoft/windowsservercore
MAINTAINER chemso@gmx.de 

# docker push chemsorly/msbuilder
SHELL ["powershell"]

# Note: Get MSBuild 15 (VS 2017)
RUN Install-WindowsFeature NET-Framework-45-Core
RUN Invoke-WebRequest "https://aka.ms/vs/15/release/vs_BuildTools.exe" -OutFile vs_BuildTools.exe -UseBasicParsing ; \
	Start-Process -FilePath 'vs_BuildTools.exe' -ArgumentList '--quiet', '--norestart', '--locale en-US', '--all' -Wait ; \
	Remove-Item .\vs_BuildTools.exe ; \
	Remove-Item -Force -Recurse 'C:\Program Files (x86)\Microsoft Visual Studio\Installer'
RUN setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles(x86)} + '\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin')

# Note: Install full VSC installation
RUN Invoke-WebRequest "https://download.visualstudio.microsoft.com/download/pr/100196707/045b56eb413191d03850ecc425172a7d/vs_Community.exe" -OutFile "$env:TEMP\vsc.exe" -UseBasicParsing
RUN Start-Process "$env:TEMP\vsc.exe" '/full /q' -wait

# Note: Add .NET + ASP.NET runtime
RUN Install-WindowsFeature NET-Framework-45-ASPNET
RUN Install-WindowsFeature Web-Asp-Net45

# Note: Add .NET 4.5 SDK (Windows 8)
RUN Invoke-WebRequest "http://download.microsoft.com/download/F/1/3/F1300C9C-A120-4341-90DF-8A52509B23AC/standalonesdk/sdksetup.exe" -OutFile "$env:TEMP\sdksetup.exe" -UseBasicParsing  
RUN Start-Process "$env:TEMP\sdksetup.exe" '/features + /q' -wait
RUN Remove-Item "$env:TEMP\sdksetup.exe"

# Node: Add .NET 4.6.2 SDK (Windows 10)
RUN Invoke-WebRequest "http://download.microsoft.com/download/6/3/B/63BADCE0-F2E6-44BD-B2F9-60F5F073038E/standalonesdk/SDKSETUP.EXE" -OutFile "$env:TEMP\sdksetup2.exe" -UseBasicParsing  
RUN Start-Process "$env:TEMP\sdksetup2.exe" '/features + /q' -wait
RUN Remove-Item "$env:TEMP\sdksetup2.exe"

# Node: Add .NET 4.7.1 SDK (Fixes some stuff for .net standard 2.0)
RUN Invoke-WebRequest "https://download.microsoft.com/download/9/0/1/901B684B-659E-4CBD-BEC8-B3F06967C2E7/NDP471-DevPack-ENU.exe" -OutFile "$env:TEMP\sdksetup3.exe" -UseBasicParsing  
RUN Start-Process "$env:TEMP\sdksetup3.exe" '/quiet' -wait
RUN Remove-Item "$env:TEMP\sdksetup3.exe"

# Note: Add NuGet
RUN Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile "C:\windows\nuget.exe" -UseBasicParsing  
WORKDIR "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v12.0"

# Note: Install Web Targets
RUN Start-Process "C:\windows\nuget.exe" 'Install MSBuild.Microsoft.VisualStudio.Web.targets -Version 12.0.4' -wait  
RUN mv 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v12.0\MSBuild.Microsoft.VisualStudio.Web.targets.12.0.4\tools\VSToolsPath\*' 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v12.0\'  
# TODO: new webtargets

# Note: Add ClickOnce Bootstrapper files and location to registry for (VS 2015)
COPY Files/Bootstrapper/ C:/Bootstrapper/
RUN New-Item -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper -Name 15.0 -Force
RUN New-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper\15.0 -Name Path -Value C:\Bootstrapper\ -PropertyType String
RUN New-Item -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper -Name 14.0 -Force
RUN New-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper\14.0 -Name Path -Value C:\Bootstrapper\ -PropertyType String
RUN New-Item -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper -Name 11.0 -Force
RUN New-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper\11.0 -Name Path -Value C:\Bootstrapper\ -PropertyType String
RUN New-Item -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper -Name 4.0 -Force
RUN New-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\GenericBootstrapper\4.0 -Name Path -Value C:\Bootstrapper\ -PropertyType String

# Note: Add Office VSTO redist, add dependencies to GAC and add office targets
RUN Invoke-WebRequest "https://download.microsoft.com/download/F/B/A/FBAB6866-71F8-4A3F-89A4-5BC6AB035C62/vstor_redist.exe" -OutFile "$env:TEMP\vstor_redist.exe" -UseBasicParsing  
RUN Start-Process "$env:TEMP\vstor_redist.exe" '/q' -wait
RUN Remove-Item "$env:TEMP\vstor_redist.exe"
COPY Files/vsto/ C:/vsto/

# Note: Adding stuff to GAC can break it during runtime. Running the image on hyperv seems to be the cause
ENV gacutilloc="C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0a\bin\NETFX 4.6.2 Tools\gacutil.exe"
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.VisualStudio.Tools.Applications.BuildTasks.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.VisualStudio.Tools.Office.BuildTasks.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.VisualStudio.Tools.Applications.Hosting.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.VisualStudio.Tools.Applications.Hosting.resources.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.InfoPath.Permission.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.interop.access.dao.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Access.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Excel.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Graph.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.InfoPath.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.InfoPath.SemiTrust.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.InfoPath.Xml.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.MSProject.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.OneNote.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Outlook.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.OutlookViewCtl.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.PowerPoint.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Publisher.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.SharePointDesigner.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.SharePointDesignerPage.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.SmartTag.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Visio.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Visio.SaveAsWeb.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.VisOcx.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Interop.Word.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Vbe.Interop.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Vbe.Interop.Forms.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Office.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/stdole.dll' -wait
RUN Start-Process $env:gacutilloc '/i C:/vsto/Microsoft.Office.Tools.Common.v4.0.Utilities.dll' -wait
RUN New-Item -ItemType dir 'C:/Program Files (x86)/MSBuild/Microsoft/VisualStudio/v14.0/OfficeTools'
RUN Copy-Item -Path 'C:/vsto/Microsoft.VisualStudio.Tools.Office.targets' -Destination 'C:/Program Files (x86)/MSBuild/Microsoft/VisualStudio/v14.0/OfficeTools/Microsoft.VisualStudio.Tools.Office.targets'
RUN Copy-Item -Path 'C:/vsto/Microsoft.VisualStudio.OfficeTools.targets' -Destination 'C:/Program Files (x86)/MSBuild/Microsoft.VisualStudio.OfficeTools.targets'
RUN Copy-Item -Path 'C:/vsto/en' -Destination 'C:/Program Files (x86)/Microsoft Visual Studio 14.0/SDK/Bootstrapper/Packages/VSTOR40/'
RUN Copy-Item -Path 'C:/vsto/product.xml' -Destination 'C:/Program Files (x86)/Microsoft Visual Studio 14.0/SDK/Bootstrapper/Packages/VSTOR40/'
