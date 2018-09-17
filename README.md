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

Since you need to build on a Linux machine, I have found that it's easiest to push all changes to a private branch, pull that in the build VM, then build.

I use a 3-deep branching strategy:
1. Fetch an upstream branch such as master or release-1.12
2. Branch off that to aggregate open PRs
3. Use a 3rd branch for my current changes

As PRs are merged, I rebase all three in order. #1 will never have conflicts. If #2 has a conflict, the open PR will also have a conflict, so wait for it to be fixed there and do a new cherry-pick. #3 - I fix conflicts, squash and update my open PR if needed.


Steps to create the branches

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

4. Fetch an upstream branch, and push it to your origin repo

```bash
git fetch upstream release-1.12
git checkout release-1.12
git push -u origin release-1.12
```

4. (optional) Make a cherry-pick branch

```bash
git checkout -b 1.12-cherrypick
git push --set-upstream origin 1.12-cherrypick
```

5. (optional) Cherry-pick a PR that hasn't been merged.

This example uses https://github.com/kubernetes/kubernetes/pull/67435. You need two pieces of information from the PR:

- The originating user (feiskyer) and branch (dns-cap)
- The commit IDs (0dc1ac03df89295c3bf5ddb7122270febe12eca2 and 3cb62394911261e3d8025d191a3ca80e6a712a67)

Create a new remote with their username, fetch their branch, cherry-pick the commits, then push to your cherrypick branch.

```bash
git remote add feiskyer https://github.com/feiskyer/kubernetes.git
git fetch feiskyer dns-cap
git cherry-pick 0dc1ac03df89295c3bf5ddb7122270febe12eca2
git cherry-pick 3cb62394911261e3d8025d191a3ca80e6a712a67
git push
```

6. Create a branch for your PR

```bash
git checkout -b mybugfix
git push --set-upstream origin mybugfix
```

#### Kubernetes Enlistment for build VM

You only need to set up a remote to the branch you're building. It's easist to use https, which will avoid needing to log into Git since you only need read access for your public branch.

```bash
mkdir -p ~/go/src/k8s.io/

# clone your fork as origin
cd ~/go/src/k8s.io
git clone https://github.com/<your_github_username>/kubernetes.git
cd kubernetes

# change to your working branch
git fetch origin mybugfix
git checkout mybugfix
```


### Kubernetes Build

Connect to the build VM with `vagrant ssh`. If you haven't already started a `tmux` session, run `tmux` to start one. It will hold the scrollback buffer, and let you disconnect and reconnect if needed without stopping a build. You can detach with _Ctrl-B, d_, and reattach later using `tmux list-sessions` to get the number, then `tmux attach-session -t #` to reconnect to it.


From the build VM:

```bash
cd ~/go/src/k8s.io/kubernetes
./build/run.sh make cross KUBE_BUILD_PLATFORMS=windows/amd64
```

It will scroll a lot as the API files are scanned, then eventually start building. Each build target has output similar to this accompanied with a few minutes of waiting.

```none
I0917 21:53:22.103338   15972 main.go:75] Completed successfully.
No changes in generated bindata file: test/e2e/generated/bindata.go
No changes in generated bindata file: pkg/generated/bindata.go
Go version: go version go1.10.3 linux/amd64
+++ [0917 21:53:22] Building go targets for windows/amd64:
    cmd/kube-proxy
    cmd/kubeadm
    cmd/kubelet
Env for windows/amd64: GOOS=windows GOARCH=amd64 GOROOT=/usr/local/go CGO_ENABLED= CC=
Coverage is disabled.
```

After the last binary is built, it will copy binaries out of the container into the VM:

```none
+++ [0917 21:56:36] Placing binaries
+++ [0917 21:56:58] Syncing out of container
+++ [0917 21:56:58] Stopping any currently running rsyncd container
+++ [0917 21:56:59] Starting rsyncd container
+++ [0917 21:57:00] Running rsync
+++ [0917 21:57:22] Stopping any currently running rsyncd container
```

Run `ls _output/dockerized/bin/windows/amd64/` to see what was built.

For more details on building, check out the [Building Kubernetes](https://github.com/kubernetes/kubernetes/blob/master/build/README.md)

#### Copying files from the build VM

Now, it's time to use SCP to copy the binaries out. 

1. Get the SSH config with `vagrant ssh-config | Out-File -Encoding ascii k8s-dev.ssh.config`
2. Copy the files out with SCP `scp -F .\k8s-dev.ssh.config k8s-dev:~/go/src/k8s.io/kubernetes/_output/dockerized/bin/windows/amd64/* .`

### Upgrading in-place




## Testing



## Credits

Some of the steps were borrowed from [Kubernetes Dev on Azure](https://github.com/khenidak/kubernetes-dev-on-azure). Thanks Kal!