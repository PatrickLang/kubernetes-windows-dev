#!/usr/bin/env bash
echo Setting up Golang

$(cd /tmp && wget -q https://storage.googleapis.com/golang/go1.10.linux-amd64.tar.gz)
sudo tar -C /usr/local -xzf /tmp/go1.10.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" | sudo tee --append /etc/profile
echo "export PATH=\$PATH:~/go/bin" | tee --append ~/.bashrc
source /etc/profile
source ~/.bashrc