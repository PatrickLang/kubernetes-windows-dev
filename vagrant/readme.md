This was originally posted at https://github.com/Microsoft/SDN/tree/master/Kubernetes/linux/vagrant

# Kubernetes build VM in Vagrant

This is a Vagrantfile and collection of scripts to set up a Kubernetes build environment. It's designed to make it fast and easy to build Kubernetes binaries for Windows without having to maintain a Linux VM long-term.

Vagrant uses a simple sequence of commands to handle VM management and running things inside the VM.

1. `vagrant up` starts the VM. If it doesn't exist, it will download and create it automatically.
2. `vagrant ssh` connects to the VM with SSH
3. `vagrant halt` shuts down the VM, but doesn't destroy it. `vagrant up` will start it again.
4. `vagrant destroy` stops the VM, and deletes it. All data is lost.

## Windows

First, [Install Hyper-V on Windows 10](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v), and be sure [Vagrant](https://vagrantup.com) is installed.

This VM configures a 60GB virtual disk, so make sure you have at least that much free. If you don't have that much free on C:, then copy this folder to another drive and run it there. Vagrant will place the VM in that path.

1. From an elevated prompt, run `vagrant up --provider hyperv`
2. `vagrant ssh` - make sure you can connect. If you get a prompt like `vagrant@k8s-dev:~$`, then you're good to go. Run `exit` to disconnect.

## Mac

> TODO

## Linux

> TODO