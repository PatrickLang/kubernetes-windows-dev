# Guide to developing Kubernetes on Windows

This repo is archived. If you'd like to see the old page, it's at [README.old.md](README.old.md). When I started this page, the steps needed to build and test Kubernetes and related container infrastructure were still in active development and changing frequently. During 2019, things stabilized, so it's probably better to go directly to each project to get the best documentation.

Here's the main topics that I covered previously with links to the most current documentation on each topic.

- How to set up a cluster including Kubernetes nodes
  - Using [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/windows-container-cli) for a Microsoft-supported cluster
  - Using [AKS-Engine](http://aka.ms/windowscontainers/kubernetes) for a self-supported or developent cluster
- How to build Kubernetes binaries (kubelet, kube-proxy, kubectl) for Windows
  - The key thing you need to know is `make cross KUBE_BUILD_PLATFORMS=windows/amd64`. There are two ways to get a working development environment
    - [Using Docker](https://github.com/kubernetes/kubernetes/blob/master/build/README.md) (easiest & recommended) 
    - [Using locally installed tools in Linux](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#building-kubernetes-on-a-local-osshell-environment)
- How to run tests against a Windows Kubernetes node - https://github.com/kubernetes-sigs/windows-testing
- How to [build ContainerD](https://github.com/containerd/containerd/blob/master/BUILDING.md). It's not obvious, but if you run `GOOS=windows make` it will build a Windows binary, even if you're building from a Linux machine.
- How to build and test Linux binaries using a Windows machine - use [Kind](https://kind.sigs.k8s.io/docs/user/using-wsl2/) in WSL2