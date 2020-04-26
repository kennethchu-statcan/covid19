#!/bin/sh

if [ ! -f seeds.json ]; then
    echo "Need to create seeds.txt first" >&2
    echo "Look at generate-seeds.sh" >&2
    exit 1
fi

pachctl create repo wifr-params
pachctl put file wifr-params@master -f seeds.json --split line
