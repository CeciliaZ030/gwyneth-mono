#!/bin/bash

# Builde Reth and Rbuilder
echo "Building Reth and Rbuilder..."
docker build ./reth -t gwyneth_reth
docker build ./rbuilder -t rbuilder



# Define variables for images and volume names
RETH="gwyneth_reth"  # Replace with your actual image name for container A
RBUILDER="rbuilder"  # Replace with your actual image name for container B
VOLUME_EXECUTION_DATA="execution_data"
VOLUME_TMP_IPC="tmp_ipc"

# Create volumes if they do not exist
echo "Creating volumes..."
docker volume create --quiet $VOLUME_EXECUTION_DATA || echo "$VOLUME_EXECUTION_DATA already exists."
docker volume create --quiet $VOLUME_TMP_IPC || echo "$VOLUME_TMP_IPC already exists."

# Start container A
echo "Starting Reth..."
docker run -d \
    --name $RETH \
    -v $VOLUME_EXECUTION_DATA:/data/reth/execution-data \
    -v $VOLUME_TMP_IPC:/tmp/ipc \
    $RETH

# Start container B
echo "Starting rbuilder..."
docker run -d \
    --name $RBUILDER \
    -v $VOLUME_EXECUTION_DATA:/data/reth/execution-data \
    -v $VOLUME_TMP_IPC:/tmp/ipc \
    $RBUILDER

echo "Containers started successfully!"
