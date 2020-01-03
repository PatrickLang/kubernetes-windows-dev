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
if [ -z "$testArgs" ]; then testArgs=$(curl -SsL $jobUrl | yq ".periodics[] | select(.name == \"$jobName\") | .spec.containers[].args[] | match(\"^--test_args=(.*)\";\"g\") | .captures[0].string "); fi

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

echo Running $testBin $testArgs

