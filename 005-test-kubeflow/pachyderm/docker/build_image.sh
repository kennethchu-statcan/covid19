#!/usr/bin/env bash

# az acr login --name k8scc01covidacr

set -e

test -z "$1" && echo Need version number && exit 1

IMAGE="kenchu-wifr-analysis:$1"

docker build . -t $IMAGE > stdout.docker.build 2> stderr.docker.build

docker tag  $IMAGE k8scc01covidacr.azurecr.io/$IMAGE
docker push        k8scc01covidacr.azurecr.io/$IMAGE
