# escape=`
# Let us use PowerShell line continuation.

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# Use the latest release channel.
ADD https://aka.ms/vs/16/release/channel C:\TEMP\VisualStudio.chman

# Download the Build Tools bootstrapper.
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe

# Install Build Tools excluding workloads and components with known issues.
# For help on command-line syntax:
# https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --channelUri C:\TEMP\VisualStudio.chman `
    --installChannelUri C:\TEMP\VisualStudio.chman `
    --add Microsoft.VisualStudio.Component.VC.CMake.Project `
    --add Microsoft.VisualStudio.Component.Git `
    --add Component.CPython3.x64 `
    --add Component.CPython3.x86 `
    --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Start developer command prompt with any other commands specified.
ENTRYPOINT C:\BuildTools\Common7\Tools\VsDevCmd.bat &&

# Default to PowerShell if no other command specified.
CMD ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
