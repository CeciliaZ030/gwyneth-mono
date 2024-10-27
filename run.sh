#!/bin/bash

# Run the Kurtosis command and capture its output
echo "Running Kurtosis command..."
KURTOSIS_OUTPUT=$(kurtosis run github.com/adaki2004/ethereum-package --args-file ./scripts/confs/network_params.yaml)

# Extract the Blockscout port
BLOCKSCOUT_PORT=$(echo "$KURTOSIS_OUTPUT" | grep -A 5 "^[a-f0-9]\+ *blockscout " | grep "http:" | sed -E 's/.*-> http:\/\/127\.0\.0\.1:([0-9]+).*/\1/' | head -n 1)

if [ -z "$BLOCKSCOUT_PORT" ]; then
    echo "Failed to extract Blockscout port."
    exit 1
fi

echo "Extracted Blockscout port: $BLOCKSCOUT_PORT"
echo "$BLOCKSCOUT_PORT" > /tmp/kurtosis_blockscout_port
# # Print the entire Kurtosis output for debugging
echo "Kurtosis Output:"
echo "$KURTOSIS_OUTPUT"

# Extract the "User Services" section
USER_SERVICES_SECTION=$(echo "$KURTOSIS_OUTPUT" | awk '/^========================================== User Services ==========================================/{flag=1;next}/^$/{flag=0}flag')
# Print the "User Services" section for debugging
echo "User Services Section:"
echo "$USER_SERVICES_SECTION"
# Extract the dynamic port assigned to the rpc service for "el-1-reth-lighthouse"
RPC_PORT=$(echo "$USER_SERVICES_SECTION" | grep -A 5 "el-1-reth-lighthouse" | grep "rpc: 8545/tcp" | sed -E 's/.* -> 127.0.0.1:([0-9]+).*/\1/')
if [ -z "$RPC_PORT" ]; then
    echo "Failed to extract RPC port from User Services section."
    exit 1
else
    echo "Extracted RPC port: $RPC_PORT"
    echo "$RPC_PORT" > /tmp/kurtosis_rpc_port
fi

# Extract the Starlark output section
STARLARK_OUTPUT=$(echo "$KURTOSIS_OUTPUT" | awk '/^Starlark code successfully run. Output was:/{flag=1; next} /^$/{flag=0} flag')

# Extract the beacon_http_url for cl-1-lighthouse-reth
BEACON_HTTP_URL=$(echo "$STARLARK_OUTPUT" | jq -r '.all_participants[] | select(.cl_context.beacon_service_name == "cl-1-lighthouse-reth") | .cl_context.beacon_http_url')

if [ -z "$BEACON_HTTP_URL" ]; then
    echo "Failed to extract beacon_http_url for cl-1-lighthouse-reth."
    exit 1
else
    echo "Extracted beacon_http_url: $BEACON_HTTP_URL"
    echo "$BEACON_HTTP_URL" > /tmp/kurtosis_beacon_http_url
fi

# Find the correct Docker container
CONTAINER_ID=$(docker ps --format '{{.ID}} {{.Names}}' | grep 'el-1-reth-lighthouse--' | awk '{print $1}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Failed to find the el-1-reth-lighthouse container."
    exit 1
else
    echo "Found container ID: $CONTAINER_ID"
fi



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
