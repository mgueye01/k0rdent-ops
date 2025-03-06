#!/bin/bash

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
AWS_REGION=${AWS_REGION:-"us-east-1"}
CLUSTER_NAME=${CLUSTER_NAME:-"k0rdent-cluster"}
SSH_KEY_NAME=${SSH_KEY_NAME:-"k0rdent"}
SSH_PRIVATE_KEY_PATH=${SSH_PRIVATE_KEY_PATH:-"~/.ssh/k0rdent"}

# Check prerequisites
check_prerequisites() {
  echo -e "${YELLOW}Checking prerequisites...${NC}"
  
  # Check AWS CLI
  if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check Terraform
  if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check kubectl
  if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check k0sctl
  if ! command -v k0sctl &> /dev/null; then
    echo -e "${RED}k0sctl is not installed. Please install it first.${NC}"
    exit 1
  fi
  
  # Check AWS credentials
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}AWS credentials are not set. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}All prerequisites are met.${NC}"
}

# Create SSH key if it doesn't exist
create_ssh_key() {
  echo -e "${YELLOW}Checking SSH key...${NC}"
  
  if [ ! -f "$SSH_PRIVATE_KEY_PATH" ]; then
    echo -e "${YELLOW}SSH key not found. Creating a new one...${NC}"
    ssh-keygen -t rsa -b 4096 -f "$SSH_PRIVATE_KEY_PATH" -N ""
    echo -e "${GREEN}SSH key created at $SSH_PRIVATE_KEY_PATH${NC}"
  else
    echo -e "${GREEN}SSH key already exists at $SSH_PRIVATE_KEY_PATH${NC}"
  fi
  
  # Import the key to AWS if it doesn't exist
  if ! aws ec2 describe-key-pairs --key-names "$SSH_KEY_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${YELLOW}Importing SSH key to AWS...${NC}"
    aws ec2 import-key-pair --key-name "$SSH_KEY_NAME" --public-key-material "fileb://${SSH_PRIVATE_KEY_PATH}.pub" --region "$AWS_REGION"
    echo -e "${GREEN}SSH key imported to AWS.${NC}"
  else
    echo -e "${GREEN}SSH key already exists in AWS.${NC}"
  fi
}

# Deploy infrastructure
deploy_infrastructure() {
  echo -e "${YELLOW}Deploying infrastructure...${NC}"
  
  cd infrastructure/terraform/aws
  
  # Initialize Terraform
  echo -e "${YELLOW}Initializing Terraform...${NC}"
  terraform init
  
  # Create terraform.tfvars
  echo -e "${YELLOW}Creating terraform.tfvars...${NC}"
  cat > terraform.tfvars <<EOF
aws_region = "${AWS_REGION}"
ssh_key_name = "${SSH_KEY_NAME}"
ssh_private_key_path = "${SSH_PRIVATE_KEY_PATH}"
cluster_name = "${CLUSTER_NAME}"
EOF
  
  # Apply Terraform
  echo -e "${YELLOW}Applying Terraform...${NC}"
  terraform apply -auto-approve
  
  # Get outputs
  CONTROLLER_IPS=$(terraform output -json controller_ips | jq -r '.[]')
  WORKER_IPS=$(terraform output -json worker_ips | jq -r '.[]')
  API_ENDPOINT=$(terraform output -json api_endpoint | jq -r '.')
  K0SCTL_CONFIG_PATH=$(terraform output -json k0sctl_config_path | jq -r '.')
  
  echo -e "${GREEN}Infrastructure deployed successfully.${NC}"
  echo -e "${GREEN}Controller IPs: $CONTROLLER_IPS${NC}"
  echo -e "${GREEN}Worker IPs: $WORKER_IPS${NC}"
  echo -e "${GREEN}API Endpoint: $API_ENDPOINT${NC}"
  
  cd ../../..
}

# Deploy k0s
deploy_k0s() {
  echo -e "${YELLOW}Deploying k0s...${NC}"
  
  cd infrastructure/terraform/aws
  
  # Apply k0sctl
  echo -e "${YELLOW}Applying k0sctl...${NC}"
  k0sctl apply --config k0sctl.yaml
  
  # Get kubeconfig
  echo -e "${YELLOW}Getting kubeconfig...${NC}"
  k0sctl kubeconfig --config k0sctl.yaml > kubeconfig
  
  # Set KUBECONFIG
  export KUBECONFIG=$(pwd)/kubeconfig
  
  echo -e "${GREEN}k0s deployed successfully.${NC}"
  echo -e "${GREEN}Kubeconfig saved to $(pwd)/kubeconfig${NC}"
  
  cd ../../..
}

# Deploy k0rdent
deploy_k0rdent() {
  echo -e "${YELLOW}Deploying k0rdent...${NC}"
  
  # Add Helm repository
  echo -e "${YELLOW}Adding Helm repository...${NC}"
  helm repo add k0rdent https://k0rdent.github.io/charts
  helm repo update
  
  # Create namespace
  echo -e "${YELLOW}Creating namespace...${NC}"
  kubectl create namespace k0rdent-system --dry-run=client -o yaml | kubectl apply -f -
  
  # Create SSH key secret
  echo -e "${YELLOW}Creating SSH key secret...${NC}"
  kubectl create secret generic k0rdent-ssh-key --from-file=id_rsa="$SSH_PRIVATE_KEY_PATH" -n k0rdent-system --dry-run=client -o yaml | kubectl apply -f -
  
  # Create values.yaml
  echo -e "${YELLOW}Creating values.yaml...${NC}"
  cd infrastructure/terraform/k0rdent
  
  # Replace environment variables in values.yaml
  envsubst < values.yaml > values.yaml.tmp
  mv values.yaml.tmp values.yaml
  
  # Install k0rdent
  echo -e "${YELLOW}Installing k0rdent...${NC}"
  helm install k0rdent k0rdent/k0rdent \
    --namespace k0rdent-system \
    --values values.yaml
  
  echo -e "${GREEN}k0rdent deployed successfully.${NC}"
  
  cd ../../..
}

# Deploy ArgoCD
deploy_argocd() {
  echo -e "${YELLOW}Deploying ArgoCD...${NC}"
  
  # Add Helm repository
  echo -e "${YELLOW}Adding Helm repository...${NC}"
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  
  # Create namespace
  echo -e "${YELLOW}Creating namespace...${NC}"
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  
  # Install ArgoCD
  echo -e "${YELLOW}Installing ArgoCD...${NC}"
  helm install argocd argo/argo-cd \
    --namespace argocd \
    --set server.service.type=LoadBalancer
  
  # Wait for ArgoCD to be ready
  echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
  
  # Get ArgoCD password
  echo -e "${YELLOW}Getting ArgoCD password...${NC}"
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
  
  # Get ArgoCD URL
  echo -e "${YELLOW}Getting ArgoCD URL...${NC}"
  ARGOCD_URL=$(kubectl -n argocd get svc argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
  
  echo -e "${GREEN}ArgoCD deployed successfully.${NC}"
  echo -e "${GREEN}ArgoCD URL: https://$ARGOCD_URL${NC}"
  echo -e "${GREEN}ArgoCD Username: admin${NC}"
  echo -e "${GREEN}ArgoCD Password: $ARGOCD_PASSWORD${NC}"
}

# Configure kubectl
configure_kubectl() {
  echo -e "${YELLOW}Configuring kubectl...${NC}"
  
  # Copy kubeconfig to ~/.kube/config
  mkdir -p ~/.kube
  cp infrastructure/terraform/aws/kubeconfig ~/.kube/config
  
  echo -e "${GREEN}kubectl configured successfully.${NC}"
}

# Main function
main() {
  echo -e "${GREEN}Starting k0rdent-ops deployment...${NC}"
  
  check_prerequisites
  create_ssh_key
  deploy_infrastructure
  deploy_k0s
  deploy_k0rdent
  deploy_argocd
  configure_kubectl
  
  echo -e "${GREEN}k0rdent-ops deployed successfully!${NC}"
  echo -e "${GREEN}You can now use kubectl to interact with your cluster.${NC}"
  echo -e "${GREEN}To create a new cluster, run: ./scripts/create-cluster.sh${NC}"
}

# Run main function
main