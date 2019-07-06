It is unclear whether we can publish this image to Docker Hub based on
[this statement][1] from a Microsoft Program Manager, Marc Goodner:

> Remember that the VS Build Tools are licensed as a supplement to your
> existing Visual Studio license. Any images built with these tools should be
> for your personal use or for use in your organization in accordance with
> your existing Visual Studio and Windows licenses. Please don’t share these
> images on a public Docker hub.

Visual Studio Community Edition is [free][2] for:

- individuals (even for commercial use)
- open source
- academic research
- training and education
- up to 5 employees of a small business (defined as fewer than 250 employees
  and less than $1 million in annual revenue)

If I am using Visual Studio Community Edition and Visual Studio Build Tools
under these conditions, am I still prohibited from sharing an image for other
users under the same conditions? Regardless, it seems I should be able to
share a Dockerfile [just like Microsoft][11].

This Dockerfile is based off some examples from Microsoft:

- [basic][9]
- [advanced][10]
- [`vs-dockerfiles/native-desktop`][12]

When building the image for yourself, mind the [known issues][3]:

- **Pass `--memory 2GB`** (or more). Some workloads require more than the
  default 1 GB. I'm not sure if I'm including any such workloads, but it's not
  worth the trouble to investigate.
- The Dockerfile passes the `--norestart` option to Visual Studio Build Tools.
  If you edit the Dockerfile, do not remove that option.
- Choose a [.NET Framework SDK base image][4] that is version 4.7.1 or later.
- The default storage limit for builds has [increased to 127 GB][5] from 20 GB
  (and [a full install of Visual Studio Build Tools can take 58 GB][7]),
  but if you run into problems, you can [edit][6] your Docker configuration at
  `C:\ProgramData\Docker\config\daemon.json` to add `"storage-opts":
  ["size=xxxGB"]`.

You can customize which [components][8] the Visual Studio Build Tools
installer installs. I have chosen these components to build `rippled`:

| Tool | Version | Component |
| ---- | ------- | --------- |
| CMake | 3.14 | `Microsoft.VisualStudio.Component.VC.CMake.Project` |
| Git | ??? | `Microsoft.VisualStudio.Component.Git` |
| MSBuild | 16.1 | `Microsoft.Component.MSBuild` |
| Python | ??? | `Component.CPython3.x64` |
| Python | ??? | `Component.CPython3.x86` |
| Visual C++ | ??? | `Microsoft.VisualStudio.Workload.VCTools`  |

> **WARNING**: This Dockerfile is a work-in-progress and aspirational. I will
> fill in the rest of the table as I learn how to install these components and
> where they are installed.

[1]: https://devblogs.microsoft.com/cppblog/using-msvc-in-a-docker-container-for-your-c-projects/
[2]: https://social.msdn.microsoft.com/Forums/vstudio/en-US/1f5c4e2f-d667-4c37-978b-9112e49142fc/visual-studio-community-edition-commercial-use-and-licensing-headaches
[3]: https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container-issues
[4]: https://hub.docker.com/_/microsoft-dotnet-framework-sdk/
[5]: https://github.com/moby/moby/issues/34947#issuecomment-442994229
[6]: https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-storage#image-size
[7]: https://devblogs.microsoft.com/setup/no-container-image-for-build-tools-for-visual-studio-2017/
[8]: https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools
[9]: https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container
[10]: https://docs.microsoft.com/en-us/visualstudio/install/advanced-build-tools-container
[11]: https://devblogs.microsoft.com/setup/docker-recipes-available-for-visual-studio-build-tools/
[12]: https://github.com/microsoft/vs-dockerfiles/blob/master/native-desktop/Dockerfile
