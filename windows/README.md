I have written about the experience and decisions that went into making this
Dockerfile [on my blog][1].

When building the image for yourself, mind the [known issues][2]:

- **Pass `--memory 2GB`** (or more). Some workloads require more than the
  default 1 GB. I'm not sure if I'm including any such workloads, but it's not
  worth the trouble to investigate.

You can customize which components the installer installs.
I have chosen these components to build `rippled`:

| Tool | Version | Component |
| ---- | ------- | --------- |
| CMake | 3.14.19050301-MSVC_2 | `Microsoft.VisualStudio.Component.VC.CMake.Project` |
| MSBuild | 16.1.76+g14b0a930a7 | `Microsoft.Component.MSBuild` |
| Visual C++ | 19.21.27702.2 | `Microsoft.VisualStudio.Workload.VCTools` |

In addition, I have installed these packages from [Scoop][]:

| Package | Version |
| ------- | ------- |
| python | 3.7.4 |
| git | 2.22.0.windows.1 |

[Scoop]: https://scoop.sh/

[1]: https://jfreeman.dev/blog/2019/07/09/what-i-learned-making-a-docker-container-for-building-c++-on-windows/
[2]: https://docs.microsoft.com/en-us/visualstudio/install/build-tools-container-issues
