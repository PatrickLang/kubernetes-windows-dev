#!/bin/bash

set -e -x -o pipefail

GOTAG="1.13.6"
DOCKERARGS="--network=host"

OUTDIR="$(pwd)/_output"
if [ ! -d $OUTDIR ]; then
    mkdir $OUTDIR
fi

cat <<EOF > $OUTDIR/buildcri.sh
set -e -x -o pipefail
export GOOS=windows
export GOARCH=amd64
go get github.com/Microsoft/hcsshim
cd src/github.com/Microsoft/hcsshim
git rev-parse HEAD > /output/hcsshim-revision.txt
cd \$GOPATH
go build -o /output/containerd-shim-runhcs-v1.exe github.com/Microsoft/hcsshim/cmd/containerd-shim-runhcs-v1
mkdir -p src/github.com/containerd
cd src/github.com/containerd
pwd
git clone https://github.com/containerd/cri.git
cd cri
# git remote add jterry75 https://github.com/jterry75/cri.git
# git fetch jterry75
# git checkout windows_port
git rev-parse HEAD > /output/cri-revision.txt
GOOS=windows make
cp _output/* /output
apt update
apt install -y zip
cd /output
zip windows-cri-containerd.zip *.exe *.txt
rm -f /output/*.exe
rm -f /output/*.txt
EOF
chmod +x $OUTDIR/buildcri.sh

cat <<EOF > $OUTDIR/buildcni.sh
set -e -x -o pipefail
export GOOS=windows
export GOARCH=amd64
mkdir -p src/github.com/Microsoft
cd src/github.com/Microsoft
git clone https://github.com/Microsoft/windows-container-networking.git
cd windows-container-networking
git rev-parse HEAD > /output/cni-revision.txt
make all
mv out/*.exe /output
apt update
apt install -y zip
cd /output
zip windows-cni-containerd.zip *.exe *.txt
rm -f /output/*.exe
rm -f /output/*.txt
EOF
chmod +x $OUTDIR/buildcni.sh



docker run $DOCKERARGS -v $OUTDIR:/output golang:$GOTAG /bin/bash -c /output/buildcri.sh
docker run $DOCKERARGS -v $OUTDIR:/output golang:$GOTAG /bin/bash -c /output/buildcni.sh
