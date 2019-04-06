# kubernetes-windows-dev
Guide to developing Kubernetes on Windows

<!-- TOC -->

- [How can I contribute to Kubernetes on Windows](#how-can-i-contribute-to-kubernetes-on-windows)
    - [Features and Bugs](#features-and-bugs)
    - [Testing](#testing)
    - [Documentation and samples](#documentation-and-samples)
- [Required tools](#required-tools)
- [Building a cluster](#building-a-cluster)
    - [Example acs-engine apimodel](#example-acs-engine-apimodel)
- [Creating Windows pod deployments](#creating-windows-pod-deployments)
- [Connecting to a Windows node](#connecting-to-a-windows-node)
    - [Simple method - Remote Desktop](#simple-method---remote-desktop)
    - [Scriptable method - PowerShell Remoting](#scriptable-method---powershell-remoting)
        - [If WinRM isn't enabled](#if-winrm-isnt-enabled)
- [Collecting Logs](#collecting-logs)
- [Hacking ACS-Engine](#hacking-acs-engine)
    - [ACS-Engine Enlistment](#acs-engine-enlistment)
    - [ACS-Engine Build](#acs-engine-build)
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
    - [Sources for kubetest](#sources-for-kubetest)
    - [Building kubetest](#building-kubetest)
    - [Running Tests](#running-tests)
        - [On an existing cluster](#on-an-existing-cluster)
        - [With a new cluster on Azure](#with-a-new-cluster-on-azure)
- [Building Other Components](#building-other-components)
    - [Azure-CNI](#azure-cni)
    - [ContainerD](#containerd)
- [Quick tips on Windows administration](#quick-tips-on-windows-administration)
    - [If you did this in bash, do this in PowerShell](#if-you-did-this-in-bash-do-this-in-powershell)
- [Credits](#credits)

<!-- /TOC -->

## How can I contribute to Kubernetes on Windows

Windows has it's own Kubernetes special interest group (SIG). The weekly meeting schedule, agenda and past recordings are all on the [SIG-Windows community page](https://github.com/kubernetes/community/tree/master/sig-windows). 


For v1.13, the sole focus is on getting Kubernetes stable and fixing outstanding conformance bugs. This [GitHub project board](https://github.com/PatrickLang/k8s-project-management/projects/1) tracks the work in these areas.

### Features and Bugs

Major features and bugs are tracked in [Windows K8s roadmap](https://trello.com/b/rjTqrwjl/windows-k8s-roadmap) trello board, and updated in the weekly SIG-Windows meetings. If the items linked to the cards aren't assigned, feel free to assign them to yourself and get started hacking on them. For more up to date details, you can query for open issues & PRs with the [sig/windows label](https://github.com/kubernetes/kubernetes/labels/sig%2Fwindows) in kubernetes/kubernetes.


### Testing

We're currently working on bringing daily and PR tests up using Prow, Kubetest, and the other tools in [kubernetes/test-infra](https://github.com/kubernetes/test-infra). The [Windows Kubernetes E2E Test](https://trello.com/b/QexBE5HK/windows-kubernetets-ee-testing) board on Trello has the current progress.


### Documentation and samples

There are some documentation topics listed in the [Windows K8s roadmap](https://trello.com/b/rjTqrwjl/windows-k8s-roadmap) trello board. Feel free to assign them (or contact us on Slack if you need help) and start writing. We definitely need documentation and samples for common scenarios including horizontal pod autoscaling, persistent volume claims, persistent sets, and applications using Kubernetes secrets and configmaps.

> TODO: link master issue for Windows API tracking

## Required tools

- [Git](https://git-scm.com/)
- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community)
- (optional but awesome) [Visual Studio Code](https://code.visualstudio.com/)
- (for Windows 10 version 1709 or older) [Putty and Pageant](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#key-management-and-agent-forwarding-with-windows-pageant) for SSH

If you're using Windows, use "Git Bash" as your command-line environment for building. It can run the same bash scripts as on Linux & Mac, and will run the build containers using Docker for Windows.

## Building a cluster

[ACS-Engine](https://github.com/Azure/acs-engine/) is what I typically use to deploy clusters. There's a [walkthrough](https://github.com/Azure/acs-engine/blob/master/docs/kubernetes/windows.md) available that I recommend for your first deployment. The rest of this guide assumes you're using acs-engine, but the steps can easily be adapted to the other deployments.

[Windows Kubernetes The Hard Way](https://github.com/pjh/kubernetes-the-hard-way) - Peter Hornyack has a guide available showing how to set up everything needed for a mixed Linux + Windows cluster on Google Cloud Platform.

[Kubernetes on Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/getting-started-kubernetes-windows) - with host gateway routing. If you want full control over the whole process or don't want to take a dependency on a cloud provider and want to use the WinCNI reference plugin that's similar to kubenet, use this guide.

### Example acs-engine apimodel

This apimodel.json is a great starting point. It includes two optional settings:

- Enable winrm for remote management
- Enable the alpha Hyper-V container support

```json
{
  "apiVersion": "vlabs",
  "properties": {
    "orchestratorProfile": {
      "orchestratorType": "Kubernetes",
      "orchestratorVersion": "1.12",
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
		"vmSize": "Standard_D2_v3",
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
	    "windowsPublisher": "MicrosoftWindowsServer",
	    "windowsOffer": "WindowsServerSemiAnnual",
	    "windowsSku": "Datacenter-Core-1803-with-Containers-smalldisk"
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

Once you have a cluster up, go ahead and run your first deployment. This assumes you have a Windows Server version 1803 node deployed. If you're using a different version, update the image with another tag for [microsoft/iis](https://hub.docker.com/r/microsoft/iis/) as needed.

```json
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iis-1803
  labels:
    app: iis-1803
spec:
  replicas: 1
  template:
    metadata:
      name: iis-1803
      labels:
        app: iis-1803
    spec:
      containers:
      - name: iis
        image: microsoft/iis:windowsservercore-1803
        ports:
          - containerPort: 80
      nodeSelector:
        "beta.kubernetes.io/os": windows
  selector:
    matchLabels:
      app: iis-1803
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
    app: iis-1803
```

Here are some repos with more samples:

- [patricklang/Windows-K8s-Samples](https://github.com/PatrickLang/Windows-K8s-Samples)


## Connecting to a Windows node

This section assumes you deployed with ACS-Engine. If you deployed another way, some changes may be needed to access the Windows node. 

### Simple method - Remote Desktop

First, get the node's private IP with `kubectl get node` and `kubectl describe node`. Most likely it's in the range of `10.240.0.*`

You can use SSH port forwarding with the Linux master node to forward a local port such as 5500 to the Windows node's private IP on port 3389.

`ssh -L 5500:<nodeip>:3389 user@linuxmaster.region.cloudapp.azure.com`

> If you're on Windows 10 version 1709 or older, here's how to [use Putty & Pageant](https://github.com/Azure/acs-engine/blob/master/docs/ssh.md#key-management-and-agent-forwarding-with-windows-pageant) instead

Once SSH is connected, use an RDP client to connect to `localhost:5500`. Use `mstsc.exe` on Windows, [FreeRDP](http://www.freerdp.com/) on Linux, or [Remote Desktop client](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/remote-desktop-mac) for Mac.

When you initially connect, there will be a command prompt open (if using Server Core), otherwise you can use the start menu to open a new PowerShell window. If you're on Server Core - run `start powershell` in that window to open a new PowerShell window.

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

## Hacking ACS-Engine

ACS-Engine work items for Windows are tracked in a GitHub [project](https://github.com/Azure/acs-engine/projects/3). Feel free to grab one if there's a feature or bug you need to work on.

### ACS-Engine Enlistment


1. Fork the [acs-engine](https://github.com/Azure/acs-engine) repo in GitHub.

2. Clone your fork of the ACS-Engine repo

```bash
# clone your fork as origin
git clone https://github.com/<your_github_username>/acs-engine.git
```

3. Set upstream to the main ACS-Engine repo.

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

1. Fetch an upstream branch such as master or release-1.12
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
git fetch upstream release-1.12
git checkout release-1.12
git push -u origin release-1.12
```

5. (optional) Cherry-pick a PR that hasn't been merged.

> This is an example of how to cherry-pick a single change. It's out of date as of November 2018, so don't use this as-is. The most up-to-date list of cherry picks is now in [scripts/prfetch.sh](scripts/prfetch.sh)

Make a cherry-pick branch

```bash
git checkout -b 1.12-cherrypick
git push --set-upstream origin 1.12-cherrypick
```

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

This section is still a work in progress. Much of the work needed is already done in https://github.com/e2e-win/e2e-win-prow-deployment

### Sources for kubetest

`kubetest` can also be downloaded from here: https://k8swin.blob.core.windows.net/k8s-windows/testing/kubetest/kubetest_latest/kubetest .

It is updated regularly and already contains the bits necessary for deploying clusters in Azure.

> TODO git repo for test-infra

### Building kubetest

`kubetest` is the end to end test runner for Kubernetes. It's built from the kubernetes/kubernetes repo, but a few changes are needed for it to work on Windows. For the latest, check out the "waiting on merge" column in the [Windows Kubernetes E2E testing board](https://trello.com/b/QexBE5HK/windows-kubernetets-ee-testing)

> Note: this list is probably not up to date - be sure to check the trello board first.

- Cherry-picks needed
  - https://github.com/kubernetes/kubernetes/pull/69571
  - https://github.com/kubernetes/kubernetes/pull/69525
  - https://github.com/kubernetes/kubernetes/pull/63600
  - https://github.com/kubernetes/kubernetes/pull/69872
- Windows test container repo list: https://github.com/e2e-win/e2e-win-prow-deployment/blob/master/repo-list.txt
- Exclusions for Linux-only tests: https://github.com/e2e-win/e2e-win-prow-deployment/blob/master/exclude_conformance_test.txt

The cherry-pick is easy to get. Checkout your cherry-pick branch, and get this additional change:

```powershell
git remote add adelina-t https://github.com/adelina-t/kubernetes
git remote add bclau https://github.com/bclau/kubernetes
git fetch bclau tests-linux-commands-fix
git cherry-pick 7cd4ebf3c3e7778efeb819c98e35846bd064fd6a
git fetch bclau tests-hostnetwork
git cherry-pick f02b6e282fe90a8701cb9c52ef7c163ead083001
git fetch bclau remove-hardcoded-yaml-images
git cherry-pick 5a561e8817bed0c45edff4ec6f3d13cb2babf943
git fetch bclau skip-windows-unrelated-tests
git cherry-pick ac66ef9c293f79eac2fb62f20027387bc4a5d93f
git push
```

Now, you can build the tests in the build VM

```bash
cd ~/go/src/k8s.io
git pull
./build/run.sh make WHAT=test/e2e/e2e.test
```

Once complete, the binary will be available at:
`~/go/src/k8s.io/kubernetes/_output/dockerized/bin/linux/amd64/e2e.test`

### Running Tests

#### On an existing cluster

The Kubernetes tests are also in the kubernetes/kubernetes repo. You can easily build and run them from the same VM used to build the Windows binaries. The binary is `e2e.test`.

> The PR fetching script at [scripts/prfetch.sh](scripts/prfetch.sh) also includes the needed changes to `e2e.test`



```bash
export KUBE_MASTER=local
#export KUBE_MASTER_IP=#masterIP # may not actually be needed if KUBECONFIG set
#export KUBE_MASTER_URL=https://#masterIP # may not actually be needed if KUBECONFIG set
export KUBECONFIG=/path/to/kubeconfig
export KUBE_TEST_REPO_LIST=$(pwd)/repo_list.yaml

curl https://raw.githubusercontent.com/e2e-win/e2e-win-prow-deployment/master/repo-list.txt -o repo_list.yaml
# run tests in background, and capture output to text files
nohup ./e2e.test --provider=local --ginkgo.noColor --ginkgo.focus=.*NodeConformance.*Conformance.* > test-all.out 2> test-all.err < /dev/null & 
```

##### NOTE

E2E tests now require all unschedulable nodes to have a label as well as a taint. Be sure to add
this label to every node you don't wish to run tests on (usually the master node in windows scenarios) otherwise tests won't start.

```bash
kubectl taint nodes $master_node_name key=value:NoSchedule
kubectl label nodes $master_node_name node-role.kubernetes.io/master=NoSchedule
```



For more on this topic, check out the official [e2e-tests](https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md#testing-against-local-clusters) doc.


#### With a new cluster on Azure



> TODO cherry-picking PRs from kubernetes/test-infra

> TODO using kubetest to build and test a new cluster


## Building Other Components

### Azure-CNI

Azure-CNI source is at [Azure/azure-container-networking](https://github.com/Azure/azure-container-networking/)

The same dev VM has everything you need to build the Azure CNI repo. Clone it inside the dev VM, then run

```bash
./build/build-all-containerized.sh windows amd64
```

## Using ContainerD

[SaswatB](https://github.com/Saswat) Set up a working environment for testing Kubernetes. It's in the Microsoft SDN repo and is used for the Windows CNI dev/test environments. You can get those scripts here https://github.com/Microsoft/SDN/tree/master/Kubernetes/containerd . I'm aiming to get this better consolidated to clarify how to build and set things up if your setup doesn't match what's prescribed in those scripts.

### Building ContainerD

> Work in progress

#### Getting Source

```
user@machine:/> cd $GOPATH
user@machine:/> mkdir -p src/github.com/containerd
user@machine:/> cd src/github.com/containerd
user@machine:/> git clone https://github.com/containerd/containerd.git
```

#### Building it

```
user@machine:/> cd $GOPATH/src/github.com/containerd/containerd
user@machine:/> export GOOS=windows
user@machine:/> make
+ bin/ctr.exe
+ bin/containerd.exe
+ bin/containerd-stress.exe
+ bin/containerd-release.exe
+ bin/containerd-shim-runhcs-v1.exe
+ binaries
```

#### Revendoring to get hcsshim changes

```
user@machine:/> go get -u github.com/lk4d4/vndr
user@machine:/> vndr github.com/Microsoft/hcsshim <new-git-commit>
```

If you intend to include a vendored change in a PR to containerd, be sure to update `vendor.conf` too.

### Setting up a node with ContainerD

>TODO - Testing Windows Server 2019 with ContainerD. VM work started here: https://github.com/patricklang/packer-windows/tree/containerd

Binaries needed

- [ ] For the CRI-ContainerD daemon:
  - [ ] containerd.exe
  - [ ] containerd-shim-runhcs-v1.exe
  - [ ] runhcs.exe
- [ ] Containerd & CRI clients:
  - [ ] ctr.exe - used for managing containers directly with ContainerD (but not CRI)
  - [ ] crictl.exe - used for managing sandboxes(pods) and containers using CRI [src](https://github.com/kubernetes-sigs/cri-tools/) [doc](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)

Configuration Steps
- [ ] Register ContainerD as service
  - [ ] Enable CRI listener for ContainerD.exe
- [ ] Getting kubelet configured to use CRI endpoint instead of dockershim


#### Create ContainerD config

If you don't already have a config file the daemon can generate one for you:
```
C:\> containerd.exe config default > config.toml
```

(Common areas of the config to change)
root - The root where all daemon data is kept
state - The state directory where all plugin data is kept snapshots, images, container bundles, etc.
grpc 
address - The address the containerd daemon will serve. Default is: \\.\pipe\containerd-containerd
debug 
level - Set to debug for all daemon debugging

> TODO: Missing CNI step

#### Test using ContainerD to pull & run an image

```
ctr.exe images pull mcr.microsoft.com/windows/nanoserver:1809
ctr.exe run --rm mcr.microsoft.com/windows/nanoserver:1809 argon-test cmd /c "echo Hello World!"
```

Example Output:

```none
PS C:\containerd> ./ctr.exe images pull mcr.microsoft.com/windows/nanoserver:1809
mcr.microsoft.com/windows/nanoserver:1809:                                        resolved       |++++++++++++++++++++++++++++++++++++++|
index-sha256:75bae46687f544f139ec57e1925d184fbb2ed70f6e0e5c993a55bd4f8e8e17a8:    exists         |++++++++++++++++++++++++++++++++++++++|
manifest-sha256:6603a3e57f2d127fbddbc7b0aa3807b02b3c25163a7c6404da1d107ce33549c4: exists         |++++++++++++++++++++++++++++++++++++++|
manifest-sha256:5953d8407d58ddc66e3eb426e320e93786a3cb173957cc5af79d46f731f3301c: exists         |++++++++++++++++++++++++++++++++++++++|
config-sha256:3601d6edd492515e2f9b352db93b0d67af0d49f1178561b5a5d50e1232c0276a:   done           |++++++++++++++++++++++++++++++++++++++|
layer-sha256:1046f7eb9dcd29d2478f707dca8726d2ae066a276196e327bd386d50f6448b2a:    done           |++++++++++++++++++++++++++++++++++++++|
config-sha256:4702b277b15f4ce1a1a3f26092229e7b79f8f6e11450d9d171bcf7367ab96350:   done           |++++++++++++++++++++++++++++++++++++++|
elapsed: 0.5 s                                                                    total:   0.0 B (0.0 B/s)              
unpacking windows/amd64 sha256:75bae46687f544f139ec57e1925d184fbb2ed70f6e0e5c993a55bd4f8e8e17a8...
done
PS C:\containerd> ./ctr.exe run --rm mcr.microsoft.com/windows/nanoserver:1809 argon-test cmd /c "echo Hello World!"
Hello World!
```

#### Test using CRI-ContainerD to pull and run an image

> TODO: this doesn't work yet, section incomplete

First, you need a sandbox/pod configuration. Copy this into a file `pod-sandbox-default.json`. It will create a process-isolated Windows pod.

```json
{
    "metadata": {
        "name": "sandbox",
        "namespace": "default",
        "attempt": 1
    }
}
```

```none
./crictl -r npipe:\\\\.\pipe\containerd-containerd pull mcr.microsoft.com/windows/nanoserver:1809
Image is up to date for sha256:4702b277b15f4ce1a1a3f26092229e7b79f8f6e11450d9d171bcf7367ab96350
```

Create the sandbox with: `.\crictl -r npipe:\\\\.\pipe\containerd-containerd runp .\pod-sandbox-default.yml`


Create a container config, copying this file into `container-config-windows-hello-world.json`

```json

```

`.\crictl.exe create <POD-ID> .\container-config-windows-hello-world.json .\pod-sandbox-default.json`





## Quick tips on Windows administration

### If you did this in bash, do this in PowerShell

bash | PowerShell
-----|-----------
`tail ...` | `Get-Content -Last 40 -Wait ...`
`ls | xargs -n1 ...` | `ls | %{ ... $_ }`


## Credits

Some of the steps were borrowed from [Kubernetes Dev on Azure](https://github.com/khenidak/kubernetes-dev-on-azure). Thanks Kal!
