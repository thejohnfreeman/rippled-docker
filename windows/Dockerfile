# escape=`
# Let us use PowerShell line continuation.

FROM mcr.microsoft.com/dotnet/framework/sdk:4.8

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]

# We need a custom script and special tool to log installation errors.
# https://docs.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container?view=vs-2019
COPY install.cmd C:\TEMP\
ADD https://aka.ms/vscollect.exe C:\TEMP\vscollect.exe

# Use the latest release channel.
ADD https://aka.ms/vs/16/release/channel C:\TEMP\VisualStudio.chman

# Download the Visual Studio Build Tools bootstrapper.
ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
# Download the Visual Studio Community bootstrapper.
ADD https://aka.ms/vs/16/release/vs_community.exe C:\TEMP\vs_community.exe

# For help on command-line syntax:
# https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio
# Install MSVC C++ compiler, CMake, and MSBuild.
RUN C:\TEMP\install.cmd C:\TEMP\vs_buildtools.exe `
    --quiet --wait --norestart --nocache `
    --installPath C:\VisualStudio `
    --channelUri C:\TEMP\VisualStudio.chman `
    --installChannelUri C:\TEMP\VisualStudio.chman `
    --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended `
    --add Microsoft.Component.MSBuild `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0
# Install Python and Git.
RUN C:\TEMP\install.cmd C:\TEMP\vs_community.exe `
    --quiet --wait --norestart --nocache `
    --installPath C:\VisualStudio `
    --channelUri C:\TEMP\VisualStudio.chman `
    --installChannelUri C:\TEMP\VisualStudio.chman `
    --add Microsoft.VisualStudio.Component.Git `
    --add Component.CPython3.x64 `
    --add Component.CPython3.x86 `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Start developer command prompt with any other commands specified.
ENTRYPOINT C:\BuildTools\Common7\Tools\VsDevCmd.bat &&

# Default to PowerShell if no other command specified.
CMD ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
