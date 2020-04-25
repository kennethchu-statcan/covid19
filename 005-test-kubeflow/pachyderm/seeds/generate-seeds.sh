#!/bin/bash

DEFAULT=5

N=${1:-$SIZE}

seq $N | awk '{ printf "{ \"seed\" : %d }\n", $1 }' | tee seeds.json
