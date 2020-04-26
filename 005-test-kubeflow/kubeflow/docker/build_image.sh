#!/usr/bin/env bash

# az acr login --name k8scc01covidacr

set -e

test -z "$1" && echo Need version number && exit 1

IMAGE="get-covid-data:$1"

cp -r ../../pipeline-test/image-loadData/src src
docker build . -t $IMAGE > stdout.docker.build 2> stderr.docker.build
rm -rf src



docker tag  $IMAGE k8scc01covidacr.azurecr.io/$IMAGE
docker push        k8scc01covidacr.azurecr.io/$IMAGE
