#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
TEMPLATE_PATH="infrastructure/kubernetes/templates/cluster-template.yaml"
CLUSTERS_DIR="infrastructure/kubernetes/clusters"
DEFAULT_REGION="us-east-1"
DEFAULT_CONTROLLER_COUNT=1
DEFAULT_CONTROLLER_INSTANCE_TYPE="t3.medium"
DEFAULT_WORKER_COUNT=2
DEFAULT_WORKER_INSTANCE_TYPE="t3.large"
DEFAULT_ENVIRONMENT="development"
DEFAULT_TEAM="platform"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo -e "${RED}kubectl is not installed. Please install it first.${NC}"
  exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo -e "${RED}git is not installed. Please install it first.${NC}"
  exit 1
fi

# Create clusters directory if it doesn't exist
mkdir -p "$CLUSTERS_DIR"

# Prompt for cluster details
echo -e "${GREEN}Welcome to the k0rdent Cluster Creation Wizard!${NC}"
echo -e "${YELLOW}Please provide the following details for your new cluster:${NC}"

read -p "Cluster Name (e.g., dev-cluster-01): " CLUSTER_NAME
if [ -z "$CLUSTER_NAME" ]; then
  echo -e "${RED}Cluster name is required.${NC}"
  exit 1
fi

read -p "Environment [$DEFAULT_ENVIRONMENT]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-$DEFAULT_ENVIRONMENT}

read -p "Team [$DEFAULT_TEAM]: " TEAM
TEAM=${TEAM:-$DEFAULT_TEAM}

read -p "AWS Region [$DEFAULT_REGION]: " REGION
REGION=${REGION:-$DEFAULT_REGION}

read -p "Controller Count [$DEFAULT_CONTROLLER_COUNT]: " CONTROLLER_COUNT
CONTROLLER_COUNT=${CONTROLLER_COUNT:-$DEFAULT_CONTROLLER_COUNT}

read -p "Controller Instance Type [$DEFAULT_CONTROLLER_INSTANCE_TYPE]: " CONTROLLER_INSTANCE_TYPE
CONTROLLER_INSTANCE_TYPE=${CONTROLLER_INSTANCE_TYPE:-$DEFAULT_CONTROLLER_INSTANCE_TYPE}

read -p "Worker Count [$DEFAULT_WORKER_COUNT]: " WORKER_COUNT
WORKER_COUNT=${WORKER_COUNT:-$DEFAULT_WORKER_COUNT}

read -p "Worker Instance Type [$DEFAULT_WORKER_INSTANCE_TYPE]: " WORKER_INSTANCE_TYPE
WORKER_INSTANCE_TYPE=${WORKER_INSTANCE_TYPE:-$DEFAULT_WORKER_INSTANCE_TYPE}

# Create cluster manifest
echo -e "${YELLOW}Creating cluster manifest...${NC}"

CLUSTER_FILE="$CLUSTERS_DIR/$CLUSTER_NAME.yaml"

# Copy template and replace placeholders
cp "$TEMPLATE_PATH" "$CLUSTER_FILE"

# Replace placeholders
sed -i "s/CLUSTER_NAME/$CLUSTER_NAME/g" "$CLUSTER_FILE"
sed -i "s/ENVIRONMENT/$ENVIRONMENT/g" "$CLUSTER_FILE"
sed -i "s/TEAM/$TEAM/g" "$CLUSTER_FILE"
sed -i "s/REGION/$REGION/g" "$CLUSTER_FILE"
sed -i "s/CONTROLLER_COUNT/$CONTROLLER_COUNT/g" "$CLUSTER_FILE"
sed -i "s/CONTROLLER_INSTANCE_TYPE/$CONTROLLER_INSTANCE_TYPE/g" "$CLUSTER_FILE"
sed -i "s/WORKER_COUNT/$WORKER_COUNT/g" "$CLUSTER_FILE"
sed -i "s/WORKER_INSTANCE_TYPE/$WORKER_INSTANCE_TYPE/g" "$CLUSTER_FILE"

echo -e "${GREEN}Cluster manifest created at $CLUSTER_FILE${NC}"

# Ask if the user wants to apply the manifest directly or create a pull request
echo -e "${YELLOW}Do you want to:${NC}"
echo "1. Apply the manifest directly (requires kubectl access to the management cluster)"
echo "2. Create a pull request (requires git access to the repository)"
read -p "Enter your choice [1/2]: " CHOICE

if [ "$CHOICE" = "1" ]; then
  # Apply the manifest directly
  echo -e "${YELLOW}Applying the manifest directly...${NC}"
  kubectl apply -f "$CLUSTER_FILE"
  
  echo -e "${GREEN}Cluster creation initiated.${NC}"
  echo -e "${YELLOW}You can check the status with:${NC}"
  echo "kubectl get cluster $CLUSTER_NAME -o wide"
  
elif [ "$CHOICE" = "2" ]; then
  # Create a pull request
  echo -e "${YELLOW}Creating a pull request...${NC}"
  
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo -e "${RED}Not in a git repository. Please run this script from the root of the k0rdent-ops repository.${NC}"
    exit 1
  fi
  
  # Create a new branch
  BRANCH_NAME="add-cluster-$CLUSTER_NAME"
  git checkout -b "$BRANCH_NAME"
  
  # Add and commit the changes
  git add "$CLUSTER_FILE"
  git commit -m "Add new cluster: $CLUSTER_NAME"
  
  # Push the changes
  git push -u origin "$BRANCH_NAME"
  
  # Provide instructions for creating a pull request
  echo -e "${GREEN}Changes pushed to branch $BRANCH_NAME.${NC}"
  echo -e "${YELLOW}Please create a pull request on GitHub:${NC}"
  echo "https://github.com/mgueye01/k0rdent-ops/pull/new/$BRANCH_NAME"
  
else
  echo -e "${RED}Invalid choice. Exiting.${NC}"
  exit 1
fi

echo -e "${GREEN}Done!${NC}"