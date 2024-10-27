#!/bin/bash

# Builde Reth and Rbuilder
echo "Building Reth and Rbuilder..."
if ! docker build ./ -t gwyneth-reth -f ./reth/Dockerfile
then
    echo "Failed to build Reth."
    exit 1
fi
if ! docker build ./ -t gwyneth-rbuilder -f ./rbuilder/Dockerfile
then
    echo "Failed to build Rbuilder."
    exit 1
fi

