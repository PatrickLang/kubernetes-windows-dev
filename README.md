# kubernetes-windows-dev
Guide to developing Kubernetes on Windows

<!-- TOC -->

- [How can I contribute to Kubernetes on Windows](#how-can-i-contribute-to-kubernetes-on-windows)
    - [Features and Bugs](#features-and-bugs)
    - [Testing](#testing)
    - [Documentation and samples](#documentation-and-samples)
- [Required tools](#required-tools)
- [Building a cluster](#building-a-cluster)
    - [Example aks-engine apimodel](#example-aks-engine-apimodel)
- [Creating Windows pod deployments](#creating-windows-pod-deployments)
- [Connecting to a Windows node](#connecting-to-a-windows-node)
    - [Simple method - Remote Desktop](#simple-method---remote-desktop)
    - [Scriptable method - SSH](#scriptable-method---ssh)
    - [Scriptable method - PowerShell Remoting](#scriptable-method---powershell-remoting)
        - [If WinRM isn't enabled](#if-winrm-isnt-enabled)
- [Collecting Logs](#collecting-logs)
- [Hacking AKS-Engine](#hacking-aks-engine)
    - [AKS-Engine Enlistment](#aks-engine-enlistment)
    - [AKS-Engine Build](#aks-engine-build)
- [Hacking on Kubernetes for Windows](#hacking-on-kubernetes-for-windows)
    - [Setting up a dev/build environment](#setting-up-a-devbuild-environment)
        - [Kubernetes Enlistment for dev box](#kubernetes-enlistment-for-dev-box)
        - [Kubernetes Enlistment for build VM](#kubernetes-enlistment-for-build-vm)
    - [Kubernetes Build](#kubernetes-build)
        - [Copying files from the build VM](#copying-files-from-the-build-vm)
    - [Installing your build](#installing-your-build)
        - [Copying binaries using Azure Files](#copying-binaries-using-azure-files)
        - [Replacing files on the node](#replacing-files-on-the-node)
- [Testing Kubernetes](#testing-kubernetes)
- [Building Other Components](#building-other-components)
    - [Azure-CNI](#azure-cni)
- [Using ContainerD](#using-containerd)
- [Quick tips on Windows administration](#quick-tips-on-windows-administration)
    - [If you did this in bash, do this in PowerShell](#if-you-did-this-in-bash-do-this-in-powershell)
- [Credits](#credits)

<!-- /TOC -->

## How can I contribute to Kubernetes on Windows

Windows has it's own Kubernetes special interest group (SIG). The weekly meeting schedule, agenda and past recordings are all on the [SIG-Windows community page](https://github.com/kubernetes/community/tree/master/sig-windows). 


This [GitHub project board](https://github.com/orgs/kubernetes/projects/8) shows the backlog and work-in progress for the current release.

### Features and Bugs

Major features and bugs are tracked in [GitHub project board](https://github.com/orgs/kubernetes/projects/8), and updated in the weekly SIG-Windows meetings. If the items linked to the cards aren't assigned, feel free to assign them to yourself and get started hacking on them. For more up to date details, you can query for open issues & PRs with the [sig/windows label](https://github.com/kubernetes/kubernetes/labels/sig%2Fwindows) in kubernetes/kubernetes.


### Testing

The current test results are available on [TestGrid]. These are run by Prow on a periodic basis, using the [SIG-Windows Job Definitions]

If you want to learn more about the Kubernetes test infrastructure, it's best to start with the [test-infra docs] and this [intro from SIG-Testing].

### Documentation and samples

User documentation is kept in the [kubernetes/website] repo. The rendered version is at [docs.kubernetes.io]. Here's the [Intro to Windows in Kubernetes].

## Required tools

- [Git](https://git-scm.com/)
- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community)
- (optional but awesome) [Visual Studio Code](https://code.visualstudio.com/)
- (for Windows 10 version 1709 or older) [Putty and Pageant](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#key-management-and-agent-forwarding-with-windows-pageant) for SSH. Windows 10 version 1803 and later have `ssh.exe` built-in which you may use instead.

If you're using Windows, use "Git Bash" as your command-line environment for building. It can run the same bash scripts as on Linux & Mac, and will run the build containers using Docker for Windows.

## Building a cluster

[AKS-Engine] is what I typically use to deploy clusters. There's a [AKS-Engine Windows Walkthrough] available that I recommend for your first deployment. The rest of this guide assumes you're using acs-engine, but the steps can easily be adapted to the other deployments.

[Windows Kubernetes The Hard Way] - Peter Hornyack has a guide available showing how to set up everything needed for a mixed Linux + Windows cluster on Google Cloud Platform.

[Intro to Windows in Kubernetes] - in the Kubernetes documentation also covers how to build an on-premises deployment

### Example aks-engine apimodel

This apimodel.json is a great starting point. It includes two optional settings:

- Enable winrm for remote management
- Enable the alpha Hyper-V container support

```json
{
  "apiVersion": "vlabs",
  "properties": {
    "orchestratorProfile": {
      "orchestratorType": "Kubernetes",
      "orchestratorVersion": "1.15",
      "kubernetesConfig": {
               "apiServerConfig" : {
                 "--feature-gates": "HyperVContainer=true"
               },
               "kubeletConfig" : {
                    "--feature-gates": "HyperVContainer=true"
                }
          }
    },
    "masterProfile": {
      "count": 1,
      "dnsPrefix": "azwink8s",
      "vmSize": "Standard_D2_v3"
    },
    "agentPoolProfiles": [
	    {
		"name": "windowspool",
		"count": 2,
		"vmSize": "Standard_D2s_v3",
		"availabilityProfile": "AvailabilitySet",
		"osType": "Windows",
		"osDiskSizeGB": 127,
		"extensions": [
		    {
          "name": "winrm"
		    }
		]
	    },
	    {
		"name": "linuxpool",
		"count": 2,
		"vmSize": "Standard_D2_v2",
		"availabilityProfile": "AvailabilitySet",
		"osType": "Linux"
	    }
    ],
    "windowsProfile": {
	    "adminUsername": "adminuser",
	    "adminPassword": "",
	    "sshEnabled": true
     },
    "extensionProfiles": [
      {
        "name": "winrm",
        "version": "v1"
      }
    ],
    "linuxProfile": {
      "adminUsername": "adminuser",
      "ssh": {
        "publicKeys": [
          {
            "keyData": ""
          }
        ]
      }
    },
    "servicePrincipalProfile": {
      "clientId": "",
      "secret": ""
    }
  }
}
```


## Creating Windows pod deployments

Once you have a cluster up, go ahead and run your first deployment. This assumes you have a Windows Server 2019 (or 1809) node deployed. If you're using a different version, update the image with another tag for [microsoft/iis](https://hub.docker.com/r/microsoft/iis/) as needed.

```json
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-2019
  labels:
    app: iis-2019
spec:
  replicas: 1
  template:
    metadata:
      name: iis-2019
      labels:
        app: iis-2019
    spec:
      containers:
      - name: iis
        image: mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019
        resources:
          limits:
            cpu: 1
            memory: 800m
          requests:
            cpu: .1
            memory: 300m
        ports:
          - containerPort: 80
      nodeSelector:
        "beta.kubernetes.io/os": windows
  selector:
    matchLabels:
      app: iis-2019
---
apiVersion: v1
kind: Service
metadata:
  name: iis
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
  selector:
    app: iis-2019
```

Here are some repos with more samples:

- [patricklang/Windows-K8s-Samples](https://github.com/PatrickLang/Windows-K8s-Samples)


## Connecting to a Windows node

This section assumes you deployed with [AKS-Engine]. If you deployed another way, some changes may be needed to access the Windows node. 

### Simple method - Remote Desktop

First, get the node's private IP with `kubectl get node` and `kubectl describe node`. Most likely it's in the range of `10.240.0.*`

You can use SSH port forwarding with the Linux master node to forward a local port such as 5500 to the Windows node's private IP on port 3389.

`ssh -L 5500:<nodeip>:3389 user@linuxmaster.region.cloudapp.azure.com`

> If you're on Windows 10 version 1709 or older, here's how to [use Putty & Pageant](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#key-management-and-agent-forwarding-with-windows-pageant) instead

Once SSH is connected, use an RDP client to connect to `localhost:5500`. Use `mstsc.exe` on Windows, [FreeRDP](http://www.freerdp.com/) on Linux, or [Remote Desktop client](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-mac) for Mac.

When you initially connect, there will be a command prompt open (if using Server Core), otherwise you can use the start menu to open a new PowerShell window. If you're on Server Core - run `start powershell` in that window to open a new PowerShell window.

### Scriptable method - SSH

First, get the node's private IP with `kubectl get node` and `kubectl describe node`. Most likely it's in the range of `10.240.0.*`

Next, SSH to the Linux master node, then to the node IP.

### Scriptable method - PowerShell Remoting

First, get the node's private IP with `kubectl get node` and `kubectl describe node`. Most likely it's in the range of `10.240.0.*`

Next, SSH to the Linux master node, and run `docker run -it mcr.microsoft.com/powershell`. Once that's running, use `Get-Credential` and `Enter-PSSession <hostname> -Credential $cred -Authentication Basic -UseSSL` to connect to the Windows node.

```bash
$ docker run -it mcr.microsoft.com/powershell
PowerShell v6.0.2
Copyright (c) Microsoft Corporation. All rights reserved.

https://aka.ms/pscore6-docs
Type 'help' to get help.

PS /> $cred = Get-Credential

PowerShell credential request
Enter your credentials.
User: azureuser
Password for user azureuser: ************

PS /> Enter-PSSession 20143k8s9000 -Credential $cred -Authentication Basic -UseSSL
[20143k8s9000]: PS C:\Users\azureuser\Documents>
```

#### If WinRM isn't enabled

If WinRM wasn't enabled when you did the deployment with ACS-Engine, you can still enable it through the Azure portal.

1. Browse to the VM in the Azure portal
2. In the left pane, browse to Operations -> Run Command
3. Click "EnableRemotePS", then click Run.

## Collecting Logs

There's a handy script that you can use to collect kubelet, kube-proxy, Docker and Windows HCS and HNS logs from every node all at once - [logslurp](https://github.com/patricklang/logslurp)

## Hacking AKS-Engine

Work items for Windows are tracked in the [AKS-Engine] repo and tagged with Windows.

### AKS-Engine Enlistment


1. Fork the [AKS-Engine] repo in GitHub.

2. Clone your fork of the [AKS-Engine] repo

```bash
# clone your fork as origin
git clone https://github.com/<your_github_username>/aks-engine.git
```

3. Set upstream to the main [AKS-Engine] repo.

```bash
cd aks-engine
# add upstream repo
git remote add upstream https://github.com/Azure/aks-engine.git
```

> TODO: 4. (optional) Cherry-pick a PR that hasn't been merged.

```bash
git remote add ...
git fetch ...
git cherry-pick ...
```

### AKS-Engine Build

The AKS-Engine dev environment works great in containers using Docker for Windows or [WSL2]. The repo has scripts to start it up:

Windows: run `.\makedev.ps1` in PowerShell

Mac / Linux: run `make dev`

Once it starts up, just run `make` to build the `aks-engine` binary for Linux. It will be placed at `bin/aks-engine`. This binary works great in Windows using WSL, or you can copy it to a Linux VM.

If you want to build Windows & Mac binaries, run `make build-cross`. The binaries will be in `_dist/aks-engine-<git tag>-<os>-<arch>`

```bash
ls _dist/
aks-engine-ee33b2b-darwin-amd64  aks-engine-ee33b2b-linux-amd64  aks-engine-ee33b2b-windows-amd64
```

For more details, see the full [developers guide](https://github.com/Azure/acs-engine/blob/master/docs/developers.md)

## Hacking on Kubernetes for Windows

Windows development is focused on the node (kubelet, kube-proxy), and client (kubectl). So far there hasn't been any push for running the other components (apiserver, controller-manager, scheduler, kube-dns) on Windows. Those components still run on Linux nodes. Most Windows features and bugfixes will not require any changes to the Linux components.

> **Welcome contribution** - CoreDNS has builds available on Windows. It should work, but a setup guide and deployment template are needed.

### Setting up a dev/build environment

Kubernetes cannot be built on Windows natively, or in a Linux container. For now, the best option is to set up a VM, pull sources, and build there. I typically edit code on my Windows machine with Visual Studio Code (and the Go extension for linting), push to my branch frequently, then pull it in the VM and build. Once I'm done with my changes, I squash the branch, clean up the history, and then submit a PR.


1. Install [Vagrant](https://vagrantup.com)
2. Copy the Vagrant folder from this repo to a drive with 60GB free
3. `cd` to that folder, then follow the steps in [vagrant/readme.md](vagrant/readme.md) to start it up.


> **Welcome contribution** - update the Kubernetes Makefile to work with Docker for Windows
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

1. Fetch an upstream branch such as master or release-1.15
2. Branch off that to aggregate open PRs
3. Use a 3rd branch for my current changes

As PRs are merged, I rebase all three in order. #1 will never have conflicts. If #2 has a conflict, the open PR will also have a conflict, so wait for it to be fixed there and do a new cherry-pick. #3 - I fix conflicts, squash and update my open PR if needed.

Steps to create the branches:

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
git fetch upstream release-1.15
git checkout release-1.15
git push -u origin release-1.15
```

5. (optional) Cherry-pick a PR that hasn't been merged.

> For an example of how to automate this see [scripts/prfetch.sh](scripts/prfetch.sh)

Make a cherry-pick branch

```bash
git checkout -b 1.15-cherrypick
git push --set-upstream origin 1.15-cherrypick
```

This example uses https://github.com/kubernetes/kubernetes/pull/67435. It merged long ago, so be sure to pick another PR if you want to try this on your own. You need two pieces of information from the PR:

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

### Installing your build

The Windows node binaries (typically in `c:\k`) can easily be replaced for testing or upgrades. The general process is:

1. Copy the new binaries to an easily accessible location - Azure Files or Google Cloud Storage work great.
2. `kubectl drain <node>`
3. Connect to the Windows node using PowerShell remoting or Remote Desktop
4. Run `net stop kubelet` on the Windows node
5. Replace `kubelet.exe` and `kube-proxy.exe`
6. Run `net start kubelet` on the Windows node
7. `kubectl uncordon <node>`


#### Copying binaries using Azure Files

1. Create a storage account [full steps](https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?toc=%2Fazure%2Fstorage%2Ffiles%2Ftoc.json&tabs=portal)
2. Create a file share [full steps](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share)
3. Mount it on [windows](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows), [mac](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-mac), or [linux](https://docs.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-linux)
4. Copy `kubelet.exe` and `kube-proxy.exe` to it
5. From the Azure Portal, browse to the Azure File Share, and click "Connect". It will open a new pane including a command to mount the share on Windows. Save that path for later.


#### Replacing files on the node

First, connect with Remote Desktop or PowerShell remoting - see [Connecting to a Windows node](#connecting-to-a-windows-node)

Find or open a new PowerShell window, and then paste in that mount command the Azure Portal from step 5 above. It will be something like `net use z: \\myazurefileaccount.file.core.windows.net\myazurefiles /u:AZURE\myazurefileaccount .......`

Now, stop the `kubelet` service, copy the files over the old ones, and restart it.

```powershell
net stop kubelet
cd \k
copy z:\kubelet.exe .
copy z:\kube-proxy.exe .
net start kubelet
```

Now, you can `kubectl uncordon` the node and run pods on it again.

## Testing Kubernetes

For steps to build the Kubernetes E2E tests and run them, see [kubernetes-sigs/windows-testing] .

[scripts/run-e2e.sh](./scripts/run-e2e.sh) is a convenience script that can make building & running tests a bit easier.

Examples:

Delete the existing test binary (if there's one), then run SIG-Windows while skipping SIG-Storage tests using 2 nodes:

```
rm ~/go/src/k8s.io/kubernetes/_output/dockerized/bin/linux/amd64/e2e.test ; nodeCount=2 testArgs='--ginkgo.focus=\[sig-windows\] --ginkgo.skip=\[sig-storage\]' ./run-e2e.sh
```

## Building Other Components

### Azure-CNI

Azure-CNI source is at [Azure/azure-container-networking](https://github.com/Azure/azure-container-networking/)

The same dev VM has everything you need to build the Azure CNI repo. Clone it inside the dev VM, then run

```bash
./build/build-all-containerized.sh windows amd64
```

## Using ContainerD

This has moved to [containerd.md](containerd.md)


## Quick tips on Windows administration

### If you did this in bash, do this in PowerShell

bash | PowerShell
-----|-----------
`tail ...` | `Get-Content -Last 40 -Wait ...`
`ls | xargs -n1 ...` | `ls | %{ ... $_ }`


## Credits

Some of the steps were borrowed from [Kubernetes Dev on Azure](https://github.com/khenidak/kubernetes-dev-on-azure). Thanks Kal!



<!-- References --> 
[TestGrid]: https://testgrid.k8s.io/sig-windows#aks-engine-azure-windows-master
[SIG-Windows Job Definitions]: https://github.com/kubernetes/test-infra/tree/master/config/jobs/kubernetes-sigs/sig-windows
[test-infra docs]: https://github.com/kubernetes/test-infra
[intro from SIG-Testing]: https://www.youtube.com/watch?v=7-_O41W3FRU
[kubernetes/website]: https://github.com/kubernetes/website/
[docs.kubernetes.io]: https://docs.kubernetes.io
[Intro to Windows in Kubernetes]: https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/
[AKS-Engine Windows Walkthrough]: https://github.com/Azure/aks-engine/blob/master/docs/topics/windows.md
[AKS-Engine]: https://github.com/Azure/aks-engine
[Windows Kubernetes The Hard Way]: https://github.com/pjh/kubernetes-the-hard-way
[WSL2]: https://docs.microsoft.com/en-us/windows/wsl/wsl2-install
[kubernetes-sigs/windows-testing]: https://github.com/kubernetes-sigs/windows-testing
