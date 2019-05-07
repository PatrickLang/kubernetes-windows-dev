# Kubernetes, Windows, and CRI-ContainerD

This page describes how to build and set up CRI-ContainerD with Kubernetes on Windows. This work is tracked for Kubernetes 1.15 as [enhancement#1001](https://github.com/kubernetes/enhancements/issues/1001). For more background on how this will be used and tested, please review the [kep](https://github.com/kubernetes/enhancements/blob/master/keps/sig-windows/20190424-windows-cri-containerd.md).




## Revision History

Date       | Description
-----------|------------
2019-05-07 | Split out from README.md



## Using ContainerD

[SaswatB](https://github.com/SaswatB) Set up a working environment for testing Kubernetes. It's in the Microsoft SDN repo and is used for the Windows CNI dev/test environments. You can get those scripts here https://github.com/Microsoft/SDN/tree/master/Kubernetes/containerd . I'm aiming to get this better consolidated to clarify how to build and set things up if your setup doesn't match what's prescribed in those scripts.

### Building ContainerD

Getting all the binaries needed will require building from multiple repos. Here's the full list of what's required.

- For the CRI-ContainerD daemon:
  - containerd.exe (built from [jterry75/cri](https://github.com/jterry75/cri/tree/windows_port/cmd/containerd))
  - containerd-shim-runhcs-v1.exe (built from [Microsoft/hcsshim](https://github.com/Microsoft/hcsshim/tree/master/cmd/containerd-shim-runhcs-v1))
- Containerd & CRI clients:
  - ctr.exe - used for managing containers directly with ContainerD (but not CRI). [src](https://github.com/containerd/cri/tree/master/cmd/ctr)
  - crictl.exe - used for managing sandboxes(pods) and containers using CRI [src](https://github.com/kubernetes-sigs/cri-tools/) [doc](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)
- CNI plugin and meta-plugin
  - nat.exe - for standalone networking (not Kubernetes) - source:[Microsoft/windows-container-networking](https://github.com/Microsoft/windows-container-networking/tree/master/plugins)
  - FlannelD.exe & flannel.exe
    - SDNBridge.exe - if using `host-gw` mode - source:[Microsoft/windows-container-networking](https://github.com/Microsoft/windows-container-networking/tree/master/plugins)
    - SDNOverlay.exe - if using `overlay` mode - source:[Microsoft/windows-container-networking](https://github.com/Microsoft/windows-container-networking/tree/master/plugins)




#### Building the CRI plugin

> This is a temporary source location. Sometime in May/June 2019, it should move back to containerd/cri

```bash
cd $GOPATH
mkdir -p src/github.com/containerd
cd src/github.com/containerd
git clone https://github.com/containerd/cri.git
cd cri
git remote add jterry75 https://github.com/jterry75/cri.git
git fetch jterry75
git checkout windows_port
export GOOS=windows
make
```

This will produce `_output/containerd.exe` and `ctr.exe`



### Building CNI meta-plugins compatible with ContainerD

> Note: these steps depend on this PR https://github.com/Microsoft/windows-container-networking/pull/24. If that's not yet merged, pull from the fork listed in the PR

Clone https://github.com/Microsoft/windows-container-networking on your Linux dev/build machine, then run:

```bash
make dev
# in the container
make all
exit
```

That will produce `nat.exe`, `sdnbridge.exe`, and `sdnoverlay.exe` which are needed later.



### Future: Building from containerd/containerd

> Don't do this yet. Right now binaries need to be built from jterry75/cri to include CRI support. Skip to the next section

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

#### Future: Revendoring to get hcsshim changes

> This is optional, only if you're testing changes to hcsshim. This won't be needed once `containerd-shim-runhcs-v1.exe` is built directly from the hcsshim repo.

```
user@machine:/> go get -u github.com/lk4d4/vndr
user@machine:/> vndr github.com/Microsoft/hcsshim <new-git-commit>
```

If you intend to include a vendored change in a PR to containerd, be sure to update `vendor.conf` too.




## Setting up a node with ContainerD

>TODO - Testing Windows Server 2019 with ContainerD. VM work started here: https://github.com/patricklang/packer-windows/tree/containerd


Configuration Steps
-  Register ContainerD as service
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

> TODO: this doesn't work yet, section incomplete. ContainerD fails to start a container without a CNI configured.

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

Create the sandbox with: `.\crictl -r npipe:\\\\.\pipe\containerd-containerd runp .\pod-sandbox-default.json`


Create a container config, copying this file into `container-config-windows-hello-world.json`

```json

```

`.\crictl.exe create <POD-ID> .\container-config-windows-hello-world.json .\pod-sandbox-default.json`


#### Viewing running local pods with crictl

`crictl -r npipe:\\\\.\pipe\containerd-containerd pods`

`crictl -r npipe:\\\\.\pipe\containerd-containerd inspectp 1c0e277aba1e1`

