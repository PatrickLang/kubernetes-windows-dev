# kubernetes-windows-dev
Guide to developing Kubernetes on Windows


## How to contribute

Windows has it's own Kubernetes special interest group (SIG). The weekly meeting schedule, agenda and past recordings are all on the [SIG-Windows community page](https://github.com/kubernetes/community/tree/master/sig-windows). 

Major features and bugs are tracked in [Trello](https://trello.com/b/rjTqrwjl/windows-k8s-roadmap), and updated in the weekly SIG-Windows meetings. If the items linked to the cards aren't assigned, feel free to assign them to yourself and get started hacking on them. For more up to date details, you can query for open issues & PRs with the [sig/windows label](https://github.com/kubernetes/kubernetes/labels/sig%2Fwindows) in kubernetes/kubernetes.

### Required tools

All platforms:

- [Git](https://git-scm.com/)
- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community)
- (optional but awesome) [Visual Studio Code](https://code.visualstudio.com/)

If you're using Windows, use "Git Bash" as your command-line environment for building. After adding a few tools, it can run the same bash scripts as on Linux & Mac, and will run the build containers using Docker for Windows.

The first tool is [xz](https://tukaani.org/xz/). Run this from an elevated PowerShell prompt to download and put it where Git Bash will find it:

```powershell
Start-BitsTransfer https://tukaani.org/xz/xz-5.2.4-windows.zip
Expand-Archive .\xz-5.2.4-windows.zip
Move-Item xz-5.2.4-windows\bin_x86-64\* "C:\Program Files\Git\usr\bin"
```

Next, get `make`. Run this from an elevated Git Bash prompt:

```bash
cd ~/Downloads
curl http://repo.msys2.org/msys/x86_64/make-4.2.1-1-x86_64.pkg.tar.xz -o make-4.2.1-1-x86_64.pkg.tar.xz
xz -d make-4.2.1-1-x86_64.pkg.tar.xz
cd /
tar xvf ~/Downloads/make-4.2.1-1-x86_64.pkg.tar
```


## Building a cluster

[ACS-Engine](https://github.com/Azure/acs-engine/) is what I typically use to deploy clusters. There's a [walkthrough](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/windows.md) available that I recommend for your first deployment. The rest of this guide assumes you're using acs-engine, but the steps can easily be adapted to the other deployments.

[Windows Kubernetes The Hard Way](https://github.com/pjh/kubernetes-the-hard-way) - Peter Hornyack has a guide available showing how to set up everything needed for a mixed Linux + Windows cluster on Google Cloud Platform.

[Kubernetes on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/getting-started-kubernetes-windows) - with host gateway routing. If you want full control over the whole process or don't want to take a dependency on a cloud provider and want to use the WinCNI reference plugin that's similar to kubenet, use this guide.

### Hacking ACS-Engine

ACS-Engine work items for Windows are tracked in a GitHub [project](https://github.com/Azure/acs-engine/projects/3). Feel free to grab one if there's a feature or bug you need to work on.

### Enlistment


1. Fork the [acs-engine](https://github.com/Azure/acs-engine) repo in GitHub.

2. Clone your fork of the Kubernetes repo

```bash
# clone your fork as origin
git clone https://github.com/<your_github_username>/acs-engine.git
```

3. Set upstream to the main Kubernetes repo.

```bash
cd acs-engine
# add upstream repo
git remote add upstream https://github.com/Azure/acs-engine.git
```

> TODO: 4. (optional) Cherry-pick a PR that hasn't been merged.

```bash
git remote add ...
git fetch ...
git cherry-pick ...
```

### Building

Windows: run `.\makedev.ps1` in PowerShell

Mac / Linux: run `make dev`

> TODO: build steps, cross-build steps

For more details, see the full [developers guide](https://github.com/Azure/acs-engine/blob/master/docs/developers.md)

## Building Windows Kubernetes binaries

Windows development is focused on the node (kubelet, kube-proxy), and client (kubectl). So far there hasn't been any push for running the other components (apiserver, controller-manager, scheduler, kube-dns) on Windows. Those components still run on Linux nodes. Most Windows features and bugfixes will not require any changes to the Linux components.

> **Welcome contribution** - CoreDNS has builds available on Windows. It should work, but a setup guide and deployment template are needed.

### Enlistment

1. Fork the Kubernetes repo in GitHub.

2. Clone your fork of the Kubernetes repo

```bash
cd ~
mkdir -p go/src/k8s.io/

# clone your fork as origin
cd ~/go/src/k8s.io
git clone https://github.com/<your_github_username>/kubernetes.git
```

3. Set upstream to the main Kubernetes repo.

```bash
cd kubernetes
# add upstream repo
git remote add upstream https://github.com/kubernetes/kubernetes.git
```

> TODO: 4. (optional) Cherry-pick a PR that hasn't been merged.

```bash
git remote add ...
git fetch ...
git cherry-pick ...
```


### Building with Docker




For more details, check out the [Building Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/build/README.md)


### Upgrading in-place

## Testing



## Credits

Some of the steps were borrowed from [Kubernetes Dev on Azure](https://github.com/khenidak/kubernetes-dev-on-azure). Thanks Kal!