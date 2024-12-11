#!/bin/bash  

# Color codes for output  
GREEN='\033[0;32m'  
RED='\033[0;31m'  
YELLOW='\033[1;33m'  
NC='\033[0m' # No Color  

# Function to check if a command exists  
command_exists() {  
    command -v "$1" >/dev/null 2>&1  
}  

# Function to check required tools based on task  
check_tools() {  
    local task=\$1  
    local required_tools=("git")  
    
    case $task in  
        "reth"|"rbuilder")  
            required_tools+=("docker")  
            ;;  
        "contracts")  
            required_tools+=("forge" "pnpm")  
            ;;  
        "all")  
            required_tools+=("docker" "forge" "pnpm")  
            ;;  
    esac  

    for tool in "${required_tools[@]}"; do  
        if ! command_exists "$tool"; then  
            echo -e "${RED}Error: $tool is not installed${NC}"  
            case $tool in  
                "git")  
                    echo "Please install Git first"  
                    ;;  
                "docker")  
                    echo "Please install Docker first: https://docs.docker.com/get-docker/"  
                    ;;  
                "forge")  
                    echo "Please install Forge first: https://book.getfoundry.sh/getting-started/installation"  
                    ;;  
                "pnpm")  
                    echo "Please install pnpm first: https://pnpm.io/installation"  
                    ;;  
            esac  
            exit 1  
        fi  
    done  
}  

# Function to check Docker daemon  
check_docker() {  
    if ! docker info >/dev/null 2>&1; then  
        echo -e "${RED}Error: Docker daemon is not running${NC}"  
        echo "Please start Docker daemon first"  
        
        if [[ "$OSTYPE" == "darwin"* ]]; then  
            echo "On macOS, start Docker Desktop application"  
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then  
            echo "Run: sudo systemctl start docker"  
        fi  
        exit 1  
    fi  
}  

# Function to handle submodules  
setup_submodules() {  
    echo -e "${YELLOW}Checking submodules...${NC}"  

    if ! git submodule status &>/dev/null; then  
        echo -e "${YELLOW}Initializing submodules...${NC}"  
        if ! git submodule init; then  
            echo -e "${RED}Failed to initialize submodules${NC}"  
            exit 1  
        fi  
        echo -e "${YELLOW}Updating submodules...${NC}"  
        if ! git submodule update --init --recursive; then  
            echo -e "${RED}Failed to update submodules${NC}"  
            exit 1  
        fi  
    fi  

    # Check all required submodules  
    local required_submodules=(  
        "rbuilder"  
        "reth"  
        "revm"  
        "revm-inspectors"  
        "ethereum-package"  
        "protocol/lib/forge-std"  
    )  

    for submodule in "${required_submodules[@]}"; do  
        if [ ! -d "$submodule" ]; then  
            echo -e "${RED}Error: Required submodule '$submodule' is missing${NC}"  
            exit 1  
        fi  
    done  

    echo -e "${GREEN}All submodules verified successfully${NC}"  
}  

# Function to build Docker image  
build_image() {  
    local name=$1  
    echo -e "${GREEN}Building ${name}...${NC}"  
    
    if [ ! -f "./${name}/Dockerfile" ]; then  
        echo -e "${RED}Error: ${name} Dockerfile not found at ./${name}/Dockerfile${NC}"  
        exit 1  
    fi  
    
    if ! docker build ./ -t "gwyneth-${name}" -f "./${name}/Dockerfile"; then  
        echo -e "${RED}Failed to build ${name}${NC}"  
        return 1  
    fi  
    
    echo -e "${GREEN}Successfully built ${name}${NC}"  
    docker images --format "table {{.Repository}}\t{{.Size}}\t{{.CreatedAt}}" | grep "gwyneth-${name}"  
}  

# Function to build contracts  
build_contracts() {  
    echo -e "\n${YELLOW}Installing dependencies in protocol directory...${NC}"  
    cd protocol || { echo -e "${RED}Failed to change to protocol directory${NC}"; exit 1; }  

    echo -e "\n${YELLOW}Running pnpm install...${NC}"  
    if ! pnpm install; then  
        echo -e "${RED}pnpm install failed${NC}"  
        exit 1  
    fi  
    echo -e "${GREEN}pnpm install completed successfully${NC}"  

    echo -e "\n${YELLOW}Running forge build...${NC}"  
    if ! forge build; then  
        echo -e "${RED}forge build failed${NC}"  
        exit 1  
    fi  
    echo -e "${GREEN}forge build completed successfully${NC}"  
    
    cd ..  
}  

# Function to install everything  
install_all() {  
    echo -e "${YELLOW}Installing all components...${NC}"  
    
    # Check all required tools first  
    check_tools "all"  
    check_docker  
    setup_submodules "all"  
    
    # Build Docker images  
    build_image "reth"  
    build_image "rbuilder"  
    
    # Build contracts  
    build_contracts  
}  

# Main execution logic  
if [ "$#" -eq 0 ]; then  
    install_all  
else  
    case "$1" in  
        "reth"|"rbuilder")  
            check_tools "$1"  
            check_docker  
            setup_submodules "$1"  
            build_image "$1"  
            ;;  
        "contracts")  
            check_tools "$1"  
            setup_submodules "$1"  
            build_contracts  
            ;;  
        *)  
            echo -e "${RED}Invalid option: \$1${NC}"  
            echo -e "Usage: \$0 [reth|rbuilder|contracts]"  
            echo -e "       \$0 (no args to install everything)"  
            exit 1  
            ;;  
    esac  
fi  

echo -e "${GREEN}All tasks completed successfully${NC}"