#!/bin/bash
set -e -o pipefail #-x


function verifyExists {
  if ! [ -x "$(command -v $1)" ]; then
    echo "$1 is not installed - please install it" >&2
    exit 1
  fi
}

# az aks-engine - skipped for now
for i in yq jq curl kubectl go
do
  verifyExists $i
done

# default to getting the latest args from GitHub
if [ -z "$jobUrl" ]; then jobUrl="https://raw.githubusercontent.com/kubernetes/test-infra/master/config/jobs/kubernetes-sigs/sig-windows/sig-windows-config.yaml"; fi
if [ -z "$jobName" ]; then jobName="ci-kubernetes-e2e-aks-engine-azure-master-windows"; fi
if [ -z "$testArgs" ]; then testArgs=$(curl -SsL $jobUrl | yq ".periodics[] | select(.name == \"$jobName\") | .spec.containers[].args[] | match(\"(--ginkgo.*)\";\"g\") | .captures[].string " | sed 's/\"//g' | sed 's/\\\\/\\/g' ); fi

# require existing cluster, else deploy one
if [ -z "$KUBECONFIG" ]; then echo "Missing KUBECONFIG" >&2; exit 1; fi
# echo Running aks-engine

# build latest tests
if [ -z "$GOPATH" ]; then GOPATH="$(go env GOPATH)"; fi
testBin="$GOPATH/src/k8s.io/kubernetes/_output/dockerized/bin/linux/amd64/e2e.test" 
if [ ! -f $testBin ]; then
  echo "e2e.test does not exist, building it"
  oldcd=$(pwd)
  cd $GOPATH/src/k8s.io/kubernetes
  ./build/run.sh make WHAT=test/e2e/e2e.test
  cd $oldcd
fi

# get test prerequisites
if [ -z "$KUBE_TEST_REPO_LIST" ]; then
  export KUBE_TEST_REPO_LIST=$(pwd)/repo_list
  if [ ! -f $KUBE_TEST_REPO_LIST ]; then
    curl -SsL -o repo_list https://raw.githubusercontent.com/kubernetes-sigs/windows-testing/master/images/image-repo-list
  fi
fi

nodeCount=$(kubectl get node -o wide | grep -e 'Ready.*agent.*Windows' | wc -l)
fullArgs="--provider=skeleton --num-nodes=$nodeCount --node-os-distro=windows -report-dir logs $testArgs"

echo Running $testBin $fullArgs
$testBin $fullArgs | tee run-e2e.log

#echo Getting logs from nodes with CollectLogs.ps1
