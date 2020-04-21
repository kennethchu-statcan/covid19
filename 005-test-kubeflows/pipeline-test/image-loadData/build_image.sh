#!/usr/bin/env bash

set -e

test -z "$1" && echo Need version number && exit 1

IMAGE="kenchu-kf-image-load-data:$1"

docker build . -t $IMAGE > stdout.docker.build 2> stderr.docker.build

# docker tag  $IMAGE k8scc01covidacr.azurecr.io/$IMAGE
# docker push        k8scc01covidacr.azurecr.io/$IMAGE

