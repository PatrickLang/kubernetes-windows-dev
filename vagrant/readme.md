This was originally posted at https://github.com/Microsoft/SDN/tree/master/Kubernetes/linux/vagrant

# Usage

- Leverage this ubuntu box as an easy way for primarily Windows users to compile k8s
- Reference on requirements for Ubuntu 16.04 to not run into delays/issues

## Typical usage

Windows


1. [Install Hyper-V on Windows 10](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)
2. From an elevated prompt, run `vagrant up --provider hyperv`
3. `vagrant ssh`