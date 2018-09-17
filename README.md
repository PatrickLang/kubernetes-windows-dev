# kubernetes-windows-dev
Guide to developing Kubernetes on Windows


## How to contribute

Windows has it's own Kubernetes special interest group (SIG). The weekly meeting schedule, agenda and past recordings are all on the [SIG-Windows community page](https://github.com/kubernetes/community/tree/master/sig-windows). 

Major features and bugs are tracked in [Trello](https://trello.com/b/rjTqrwjl/windows-k8s-roadmap), and updated in the weekly SIG-Windows meetings. If the items linked to the cards aren't assigned, feel free to assign them to yourself and get started hacking on them. For more up to date details, you can query for open issues & PRs with the [sig/windows label](https://github.com/kubernetes/kubernetes/labels/sig%2Fwindows) in kubernetes/kubernetes.

### Required tools

- [Git](https://git-scm.com/)
- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community)
- (optional but awesome) [Visual Studio Code](https://code.visualstudio.com/)

If you're using Windows, use "Git Bash" as your command-line environment for building. It can run the same bash scripts as on Linux & Mac, and will run the build containers using Docker for Windows.

## Building a cluster

[ACS-Engine](https://github.com/Azure/acs-engine/) is what I typically use to deploy clusters. There's a [walkthrough](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/windows.md) available that I recommend for your first deployment. The rest of this guide assumes you're using acs-engine, but the steps can easily be adapted to the other deployments.

[Windows Kubernetes The Hard Way](https://github.com/pjh/kubernetes-the-hard-way) - Peter Hornyack has a guide available showing how to set up everything needed for a mixed Linux + Windows cluster on Google Cloud Platform.

[Kubernetes on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/getting-started-kubernetes-windows) - with host gateway routing. If you want full control over the whole process or don't want to take a dependency on a cloud provider and want to use the WinCNI reference plugin that's similar to kubenet, use this guide.

## Hacking ACS-Engine

ACS-Engine work items for Windows are tracked in a GitHub [project](https://github.com/Azure/acs-engine/projects/3). Feel free to grab one if there's a feature or bug you need to work on.

### ACS-Engine Enlistment


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

### ACS-Engine Build

The ACS-Engine dev environment works great in containers. The repo has scripts to start it up:

Windows: run `.\makedev.ps1` in PowerShell

Mac / Linux: run `make dev`

Once it starts up, just run `make` to build the `acs-engine` binary for Linux. It will be placed at `bin/acs-engine`. This binary works great in Windows using WSL, or you can copy it to a Linux VM.

> TODO: cross-build steps

For more details, see the full [developers guide](https://github.com/Azure/acs-engine/blob/master/docs/developers.md)

## Hacking on Kubernetes for Windows

Windows development is focused on the node (kubelet, kube-proxy), and client (kubectl). So far there hasn't been any push for running the other components (apiserver, controller-manager, scheduler, kube-dns) on Windows. Those components still run on Linux nodes. Most Windows features and bugfixes will not require any changes to the Linux components.

> **Welcome contribution** - CoreDNS has builds available on Windows. It should work, but a setup guide and deployment template are needed.

### Setting up a dev/build environment

Kubernetes cannot be built on Windows natively, or in a Linux container. For now, the best option is to set up a VM, pull sources, and build there. I typically edit code on my Windows machine with Visual Studio Code (and the Go extension for linting), push to my branch frequently, then pull it in the VM and build. Once I'm done with my changes, I squash the branch, clean up the history, and then submit a PR.

The easiest way to set up a VM is to get [Vagrant](https://vagrantup.com), then follow the steps in [vagrant/readme.md](vagrant/readme.md) to start it up.


> **Welcome contribution** - update Makefile to work with Docker for Windows
>The build scripts themselves currently have blocks on OS
>
>```$ make -f build/root/Makefile cross
>!!! [0917 11:44:01] Unsupported host OS.  Must be Linux or Mac OS X.
>!!! [0917 11:44:01] Call tree:
>!!! [0917 11:44:01]  1: hack/make-rules/cross.sh:25 source(...)
>make: *** [build/root/Makefile:482: cross] Error 1

#### Kubernetes Enlistment for dev box

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

4. Make a working branch

> TODO

5. (optional) Cherry-pick a PR that hasn't been merged.

> TODO: finish this

```bash
git remote add ...
git fetch ...
git cherry-pick ...
```

#### Kubernetes Enlistment for build VM

You only need to set up a remote to the branch you're building. This uses https, which will avoid needing to log into Git since you only need read access to your branch.

```bash
mkdir -p ~/go/src/k8s.io/

# clone your fork as origin
cd ~/go/src/k8s.io
git clone https://github.com/<your_github_username>/kubernetes.git

# change to your working branch
# TODO
```


### Kubernetes Build

Connect to the build VM with `vagrant ssh`. If you haven't already started a `tmux` session, run `tmux` to start one. It will hold the scrollback buffer, and let you disconnect and reconnect if needed without stopping a build. You can detach with _Ctrl-B, d_, and reattach later using `tmux list-sessions` to get the number, then `tmux attach-session -t #` to reconnect to it.


From the build VM:

```bash
cd ~/go/src/k8s.io/kubernetes
./build/run.sh make cross
```

For more details, check out the [Building Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/build/README.md)


### Upgrading in-place

## Testing



## Credits

Some of the steps were borrowed from [Kubernetes Dev on Azure](https://github.com/khenidak/kubernetes-dev-on-azure). Thanks Kal!